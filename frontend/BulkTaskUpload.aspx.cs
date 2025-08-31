using CsvHelper.Configuration;
using System;
using System.Globalization;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.IO;
using CsvHelper;
using System.Text;
using CsvHelper.Configuration.Attributes;
using QProcess.Repositories;
using System.Linq.Expressions;
using System.Data.SqlClient;
using QProcess.Extensions;
using QProcess.Configuration;
using System.Runtime.CompilerServices;
using Unity;
using QProcess.warmup;
using CsvHelper.TypeConversion;

namespace QProcess
{
    public partial class BulkTaskUpload : Page
    {
        [Unity.Dependency]
        public UserRepository userRepo { get; set; }

        [Unity.Dependency]
        public ChecklistRepository checklistRepo { get; set; }

        [Unity.Dependency]
        public StatusReportRepository statusRepo { get; set; }

        CsvConfiguration config;
        StringBuilder resultMessage = new StringBuilder();
        private static string appName = AppSettings.Get("AppName");
        int errorCount = 0;
        StringBuilder resultMessages = new StringBuilder();
        List<User> activeUsers = new List<User>();
        IEnumerable<Checklist> activeTasks = new List<Checklist>();
        List<ReportHeader> statusReports = new List<ReportHeader>();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (userRepo == null) userRepo = UnityConfig.Container.Resolve<UserRepository>();
            if (checklistRepo == null) checklistRepo = UnityConfig.Container.Resolve<ChecklistRepository>();
            if (statusRepo == null) statusRepo = UnityConfig.Container.Resolve<StatusReportRepository>();


            if (!IsPostBack) resultMessageLabel.Text = string.Empty;

            config = new CsvConfiguration(CultureInfo.CurrentCulture)
            {
                HasHeaderRecord = true,
                TrimOptions = TrimOptions.Trim,
                MissingFieldFound = context =>
                {
                    resultMessage.AppendLine($"Missing field found: {context.Index}");
                    errorCount++;
                },
                IgnoreBlankLines = false,
            };
        }

        public void DownloadTemplate(object sender, EventArgs e)
        {

            var records = new List<BulkTask>();
            var memStream = new MemoryStream();
            using (var writer = new StreamWriter(memStream))
            {
                using (var csvWriter = new CsvWriter(writer, config))
                {
                    csvWriter.Context.RegisterClassMap<BulkTaskMap>();
                    csvWriter.WriteRecords(records);
                }
            }

            string templateFileName = "TaskTemplate.csv";

            Response.Clear();
            Response.ContentType = "text/csv";
            Response.AddHeader("Content-Disposition", $"attachment; filename={templateFileName}");
            Response.BinaryWrite(memStream.ToArray());
            Response.End();
        }

