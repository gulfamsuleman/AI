using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;
using QProcess.Controls;
using System.Web;
using QProcess.Extensions;

namespace QProcess
{

    public partial class Calendar : SessionPage, IProvideReportIdForLogging
    {
        protected List<CalendarChecklist> Day1 { get; set; }
        protected List<CalendarChecklist> Day2 { get; set; }
        protected List<CalendarChecklist> Day3 { get; set; }
        protected List<CalendarChecklist> Day4 { get; set; }
        protected List<CalendarChecklist> Day5 { get; set; }
        protected List<CalendarChecklist> Day6 { get; set; }
        protected List<CalendarChecklist> OldOverdueTasks { get; set; }
        protected Controls_Calendar_OverdueCalendarDay OverdueDay;
        protected DateTime Day1Date { get; set; }
        protected DateTime Day2Date { get; set; }
        protected DateTime Day3Date { get; set; }
        protected DateTime Day4Date { get; set; }
        protected DateTime Day5Date { get; set; }
        protected DateTime Day6Date { get; set; }
        protected DateTime SelectedDate { get; set; }
        protected DateTime StartDate { get; set; }
        protected DateTime EndDate { get; set; }
        
        public int ReportId { get; set; }
        DateTime currOverdueDate = DateTime.Parse("1/1/1970");
        protected string PrintVisiblity = "hidden"; //added by Venkat
        public int FilterMask { get; set; }
        public bool PushReminders { get; set; } = true;
        protected int[] AssigneeIds { get; set; }
        protected bool ShowStatus { get; set; }
        protected List<CalendarAssignee> Assignees { get; set; }

        public Controls_Calendar_CalendarDayOfWeek DayOfWeek1 { get; set; }
        public Controls_Calendar_CalendarDayOfWeek DayOfWeek2 { get; set; }
        public Controls_Calendar_CalendarDayOfWeek DayOfWeek3 { get; set; }
        public Controls_Calendar_CalendarDayOfWeek DayOfWeek4 { get; set; }
        public Controls_Calendar_CalendarDayOfWeek DayOfWeek5 { get; set; }
        public Controls_Calendar_CalendarDayOfWeek DayOfWeek6 { get; set; }
        public PlaceHolder phOverdue { get; set; }
        public Repeater Repeater1 { get; set; }        

        public Calendar()
        {
            Repeater1 = new Repeater();

            DayOfWeek1 = new Controls_Calendar_CalendarDayOfWeek();
            DayOfWeek2 = new Controls_Calendar_CalendarDayOfWeek();
            DayOfWeek3 = new Controls_Calendar_CalendarDayOfWeek();
            DayOfWeek4 = new Controls_Calendar_CalendarDayOfWeek();
            DayOfWeek5 = new Controls_Calendar_CalendarDayOfWeek();
            DayOfWeek6 = new Controls_Calendar_CalendarDayOfWeek();

            phOverdue = new PlaceHolder();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request)) || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }

            ReportId = 1;            
            SelectedDate = Context.Request.Params["date"] != null 
                ? DateTime.Parse(Context.Request.Params["date"]) 
                : QProcess.Session.CurrentSession.UserTimeZone.GetLocalTime(DateTime.UtcNow).Date;
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
            EndDate = StartDate.AddDays(5);

            Day1Date = StartDate;
            Day2Date = StartDate.AddDays(1);
            Day3Date = StartDate.AddDays(2);
            Day4Date = StartDate.AddDays(3);
            Day5Date = StartDate.AddDays(4);
            Day6Date = StartDate.AddDays(5);

            // Correct for an EndDate that is at midgnight of the EndDate instead of 11:59PM of the EndDate
            var checklists = calendarRepo.GetChecklists(userId, AssigneeIds, ShowStatus, StartDate, EndDate.AddDays(1)).ToList();

            Repeater1.DataBind();

            DayOfWeek1.WeekDate = Day1Date;
            DayOfWeek1.IsSelectedDay = Day1Date == SelectedDate;
            DayOfWeek1.Checklists = checklists.Where(c => c.DueTime.Date == Day1Date.Date|| (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date <= Day1Date.Date && c.DueTime.Date > Day1Date.Date)).ToList();
            DayOfWeek1.DataBind();

            DayOfWeek2.WeekDate = Day2Date;
            DayOfWeek2.IsSelectedDay = Day2Date == SelectedDate;
            DayOfWeek2.Checklists = checklists.Where(c => c.DueTime.Date == Day2Date.Date || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date == Day2Date.Date)).ToList();
            DayOfWeek2.DataBind();

            DayOfWeek3.WeekDate = Day3Date;
            DayOfWeek3.IsSelectedDay = Day3Date == SelectedDate;
            DayOfWeek3.Checklists = checklists.Where(c => c.DueTime.Date == Day3Date.Date || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date == Day3Date.Date)).ToList();
            DayOfWeek3.DataBind();

            DayOfWeek4.WeekDate = Day4Date;
            DayOfWeek4.IsSelectedDay = Day4Date == SelectedDate;
            DayOfWeek4.Checklists = checklists.Where(c => c.DueTime.Date == Day4Date.Date || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date == Day4Date.Date)).ToList();
            DayOfWeek4.DataBind();

            DayOfWeek5.WeekDate = Day5Date;
            DayOfWeek5.IsSelectedDay = Day5Date == SelectedDate;
            DayOfWeek5.Checklists = checklists.Where(c => c.DueTime.Date == Day5Date.Date || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date == Day5Date.Date)).ToList();
            DayOfWeek5.DataBind();

            DayOfWeek6.WeekDate = Day6Date;
            DayOfWeek6.IsSelectedDay = Day6Date == SelectedDate;
            DayOfWeek6.Checklists = checklists.Where(c => c.DueTime.Date == Day6Date.Date || (c.ReminderDate != DateTime.MinValue && c.ReminderDate.Date == Day6Date.Date)).ToList();
            DayOfWeek6.DataBind();


            OldOverdueTasks = checklists.Where(c => c.DueTime.Date < DateTime.UtcNow.Date &&  c.Active && c.TaskStage != TaskStage.Future && !c.IsAlert).ToList();
            foreach (CalendarChecklist ck in OldOverdueTasks)
            {
                if (currOverdueDate == DateTime.Parse("1/1/1970") || ck.DueTime.Date != currOverdueDate.Date)
                {
                    currOverdueDate = ck.DueTime.Date;
                    OverdueDay = (Controls_Calendar_OverdueCalendarDay)LoadControl("~/Controls/Calendar/OverdueCalendarDay.ascx");
                    phOverdue.Controls.Add(OverdueDay);
                    OverdueDay.WeekDate = currOverdueDate.Date;
                    OverdueDay.IsSelectedDay = false;
                    OverdueDay.Checklists = OldOverdueTasks.Where(c => c.DueTime.Date == currOverdueDate.Date).ToList();
                    OverdueDay.DataBind();
                }
            }

            if (new UserRepository().IsPrintButtonVisible(userId))
            {
                PrintVisiblity = "visible";
            }
        }


    }
}
/* Copyright © 2024 Renegade Swish, LLC */

