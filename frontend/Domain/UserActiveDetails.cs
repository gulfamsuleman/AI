using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace QProcess.Domain
{
    public class UserActiveDetails
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public List<Checklist> ActiveChecklists { get; set; }
        public List<Checklist> PastDueChecklists { get; set; }
        public List<StatusReport> StatusReports { get; set; }
        public List<UserGroup> Groups { get; set; }
    }

    public class GroupDetails
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public List<Checklist> ActiveChecklists { get; set; }
        public List<Checklist> PastDueChecklists { get; set; }
    }
}