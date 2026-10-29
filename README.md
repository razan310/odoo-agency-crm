# Agency Lead Manager — Odoo CRM + Automation + Next.js

A small digital agency receives project requests from its website. Leads land
in **Odoo 18 CRM**, get qualified and assigned automatically, move through a
sales pipeline, and the team is notified at key moments. A **Next.js** site
captures leads and shows a pipeline dashboard.

Everything is configuration as code: a custom Odoo module (`agency_crm`)
defines the fields, stages, automations and demo data, so the whole setup can
be rebuilt from scratch with a couple of commands.

> 🚧 Work in progress — built phase by phase.

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Environment: Docker Compose, Odoo 18 + PostgreSQL 16, Makefile | ✅ |
| 1 | CRM configuration as code (`agency_crm` module) | ⏳ |
| 2 | Automations inside Odoo (emails, assignment, scoring, reminders, quotations, webhooks, digest) | ⏳ |
| 3 | Next.js lead capture (EN/AR) over JSON-RPC | ⏳ |
| 4 | Webhook receiver + pipeline dashboard | ⏳ |
| 5 | Tests, docs and polish | ⏳ |

## Architecture

```mermaid
flowchart LR
    visitor([Website visitor]) --> web[Next.js app<br/>contact form + dashboard]
    web -- "JSON-RPC (execute_kw)<br/>API key" --> odoo[Odoo 18<br/>CRM + agency_crm module]
    odoo -- "webhook on Won<br/>shared secret" --> web
    odoo --> db[(PostgreSQL 16)]
    odoo -- emails --> team([Sales team])
```

## Requirements

- Docker with Compose v2 (Docker Desktop on macOS/Windows)
- `make`

## Quick start

```bash
git clone <this repo> && cd odoo-agency-crm
make up
```

`make up` creates `.env` from `.env.example` on the first run, starts
PostgreSQL and Odoo, creates the `agency_crm` database (no demo data) and
installs CRM, Sales and Contacts. The first run takes about a minute.

Open <http://localhost:8069> and log in with `admin` / `admin`
(the `ODOO_ADMIN_PASSWORD` from `.env`).

## Configuration and passwords

All settings live in `.env` (gitignored). `.env.example` documents them.

| Variable | What it is |
| --- | --- |
| `POSTGRES_USER`, `POSTGRES_PASSWORD` | PostgreSQL account used by Odoo |
| `ODOO_DB` | Database name (`agency_crm`) |
| `ODOO_PORT` | Host port for the web UI (`8069`) |
| `ODOO_MASTER_PASSWORD` | Odoo **master password** (`admin_passwd`). Protects the database manager (`/web/database/manager`): create, back up, restore, drop databases. Not a login. |
| `ODOO_ADMIN_PASSWORD` | Login password of the `admin` **user**, applied when the database is created |

`odoo/config/odoo.conf` is a template: `odoo/scripts/entrypoint.sh` fills its
`${VAR}` placeholders from the environment when the container starts, so no
secret is committed.

## Make commands

| Command | Description |
| --- | --- |
| `make up` | Start PostgreSQL + Odoo; create the database on first run |
| `make down` | Stop containers (data is kept in Docker volumes) |
| `make logs` | Follow Odoo logs |
| `make ps` | Show container status |
| `make odoo-shell` | Python shell with `env` on the database |
| `make psql` | psql prompt on the database |
| `make init-db` | Create the database and install the base apps |
| `make install-module` | Install `MODULE` (default `agency_crm`) |
| `make update-module` | Upgrade `MODULE` after code or data changes |
| `make reset-db` | Drop the database + filestore and create it again |

## Project structure

```
.
├── docker-compose.yml        # db (PostgreSQL 16) + odoo (Odoo 18)
├── Makefile                  # developer shortcuts
├── .env.example              # documented settings, copied to .env
├── odoo/
│   ├── config/odoo.conf      # Odoo config template
│   ├── scripts/              # container entrypoint, setup scripts
│   └── addons/               # custom modules (agency_crm)
└── web/                      # Next.js app (phase 3)
```

## Troubleshooting

- **Port 8069 already in use**: set another `ODOO_PORT` in `.env`.
- **Something failed**: `docker compose logs odoo --tail=200`.
- **Start over**: `make reset-db` (database only) or
  `docker compose down -v` (removes all volumes), then `make up`.

## Automations

_Coming in phase 2._

## Screenshots

_Coming soon._

## What I learned

_Written at the end of the project._
