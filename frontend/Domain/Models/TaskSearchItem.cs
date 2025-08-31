namespace QProcess.Models
{
    public class TaskSearchResult
    {
        public string Timestamp { get; set; }
        public TaskSearchItem[] Data { get; set; }
        public int ActualCount { get; set; }

        public class TaskSearchItem
        {
            public string TaskName { get; set; }
            public string Due { get; set; }
            public string Completed { get; set; }
            public string Assignees { get; set; }
            public string Controllers { get; set; }
            public string Schedule { get; set; }
            public string LastCompletedBy { get; set; }
            public string LastCompletedDate { get; set; }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

