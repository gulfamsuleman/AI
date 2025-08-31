using System;
using System.Linq;
using System.Collections.Generic;
using QProcess.Repositories;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_Calendar_CalendarDayOfWeek : System.Web.UI.UserControl
    {
        public bool IsSelectedDay { get; set; }
        public List<CalendarChecklist> Checklists { get; set; }
        public DateTime WeekDate { get; set; }
        public string BackgroundStyle { get; set; }
        public bool PushReminders { get; set; } = true;

        public Repeater Repeater1 { get; set; }

        public Controls_Calendar_CalendarDayOfWeek()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsSelectedDay)
                BackgroundStyle = "selected-day";
            else if (WeekDate.Date == QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date)
                BackgroundStyle = "today";
            else
                BackgroundStyle = "normal";

            if (Checklists != null)
            {
                Repeater1.DataSource = Checklists.OrderBy(c => c.DueTime.Date == WeekDate.Date ? c.DueTime.TimeOfDay : c.ReminderDate.TimeOfDay);
                Repeater1.DataBind();
            }
        }

        protected DateTime GetDisplayDate(CalendarChecklist checklist)
        {
            return checklist.DueTime.Date == WeekDate.Date ? checklist.DueTime : checklist.ReminderDate;
        }

        protected string GetLinkStyle(bool isActive, DateTime dueDate, DateTime softDueDate, TaskStage taskStage, bool reminder, bool alert)
        {
            string linkStyle = "";
            if (!isActive || taskStage == TaskStage.Future)
            {
                linkStyle = "grey";
                if (!isActive)
                {
                    linkStyle += " strikethrough completedTask hide";
                }
                if (taskStage == TaskStage.Future)
                    linkStyle += " italic futureTask";
                if (alert)
                    linkStyle += " alert ";
                return linkStyle;
            }
            linkStyle = dueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() ? "red bold overdueTask" : "blue bold activeTask";
            if (reminder)
                if (softDueDate.Date == WeekDate.Date)
                    linkStyle = "green softDue";
            else
                    linkStyle = "green softDueReminder";
            if (alert)
                linkStyle = "lightblue alert hide";
            return linkStyle;
        }

        protected string GetUpcomingID(TaskStage taskStage, int id)
        {
            if (taskStage == TaskStage.Future)
            {
                return id.ToString();
            }
            else
            {
                return "";
            }
        }

        protected string GetActiveChecklistID(TaskStage taskStage, int id)
        {
            if (taskStage == TaskStage.Current)
            {
                return id.ToString();
            }
            else
            {
                return "";
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