        public void ImportCsv(object sender, EventArgs e)
        {
            const int maxErr = 10;

            BulkTask currentRecord = null;
            resultMessage.Clear();
            errorCount = 0;
            resultMessageLabel.Text = "";
            if (taskCsvUpload.HasFile && Path.GetExtension(taskCsvUpload.FileName) == ".csv")
            {
                try
                {
                    activeUsers = userRepo.GetUsers().Where(u => u.IsDeleted == false).ToList();
                    statusReports = statusRepo.GetReports().ToList();
                    var activeGroups = userRepo.GetGroups().ToList();

                    int userId = QProcess.Session.CurrentSession.QUser.Id;
                    var preferences = userRepo.GetBulkImportPreferences(userId);

                    using (var reader = new StreamReader(taskCsvUpload.PostedFile.InputStream))
                    {
                        using (var csv = new CsvReader(reader, config))
                        {
                            csv.Context.RegisterClassMap<BulkTaskMap>();
                            csv.Read();
                            csv.ReadHeader();
                            var records = csv.GetRecords<BulkTask>().ToList();
                            var specifiedGroup = new UserGroup();
                            var specifiedStatusReport = new ReportHeader();

                            var filteredRecords = new List<BulkTask>();

                            // Trim all string fields in each record
                            foreach (var record in records)
                            {
                                foreach (var property in record.GetType().GetProperties())
                                {
                                    if (property.PropertyType == typeof(string))
                                    {
                                        var value = property.GetValue(record) as string;
                                        if (value != null)
                                        {
                                            property.SetValue(record, value.Trim());
                                        }
                                    }
                                }

                                // Skip rows missing bare requirements
                                bool isEmpty = string.IsNullOrWhiteSpace(record.Task);

                                if (isEmpty)
                                    continue;

                                // Apply preferences to blank fields
                                if (preferences != null)
                                {
                                    if (string.IsNullOrWhiteSpace(record.Controller1) && !string.IsNullOrWhiteSpace(preferences.ControllerName))
                                        record.Controller1 = preferences.ControllerName;
                                    if (string.IsNullOrWhiteSpace(record.Assignee1) && !string.IsNullOrWhiteSpace(preferences.AssigneeName))
                                        record.Assignee1 = preferences.AssigneeName;
                                    if (preferences.ReportOrig == 0 && string.IsNullOrWhiteSpace(record.StatusReportName))
                                    {
                                        record.IsOnStatusReport = false;
                                    }
                                    else if (preferences.ReportOrig != -1)
                                    {
                                        if (string.IsNullOrWhiteSpace(record.StatusReportName) && !string.IsNullOrWhiteSpace(preferences.ReportName))
                                            record.StatusReportName = preferences.ReportName;
                                        if (string.IsNullOrWhiteSpace(record.StatusReportSection) && !string.IsNullOrWhiteSpace(preferences.SectionName))
                                            record.StatusReportSection = preferences.SectionName;
                                    }
                                    // preferences.ReportOrig = -1 means the preference is to default to assignee's status report (multiple assignees possible, so leave blank)
                                    else
                                    {
                                        record.StatusReportName = string.Empty;
                                        record.StatusReportSection = string.Empty;

                                        record.IsDefaultToAssignee = true;
                                    }

                                    if (string.IsNullOrWhiteSpace(record.AddToPriorityList))
                                    {
                                        record.ToPriorityList = false;
                                        record.Priority = 0;
                                    }
                                    else
                                    {
                                        var value = record.AddToPriorityList.ToLower().Trim();

                                        if (value == "x" || value == "y" || value == "yes")
                                        {
                                            record.ToPriorityList = true;
                                            // User specifically flagged as needing to be added to priority list in spreadsheet.
                                            // Default to end if no preference or preference is not to show on priority list.
                                            if (preferences.Priority <= 0)
                                            {
                                                record.Priority = 999;
                                            }
                                            else
                                            {
                                                record.Priority = preferences.Priority;
                                            }
                                        }
                                        else
                                        {
                                            record.ToPriorityList = false;
                                            record.Priority = 0;
                                        }
                                    }

                                    // Fill in DueDate from preferences if missing
                                    if (!record.DueDate.HasValue && preferences.Due != 0)
                                    {
                                        int daysToAdd = 1; // Default to tomorrow
                                        if (preferences.Due == -1 || preferences.Due == 1)
                                            daysToAdd = 1;
                                        else if (preferences.Due > 1 && preferences.Due <= 10)
                                            daysToAdd = preferences.Due;

                                        record.DueDate = DateTime.UtcNow.Date.AddDays(daysToAdd);
                                    }

                                    // Fill in SoftDueDate from preferences if missing and DueDate if set
                                    if (!record.SoftDueDate.HasValue && record.DueDate.HasValue && preferences.SoftDue != 0)
                                    {
                                        if (preferences.SoftDue == -1)
                                        {
                                            // Same as DueDate
                                            record.SoftDueDate = record.DueDate;
                                        }
                                        else if (preferences.SoftDue > 0 && preferences.SoftDue <= 10)
                                        {
                                            // DueDate - X days
                                            record.SoftDueDate = record.DueDate.Value.AddDays(-preferences.SoftDue);
                                        }
                                    }
                                }

                                filteredRecords.Add(record);
                            }

                            //Validate all records
                            foreach (var (index, record) in filteredRecords.Select((record, index) => (index, record)))
                            {
                                try
                                {
                                    if (errorCount >= maxErr)
                                    {
                                        resultMessage.AppendLine($"Too many errors detected in file - aborting import");
                                        break;
                                    }

                                    record.RowNumber = index + 2; //account for actual record row in file
                                    currentRecord = record;

                                    // Require DueDate
                                    if (!record.DueDate.HasValue)
                                    {
                                        resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - The Due Date field is required<br>");
                                        errorCount++;
                                    }

                                    if (record.Controller1.IsNullOrBlank())
                                    {
                                        resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The Controller1 field is required<br>");
                                        errorCount++;
                                    }
                                    else
                                    {
                                        specifiedGroup = activeGroups.Where(u => u.GroupName == record.Controller1.Trim()).FirstOrDefault();

                                        if (specifiedGroup == null)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Controller1 does not match any user in {appName}<br>");
                                            errorCount++;
                                        }
                                    }
                                    // Skip validation if defaulting to assignee or is meant to be added to status report
                                    if (!record.IsDefaultToAssignee && record.IsOnStatusReport)
                                    {
                                        if (record.StatusReportName.IsNullOrBlank())
                                        {
                                            //both specified or both blank
                                            if (!record.StatusReportSection.IsNullOrBlank())
                                            {
                                                resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                    $"Status Report Section was specified but Status Report was not - Please specify both or neither<br>");
                                                errorCount++;
                                            }
                                        }
                                        else
                                        {
                                            specifiedStatusReport = statusReports.Where(sr => sr.Name == record.StatusReportName.Trim()).FirstOrDefault();

                                            if (specifiedStatusReport == null)
                                            {
                                                resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                    $"The specified Status Report Name does not match any report in {appName}<br>");
                                                errorCount++;
                                            }
                                            else if (record.StatusReportSection.IsNullOrBlank())
                                            {
                                                resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                    $"Status Report was specified but Status Report Section was not - Please specify both or neither<br>");
                                                errorCount++;
                                            }
                                            else
                                            {
                                                var taskType = statusRepo.GetTaskTypeByReport(specifiedStatusReport.Name.Trim(), record.StatusReportSection.Trim());

                                                if (taskType == null)
                                                {
                                                    resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                        $"The specified Status Report Section does not exist on the Status Report<br>");
                                                    errorCount++;
                                                }
                                            }
                                        }
                                    }

                                    if (record.Task.IsNullOrBlank())
                                    {
                                        resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                            $"Task name is required<br>");
                                        errorCount++;
                                    }

                                    if (specifiedGroup != null)
                                    {
                                        var okToUse = checklistRepo.DuplicateNameCheck(record.Task.Trim(), specifiedGroup.Id);

                                        if (!okToUse)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Task name already exists<br>");
                                            errorCount++;
                                        }
                                    }

