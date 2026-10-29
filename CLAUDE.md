# CLAUDE.md

Agency Lead Manager: Odoo 18 CRM configured as code (`agency_crm` module),
Odoo automations, and a Next.js app talking to Odoo over JSON-RPC.
It is both a learning project and a portfolio piece for agency clients.

## Working agreement

- **Teaching mode.** Before each phase, explain in 5–10 lines what we are
  about to do and the Odoo concepts involved. Explanations to Razan are in
  Arabic (Levantine/Syrian dialect) with technical terms kept in English.
  Code, comments, commit messages and docs stay in English.
- **One phase at a time.** End each phase by running and verifying it, then
  summarize what was built, list exactly what to click or check in the Odoo
  UI or browser, and stop until Razan says "continue".
- **Verify, don't guess.** Check the running Odoo version and inspect real
  models/fields (`ir.model.fields`, `make odoo-shell`) before writing XML or
  code. On failure, read `docker compose logs odoo --tail=200` and fix the
  root cause.
- Small commits with clear messages after each working step.
- Never commit secrets: `.env` is gitignored, `.env.example` documents it.
- If something needs a manual step (API key, UI click), say so precisely
  and wait.

## Phases

0. Environment (Docker Compose, Makefile) — done
1. CRM configuration as code: fields, views, stages, sample leads — done
2. Automations in module data XML, each with a `TransactionCase` test
3. Next.js lead capture (EN/AR, zod, typed JSON-RPC client)
4. Webhook receiver + dashboard
5. Tests, README, fresh-clone check

## Commands

```bash
make up              # start; creates the database on first run
make logs            # follow Odoo logs
make odoo-shell      # Python shell with `env`
make update-module   # upgrade our modules after changes (MODULES=agency_crm for one)
make test            # tests in a throwaway test_agency_crm database
make reset-db        # drop + recreate the database
docker compose exec odoo odoo --version
```

## Environment facts (verified)

- Odoo `18.0-20261015` (image `odoo:18`, native arm64 available),
  PostgreSQL 16. Python 3.12 inside the Odoo image.
- `odoo/config/odoo.conf` is a template rendered by
  `odoo/scripts/entrypoint.sh` into `/etc/odoo/odoo.conf` at container start.
- `odoo shell` rolls back at the end: scripts must call `env.cr.commit()`.
- `--test-enable` always starts the HTTP server, so one-off Odoo commands
  run in `docker compose run --rm odoo odoo ...`, not `exec` (port clash).
- The `agency_crm` database is created without demo data
  (`--without-demo=all`). Odoo only loads a module's `demo` files when all
  its dependencies have demo data (`should_have_demo()`), so sample leads
  live in a separate module, `agency_crm_sample`, as regular `noupdate` data.
  Uninstalling it removes them (verified).
- Stage external IDs: `crm.stage_lead1` New, `crm.stage_lead2` Contacted,
  `agency_crm.stage_meeting` Meeting, `crm.stage_lead3` Proposal Sent,
  `crm.stage_lead4` Won. crm's stages are renamed, not deleted: `crm.stage`
  has no `active` field and `crm.lead.stage_id` is `ondelete="restrict"`.
  Overriding crm's `noupdate` records applies at install only; `-u` skips them.
- In another module's data file, refs need the full prefix
  (`agency_crm.stage_meeting`), otherwise they resolve to the current module.
- crm sets `date_closed` and won/lost probability in `write()`, not `create()`:
  data creating already-won/lost leads must set `date_closed` itself.
- `crm.lead.priority` values: `'0'`..`'3'` (stars). Lost = `active=False`,
  `probability=0`, `lost_reason_id`.
- `make test` runs `--test-tags /agency_crm,/agency_crm_sample` on a fresh
  database without demo; a failing test makes it exit non-zero (verified).
- Fresh database: company "My Company", country United States, currency USD
  (kept for now; AED/SAR still open), chart of accounts `generic_coa`.
