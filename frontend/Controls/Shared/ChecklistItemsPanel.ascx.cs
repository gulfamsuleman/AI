using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_ChecklistItemsPanel : System.Web.UI.UserControl
	{
		public int ChecklistId { get; set; }
		public int ChangeId { get; set; }
		protected IEnumerable<NamedEntity> ItemTypes;
		public List<ChecklistItem> ChecklistItems { get; set; }

		public Repeater Repeater1 { get; set; }

		public Controls_Shared_ChecklistItemsPanel()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			ItemTypes = selectListRepo.GetItemTypes();
			Repeater1.DataBind();
			var checklistRepo = new ChecklistRepository();
			if (ChangeId <= 0)
				ChecklistItems = checklistRepo.GetChecklistItems(ChecklistId, QProcess.Session.CurrentSession.QUser.Id);
			else
				ChecklistItems = checklistRepo.ApprovalGetChecklistItems(ChecklistId, ChangeId);
		}

		public string SerializedItems()
		{
			var serializer = new JavaScriptSerializer();
            serializer.MaxJsonLength = Int32.MaxValue;
            var toSerialize = ChecklistItems.Select(c => 
				new { 
					id = c.ItemId, 
					typeString = c.ItemTypeString ?? "", 
					type = c.ItemTypeId, 
					text = c.Description.Replace("'", "`") ?? "", 
					url = c.Url.Replace("'", "`") ?? "" }).ToList();
			return serializer.Serialize(toSerialize);
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

