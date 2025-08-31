using ClosedXML.Excel;
using QProcess.Repositories;
using System;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web;

namespace QProcess.Mobile
{
    public partial class MobileManageTasksExport : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string group = Request.Form["group"];
            string manager = Request.Form["manager"];
            string search = Request.Form["search"];

            int groupId = 0;
            int managerId = 0;
            int.TryParse(group, out groupId);
            int.TryParse(manager, out managerId);

            int userId = QProcess.Session.CurrentSession.QUser.Id;

            var cultureInfo = new CultureInfo("en-US");
            var checklistRepo = new ChecklistRepository();
            var checklists = checklistRepo
                .GetChecklistsForExport(userId, groupId, true, search).ToList();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.AddWorksheet("Task Export");

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
                    memStream.Position = 0;

                    var title = $"Task Export - {DateTime.Now:yyyy-MM-dd}.xlsx";
                    Response.Clear();
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.AddHeader("content-disposition", "attachment;filename=" + title);
                    Response.BinaryWrite(memStream.ToArray());
                    Response.End();
                }
            }
        }
    }
}