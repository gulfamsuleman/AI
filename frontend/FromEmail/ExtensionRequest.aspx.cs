using System;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using DataAccessLayer;
using QProcess.Extensions;

namespace QProcess
{

    public partial class FromEmail_ExtensionRequest : Page
    {
        public TextBox txtID { get; set; }
        public TextBox txtUser { get; set; }
        public TextBox txtNewDeadline { get; set; }
        public TextBox txtReason { get; set; }
        public Label lblNewDeadline { get; set; }
        public Label lblTaskName { get; set; }
        public Label lblError { get; set; }
        public Label lblFinish { get; set; }
        public HtmlGenericControl pReason { get; set; }
        public HtmlGenericControl hdrFinish { get; set; }
        public Button btnSend { get; set; }
        public Panel pnlForm { get; set; }
        public Panel pnlFinish { get; set; }
        public Panel pnlError { get; set; }

        public FromEmail_ExtensionRequest()
        {
            txtID = new TextBox();
            txtUser = new TextBox();
            txtUser = new TextBox();
            txtNewDeadline = new TextBox();
            txtReason = new TextBox();
            lblTaskName = new Label();
            lblError = new Label();
            lblFinish = new Label();            
            lblNewDeadline = new Label();
            pReason = new HtmlGenericControl("p");
            btnSend = new Button();
            hdrFinish = new HtmlGenericControl("h1");
            pnlForm = new Panel();
            pnlFinish = new Panel();
            pnlError = new Panel();
        }
        
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                BindControls();
            }
        }

        private void BindControls()
        {
            bool IsController = false;
            DateTime DueTime;
            DateTime NextDue;
            DateTime TwoDays;
            DateTime NewDue;

            txtID.Text = Request["ac"].ToBlank();
            txtUser.Text = Request["userID"].ToBlank();

            System.Data.DataSet ds = null;
            using (var db = new DBCommand("QCheck_ActiveChecklistInfo"))
                ds = db.Add("@ActiveChecklistID", txtID.Text).Add("@UserID", txtUser.Text).ExecuteDataSet();

            lblTaskName.Text = ds.Tables[0].Rows[0]["ChecklistName"].ToBlank();
            IsController = ds.Tables[0].Rows[0]["IsController"].ToBoolEx().Value;

            //Per GPR, task is due 2 days from today, not two days from when it was due.  Preserving the time from the original deadline.
            DueTime = ds.Tables[0].Rows[0]["DueTime"].ToDateTimeEx().Value;
            if (ds.Tables[0].Rows[0]["DueTime"].ToDateTimeEx().HasValue)
                NextDue = DateTime.Parse("12/31/2199");
            else
                NextDue = ds.Tables[0].Rows[0]["NextDue"].ToDateTimeEx().Value;

            TwoDays = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(2);
            NewDue = new DateTime(TwoDays.Year, TwoDays.Month, TwoDays.Day, DueTime.Hour, DueTime.Minute, DueTime.Second);

            //Deadlines can't be pushed past the next occurrence for a recurring task, but they can be the same
            if (NewDue > NextDue)
            {
                // If the next occurrence is also overdue, there's no point in this extension
                if (NextDue < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
                {
                    lblError.Text = "You can't extend the deadline of this task, the next occurrence is also overdue.  You must complete this task and extend the next occurrence.";
                    ShowPanel("Error");
                }
                else
                {
                    NewDue = NextDue;
                }
            }

            lblNewDeadline.Text = NewDue.ToString();
            txtNewDeadline.Text = NewDue.ToString();

            if (IsController)
            {
                pReason.Visible = false;
                btnSend.Text = "Save New Deadline";
                hdrFinish.InnerText = "Deadline Extended";
                lblFinish.Text = "Task <b>" + lblTaskName.Text + "</b> extended to <b>" + lblNewDeadline.Text + "</b>";
                SaveForm();
            }
            else
            {
                ShowPanel("Form");
            }
        }

        protected void btnSend_Click(object sender, EventArgs e)
        {
            SaveForm();
        }

        private void SaveForm()
        {
            try
            {
                using (var db = new DBCommand("QCheck_QuickDeadlineExtension"))
                {
                    db.Add("@ActiveChecklistID", txtID.Text)
                      .Add("@NewDueTime", txtNewDeadline.Text)
                      .Add("@UserID", txtUser.Text)
                      .Add("@Comment", txtReason.Text)
                      .ExecuteNonQuery();
                    ShowPanel("Finish");
                }
            }
            catch (Exception ex)
            {
                lblError.Text = ex.ToString();
                ShowPanel("Error");
            }
        }

        private void ShowPanel(string panel)
        {
            switch (panel)
            {
                case "Form":
                    pnlForm.Visible = true;
                    pnlFinish.Visible = false;
                    pnlError.Visible = false;
                    break;
                case "Finish":
                    pnlForm.Visible = false;
                    pnlFinish.Visible = true;
                    pnlError.Visible = false;
                    break;
                case "Error":
                    pnlForm.Visible = false;
                    pnlFinish.Visible = false;
                    pnlError.Visible = true;
                    break;
                default:
                    pnlForm.Visible = true;
                    pnlFinish.Visible = false;
                    pnlError.Visible = false;
                    break;
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

