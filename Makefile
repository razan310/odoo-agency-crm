# Developer shortcuts. Run `make help` to list them.

COMPOSE := docker compose
# Values from .env, with the same defaults as .env.example.
env_value = $(or $(shell sed -n 's/^$(1)=//p' .env 2>/dev/null),$(2))
DB ?= $(call env_value,ODOO_DB,agency_crm)
PORT ?= $(call env_value,ODOO_PORT,8069)
PG_USER := $(call env_value,POSTGRES_USER,odoo)
MODULE ?= agency_crm
BASE_APPS := crm,sale_management,contacts

# One-off Odoo commands run in a throwaway container (`run --rm`), not in the
# web server container (`exec`): commands like `--test-enable` start their own
# HTTP server, which would clash with the running one on port 8069.
ODOO_RUN := $(COMPOSE) run --rm odoo odoo
DB_EXISTS := $(COMPOSE) exec -T db psql -U $(PG_USER) -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$(DB)'"

.DEFAULT_GOAL := help
.PHONY: help up down logs ps odoo-shell psql init-db install-module update-module reset-db

help: ## List available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.env:
	cp .env.example .env
	@echo "Created .env from .env.example (local development passwords)."

up: .env ## Start PostgreSQL + Odoo; create the database on first run
	$(COMPOSE) up -d --wait db
	@if [ -z "$$($(DB_EXISTS))" ]; then $(MAKE) --no-print-directory init-db; fi
	$(COMPOSE) up -d
	@echo "Odoo is running at http://localhost:$(PORT) (database: $(DB))"

down: ## Stop containers (data volumes are kept)
	$(COMPOSE) down

logs: ## Follow Odoo logs
	$(COMPOSE) logs -f --tail=200 odoo

ps: ## Show container status
	$(COMPOSE) ps

odoo-shell: ## Interactive Python shell with `env` on the database
	$(COMPOSE) exec odoo odoo shell -d $(DB) --no-http

psql: ## psql prompt on the Odoo database
	$(COMPOSE) exec db psql -U $(PG_USER) -d $(DB)

init-db: ## Create the database without demo data and install the base apps
	$(ODOO_RUN) -d $(DB) -i $(BASE_APPS) --without-demo=all --stop-after-init
	$(COMPOSE) run --rm -T odoo odoo shell -d $(DB) --no-http < odoo/scripts/set_admin_password.py

install-module: ## Install MODULE (default: agency_crm)
	$(COMPOSE) stop odoo
	$(ODOO_RUN) -d $(DB) -i $(MODULE) --stop-after-init
	$(COMPOSE) up -d odoo

update-module: ## Upgrade MODULE after code/data changes (default: agency_crm)
	$(COMPOSE) stop odoo
	$(ODOO_RUN) -d $(DB) -u $(MODULE) --stop-after-init
	$(COMPOSE) up -d odoo

reset-db: ## Drop the database + filestore and create it again (asks first)
	@read -p "Drop database '$(DB)' and all its data? [y/N] " answer; \
		[ "$$answer" = y ] || { echo "Aborted."; exit 1; }
	$(COMPOSE) up -d --wait db
	$(COMPOSE) stop odoo
	@if [ -n "$$($(DB_EXISTS))" ]; then $(ODOO_RUN) db drop $(DB); fi
	$(MAKE) --no-print-directory init-db
	$(COMPOSE) up -d odoo
