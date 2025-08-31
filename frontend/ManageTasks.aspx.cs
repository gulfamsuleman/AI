using System;
using System.Web;
using System.Collections.Generic;
using QProcess.Repositories;
using QProcess.Extensions;
using CsvHelper.Configuration;
using System.IO;
using System.Globalization;
using DotNetOpenAuth.OpenId;
using static DotNetOpenAuth.OpenId.Extensions.AttributeExchange.WellKnownAttributes;
using System.Linq;
using static QProcess.ChecklistExportMap;
using ClosedXML.Excel;
using System.Runtime.InteropServices.ComTypes;
using CsvHelper.Configuration.Attributes;

namespace QProcess
{

    public partial class ManageTasks : SessionPage
	{
		public IEnumerable<TreeNodeData> Tree { get; set; }
		public int UserId { get; set; }
		public int? ChecklistId { get; set; }
		public int? ChangeId { get; set; }
		public IEnumerable<NamedEntity> Groups { get; set; }
		public string SearchTerm { get; set; }
        public string NewSearchTerm { get; set; } = "";

		protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request))
                || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }

            var treeViewRepo = new TreeViewRepository();
			var selectListRepository = new SelectListRepository();
			var userRepo = new UserRepository();
			if (Context.Request.Params["checklistId"] != null)
				ChecklistId = int.Parse(Context.Request.Params["checklistId"]);
			if (Context.Request.Params["changeId"] != null)
				ChangeId = int.Parse(Context.Request.Params["changeId"]);
			Groups = selectListRepository.GetGroups();
			UserId = CurrentSession.QUser.Id;
			SearchTerm = userRepo.GetPreference(UserId, "ControlSearch");
			DataBind();
            NewSearchTerm = SearchTerm;
		}

		public void ExportTasks(object sender, EventArgs e)
		{
            var search = NewSearchTerm;
            var cultureInfo = new CultureInfo("en-US");
			var checklistRepo = new ChecklistRepository();
            var checklists = checklistRepo
                .GetChecklistsForExport(CurrentSession.QUser.Id, 0, true, search).ToList();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.AddWorksheet($"Task Export");

                worksheet.Cell(1, 1).Value = "Task Name";
                worksheet.Cell(1, 2).Value = "Assignees";
                worksheet.Cell(1, 3).Value = "Controllers";
                worksheet.Cell(1, 4).Value = "Next Due Date";
                worksheet.Cell(1, 5).Value = "Schedule";
                worksheet.Cell(1, 6).Value = "Changes Pending?";
                worksheet.Cell(1, 7).Value = "New Due Date (If any)";
                worksheet.Cell(1, 8).Value = "Created Date";

                var headerRange = worksheet.Range("A1:H1");
                headerRange.Style.Font.Bold = true;
                headerRange.Style.Font.FontColor = XLColor.White;
                headerRange.Style.Fill.BackgroundColor = XLColor.DarkMidnightBlue;
                headerRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;

                for (var i = 0; i < checklists.Count; i++)
                {
                    var checklist = checklists[i];
                    worksheet.Cell(i + 2, 1).Value = checklist.Name;
                    worksheet.Cell(i + 2, 2).Value = checklist.Assignees;
                    worksheet.Cell(i + 2, 3).Value = checklist.Controllers;
                    worksheet.Cell(i + 2, 4).Value = checklist.DueDate;
                    worksheet.Cell(i + 2, 5).Value = checklist.RecurranceSchedule;
                    worksheet.Cell(i + 2, 6).Value = checklist.PendingChange;
                    worksheet.Cell(i + 2, 7).Value = checklist.NewDeadline;
                    worksheet.Cell(i + 2, 8).Value = checklist.CreateDate;

                    worksheet.Cell(i + 2, 4).Style.DateFormat.Format = "MM/dd/yyyy h:mm AM/PM";
                    worksheet.Cell(i + 2, 7).Style.DateFormat.Format = "MM/dd/yyyy h:mm AM/PM";
                    worksheet.Cell(i + 2, 8).Style.DateFormat.Format = "MM/dd/yyyy h:mm AM/PM";
                }

                worksheet.Columns().AdjustToContents();

                using (var memStream = new MemoryStream())
                {
                    workbook.SaveAs(memStream);
                    memStream.Position = 0; // Reset stream position before reading

                    var title = $"Task Export - {DateTime.Now.ToShortDateString()}.xlsx";
                    // Send the file to the client
                    Response.Clear();
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.AddHeader("content-disposition", "attachment;filename=" + title);
                    Response.BinaryWrite(memStream.ToArray());
                    Response.End();
                }

                
            }

            //var config = new CsvConfiguration(CultureInfo.InvariantCulture)
            //{
            //    HasHeaderRecord = true,
            //    TrimOptions = TrimOptions.Trim,
            //    MissingFieldFound = null,
            //    IgnoreBlankLines = true,
            //};

            //var records = new List<ChecklistExportMap>();

            //         using (var writer = new StreamWriter(memStream))
            //         {
            //             using (var csvWriter = new CsvWriter(writer, config))
            //             {
            //                 csvWriter.Context.RegisterClassMap<ChecklistExportMap>();
            //                 csvWriter.WriteRecords(checklists);
            //             }
            //         }

            //         string templateFileName = $"Task Export {DateTime.Now}.csv";

            //         Response.Clear();
            //Response.ContentType = "text/csv";
            //Response.AddHeader("Content-Disposition", $"attachment; filename={templateFileName}");
            //Response.BinaryWrite(memStream.ToArray());
            //Response.End();
        }
	}

	public class ChecklistExportMap : ClassMap<ChecklistObject>
	{
		public ChecklistExportMap()
		{
            var format = "MM/dd/yyyy h:mm tt";
            var enUS = CultureInfo.GetCultureInfo("en-US");
            Map(m => m.Name).Name("Task Name");
            Map(m => m.Assignees).Name("Assignees");
            Map(m => m.Controllers).Name("Controllers");
            Map(m => m.DueDate).Name("Next Due Date").TypeConverterOption.Format(format).TypeConverterOption.CultureInfo(enUS);
            Map(m => m.RecurranceSchedule).Name("Schedule");
            Map(m => m.PendingChange).Name("Changes Pending?").Optional();
            Map(m => m.NewDeadline).Name("New Deadline (If any)").TypeConverterOption.Format(format).TypeConverterOption.CultureInfo(enUS).Optional();
            Map(m => m.CreateDate).Name("Created Date").TypeConverterOption.Format(format).TypeConverterOption.CultureInfo(enUS);

            //Map(m => m.ChecklistId).Ignore();
            //Map(m => m.Identifier).Ignore();
            //Map(m => m.UniqueId).Ignore();
            //Map(m => m.UpcomingId).Ignore();
            //Map(m => m.StatusReportString).Ignore();
            //Map(m => m.AssigneeCount).Ignore();
            //Map(m => m.TaskStage).Ignore();
            //Map(m => m.ControllerPartOfAssignee).Ignore();
            //Map(m => m.IsNA).Ignore();
            //Map(m => m.NAReason).Ignore();
            //Map(m => m.IsRecurring).Ignore();



        }

        public class ChecklistObject
        {
            public string Name { get; set; }
            public string Controllers { get; set; }
            public string Assignees { get; set; }
            public DateTime? CreateDate { get; set; }
            public string RecurranceSchedule { get; set; }
            public bool PendingChange { get; set; }
            public DateTime? NewDeadline { get; set; }
            public DateTime? DueDate { get; set; }
        }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

