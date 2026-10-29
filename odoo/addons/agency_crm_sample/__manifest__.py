{
    "name": "Agency CRM - Sample Data",
    "version": "18.0.1.0.0",
    "summary": "Realistic sample leads from Gulf SMEs for demos. Uninstall to remove them.",
    "category": "Sales/CRM",
    "author": "Razan",
    "license": "LGPL-3",
    # Regular data (not "demo"): the main database has no demo data, and
    # Odoo only loads a module's demo files when all its dependencies have
    # demo data too. Keeping the samples in their own module means they can
    # be installed on demand and removed by uninstalling it.
    "depends": ["agency_crm"],
    "data": [
        "data/res_partner_data.xml",
        "data/crm_lead_data.xml",
    ],
    "installable": True,
    "application": False,
}
