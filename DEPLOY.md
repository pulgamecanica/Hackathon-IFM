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

```bash
git commit -am "..."     # Kamal versions the image from the git SHA
bin/kamal deploy
```

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
