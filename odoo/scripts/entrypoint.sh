#!/bin/bash
# Wrapper around the official odoo image entrypoint.
#
# 1. Renders /etc/odoo/odoo.conf from the committed template, replacing
#    ${VAR} placeholders with environment variables (secrets come from .env).
# 2. Hands over to the image's /entrypoint.sh, which waits for PostgreSQL
#    and starts Odoo with the given command.
set -euo pipefail

TEMPLATE=/opt/agency/config/odoo.conf
TARGET="${ODOO_RC:-/etc/odoo/odoo.conf}"

for var in POSTGRES_USER POSTGRES_PASSWORD ODOO_MASTER_PASSWORD ODOO_DB; do
  if [ -z "${!var:-}" ]; then
    echo "entrypoint: required environment variable $var is not set (see .env.example)" >&2
    exit 1
  fi
done

python3 - "$TEMPLATE" "$TARGET" <<'PY'
import os
import sys

src, dst = sys.argv[1:]
with open(src) as f:
    rendered = os.path.expandvars(f.read())
with open(dst, "w") as f:
    f.write(rendered)
PY

exec /entrypoint.sh "$@"
