using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Reports_History : System.Web.UI.UserControl
    {
        protected List<NamedEntity> Users { get; set; }
        protected List<CompletedChecklist> Checklists { get; set; }
        protected int SelectedMemberId { get; set; }
        protected DateTime StartDate { get; set; }
        protected DateTime EndDate { get; set; }
        protected bool Show { get; set; }
        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }
        public Controls_Reports_SortBy SortByControl { get; set; }

        public Controls_Reports_History()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
            SortByControl = new Controls_Reports_SortBy();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var selectListRepo = new SelectListRepository();
            var reportsRepo = new ReportsRepository();
            Users = selectListRepo.GetGroups().ToList();
            Users.Insert(0, new NamedEntity { Id = -1, Name = "All" });
            SortByControl.Sort = "Person";

            StartDate = QProcess.Session.CurrentSession?.UserTimeZone.GetLocalTimeNow().Date.AddDays(-7)
                ?? DateTime.Today;
            EndDate = QProcess.Session.CurrentSession?.UserTimeZone.GetLocalTimeNow().Date
                ?? DateTime.Today;

            if (Context.Request.Headers["X-Sort"] != null && Context.Request.Headers["X-StartDate"] != null
                && Context.Request.Headers["X-EndDate"] != null && Context.Request.Headers["X-SelectedMemberId"] != null)
            {
                Show = true;
                SortByControl.Sort = Convert.ToString(Context.Request.Headers["X-Sort"]);
                StartDate = Convert.ToDateTime(Context.Request.Headers["X-StartDate"]);
                EndDate = Convert.ToDateTime(Context.Request.Headers["X-EndDate"]);
                SelectedMemberId = Convert.ToInt32(Context.Request.Headers["X-SelectedMemberId"]);
                Checklists = reportsRepo.GetCompletedChecklists(QProcess.Session.CurrentSession.QUser.Id, SelectedMemberId, StartDate, EndDate,
                                               SortByControl.Sort).ToList();
                Repeater2.DataSource = Checklists;
                Repeater2.DataBind();
            }            

            Repeater1.DataSource = Users;
            Repeater1.DataBind();
        }

        protected string NAOutput(object IsNA, object NAReason)
        {
            bool isNA = Convert.ToBoolean(IsNA);
            string naReason = Convert.ToString(NAReason);
            string naString = "";

            if (isNA)
            {
                naString = "<span class=\"NA\" title=\"" + naReason + "\"> [MARKED N/A]</span>";
            }

            return naString;
        }

        protected string CompletedOn(object CompletedDate, object IsNA)
        {
            if (Convert.ToBoolean(IsNA))
            {
                return "";
            }
            else
            {
                return Convert.ToString(CompletedDate);
            }
        }

        protected string NAOn(object CompletedDate, object IsNA)
        {
            if (Convert.ToBoolean(IsNA))
            {
                return Convert.ToString(CompletedDate);
            }
            else
            {
                return "";
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

