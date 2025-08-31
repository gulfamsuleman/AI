namespace QProcess.Models
{
    public class SearchResult
    {
        public string Timestamp { get; set; }
        public ItemResult[] Data { get; set; }
        public bool Truncated { get; set; }

        public SearchResult() { }

        public class ItemResult
        {
            #region properties
            public int ChecklistId { get; set; }
            public bool IsDeleted { get; set; }
            public bool IsArchived { get; set; }
            public string Name { get; set; }
            public string Schedule { get; set; }
            public string Completed { get; set; }
            public string Controllers { get; set; }
            public string Assignees { get; set; }
            public string Comment { get; set; }
            public string ItemText { get; set; }
            private string statusReport;
            public string StatusReport
            {
                get
                {
                    return statusReport;
                }
                set
                {
                    // strip out HTML if exist
                    if (value.IndexOf('>') != -1)
                    {
                        statusReport = System.Text.RegularExpressions.Regex.Replace(value, "<.*?>", string.Empty);
                    }
                    else
                    {
                        statusReport = value;
                    }
                }
            }
            #endregion

            public ItemResult() { }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

