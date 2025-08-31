using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_ControllersPanel : UserControl
    {
        public int ChecklistId { get; set; }
        public int ChangeId { get; set; }
        protected IList<NamedEntity> Controllers;
        protected IList<NamedEntity> ControllersWithGroups;
        public List<ChecklistManager> MyControllers { get; set; }
        protected int SupervisorId { get; set; }

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }

        public Controls_Shared_ControllersPanel()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SupervisorId = QProcess.Session.CurrentSession.QUser.SupervisorId;
            var selectListRepo = new SelectListRepository();
            Controllers = selectListRepo.GetAllSupervisors().ToList();
            Controllers.Insert(0, new NamedEntity { Id = -1, Name = "" });
            ControllersWithGroups = selectListRepo.GetGroups().ToList();
            ControllersWithGroups.Insert(0, new NamedEntity { Id = -1, Name = "" });
            Repeater1.DataBind();
            Repeater2.DataBind();
            var checklistRepo = new ChecklistRepository();
            MyControllers = checklistRepo.GetChecklistManagers(ChecklistId, ChangeId);
        }

        public HtmlString SerializedControllers()
        {
            var serializer = new JavaScriptSerializer();
            var toSerialize = MyControllers.Select(c => new { mapId = c.ID, name = c.Name, existing = c.Existing }).ToList();
            return new HtmlString(serializer.Serialize(toSerialize));
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

