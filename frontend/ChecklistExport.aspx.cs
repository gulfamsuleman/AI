using System;
using QProcess.Extensions;
using QProcess.Repositories;
using QProcess.Controls;
using System.Web;

namespace QProcess
{

    public partial class ChecklistExport : SessionPage
	{
		public Controls_Shared_ChecklistExport ChecklistExportControl { get; set; }

        protected Checklist Checklist { get; set; }
		protected int ChecklistId { get; set; }
		protected TaskStage TaskStage { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var checklistRepo = new ChecklistRepository();

			ChecklistId = Convert.ToInt32(Context.Request.QueryString["checklistId"]);
			TaskStage = (Convert.ToString(Context.Request.QueryString["taskStage"])).FromString<TaskStage>();

			Checklist = checklistRepo.GetSingleChecklist(CurrentSession.QUser.Id, TaskStage, ChecklistId);
			ChecklistExportControl.Checklist = Checklist;
			ChecklistExportControl.DataBind();
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

