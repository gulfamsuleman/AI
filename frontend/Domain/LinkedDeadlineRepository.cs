using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Extensions;
using QProcess.Models;

namespace QProcess.Repositories
{
    public class LinkedDeadlineRepository
    {
        public IEnumerable<LinkedDeadline> GetLinkedDeadlines(int userId)
        {
            using (var cmd = new CmdObj("QCheck_LinkedDeadlines_Get", 360))
            {
                cmd.Add("@UserID", userId);
                var linked = cmd.GetDS();
                return linked.Tables[0].AsEnumerable().Select(ld =>
                {
                    var linkeddeadlinetask = new LinkedDeadline
                    {
                        Id = (int)ld["ID"],
                        SourceTaskName = (string)ld["sourcechecklist"],
                        LinkedTaskName = (string)ld["linkedchecklist"],
                        DaysOffset = (int)ld["DaysOffset"]
                    };
                    return linkeddeadlinetask;
                });
            }
        }

        public bool AddLink(int sourceActiveChecklist, int linkedActiveChecklist, int daysoffset, int userId)
        {

            using (var cmd = new CmdObj("QCheck_LinkedDeadlines_Add"))
            {
                cmd.Add("@SourceActiveChecklist", sourceActiveChecklist);
                cmd.Add("@LinkedActiveChecklist", linkedActiveChecklist);
                cmd.Add("@DaysOffset", daysoffset);
                cmd.Add("@CreatedBy", userId);
                cmd.Add("@Created", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                return cmd["@Created"].ToBoolEx().Value;
            }
        }

        public void DeleteLink(int ID, int userId)
        {
            using (var cmd = new CmdObj("QCheck_LinkedDeadlines_Delete", 360))
            {
                cmd.Add("@ID", ID);
                cmd.Add("@ModifiedBy", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<TaskDetails> GetControlledTaskNames(int userId)
        {
            using (var cmd = new CmdObj("QCheck_LinkedDeadlines_ControlledTaskNames"))
            {
                cmd.Add("@UserID", userId);
                var myTasks = cmd.GetDS();
                return myTasks.Tables[0].AsEnumerable().Select(mt => new TaskDetails
                {
                    Id = (int)mt["ID"],
                    Name = (string)mt["taskname"]
                }).ToList();
            }
        }

    }

    public class LinkedDeadline 
    {
        public int Id { get; set; }
        public string SourceTaskName { get; set; }
        public string LinkedTaskName { get; set; }
        public int DaysOffset { get; set; }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

