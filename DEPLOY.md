# Deploying hackathon_ifm

Production deploy uses [Kamal](https://kamal-deploy.org) to a single DigitalOcean droplet.

| Thing        | Value                                |
| ------------ | ------------------------------------ |
| Domain       | `ifm.pulgamecanica.com`              |
| Server       | `209.38.240.185` (SSH as `root`)     |
| Registry     | `ghcr.io/pulgamecanica/hackathon-ifm`|
| Database     | PostgreSQL 16, Kamal accessory `db`  |
| TLS          | Auto Let's Encrypt via kamal-proxy   |

## Prerequisites (on the machine you deploy from)

1. **SSH** access to `root@209.38.240.185` with your key (`ssh root@209.38.240.185` must work).
2. **Docker** running locally (Kamal builds the image locally and pushes to ghcr).
3. **GitHub CLI** logged in: `gh auth status` green. The registry password is pulled
   from `gh auth token` (see `.kamal/secrets`), and that token needs the
   `write:packages` scope.
4. `config/master.key` present (it is, and gitignored).
5. `.kamal/db_password` present — a random password was generated here. It is
   gitignored, so **keep a copy**; losing it means you can't reach the existing DB.

## DNS

`ifm.pulgamecanica.com` must have an A record → `209.38.240.185` (already done).

## First deploy (prepares the empty server)

The server is bare. `kamal setup` installs Docker, boots the kamal-proxy,
starts the Postgres accessory, then builds + pushes + deploys the app.

```bash
# 0. One-time: Kamal derives image versions from git, so commit first.
git add -A && git commit -m "Initial deploy config"

# 1. Boot the Postgres accessory on the server.
bin/kamal accessory boot db

# 2. Provision Docker on the server + first deploy (creates Let's Encrypt cert).
bin/kamal setup
```

`db:prepare` runs automatically on container boot (see `bin/docker-entrypoint`),
creating and migrating the primary, cache, queue, and cable databases.

## Subsequent deploys

Pushing to `main` deploys automatically (see below). To deploy by hand:

```bash
git commit -am "..."     # Kamal versions the image from the git SHA
bin/kamal deploy
```

## Continuous deployment (GitHub Actions)

`.github/workflows/deploy.yml` runs after the **CI** workflow succeeds on `main`
(and can be run manually via the Actions tab → Deploy → Run workflow). It builds
and pushes the image to ghcr.io using the Actions `GITHUB_TOKEN`, then runs
`bin/kamal deploy` over SSH.

The runner needs the `config/master.key` and `.kamal/db_password` files, which are
gitignored — the workflow recreates them from repository secrets. Set these three
secrets once (the fourth, `GITHUB_TOKEN`, is provided automatically):

```bash
gh secret set RAILS_MASTER_KEY   < config/master.key
gh secret set POSTGRES_PASSWORD  < .kamal/db_password
gh secret set SSH_PRIVATE_KEY    < ~/.ssh/id_ed25519   # key whose PUBLIC half is in the server's root authorized_keys
```

> The CI workflow's `GITHUB_TOKEN` automatically has `packages: write` for images
> under `ghcr.io/pulgamecanica/*`, so no PAT is needed in CI.

CD only handles redeploys. The one-time server provisioning (`kamal accessory boot db`
+ `kamal setup`) must be run manually first, as described above.

## Handy commands

```bash
bin/kamal logs -f                 # tail app logs
bin/kamal console                 # rails console on the server
bin/kamal shell                   # bash in the app container
bin/kamal dbc                     # rails dbconsole
bin/kamal accessory logs db -f    # postgres logs
bin/kamal proxy logs -f           # kamal-proxy (TLS/routing) logs
bin/kamal app exec "bin/rails db:migrate"
```

## Notes

- **Postgres is internal only.** No host port is published; the app reaches it
  over the private Kamal docker network at host `hackathon_ifm-db` (set as
  `DB_HOST`). It is not exposed to the host or the internet.
- Postgres data lives in the named directory volume `data` on the server, and
  app storage in the `hackathon_ifm_storage` volume — both survive redeploys.
- TLS termination happens at kamal-proxy; the app runs with `assume_ssl` and
  `force_ssl` enabled (`config/environments/production.rb`).
- The firewall must allow inbound **80** and **443** (Let's Encrypt + traffic)
  and **22** (SSH). On DigitalOcean check any cloud firewall attached to the droplet.
