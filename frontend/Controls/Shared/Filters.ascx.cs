using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_Filters : System.Web.UI.UserControl
    {
        protected List<NamedEntity> AssignmentGroups { get; set; }
        public Repeater AssignmentGroupsRepeater { get; set; }

        public Controls_Shared_Filters()
        {
            AssignmentGroupsRepeater = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var selectListRepo = new SelectListRepository();
            AssignmentGroups = selectListRepo.GetReportsUserList().ToList();

            AssignmentGroupsRepeater.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

