#!/usr/bin/env bash
# Copy the MySQL database and the storage/ directory of a Laravel site from server 1 (source)
# to server 2 (destination), through this Mac (the two servers never talk to each other).
#
# Usage (all values come from flags or environment variables, nothing is hardcoded):
#   transfer-data.sh --mode test|cutover \
#     --src forge@IP_SOURCE --src-dir /home/forge/SITE_SOURCE --src-db NAME_SOURCE \
#     --dst forge@IP_DEST   --dst-dir /home/forge/SITE_DEST   --dst-db NAME_DEST \
#     [--dst-php php8.3] [--db-user forge] [--skip-db] [--skip-storage] [--yes]
#
#   test    : the source site stays online. Use it for the rehearsal.
#   cutover : the source site is put in maintenance (artisan down) BEFORE the export and stays down.
#
# MySQL passwords are read from each server's .env (DB_PASSWORD) over SSH at run time, so no
# password is ever written on this Mac. Copies of the export are kept in ~/Downloads.
# Zero-downtime layouts are detected: storage/ is at the site root, the code lives in current/.
set -euo pipefail

MODE=""; SRC=""; SRC_DIR=""; SRC_DB=""; DST=""; DST_DIR=""; DST_DB=""
DST_PHP="php8.3"; DB_USER="forge"; SKIP_DB=0; SKIP_STORAGE=0; YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --src) SRC="$2"; shift 2 ;;       --src-dir) SRC_DIR="$2"; shift 2 ;;  --src-db) SRC_DB="$2"; shift 2 ;;
    --dst) DST="$2"; shift 2 ;;       --dst-dir) DST_DIR="$2"; shift 2 ;;  --dst-db) DST_DB="$2"; shift 2 ;;
    --dst-php) DST_PHP="$2"; shift 2 ;; --db-user) DB_USER="$2"; shift 2 ;;
    --skip-db) SKIP_DB=1; shift ;;    --skip-storage) SKIP_STORAGE=1; shift ;; --yes) YES=1; shift ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done
for v in MODE SRC SRC_DIR SRC_DB DST DST_DIR DST_DB; do
  [ -n "${!v}" ] || { echo "missing --$(echo "$v" | tr '[:upper:]' '[:lower:]' | tr _ -)" >&2; exit 2; }
done
[ "$MODE" = "test" ] || [ "$MODE" = "cutover" ] || { echo "--mode must be test or cutover" >&2; exit 2; }

DATE="$(date +%Y%m%d-%H%M)"
ZIP_STORAGE="storage-$DATE.tar.gz"
ZIP_DB="db-$DATE.sql.gz"
ZIP_DB_BEFORE="db-before-import-$DATE.sql.gz"

# Where the code lives (current/ on zero-downtime sites, else the site root).
CODE1="if [ -d $SRC_DIR/current ]; then cd $SRC_DIR/current; else cd $SRC_DIR; fi"
CODE2="if [ -d $DST_DIR/current ]; then cd $DST_DIR/current; else cd $DST_DIR; fi"

env_value() { # host site_dir KEY  -> value of KEY in the site's .env (site root first, then current/)
  ssh "$1" "f=$2/.env; [ -f \$f ] || f=$2/current/.env; grep -E '^$3=' \$f | head -1 | cut -d= -f2- | sed -e 's/^\"//' -e 's/\"\$//' -e \"s/^'//\" -e \"s/'\$//\""
}

echo "Transfer ($MODE) from $SRC to $DST"
[ "$SKIP_DB" = 1 ]      || echo "  - database $SRC_DB -> $DST_DB (replaces the destination database; a backup is taken first)"
[ "$SKIP_STORAGE" = 1 ] || echo "  - $SRC_DIR/storage -> $DST_DIR/storage (previous storage kept as storage_old)"
if [ "$MODE" = "cutover" ]; then
  echo "  - the SOURCE site will be put in MAINTENANCE (artisan down) and left down."
fi
if [ "$YES" != 1 ]; then
  read -r -p "Continue? (yes/no) " answer
  [ "$answer" = "yes" ] || exit 1
fi

echo "0/9 Reading database passwords from the servers' .env files..."
DB_PASS1="$(env_value "$SRC" "$SRC_DIR" DB_PASSWORD)"
DB_PASS2="$(env_value "$DST" "$DST_DIR" DB_PASSWORD)"
[ -n "$DB_PASS1" ] || { echo "DB_PASSWORD not found in $SRC:$SRC_DIR/.env" >&2; exit 1; }
[ -n "$DB_PASS2" ] || { echo "DB_PASSWORD not found in $DST:$DST_DIR/.env" >&2; exit 1; }
DST_ENV_DB="$(env_value "$DST" "$DST_DIR" DB_DATABASE)"
[ "$DST_ENV_DB" = "$DST_DB" ] || { echo "Destination .env has DB_DATABASE=$DST_ENV_DB but --dst-db is $DST_DB. Fix one of them first." >&2; exit 1; }

