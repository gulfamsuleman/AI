using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_Controllers : System.Web.UI.UserControl
    {
        protected List<NamedEntity> Assignees;
        public bool IsSupervisorsAdmin { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_Shared_Controllers()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var selectListRepo = new SelectListRepository();
            Assignees = selectListRepo.GetGroups().ToList();
            Assignees.Insert(0, new NamedEntity { Id = -1, Name = "" });
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

