using QProcess.Controls;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileCalendar : SessionPage, IProvideReportIdForLogging
    {
        protected List<CalendarChecklist> Day1 { get; set; }
        protected DateTime Day1Date { get; set; }

        protected DateTime SelectedDate { get; set; }

        public int FilterMask { get; set; }
        
        protected int[] AssigneeIds { get; set; }
        protected bool ShowStatus { get; set; }
        protected DateTime StartDate { get; set; }
        protected DateTime EndDate { get; set; }
        protected List<CalendarAssignee> Assignees { get; set; }
        public int ReportId { get; set; }

        public MobileCalendar()
        {
            Repeater1 = new Repeater();

            DayOfWeek1 = new Controls_Calendar_CalendarDayOfWeek();
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            ReportId = 1;
            SelectedDate = String.IsNullOrWhiteSpace(Context.Request.Params["date"]) 
                ? QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date
                : DateTime.Parse(Context.Request.Params["date"]);
            var calendarRepo = new CalendarRepository();
            int userId = QProcess.Session.CurrentSession.QUser.Id;
            Assignees = calendarRepo.GetAssignees(userId).ToList();
            try
            {
                if (Context.Request.Params["assigneeId"] != null)
                {
                    AssigneeIds = Context.Request.Params["assigneeId"]
                        .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                        .Select(s => int.Parse(s)).ToArray();
                }
                else
                {
                    AssigneeIds = new[] { 0 };
                }
            }
            catch { AssigneeIds = new[] { 0 }; }
            ShowStatus = Context.Request.Params["showStatus"] != null && bool.Parse(Context.Request.Params["showStatus"]);
            FilterMask = Context.Request.Params["filterMask"] != null
                ? int.Parse(Context.Request.Params["filterMask"])
                : Session.Keys.OfType<string>().Contains("filterMask")
                    ? (int)Session["filterMask"]
                    : 103; //Active, Soft Deadlines, Overdue, Future and Controlled by User

            Session["filterMask"] = FilterMask;

            StartDate = SelectedDate;
            Day1Date = StartDate;
            EndDate = StartDate.AddDays(5);

            var checklists = calendarRepo.GetChecklists(userId, AssigneeIds, ShowStatus, StartDate, EndDate.AddDays(1)).ToList();

            Repeater1.DataBind();

            DayOfWeek1.WeekDate = Day1Date;
            DayOfWeek1.IsSelectedDay = Day1Date == SelectedDate;
            DayOfWeek1.Checklists = checklists.Where(c =>
                c.DueTime.Date == Day1Date.Date
                || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date <= Day1Date.Date && c.DueTime.Date > Day1Date.Date)
            ).ToList();


            DayOfWeek1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

