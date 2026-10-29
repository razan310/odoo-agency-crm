{
    "name": "Agency CRM",
    "version": "18.0.1.0.0",
    "summary": "CRM configuration for a digital agency: lead fields, pipeline stages and automations",
    "category": "Sales/CRM",
    "author": "Razan",
    "license": "LGPL-3",
    "depends": ["crm", "sale_management", "mail", "base_automation"],
    "data": [
        "data/crm_stage_data.xml",
        "data/crm_lost_reason_data.xml",
        "views/crm_lead_views.xml",
    ],
    "installable": True,
    "application": False,
}
