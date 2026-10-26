#!/usr/bin/env bash
# Search Forge server sizes across DigitalOcean and Laravel VPS, and propose equivalents.
#
#   find-size.sh premium intel 8gb 4vcpu          # free-text search, both providers
#   find-size.sh laravel 4gb                      # "laravel"/"vps" or "digitalocean"/"do" restricts the provider
#   find-size.sh --like <server_id>               # current capacity of that server + equivalent sizes on both providers
#   find-size.sh --like <server_id> intel         # equivalents filtered by extra words
#
# Numbers followed by gb/mb are RAM, numbers followed by vcpu/cpu/core are CPUs, other words are
# matched against the size name (case-insensitive). Output: provider, size id, code, RAM, vCPU, disk, USD/month, name.
# The catalog is cached for one hour in ~/.forge-migrations/cache/.
# Prices are not in the Forge API: they come from two public pages, refreshed hourly, and are indicative.
#   - Laravel VPS: https://vps.forge.laravel.com/api/prices (the JSON behind the docs' pricing table);
#     the Business tier price is shown (Witify is on that tier).
#   - DigitalOcean: the size objects embedded in https://www.digitalocean.com/pricing/droplets, matched by slug.
# A "?" means no public price was found for that size.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
API="$HERE/forge-api.sh"
CACHE="$HOME/.forge-migrations/cache"; mkdir -p "$CACHE"; chmod 700 "$HOME/.forge-migrations"

PROVIDERS="1 12"   # 1 = DigitalOcean (ocean2), 12 = Laravel VPS (laravel)
pname() { case "$1" in 1) echo "DigitalOcean";; 12) echo "Laravel VPS";; *) echo "provider $1";; esac; }

catalog() { # provider -> json lines {provider,id,code,ram,cpus,disk,name}
  local p="$1" f="$CACHE/sizes-$p.json"
  if [ ! -f "$f" ] || [ -n "$(find "$f" -mmin +60)" ]; then
    local cur="" out all="[]"
    while :; do
      local q="page[size]=100"; [ -n "$cur" ] && q="$q&page[cursor]=$cur"
      out="$("$API" GET "/providers/$p/sizes" "$q" 2>/dev/null)"
      all="$(jq -n --argjson a "$all" --argjson b "$(echo "$out" | jq '.data')" '$a + $b')"
      cur="$(echo "$out" | jq -r '.meta.next_cursor // empty')"; [ -z "$cur" ] && break
    done
    echo "$all" > "$f"
  fi
  jq -c --arg p "$p" --arg pn "$(pname "$p")" '.[] | {provider:$pn, pid:$p, id:.id, code:.attributes.code, ram:.attributes.ram, cpus:.attributes.cpus, disk:.attributes.disk, name:.attributes.name}' "$f"
}

prices() { # refresh the two public price sources into the cache (best effort; failures leave "?" prices)
  local f="$CACHE/do-prices.json"
  if [ ! -s "$f" ] || [ -n "$(find "$f" -mmin +60)" ]; then
    curl -sL -A "Mozilla/5.0" https://www.digitalocean.com/pricing/droplets 2>/dev/null | sed 's/\\"/"/g' \
      | grep -o -E '\{"memory":[0-9.]+,"cpus":[0-9]+,"disk":\{[^}]*\},"network":\{[^}]*\},"api":(true|false),"price":\{[^}]*\},"slug":"[^"]+"\}' \
      | jq -s 'map({key:.slug, value:.price.monthly}) | from_entries' > "$f.tmp" 2>/dev/null && [ -s "$f.tmp" ] && mv "$f.tmp" "$f" || { rm -f "$f.tmp"; [ -s "$f" ] || echo '{}' > "$f"; }
  fi
  f="$CACHE/vps-prices.json"
  if [ ! -s "$f" ] || [ -n "$(find "$f" -mmin +60)" ]; then
    curl -s https://vps.forge.laravel.com/api/prices > "$f.tmp" 2>/dev/null && jq -e 'type=="array"' "$f.tmp" >/dev/null 2>&1 && mv "$f.tmp" "$f" || { rm -f "$f.tmp"; [ -s "$f" ] || echo '[]' > "$f"; }
  fi
}

