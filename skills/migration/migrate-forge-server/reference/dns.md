# Client domains: the Witify DNS standard

The client never points a domain straight at a server IP. The client creates **CNAME** records to a Witify name, `<slug>.prod.hosting.witify.io`, and that name is the only place the IP lives (an **A** record in the `witify.io` zone on Cloudflare). A server migration is then one record change on our side, at the time we choose, with no coordination with the client or their DNS provider.

| Type | Name | Value | Where |
| --- | --- | --- | --- |
| A | `<slug>.prod.hosting.witify.io` | IP of the Forge server | Cloudflare, zone `witify.io` |
| CNAME | `app.client.com` | `<slug>.prod.hosting.witify.io` | Client's DNS |
| CNAME | `www.app.client.com` | `<slug>.prod.hosting.witify.io` | Client's DNS |
| CNAME | `ws.app.client.com` | `<slug>.prod.hosting.witify.io` | Client's DNS, only with Laravel Reverb |

- The slug is short, lowercase and unique per application (`la`, `orionflow`, `sigtic`).
- Every CNAME points directly at the Witify name (no `www → app` chain).
- The A record is **DNS only** (grey cloud). Never proxy it: the client's domain would land on Cloudflare, which rejects it (error 1014 when the client is on Cloudflare, 1001 otherwise).
- TTL Auto (300 s).

## Where the migration touches DNS

1. **Inventory.** `dig +short <domain>` on each production domain. A CNAME to `<slug>.prod.hosting.witify.io` is the standard case: the switch is ours. A bare A record to the old IP means the client (or whoever manages that zone) has to change it: say so early, before the cutover date is picked, and prepare the email below.
2. **Cutover.** Change the IPv4 of `<slug>.prod.hosting` in Cloudflare → DNS → `witify.io` to the new server's IP. Wait about five minutes, then `dig +short` must return the Witify name followed by the new IP. Do not open the domain in Chrome before `dig` is right: the browser would cache the old answer.
3. **A client on the old model.** When no Witify name exists yet, create the A record now and ask the client to replace their A record with the CNAME. The same email works; the cutover waits for `dig`.

## Email template (client on the old model, or a new domain)

```txt
Objet : Configuration du domaine app.client.com

Bonjour {Prénom},

Pour mettre en ligne {Nom de l'application}, nous avons besoin que vous ajoutiez les enregistrements DNS suivants chez votre fournisseur de domaine (GoDaddy, Cloudflare, etc.).

Type : CNAME
Nom : app
Valeur : <slug>.prod.hosting.witify.io

Type : CNAME
Nom : www.app
Valeur : <slug>.prod.hosting.witify.io

Type : CNAME
Nom : ws.app
Valeur : <slug>.prod.hosting.witify.io

Quelques précisions :
- Certains fournisseurs demandent le nom complet (ex. app.client.com) plutôt que le préfixe seulement.
- Si votre fournisseur offre un proxy (le nuage orange chez Cloudflare, par exemple), désactivez-le pour ces enregistrements. Le mode doit être « DNS seulement ».
- Supprimez tout enregistrement existant qui porte les mêmes noms (A, AAAA ou CNAME).
- Cette configuration est permanente. Lors d'un changement de serveur, nous mettons à jour l'adresse de notre côté, sans intervention de votre part.
- Merci de ne pas modifier ni supprimer ces enregistrements sans nous en aviser.

Écrivez-nous lorsque c'est fait. Nous activerons ensuite le certificat de sécurité (HTTPS).

Si vous préférez, nous pouvons faire la configuration nous-mêmes avec un accès temporaire à votre zone DNS.

Merci!

{Signature}
```

Remove the `ws.app` block when the project does not use Reverb. The email is a draft for François to send: never send it yourself.

## Special cases

- **Apex domain (`client.com`).** A CNAME is impossible at the apex. Use CNAME flattening or an ALIAS record when the provider offers it (Cloudflare, DNSimple, Route 53); otherwise an A record to the IP, and note that this client must be contacted at every migration.
- **Record conflicts.** A CNAME cannot coexist with any other record on the same name (TXT, MX, A). The client removes the old ones.
- **Client on Cloudflare.** Their CNAMEs must also be DNS only.
- **End of service.** Delete the record in `witify.io` and ask the client to remove the CNAMEs.

## SSL

Forge issues Let's Encrypt certificates per domain record with HTTP-01, so the names must already resolve to the new server. DNS-01 and wildcard certificates are not possible (we do not control the client's zone). To avoid a certificate gap at cutover, install the old site's certificate on the new site first (`/etc/nginx/ssl/<domain>/<id>/server.crt` and `server.key` on the old server, "existing" certificate in Forge), switch DNS, then request Let's Encrypt for automatic renewals.
