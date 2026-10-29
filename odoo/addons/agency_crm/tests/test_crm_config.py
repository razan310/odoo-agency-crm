from odoo.tests import TransactionCase, tagged


@tagged("post_install", "-at_install")
class TestCrmConfig(TransactionCase):
    def test_pipeline_stages(self):
        stages = self.env["crm.stage"].search([("team_id", "=", False)])
        self.assertEqual(
            stages.mapped("name"),
            ["New", "Contacted", "Meeting", "Proposal Sent", "Won"],
        )
        self.assertEqual(stages.filtered("is_won"), self.env.ref("crm.stage_lead4"))

    def test_lead_fields(self):
        lead = self.env["crm.lead"].create(
            {
                "name": "Clinic booking app",
                "service_type": "mobile_app",
                "lead_channel": "linkedin",
                "budget": 30000,
            }
        )
        self.assertEqual(lead.service_type, "mobile_app")
        self.assertEqual(lead.lead_channel, "linkedin")
        self.assertEqual(lead.budget, 30000)
        self.assertEqual(lead.company_currency, self.env.company.currency_id)
