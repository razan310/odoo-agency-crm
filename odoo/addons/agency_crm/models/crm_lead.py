from odoo import fields, models

SERVICE_TYPES = [
    ("website", "Website"),
    ("mobile_app", "Mobile App"),
    ("erp_crm", "ERP / CRM"),
    ("automation", "Automation"),
    ("other", "Other"),
]

LEAD_CHANNELS = [
    ("website_form", "Website Form"),
    ("referral", "Referral"),
    ("linkedin", "LinkedIn"),
    ("whatsapp", "WhatsApp"),
    ("other", "Other"),
]


class CrmLead(models.Model):
    # Extend the existing model: Odoo adds the new columns to the crm_lead
    # table when the module is installed or upgraded.
    _inherit = "crm.lead"

    service_type = fields.Selection(
        SERVICE_TYPES,
        string="Service Type",
        tracking=True,
        help="What the client wants us to build.",
    )
    budget = fields.Monetary(
        string="Budget",
        # Same currency as Expected Revenue: the company currency.
        currency_field="company_currency",
        tracking=True,
        help="Budget announced by the client.",
    )
    lead_channel = fields.Selection(
        LEAD_CHANNELS,
        string="Channel",
        tracking=True,
        help="How the request reached the agency.",
    )
