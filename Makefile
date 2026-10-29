# Developer shortcuts. Run `make help` to list them.

COMPOSE := docker compose
# Values from .env, with the same defaults as .env.example.
env_value = $(or $(shell sed -n 's/^$(1)=//p' .env 2>/dev/null),$(2))
DB ?= $(call env_value,ODOO_DB,agency_crm)
PORT ?= $(call env_value,ODOO_PORT,8069)
PG_USER := $(call env_value,POSTGRES_USER,odoo)
BASE_APPS := crm,sale_management,contacts
# Our modules. Override for a single one: make update-module MODULES=agency_crm
MODULES ?= agency_crm,agency_crm_sample
TEST_DB := test_$(DB)
comma := ,
# "/agency_crm,/agency_crm_sample": run only the tests of our modules.
TEST_TAGS := $(subst $(comma),$(comma)/,/$(MODULES))

# One-off Odoo commands run in a throwaway container (`run --rm`), not in the
# web server container (`exec`): commands like `--test-enable` start their own
# HTTP server, which would clash with the running one on port 8069.
ODOO_RUN := $(COMPOSE) run --rm odoo odoo
db_exists = $(COMPOSE) exec -T db psql -U $(PG_USER) -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$(1)'"

.DEFAULT_GOAL := help
.PHONY: help up down logs ps odoo-shell psql init-db install-module update-module test reset-db

help: ## List available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.env:
	cp .env.example .env
	@echo "Created .env from .env.example (local development passwords)."

up: .env ## Start PostgreSQL + Odoo; create the database on first run
	$(COMPOSE) up -d --wait db
	@if [ -z "$$($(call db_exists,$(DB)))" ]; then $(MAKE) --no-print-directory init-db; fi
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

init-db: ## Create the database (no Odoo demo data) with the base apps and our modules
	$(ODOO_RUN) -d $(DB) -i $(BASE_APPS),$(MODULES) --without-demo=all --stop-after-init
	$(COMPOSE) run --rm -T odoo odoo shell -d $(DB) --no-http < odoo/scripts/set_admin_password.py

# The web server is stopped during install/upgrade and always started again,
# even when the Odoo command fails.
install-module: ## Install MODULES (default: agency_crm,agency_crm_sample)
	$(COMPOSE) stop odoo
	$(ODOO_RUN) -d $(DB) -i $(MODULES) --stop-after-init; status=$$?; $(COMPOSE) up -d odoo; exit $$status

update-module: ## Upgrade MODULES after code or data changes
	$(COMPOSE) stop odoo
	$(ODOO_RUN) -d $(DB) -u $(MODULES) --stop-after-init; status=$$?; $(COMPOSE) up -d odoo; exit $$status

test: ## Run our module tests in a throwaway database (test_<DB>)
	$(COMPOSE) up -d --wait db
	@if [ -n "$$($(call db_exists,$(TEST_DB)))" ]; then $(ODOO_RUN) db drop $(TEST_DB); fi
	$(ODOO_RUN) -d $(TEST_DB) -i $(MODULES) --without-demo=all --test-enable --test-tags $(TEST_TAGS) --stop-after-init
	$(ODOO_RUN) db drop $(TEST_DB)

reset-db: ## Drop the database + filestore and create it again (asks first)
	@read -p "Drop database '$(DB)' and all its data? [y/N] " answer; \
		[ "$$answer" = y ] || { echo "Aborted."; exit 1; }
	$(COMPOSE) up -d --wait db
	$(COMPOSE) stop odoo
	@if [ -n "$$($(call db_exists,$(DB)))" ]; then $(ODOO_RUN) db drop $(DB); fi
	$(MAKE) --no-print-directory init-db
	$(COMPOSE) up -d odoo