                                    if (!string.IsNullOrEmpty(record.Controller2))
                                    {
                                        specifiedGroup = activeGroups.Where(u => u.GroupName == record.Controller2.Trim()).FirstOrDefault();

                                        if (specifiedGroup == null)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Controller2 does not match any user in {appName}<br>");
                                            errorCount++;
                                        }
                                    }

                                    if (record.Assignee1.IsNullOrBlank())
                                    {
                                        resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The Assignee1 column is required<br>");
                                        errorCount++;
                                    }
                                    else
                                    {
                                        specifiedGroup = activeGroups.Where(u => u.GroupName == record.Assignee1.Trim()).FirstOrDefault();

                                        if (specifiedGroup == null)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Assignee1 does not match any user in {appName}<br>");
                                            errorCount++;
                                        }
                                    }

                                    if (!string.IsNullOrEmpty(record.Assignee2))
                                    {
                                        specifiedGroup = activeGroups.Where(u => u.GroupName == record.Assignee2.Trim()).FirstOrDefault();

                                        if (specifiedGroup == null)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Assignee2 does not match any user in {appName}<br>");
                                            errorCount++;
                                        }
                                    }
                                    if (!string.IsNullOrEmpty(record.Assignee3))
                                    {
                                        specifiedGroup = activeGroups.Where(u => u.GroupName == record.Assignee3.Trim()).FirstOrDefault();

                                        if (specifiedGroup == null)
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                $"The specified Assignee3 does not match any user in {appName}<br>");
                                            errorCount++;
                                        }
                                    }
                                    if (!string.IsNullOrEmpty(record.AddToPriorityList))
                                    {
                                        var value = record.AddToPriorityList.ToLower().Trim();

                                        if (value != "x" && value != "y" && value != "yes")
                                        {
                                            resultMessage.AppendLine($"Error in record on row {currentRecord.RowNumber} - " +
                                                    $"Invalid input for  field: Add To Priority List. Please either leave blank or mark X, Y, or YES<br>");
                                            errorCount++;
                                        }
                                    }


                                }
                                catch (Exception ex)
                                {
                                    resultMessage.AppendLine($"Error validating row {currentRecord.RowNumber}, {ex.Message}<br>");
                                    ++errorCount;
                                }
                            }

                            if (errorCount == 0)
                            {
                                try
                                {
                                    var importMessages = checklistRepo.AddBulkTasks(records);

                                    if (importMessages.Length > 0)
                                    {
                                        errorCount++;
                                        resultMessage.Append(importMessages.ToString());
                                    }
                                }
                                catch (Exception ex)
                                {
                                    errorCount++;
                                    resultMessage.AppendLine($"Error in bulk insert - {ex.Message}. No records inserted.");
                                }
                            }

                            if (errorCount > 0)
                            {
                                resultMessage.AppendLine("Please check and correct file errors and retry your import.<br>");
                                resultMessageLabel.Text = resultMessage.ToString();
                            }
                            else
                                resultMessageLabel.Text = "File import successful!";
                        }
                    }
                }
                catch (HeaderValidationException hvex)
                {
                    var result = "";
                    foreach (InvalidHeader header in hvex.InvalidHeaders)
                    {
                        header.Names.ForEach(h =>
                        {
                            result += $"{h}<br>";
                            errorCount++;
                        });
                    }
                    resultMessage.AppendLine($"The following headers are missing from the file or are incorrectly entered.<br>Please try again after correcting file:<br>{result}");

                    resultMessageLabel.Text = resultMessage.ToString();
                }
                catch (FieldValidationException ex)
                {
                    var rowNum = ex.Context.Parser.RawRow;
                    var record = ex.Context.Parser.RawRecord;
                    var headers = ex.Context.Reader.HeaderRecord;
                    var fieldsMessage = "<b>Invalid Record:</b> ";
                    foreach (var field in record)
                    {
                        if (field.ToString() == ",")
                            fieldsMessage += field + " ";
                        else fieldsMessage += field;
                    }
                    resultMessage.AppendLine($"Error loading records from CSV in row <b>{rowNum}.</b><br>{fieldsMessage}<br>Please ensure all fields are filled in and correct.");

                    resultMessageLabel.Text = resultMessage.ToString();
                }
                catch (Exception ex)
                {
                    resultMessage.AppendLine($"Error loading records from CSV:<br>{ex.Message}");

                    resultMessageLabel.Text = resultMessage.ToString();
                }
            }
            else
            {
                resultMessageLabel.Text = "File not specified or invalid format. Please ensure the selected file is in the .csv format.";
            }
        }
    }
}

