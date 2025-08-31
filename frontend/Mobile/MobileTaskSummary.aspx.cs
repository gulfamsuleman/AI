using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileTaskSummary : SessionPage
    {
        public string StartDateString { get; private set; }
        public string EndDateString { get; private set; }
        protected List<NamedEntity> Members { get; set; }
        protected List<Checklist> Tasks { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            DateTime start;
            DateTime end;

            if (!IsPostBack)
            {
                start = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1);
                end = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(13);

                var selectListRepo = new SelectListRepository();
                Members = selectListRepo.GetGroups().ToList();
                Members.Insert(0, new NamedEntity { Id = -1, Name = "All" });

                assignedtoList.DataSource = Members;
                assignedtoList.DataTextField = "Name";
                assignedtoList.DataValueField = "Id";
                assignedtoList.DataBind();
            }
            else
            {
                start = (hidStartDate.Value).ToDateTimeEx().Value;
                end = (hidEndDate.Value).ToDateTimeEx().Value;
            }

            StartDateString = start.ToShortDateString();
            EndDateString = end.ToShortDateString();
            hidStartDate.Value = StartDateString;
            hidEndDate.Value = EndDateString;



            var checklistRepo = new ChecklistRepository();
            Tasks = checklistRepo.GetPotentialNAChecklists(QProcess.Session.CurrentSession.QUser.Id, start, end, assignedtoList.SelectedValue.ToIntEx().Value);

            rptNATasks.DataSource = Tasks;

            Page.DataBind();
        }

        protected String DateFormat(Object dt)
        {
            DateTime d = (DateTime)dt;
            return d.ToShortDateString();

        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }

    }

}
/* Copyright © 2024 Renegade Swish, LLC */

