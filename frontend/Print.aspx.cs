using System;
using System.Collections.Generic;
using QProcess.Configuration;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class Print : Page
    {
        protected IEnumerable<NamedEntity> Controllers;
        protected IEnumerable<NamedEntity> ControllersWithGroups;
        protected IEnumerable<NamedEntity> Assignees;
        protected IList<NamedEntity> Folders;
        protected IEnumerable<NamedEntity> ItemTypes;
        protected Dictionary<double, string> TimeOptions = new Dictionary<double, string>();
        protected int UserId { get; set; }
        protected string FullName { get; set; }
        protected bool ShowPriority { get; set; }
        protected int TaskType { get; set; }
        protected string Firm { get; set; }

        public Repeater rptAssignees { get; set; }

        public Print()
        {
            rptAssignees = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Firm = AppSettings.Get("Firm");

            UserId = QProcess.Session.CurrentSession.QUser.Id;
            FullName = QProcess.Session.CurrentSession.QUser.FullName;
            var newDateTime = new DateTime(1900, 1, 1, 0, 0, 0);
            for (var i = 0.0; i < 24; i += .5)
            {
                var tempTime = newDateTime.AddHours(i);
                TimeOptions.Add(i, tempTime.ToString("t"));
            }

            var selectListRepo = new SelectListRepository();

            Controllers = selectListRepo.GetAllSupervisors();
            // ControllersWithGroups = selectListRepo.GetReportsUserList();
            Assignees = selectListRepo.GetPrintUserList(UserId);
            //Assignees = selectListRepo.GetReportsUserList();
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

        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