public class BulkTask
{
    public string Task { set; get; }

    public DateTime? DueDate { set; get; }

    public DateTime? SoftDueDate { set; get; } = null;

    public string Controller1 { set; get; }

    public string Controller2 { set; get; } = "";

    public string Assignee1 { set; get; }

    public string Assignee2 { set; get; } = "";

    public string Assignee3 { set; get; } = "";

    public string Item2 { set; get; } = "";

    public string Item3 { set; get; } = "";

    public string Item4 { set; get; } = "";

    public string Item5 { set; get; } = "";

    public string Item6 { set; get; } = "";

    public string Item7 { set; get; } = "";

    public string Item8 { set; get; } = "";

    public string Item9 { set; get; } = "";

    public string StatusReportName { set; get; }

    public string StatusReportSection { get; set; }

    public string AddToPriorityList { get; set; }

    public int RowNumber { get; set; }
    public int Priority { get; set; }

    public bool ToPriorityList { get; set; } = false;
    public bool IsDefaultToAssignee = false;
    public bool IsOnStatusReport = true;
}

public class BulkTaskMap : ClassMap<BulkTask>
{
    public BulkTaskMap()
    {
        Map(m => m.Task).Name("Task");
        Map(m => m.DueDate)
            .Name("Due Date")
            .TypeConverter(new NullableDateTimeConverter("MM/dd/yyyy", "M/d/yyyy"))
            .Optional();
        Map(m => m.SoftDueDate)
            .Name("Soft Due Date")
            .TypeConverter(new NullableDateTimeConverter("MM/dd/yyyy", "M/d/yyyy"))
            .Optional();
        Map(m => m.Controller1).Name("Controller 1");
        Map(m => m.Controller2).Name("Controller 2").Optional().Default("");
        Map(m => m.Assignee1).Name("Assignee 1");
        Map(m => m.Assignee2).Name("Assignee 2").Optional().Default("");
        Map(m => m.Assignee3).Name("Assignee 3").Optional().Default("");
        Map(m => m.Item2).Name("Item 2").Optional().Default("");
        Map(m => m.Item3).Name("Item 3").Optional().Default("");
        Map(m => m.Item4).Name("Item 4").Optional().Default("");
        Map(m => m.Item5).Name("Item 5").Optional().Default("");
        Map(m => m.Item6).Name("Item 6").Optional().Default("");
        Map(m => m.Item7).Name("Item 7").Optional().Default("");
        Map(m => m.Item8).Name("Item 8").Optional().Default("");
        Map(m => m.Item9).Name("Item 9").Optional().Default("");
        Map(m => m.StatusReportName).Name("Status Report Name").Default("");
        Map(m => m.StatusReportSection).Name("Status Report Section").Default("");
        Map(m => m.AddToPriorityList)
            .Name("Add To Priority List? (Mark with X)")
            .Optional().Default("");
        Map(m => m.RowNumber).Ignore();
        Map(m => m.ToPriorityList).Ignore();
    }
}

public class NullableDateTimeConverter : ITypeConverter
{
    private readonly string[] _dateFormats;

    public NullableDateTimeConverter(params string[] dateFormats)
    {
        _dateFormats = dateFormats;
    }

    public object ConvertFromString(string text, IReaderRow row, MemberMapData memberMapData)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return null; // Allow null value
        }

        foreach (var format in _dateFormats)
        {
            if (DateTime.TryParseExact(text, format, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date))
            {
                return date;
            }
        }

        throw new CsvHelperException(row.Context, $"The date '{text}' is not in the correct format(s) '{string.Join(", ", _dateFormats)}'.");
    }

    public string ConvertToString(object value, IWriterRow row, MemberMapData memberMapData)
    {
        if (value == null)
        {
            return string.Empty;
        }

        // Use the first format for output conversion
        return ((DateTime)value).ToString(_dateFormats[0], CultureInfo.InvariantCulture);
    }
}


/* Copyright © 2024 Renegade Swish, LLC */