if [ "$MODE" = "cutover" ]; then
  echo "1/9 Putting the source site in maintenance..."
  ssh "$SRC" "$CODE1 && php artisan down"
else
  echo "1/9 Source site left online (test mode)."
fi

if [ "$SKIP_DB" != 1 ]; then
  echo "2/9 Exporting the source database..."
  ssh "$SRC" "set -o pipefail; MYSQL_PWD='$DB_PASS1' mysqldump -u $DB_USER --single-transaction --quick --routines --triggers --no-tablespaces $SRC_DB | gzip > ~/$ZIP_DB"
  echo "3/9 Downloading the export to this Mac, then uploading it to the destination..."
  scp "$SRC:~/$ZIP_DB" "$HOME/Downloads/$ZIP_DB"
  ssh "$SRC" "rm ~/$ZIP_DB"
  scp "$HOME/Downloads/$ZIP_DB" "$DST:~/"
  echo "4/9 Backing up the current destination database (rollback point)..."
  ssh "$DST" "set -o pipefail; MYSQL_PWD='$DB_PASS2' mysqldump -u $DB_USER --single-transaction --quick --routines --triggers --no-tablespaces $DST_DB | gzip > ~/$ZIP_DB_BEFORE"
  echo "5/9 Importing into the destination database..."
  ssh "$DST" "set -e -o pipefail; gunzip < ~/$ZIP_DB | MYSQL_PWD='$DB_PASS2' mysql -u $DB_USER $DST_DB; rm ~/$ZIP_DB"
else
  echo "2-5/9 Database skipped."
fi

if [ "$SKIP_STORAGE" != 1 ]; then
  echo "6/9 Archiving storage/ on the source (without logs and caches)..."
  ssh "$SRC" "cd $SRC_DIR && tar czf ~/$ZIP_STORAGE \
    --exclude='storage/logs/*' \
    --exclude='storage/framework/cache/data/*' \
    --exclude='storage/framework/sessions/*' \
    --exclude='storage/framework/views/*' \
    --exclude='storage/debugbar/*' \
    storage"
  echo "7/9 Downloading the archive to this Mac, then uploading it to the destination..."
  scp "$SRC:~/$ZIP_STORAGE" "$HOME/Downloads/$ZIP_STORAGE"
  ssh "$SRC" "rm ~/$ZIP_STORAGE"
  scp "$HOME/Downloads/$ZIP_STORAGE" "$DST:~/"
  echo "8/9 Replacing storage/ on the destination..."
  ssh "$DST" "
    set -e
    cd $DST_DIR
    rm -rf storage_old
    if [ -d storage ]; then mv storage storage_old; fi
    tar xzf ~/$ZIP_STORAGE
    rm -f storage/framework/down
    chmod -R 775 storage
    rm ~/$ZIP_STORAGE
  "
else
  echo "6-8/9 Storage skipped."
fi

echo "9/9 Migrations and caches on the destination..."
ssh "$DST" "
  set -e
  $CODE2
  if [ ! -f vendor/autoload.php ]; then
    echo '  No successful deployment yet on the destination: deploy from Forge, the deploy script will run the migrations.'
    exit 0
  fi
  $DST_PHP artisan storage:link || true
  $DST_PHP artisan migrate --force
  $DST_PHP artisan optimize:clear
  $DST_PHP artisan queue:restart
  $DST_PHP artisan up
"

echo
echo "Done."
echo "Copies on this Mac: ~/Downloads/$ZIP_DB and ~/Downloads/$ZIP_STORAGE"
echo "On the destination: previous database in ~/$ZIP_DB_BEFORE, previous storage in $DST_DIR/storage_old"
echo
if [ "$MODE" = "cutover" ]; then
  echo "The SOURCE site is IN MAINTENANCE. To bring it back online (rollback):"
  echo "  ssh $SRC \"$CODE1 && php artisan up\""
  echo
fi
echo "Rollback the destination database:"
echo "  ssh $DST \"gunzip < ~/$ZIP_DB_BEFORE | MYSQL_PWD=\\\"\\\$(grep ^DB_PASSWORD= $DST_DIR/.env | cut -d= -f2-)\\\" mysql -u $DB_USER $DST_DB\""
echo "Rollback the destination storage:"
echo "  ssh $DST \"cd $DST_DIR && rm -rf storage && mv storage_old storage\""
