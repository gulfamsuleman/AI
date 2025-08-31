
namespace QProcess.Models
{
    /// <summary>
    /// Summary description for PrioritySchedule
    /// </summary>
    public class PrioritySchedule
    {
        public int ScheduleID { get; set; }
        public int SupervisorID { get; set; }
        public int SubOrdinateId { get; set; }

        public string SupervisorName { get; set; }
        public string EmployeeName { get; set; }

        public string DaysOfWeek { get; set; }

        public string TimesOfDay { get; set; }

        public string ReportDay { get; set; }

        public int OffsetDays { get; set; }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

