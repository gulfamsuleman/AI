using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace QProcess.Domain
{
    public class UserStats
    {
        public int UserId { get; set; }
        public string FullName { get; set; }
        public int Tasks { get; set; }
        public int LatePriorities { get; set; }
        public int ChargedPriorities { get; set;}
        public int LateTasks { get; set; }
        public int ChargedTasks { get; set; }
        public int OverdueTasks { get; set; }  
        public int SupervisorControlledTasks { get; set; }
        public int SupervisorControlledPct { get; set; }
        public int CommentsMade { get; set; }   
        public int TasksCompleted { get; set; }
        public int PriorityEmailsTotal { get; set; }
        public int TasksCreated { get; set; }
        public int EmailsSent { get; set; }
        public int ChangeRequests { get; set; }


        //PHI Points

        public int TasksCompletedOnTime { get; set; }
        public int TasksCreatedThroughEmail { get; set; }
        public int MultiStepOrRecurringTasksCompleted { get; set; }
        public int SendPriorityListOrStatusEmail { get; set; }
        public int MissingPriorityListsorStatusReport { get; set; }

        public double TotalPoints { get; set; }
    }
}