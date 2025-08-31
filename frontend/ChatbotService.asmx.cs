using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Services;
using Newtonsoft.Json;
using System.Security.Policy;
using QProcess.Repositories;
using System.Web.Http.Routing.Constraints;
using System.Web.Http.Results;
using System.Runtime;
using QProcess.Controls;
using static QProcess.Services.ControlService;
using System.Web.Providers.Entities;
using QProcess.Domain.Models;

namespace QProcess
{
    /// <summary>
    /// Summary description for ChatbotService
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    [System.Web.Script.Services.ScriptService]
    public class ChatbotService : WebService
    {

        [WebMethod]
        public string HelloWorld()
        {
            return "Hello World";
        }

        [WebMethod(EnableSession = true)]
        public async Task<string> TalkToBot(string request, List<object> chatHistory = null)
        {
            string currentUser = QProcess.Session.CurrentSession.QUser.FullName;
            int userId = QProcess.Session.CurrentSession.QUser.Id;
            var timeZone = QProcess.Session.CurrentSession.QUser.MyTimeZone;
            var result = await InvokeRequestResponseService(request, currentUser, userId, timeZone, chatHistory);
            return result;
        }

        public async Task<string> CreateTaskThroughBot(BotResponse request, string currentUser, int userId, UserTimeZone timeZone)
        {
            try
            {
                var newTask = new TaskFromBotRequest
                {
                    TaskName = request.TaskName,
                    Items = request.Items != null ? string.Join(",", request.Items) : "",
                    Controllers = request.Controllers != null ? string.Join(",", request.Controllers) : "",
                    Assignees = request.Assignees != null ? string.Join(",", request.Assignees) : "",
                    DueDate = !string.IsNullOrEmpty(request.DueDate) ? timeZone.GetSystemTime(DateTime.Parse(request.DueDate)).Date : DateTime.UtcNow.AddHours(24).Date,
                    LocalDueDate = !string.IsNullOrEmpty(request.DueDate) ? DateTime.Parse(request.DueDate) : DateTime.Now.AddHours(24),
                    FinalDueDate = !string.IsNullOrEmpty(request.FinalDueDate) ? DateTime.Parse(request.FinalDueDate) : DateTime.Now.AddHours(24),
                    SoftDueDate = !string.IsNullOrEmpty(request.SoftDueDate) ? DateTime.Parse(request.SoftDueDate) : DateTime.UtcNow.AddHours(19),
                    DueTime = !string.IsNullOrEmpty(request.DueDate) ? DateTime.Parse(request.DueDate).Hour : 19,
                    IsRecurring = request.IsRecurring != null ? bool.Parse(request.IsRecurring[0]) : false,
                    Location = timeZone.TimeZoneOverride ?? timeZone.LastTimeZone,
                    StatusReports = request.StatusReports != null ? request.StatusReports : new List<StatusReportRequest>(),
                    Alerts = request.Alerts != null ? request.Alerts : new List<Alert>(),
                    RecurringType = int.Parse(request.IsRecurring[2]),
                    RecurringInterval = 0,
                    BusinessDayBehavior = int.Parse(request.IsRecurring[3])
                };

                if (newTask.Controllers.Contains("Current User"))
                    newTask.Controllers = newTask.Controllers.Replace("Current User", currentUser);

                if (newTask.Assignees.Contains("Current User"))
                    newTask.Assignees = newTask.Assignees.Replace("Current User", currentUser);

                if (newTask.IsRecurring)
                {
                    newTask.RecurringType = int.Parse(request.IsRecurring[2]);
                    newTask.RecurringInterval = 1;
                    newTask.BusinessDayBehavior = int.Parse(request.IsRecurring[3]);
                    switch (request.IsRecurring[1].ToLowerInvariant().Trim())
                    {
                        case "daily":
                            newTask.RecurringSchedule = (int)RecurranceSchedule.Daily;
                            break;
                        case "weekly":
                            newTask.RecurringSchedule = (int)RecurranceSchedule.Weekly;
                            break;
                        case "monthly":
                            newTask.RecurringSchedule = (int)RecurranceSchedule.Monthly;
                            break;
                        case "yearly":
                            newTask.RecurringSchedule = (int)RecurranceSchedule.Yearly;
                            break;
                        case "quarterly":
                            newTask.RecurringSchedule = (int)RecurranceSchedule.Quarterly;
                            break;
                    }
                }

                var checklistRepo = new ChecklistRepository();
                var userRepo = new UserRepository();
                var statusRepo = new StatusReportRepository();
                var result = checklistRepo.CreateGenericChecklist(newTask);

                if (newTask.StatusReports.Count > 0)
                {
                    foreach (var report in request.StatusReports)
                    {
                        var statusReportTrimmed = report.StatusReportName.ToLower().Trim() == "current user"  || 
                            report.StatusReportName.ToLower().Trim() == "all assignees" ? currentUser : report.StatusReportName;

                        var sectionId = statusRepo.GetTaskTypeByReport(statusReportTrimmed, report.StatusReportSection).Section;
                        var statusResult =  statusRepo.AddTaskToStatusSection(int.Parse(sectionId), 0, request.TaskName);
                    }
                }

                if (newTask.Alerts.Count > 0)
                {
                    foreach (var alert in newTask.Alerts)
                    {
                        switch (alert.AlertType.ToLower().Trim())
                        {
                            case "all assigees":
                                alert.AlertTypeCode = AlertType.Reminder.ToString();
                                break;
                            case "task overdue":
                                alert.AlertTypeCode = AlertType.Overdue.ToString();
                                break;
                            case "recurring after overdue":
                                alert.AlertTypeCode = AlertType.Overdue.ToString();
                                break;
                            case "schedule edit":
                                alert.AlertTypeCode = AlertType.Schedule.ToString();
                                break;
                            case "X hours before due":
                                alert.AlertTypeCode = AlertType.Hours.ToString();
                                break;
                            case "task completed":
                                alert.AlertTypeCode = AlertType.Complete.ToString();
                                break;
                            case "assignees changed":
                                alert.AlertTypeCode = AlertType.Assignment.ToString();
                                break;
                            case "custom alert":
                                alert.AlertTypeCode = AlertType.Custom.ToString();
                                break;

                        }

                        if (alert.AlertRecipients.Contains("Current User"))
                            alert.AlertRecipients = alert.AlertRecipients.Replace("Current User", currentUser);
                        if (alert.AlertRecipients.ToLower().Contains("all assignees"))
                            alert.AlertRecipients = currentUser;

                        alert.AlertGroupID = userRepo.GetGroups().Where(g => g.GroupName == alert.AlertRecipients).FirstOrDefault().Id;
                        var alertResult = checklistRepo.AddAlert(int.Parse(result), alert.AlertTypeCode, alert.AlertDays, alert.AlertInterval, alert.AlertGroupID, alert.AlertText);
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                var result = ex.Message.ToString();
                return result;
            }
        }

        private async Task<string> InvokeRequestResponseService(string requestObject, string currentUser, int userId, UserTimeZone timeZone, List<object> chatHistory = null)
        {
            var handler = new HttpClientHandler()
            {
                ClientCertificateOptions = ClientCertificateOption.Manual,
                ServerCertificateCustomValidationCallback =
                        (httpRequestMessage, cert, cetChain, policyErrors) => { return true; }
            };
            using (var client = new HttpClient(handler))
            {

                if (chatHistory == null)
                {
                    chatHistory = new List<object>();
                    var input = new
                    {
                        question = ""
                    };
                    var output = "";

                    chatHistory.Add(new
                    {
                        inputs = input,
                        outputs = output
                    });
                }

                var body = new
                {
                    chat_history = chatHistory,
                    question = requestObject
                };
                var jsonRequest = JsonConvert.SerializeObject(body);

                string apiKey = Configuration.AppSettings.Get("BotSecret");
                if (string.IsNullOrEmpty(apiKey))
                {
                    throw new Exception("A key should be provided to invoke the endpoint");
                }
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                client.BaseAddress = new Uri("https://ai-endpoint-qchat-xprocess.eastus.inference.ml.azure.com/score");

                var content = new StringContent(jsonRequest);
                content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                content.Headers.Add("azureml-model-deployment", "ai-endpoint-qchat-xprocess-v2");

                HttpResponseMessage response = await client.PostAsync("", content).ConfigureAwait(false);
                string result = "";
                if (response.IsSuccessStatusCode)
                {
                    try
                    {
                        result = await response.Content.ReadAsStringAsync();
                        if (result.Contains("IsConfirmed"))
                        {
                                try
                                {
                                    var resultObject = JsonConvert.DeserializeObject<ChatResponse>(result);

                                    var botTask = JsonConvert.DeserializeObject<BotResponse>(resultObject.Answer);
                                    var taskNo = await CreateTaskThroughBot(botTask, currentUser, userId, timeZone);

                                    var answerObject = new
                                    {
                                        answer = $"Task successfully created with ID: {taskNo}"
                                    };
                                    var resultToJson = JsonConvert.SerializeObject(answerObject);
                                    Console.WriteLine("Result: {0}", resultToJson);

                                    return $"{resultToJson}";
                                } catch (Exception ex)
                                {
                                    var testVar = ex.Message;
                                    var answerObject = new
                                    {
                                        answer = $"I'm sorry, I had a problem creating the task. Could you either confirm or make any changes to the task?"
                                    };

                                    var resultToJson = JsonConvert.SerializeObject(answerObject);
                                    Console.WriteLine("Result: {0}", resultToJson);

                                    return $"{resultToJson}";
                                }
                        }

                        else
                        {
                            return $"{result}";
                        }

                    } catch (Exception ex)
                    {
                        var answerObject = new
                        {
                            answer = $"There was a problem creating the task: {ex.Message}"
                        };

                        var resultToJson = JsonConvert.SerializeObject(answerObject);
                        Console.WriteLine("Result: {0}", resultToJson);

                        return $"{resultToJson}";
                    }
                }
                else
                {
                    Console.WriteLine(string.Format("The request failed with status code: {0}", response.StatusCode));
                    Console.WriteLine(response.Headers.ToString());

                    string responseContent = await response.Content.ReadAsStringAsync();
                    Console.WriteLine(responseContent);
                    return responseContent;
                }
            }
        }
    }

    public class BotResponse
    {
        public List<string> Controllers { get; set; }
        public List<string> Assignees { get; set; }
        public string DueDate { get; set; }
        public string FinalDueDate { get; set; }
        public string SoftDueDate { get; set; }
        public List<StatusReportRequest> StatusReports { get; set; }
        public string TaskName { get; set; }
        public List<string> Items { get; set; }
        public string Type { get; set; }
        public string Summary { get; set; }
        public List<string> IsRecurring { get; set; }
        public List<Alert> Alerts { get; set; }
        public bool IsConfirmed { get; set; }
    }

    public class ChatResponse
    {
        public string Answer { get; set; }
    }

    public class TaskFromBotRequest
    {
        public string Controllers { get; set; }
        public string PrimaryController { get; set; }
        public string SecondaryControllers { get; set; }
        public string Assignees { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime FinalDueDate { get; set; }
        public DateTime LocalDueDate { get; set; }
        public double DueTime { get; set; }
        public DateTime SoftDueDate { get; set; }
        public bool IsRecurring { get; set; }
        public int RecurringSchedule { get; set; }
        public int RecurringType { get; set; }
        public int RecurringInterval { get; set; }
        public int BusinessDayBehavior { get; set; }
        public string Items { get; set; }
        public string TaskName { get; set; }
        public List<StatusReportRequest> StatusReports { get; set; }
        public string Location { get; set; }
        public List<Alert> Alerts { get; set; }
    }

    public enum RecurranceSchedule
    {
        Daily = 2,
        Weekly = 3,
        Monthly = 4,
        Yearly = 5,
        Quarterly = 6
    }

    public class Alert
    {
        public int ID { get; set; }
        public int ChangeID { get; set; }
        public string AlertType { get; set; }
        public string AlertTypeCode { get; set; }
        public int? AlertDays { get; set; }
        public double? AlertInterval { get; set; }
        public int AlertGroupID { get; set; }
        public string AlertText { get; set; }
        public string AlertRecipients { get; set; }
    }

    public class StatusReportRequest
    {
        public string StatusReportName { get; set; }
        public string StatusReportSection { get; set; }
    }

}