with_prices() { # json lines in -> json lines out, with .price (string)
  prices
  jq -c --slurpfile do "$CACHE/do-prices.json" --slurpfile vps "$CACHE/vps-prices.json" '
    . as $r | (.name|ascii_downcase) as $n
    | ($do[0][.code] // null) as $dop
    | (if ($n|contains("premium intel")) then "Premium Intel" elif ($n|contains("premium amd")) then "Premium AMD" else "Regular" end) as $ct
    | (if ($n|contains("cpu optimized")) then "CPU Optimized" elif ($n|contains("general purpose")) then "General Purpose"
       elif ($n|contains("memory optimized")) then "Memory Optimized" elif ($n|contains("storage optimized")) then "Storage Optimized" else "Shared CPU" end) as $cat
    | ([$vps[0][] | select(.cpu_type==$ct and .category==$cat and .vcpu=="\($r.cpus) vCPU" and .ram=="\($r.ram/1024|floor) GB" and .storage=="\($r.disk/1024|floor) GB")] | first) as $vp
    | .price = (if .pid=="1" then (if $dop then ($dop|tostring) else "?" end)
                elif $vp then ($vp.price_business|tostring) else "?" end)'
}

print_table() { # reads json lines on stdin
  { echo -e "PROVIDER\tSIZE_ID\tCODE\tRAM_GB\tVCPU\tDISK_GB\tUSD/MO\tNAME"
    with_prices | jq -r '[.provider, .id, .code, (.ram/1024|if .==floor then tostring else (.*10|round/10|tostring) end), .cpus, (.disk/1024|floor), .price, .name] | @tsv' \
      | sort -t$'\t' -k1,1 -k4,4n -k5,5n -k6,6n; } | column -t -s$'\t'
  echo "USD/MO: DigitalOcean = monthly list price; Laravel VPS = Business tier price. Public, indicative prices: confirm in the Forge size picker."
}

LIKE=""; WORDS=(); RAM=""; CPUS=""; PROV="$PROVIDERS"
while [ $# -gt 0 ]; do
  case "$1" in
    --like) LIKE="$2"; shift 2 ;;
    *) w="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
       case "$w" in
         laravel|vps|laravelvps) PROV="12" ;;
         digitalocean|do|ocean|ocean2|droplet) PROV="1" ;;
         *gb|*mb) n="${w%gb}"; n="${n%mb}"; case "$w" in *mb) RAM="$n";; *) RAM="$((n*1024))";; esac ;;
         *vcpu|*vcpus|*cpu|*cpus|*core|*cores) CPUS="$(echo "$w" | sed -E 's/[a-z]+$//')" ;;
         *) WORDS+=("$w") ;;
       esac; shift ;;
  esac
done

if [ -n "$LIKE" ]; then
  srv="$("$API" GET "servers/$LIKE" 2>/dev/null | jq '.data.attributes')"
  name="$(echo "$srv" | jq -r .name)"; ip="$(echo "$srv" | jq -r .ip_address)"; prov="$(echo "$srv" | jq -r .provider)"; size="$(echo "$srv" | jq -r .size)"
  echo "Server $LIKE ($name, $prov, size '$size', $ip)"
  live="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "forge@$ip" 'echo "$(nproc) $(free -m | awk "/^Mem:/{print \$2}") $(df -BG --output=size / | tail -1 | tr -dc 0-9) $(cat /proc/loadavg | cut -d" " -f1-3) $(df -BG --output=used / | tail -1 | tr -dc 0-9)"; grep -m1 "model name" /proc/cpuinfo | cut -d: -f2' 2>/dev/null || true)"
  if [ -n "$live" ]; then
    cpu="$(echo "$live" | sed -n 2p | sed 's/^ *//')"; set -- $(echo "$live" | sed -n 1p); CPUS="$1"; RAM="$2"
    echo "Live capacity: $1 vCPU, $2 MB RAM, $3 GB disk ($7 GB used), load average $4 $5 $6"
    echo "CPU model: ${cpu:-unknown}  (Intel/AMD tells the family: add 'intel' or 'amd' to the search to keep it)"
    # free -m reports a bit less than the nominal size: round RAM up to the nominal GB
    RAM="$(( ( (RAM + 512) / 1024 ) * 1024 ))"
    echo "Looking for equivalents: $CPUS vCPU, $((RAM/1024)) GB RAM"
  else
    pid=1; [ "$prov" = "laravel" ] && pid=12
    row="$(catalog "$pid" | jq -c --arg s "$size" 'select(.id==$s or .code==$s)' | head -1)"
    [ -n "$row" ] || { echo "Cannot SSH to the server and size '$size' is not in the current catalog: pass the RAM and CPUs yourself (e.g. 8gb 4vcpu)." >&2; exit 1; }
    RAM="$(echo "$row" | jq -r .ram)"; CPUS="$(echo "$row" | jq -r .cpus)"
    echo "Current size: $(echo "$row" | jq -r .name)"
  fi
  echo
fi

for p in $PROV; do catalog "$p"; done | jq -c --arg ram "$RAM" --arg cpus "$CPUS" --argjson words "$(printf '%s\n' "${WORDS[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" '
  select(($ram=="" ) or (.ram==($ram|tonumber)))
  | select(($cpus=="") or (.cpus==($cpus|tonumber)))
  | . as $row | (.name|ascii_downcase) as $n
  | select(all($words[]; . as $w | ($w=="standard" and ($n|test("premium|dedicated|optimized")|not)) or ($n|contains($w))))
' | print_table
