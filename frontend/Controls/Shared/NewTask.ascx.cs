using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{

    public partial class Controls_Shared_NewTask : QProcessControl
    {
        protected IEnumerable<NamedEntity> Controllers;
        protected IEnumerable<NamedEntity> ControllersWithGroups;
        protected IEnumerable<NamedEntity> TaskTemplates;
        protected IEnumerable<NamedEntity> Assignees;
        protected IList<NamedEntity> Folders;
        protected IEnumerable<NamedEntity> ItemTypes;
        protected Dictionary<double, string> TimeOptions = new Dictionary<double, string>();
        protected int UserId { get; set; }
        protected string FullName { get; set; }
        protected bool ShowPriority { get; set; }
        protected int TaskType { get; set; }

        public Repeater rptAssignees { get; set; }
        public Repeater rptFolders { get; set; }
        public Repeater rptControllers { get; set; }
        public Repeater rptGroupsControllers { get; set; }
        public Repeater rptControllers2 { get; set; }
        public Repeater rptGroupsControllers2 { get; set; }
        public Repeater rptTemplate { get; set; }

        public Controls_Shared_NewTask()
        {
            rptAssignees = new Repeater();
            rptFolders = new Repeater();
            rptControllers = new Repeater();
            rptGroupsControllers = new Repeater();
            rptControllers2 = new Repeater();
            rptGroupsControllers2 = new Repeater();
            rptTemplate = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Models.IUser qUser = CurrentSession.QUser;

            if (!Request.IsAuthenticated) return;

            UserId = qUser.Id;
            FullName = CurrentSession.QUser.FullName;
            var newDateTime = new DateTime(1900, 1, 1, 0, 0, 0);
            for (var i = 0.0; i < 24; i += .5)
            {
                var tempTime = newDateTime.AddHours(i);
                TimeOptions.Add(i, tempTime.ToString("t"));
            }

            var selectListRepo = new SelectListRepository();

            Controllers = selectListRepo.GetAllSupervisors();
            ControllersWithGroups = selectListRepo.GetGroups();
            TaskTemplates = selectListRepo.GetTaskTemplates(UserId, CurrentSession.QUser.IsAdmin);
            Assignees = ControllersWithGroups;
            Folders = selectListRepo.GetFolders(UserId).ToList();
            Folders.Insert(0, new NamedEntity { Id = 0, Name = "" });
            ItemTypes = selectListRepo.GetItemTypes();

            // Loaded from My Status, add the extra bits
            if (Context.Request.Headers["X-ShowPriority"] != null)
            {
                bool sp;
                if (bool.TryParse(Context.Request.Headers["X-ShowPriority"].ToString(), out sp))
                {
                    ShowPriority = sp;
                }
            }
            if (Context.Request.Headers["X-TaskType"] != null)
            {
                int tt;
                if (int.TryParse(Context.Request.Headers["X-TaskType"].ToString(), out tt))
                {
                    TaskType = tt;
                }
            }

            rptAssignees.DataSource = Assignees;
            rptAssignees.DataBind();
            rptFolders.DataSource = Folders;
            rptFolders.DataBind();
            rptControllers.DataSource = Controllers;
            rptControllers.DataBind();
            rptGroupsControllers.DataSource = ControllersWithGroups;
            rptGroupsControllers.DataBind();
            rptControllers2.DataSource = new[] { new NamedEntity { Id = 0, Name = "" } }.Concat(Controllers);
            rptControllers2.DataBind();
            rptGroupsControllers2.DataSource = new[] { new NamedEntity { Id = 0, Name = "" } }.Concat(ControllersWithGroups);
            rptGroupsControllers2.DataBind();
            rptTemplate.DataSource = TaskTemplates;
            rptTemplate.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

