"""Set the login password of the built-in "admin" user from $ODOO_ADMIN_PASSWORD.

A database created from the command line gets admin/admin by default.
This script is executed by `odoo shell`, which injects `env`
(an Odoo Environment running as superuser):

    docker compose run --rm -T odoo odoo shell -d agency_crm < odoo/scripts/set_admin_password.py
"""

import os

password = os.environ.get("ODOO_ADMIN_PASSWORD")
if not password:
    raise SystemExit("ODOO_ADMIN_PASSWORD is not set")

admin = env.ref("base.user_admin")  # noqa: F821 - provided by odoo shell
admin.password = password  # stored hashed by res.users

# `odoo shell` rolls the transaction back when the script ends,
# so changes must be committed explicitly.
env.cr.commit()  # noqa: F821
print(f"Password set for user '{admin.login}'.")
