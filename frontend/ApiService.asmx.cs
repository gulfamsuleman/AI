using QProcess.Domain.SYSTEM;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Security.Authentication;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Services;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.Globalization;
using static AuthProvider;
using QProcess.Domain.Models;
using TimeZoneConverter;

namespace QProcess
{
    /// <summary>
    /// Summary description for ApiService
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    [System.Web.Script.Services.ScriptService]
    public class ApiService : WebService
    {
        private AuthProvider auth => AuthProvider.Instance;

        private HttpRequest Request => HttpContext.Current.Request;
        private string UserHostAddress => Request.UserHostAddress;
        public ApiService()
        {
            auth.AutoRoll = false;
            auth.RateLimitEnabled = true;
            auth.AccessTokenValidMinutes = 120;

            auth.LogApiAuth = LogApiAuth;
            auth.LogAccessTokenAuth = LogaccessTokenAuth;
            auth.LogAuthRefresh = LogAuthRefresh;
            auth.GetApiKeyAuthLogs = GetApiKeyAuthLogs;
            auth.GetAccessTokenAuthLogs = GetAccessTokenAuthLogs;
            auth.GetApiKeyAuthLogs = GetRefreshAuthLogs;

            SimpleJwt.SetDefaultClaim("iss", () => ConfigurationManager.AppSettings["ApiDefaultIssuer"].ToString());
            SimpleJwt.SetDefaultClaim("aud", () => ConfigurationManager.AppSettings["ApiDefaultAudience"].ToString());
        }

        private void LogApiAuth(string apiKey, string source, string methodName, bool success)
        {
            var checklistRepo = new ChecklistRepository();
            checklistRepo.LogAccessAttempt(apiKey, "apiKey", source, methodName, success);
        }

        private void LogaccessTokenAuth(string accessToken, string source, string methodName, bool success)
        {
            var checklistRepo = new ChecklistRepository();
            checklistRepo.LogAccessAttempt(accessToken, "accessToken", source, methodName, success);
        }

        private void LogAuthRefresh(string refresh, string source, string methodName, bool success)
        {
            var checklistRepo = new ChecklistRepository();
            checklistRepo.LogAccessAttempt(refresh, "refresh", source, methodName, success);
        }

        private AuthProvider.AuthLog[] GetApiKeyAuthLogs(string apiKey, string source, int minutesSince)
        {
            var checklistRepo = new ChecklistRepository();
            return checklistRepo.GetApiKeyAuthLogs(apiKey, "apiKey", source, minutesSince).ToArray();
        }

        private AuthProvider.AuthLog[] GetAccessTokenAuthLogs(string accessToken, string source, int minutesSince)
        {
            var checklistRepo = new ChecklistRepository();
            return checklistRepo.GetApiKeyAuthLogs(accessToken, "refresh", source, minutesSince).ToArray();
        }

        private AuthProvider.AuthLog[] GetRefreshAuthLogs(string refresh, string source, int minutesSince)
        {
            var checklistRepo = new ChecklistRepository();
            return checklistRepo.GetApiKeyAuthLogs(refresh, "refresh", source, minutesSince).ToArray();
        }

        [WebMethod()]
        public string HelloWorld()
        {
            //totally unauthed
            return "Hello World";
        }

        [WebMethod]
        public AuthProvider.AuthToken Authenticate()
        {
            //Authentication header should be "accessToken <tokenValue>"            
            var authHeader = (Request.Headers["Authorization"] ?? Request.Headers["Authentication"]).Split(' ');

            auth.AssertApiKey(authHeader[1], "ApiService.Authenticate", UserHostAddress);

            var apiKey = auth.RetrieveApiKey(authHeader[1]);

            return auth.GenerateAccessToken(apiKey.ID.ToString());
        }

        [WebMethod]
        public AuthProvider.AuthToken RenewToken(string refresh)
        {
            return auth.RollAccessToken(refresh, "ApiService.RenewToken", UserHostAddress);
        }

        [WebMethod(EnableSession = true)]
        public AuthProvider.ApiKey RequestAccessToken(string requestor, string onBehalfOf, string approver, string intent, DateTime? notBefore = null)
        {
            return auth.CreateApiKey(requestor, onBehalfOf, approver, intent, notBefore);
        }

        [WebMethod(true)]
        public void CreateSigningKey(DateTime? asOf = null)
        {
            if (!Request.IsAuthenticated || !QProcess.Session.CurrentSession.QUser.IsApiAdmin)
                throw new HttpException(403, "Unauthorized");

            auth.GenerateSecretHmacKey(asOf);
        }

        [WebMethod]
        public AuthProvider.Response<bool> DoSomethingUseful(string accessToken, string theInput)
        {
            auth.AssertAccessToken(accessToken, UserHostAddress);

            //Do something incredibly useful
            Thread.Sleep(1000);
            var result = true;

            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> CreateSimpleTaskWithLocation(string accessToken, string taskName, string assignees,
            DateTime? dueDate = null, string reportSectionId = null, string controller = null, string location = null)
        {
            string result = "";
            DateTime? correctedDate = null;

            if (string.IsNullOrEmpty(location)) location = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();

            var myTz = new UserTimeZone(location, location, location);

            auth.AssertAccessToken(accessToken, UserHostAddress);

            int reportResult = 0;
            var reportRepo = new StatusReportRepository();
            var userRepo = new UserRepository();
            var user = userRepo.GetUsers().Where(u => u.FullName == assignees.Split(',')[0]).FirstOrDefault();

            if (!string.IsNullOrEmpty(reportSectionId) && !int.TryParse(reportSectionId, out reportResult))
            {
                result = $"A valid report section Id must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }
            else reportResult = reportRepo.GetDefaultReport(user.Id);


            if (dueDate != null && dueDate.Value.Hour == 0)
            {
                correctedDate = dueDate.Value.AddHours(19);
            }

            if (string.IsNullOrEmpty(taskName) || string.IsNullOrEmpty(assignees))
                result = $"Task Name and assignee(s) fields are required";

            else
            {
                var checklist = new CreateChecklistRequest()
                {
                    TaskName = taskName,
                    Assignees = assignees,
                    Controller = controller,
                    SectionId = reportResult,
                    DueDate = correctedDate.Value,
                    DueTime = correctedDate.Value.Hour,
                    Location = location
                };
                var checklistRepo = new ChecklistRepository();
                result = checklistRepo.CreateGenericChecklist(checklist);
            }

            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> CreateSimpleTask(string accessToken, string taskName, string assignees,
            DateTime? dueDate = null, string reportSectionId = null, string controller = null)
        {
            string result = "";
            DateTime? correctedDate = null;
            var location = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var myTz = new UserTimeZone(location, location, location);

            auth.AssertAccessToken(accessToken, UserHostAddress);

            int reportResult = 0;
            var reportRepo = new StatusReportRepository();
            var userRepo = new UserRepository();
            var user = userRepo.GetUsers().Where(u => u.FullName == assignees.Split(',')[0]).FirstOrDefault();

            if (!string.IsNullOrEmpty(reportSectionId) && !int.TryParse(reportSectionId, out reportResult))
            {
                result = $"A valid report section Id must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }
            else if (!string.IsNullOrEmpty(reportSectionId) && int.TryParse(reportSectionId, out reportResult))
            {
                if (reportResult == 0)
                reportResult = reportRepo.GetMySections(user.Id).FirstOrDefault().Id;
            }

            else reportResult = 0;
            if (dueDate != null && dueDate.Value.Hour == 0)
            {
                correctedDate = dueDate.Value.AddHours(19);
            }

            if (string.IsNullOrEmpty(taskName) || string.IsNullOrEmpty(assignees))
                result = $"Task Name and assignee(s) fields are required";

            else
            {
                var checklist = new CreateChecklistRequest()
                {
                    TaskName = taskName,
                    Assignees = assignees,
                    Controller = controller,
                    SectionId = reportResult,
                    DueDate = correctedDate.Value,
                    DueTime = correctedDate.Value.Hour,
                    Location = location
                };
                var checklistRepo = new ChecklistRepository();
                result = checklistRepo.CreateGenericChecklist(checklist);
            }

            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> CompleteTaskByIdOrName(string accessToken, string activeChecklistId = null, string taskName = null)
        {
            int intResult;
            string result = "";

            auth.AssertAccessToken(accessToken, UserHostAddress);

            if ((string.IsNullOrEmpty(activeChecklistId) || !int.TryParse(activeChecklistId, out intResult)) && string.IsNullOrEmpty(taskName))
            {
                result = $"A valid active checklist id OR task name must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }

            int.TryParse(activeChecklistId, out intResult);
            var checklistRepo = new ChecklistRepository();
            result = checklistRepo.CompleteTaskByIdOrName(intResult, taskName);


            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> AddTaskToStatusSection(string accessToken, string reportSectionId, string activeChecklistId = null, string taskName = null)
        {
            int intResult;
            int reportResult;
            string result = "";

            if (string.IsNullOrEmpty(reportSectionId) || !int.TryParse(reportSectionId, out reportResult))
            {
                result = $"A valid report section Id must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }

            auth.AssertAccessToken(accessToken, UserHostAddress);

            if ((string.IsNullOrEmpty(activeChecklistId) || !int.TryParse(activeChecklistId, out intResult)) && string.IsNullOrEmpty(taskName))
            {
                result = $"A valid active checklist id OR task name must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }

            int.TryParse(activeChecklistId, out intResult);

            var statusRepo = new StatusReportRepository();
            result = statusRepo.AddTaskToStatusSection(reportResult, intResult, taskName);

            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> AddCommentsToTask(string accessToken,
            string comments, string taskName = null, string activeChecklistId = null)
        {
            int intResult;
            string result = "";

            auth.AssertAccessToken(accessToken, UserHostAddress);

            if ((string.IsNullOrEmpty(activeChecklistId) || !int.TryParse(activeChecklistId, out intResult)) && string.IsNullOrEmpty(taskName))
            {
                result = $"A valid active checklist id OR task name must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }

            int.TryParse(activeChecklistId, out intResult);

            if (comments.Length == 0)
            {
                result = $"No comments to add!";
                return auth.CreateResponse(result, UserHostAddress);
            }

            var statusRepo = new StatusReportRepository();
            result = statusRepo.CreateNewComment(comments, intResult, taskName);

            return auth.CreateResponse(result, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> GetStatusOfTask(string accessToken, string activeChecklistId = null, string taskName = null)
        {
            int intResult;
            string result = "";

            auth.AssertAccessToken(accessToken, UserHostAddress);

            if ((string.IsNullOrEmpty(activeChecklistId) || !int.TryParse(activeChecklistId, out intResult)) && string.IsNullOrEmpty(taskName))
            {
                result = $"A valid active checklist id OR task name must be provided";
                return auth.CreateResponse(result, UserHostAddress);
            }

            int.TryParse(activeChecklistId, out intResult);

            var checklistRepo = new ChecklistRepository();
            result = JsonConvert.SerializeObject(checklistRepo.GetStatusOfTask(intResult, taskName));

            return auth.CreateResponse(result, UserHostAddress);
        }
        [WebMethod]
        public AuthProvider.Response<string> GetStatusofTasksByUserName(string accessToken, string userFullName)
        {

            auth.AssertAccessToken(accessToken, UserHostAddress);

            if (string.IsNullOrEmpty(userFullName))
            {
                return auth.CreateResponse($"A username must be provided.", UserHostAddress);
            }

            var checklistRepo = new ChecklistRepository();

            var serializer = new JsonSerializer();
            var listResult = JsonConvert.SerializeObject(checklistRepo.GetStatusOfAllTasksByUser(userFullName));

            return auth.CreateResponse(listResult, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> GetTasksByStatusReport(string accessToken, string reportName)
        {
            auth.AssertAccessToken(accessToken, UserHostAddress);

            if (string.IsNullOrEmpty(reportName))
            {
                return auth.CreateResponse($"A report name must be provided.", UserHostAddress);
            }

            var checklistRepo = new ChecklistRepository();

            var serializer = new JsonSerializer();

            var listResult = JsonConvert.SerializeObject(checklistRepo.GetStatusOfAllTasksByReport(reportName));

            return auth.CreateResponse(listResult, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> ChangeTaskDuedateById(string accessToken, int activeChecklistId, DateTime newDueDate)
        {
            auth.AssertAccessToken(accessToken, UserHostAddress);

            var location = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var myTz = new UserTimeZone(location, location, location);

            if (newDueDate.Hour == 0) newDueDate.AddHours(19);

            var checklistRepo = new ChecklistRepository();

            var serializer = new JsonSerializer();

            var listResult = JsonConvert.SerializeObject(checklistRepo
                .ChangeTaskDeadlineById(activeChecklistId, myTz, myTz.GetSystemTime(newDueDate)));

            return auth.CreateResponse(listResult, UserHostAddress);
        }

        [WebMethod]
        public AuthProvider.Response<string> AddItemsToTask(string accessToken, int activeChecklistId, string itemText, string itemUrl = null, int itemType = 1)
        {
            auth.AssertAccessToken(accessToken, UserHostAddress);

            var location = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var myTz = new UserTimeZone(location, location, location);

            var checklistRepo = new ChecklistRepository();

            var serializer = new JsonSerializer();
            var listResult = JsonConvert.SerializeObject(checklistRepo
                .AddChecklistItemThroughApi(activeChecklistId, itemText, itemUrl, itemType));

            return auth.CreateResponse(listResult, UserHostAddress);
        }
    }
}

/// <summary>
/// Provides a simple security model based on persistent API keys and expiring refreshable access tokens.
/// </summary>
public class AuthProvider
{
    #region Defaults/Backing fields
    private readonly int DEFAULT_APIKEY_SIZEBYTES = 256;
    private readonly int DEFAULT_APIKEY_EXPIREDAYS = 365;
    private readonly int DEFAULT_ACCESSTOKEN_SIZEBYTES = 64;
    private readonly int DEFAULT_ACCESSTOKEN_VALIDMINUTES = 30;
    private readonly int DEFAULT_REFRESH_SIZEBYTES = 64;
    private readonly int DEFAULT_REFRESH_VALIDMINUTES = 60;

    private readonly int DEFAULT_RATELIMIT_INTERVALMINUTES = 3;
    private readonly int DEFAULT_RATELIMIT_MAXAUTHSUCCESS = 10;
    private readonly int DEFAULT_RATELIMIT_MAXAUTHFAILURE = 3;
    private readonly int DEFAULT_RATELIMIT_MAXCALLS = 30;
    private readonly int DEFAULT_RATELIMIT_COOLDOWNMINUTES = 5;

    private int _apiKeySize;
    private int _apiKeyExpireDays;
    private int _accessTokenSize;
    private int _accessTokenValidMinutes;
    private int _refreshTokenSize;
    private int _refreshValidMinutes;

    private int _rateLimitIntervalMinutes;
    private int _rateLimitMaxAuthSuccess;
    private int _rateLimitMaxAuthFailure;
    private int _rateLimitMaxTotalCalls;
    private int _rateLimitCooldownMinutes;
    #endregion

    public delegate void LogAuthToken(string token, string source, string methodName, bool success);

    public LogAuthToken LogApiAuth { get; set; }
    public LogAuthToken LogAccessTokenAuth { get; set; }
    public LogAuthToken LogAuthRefresh { get; set; }

    public delegate AuthLog[] AuthLogGetter(string token, string source, int sinceMinutesAgo);

    public AuthLogGetter GetApiKeyAuthLogs { get; set; }
    public AuthLogGetter GetAccessTokenAuthLogs { get; set; }
    public AuthLogGetter GetRefreshAuthLogs { get; set; }

    #region Properties

    /// <summary>
    /// Gets or sets a value indicating whether access tokens are automatically refreshed 
    /// when they approach their expiration timestamp. If true, the instance will automatically
    /// "roll" the token over to new values and extend the expiration time as part of creating a response.
    /// </summary>
    public bool AutoRoll { get; set; }

    /// <summary>
    /// Gets or sets the desired API key entropy size in bytes. Keys are Base64-encoded and will be represented as a 
    /// string with a length 4/3 the size specified here.
    /// </summary>
    public int ApiKeySize
    {
        get { return _apiKeySize; }
        set { _apiKeySize = (value <= 0 ? DEFAULT_APIKEY_SIZEBYTES : value); }
    }
    /// <summary>
    /// Gets or sets the number of days from the time of issue that an API key will remain valid. 
    /// Set to zero or a negative value to restore the system default of 365 days.
    /// </summary>
    public int ApiKeyExpireDays
    {
        get { return _apiKeyExpireDays; }
        set { _apiKeyExpireDays = (value <= 0 ? DEFAULT_APIKEY_EXPIREDAYS : value); }
    }
    /// <summary>
    /// Gets or sets the desired access token entropy size in bytes. Tokens are Base64-encoded and 
    /// will be represented as a string with a length 4/3 the size specified here.
    /// </summary>
    public int AccessTokenSize
    {
        get { return _accessTokenSize; }
        set { _accessTokenSize = (value <= 0 ? DEFAULT_ACCESSTOKEN_SIZEBYTES : value); }
    }
    /// <summary>
    /// Gets or sets the number of minutes from the time of issue that a access token will remain valid.
    /// Set to zero or a negative value to restore the system default of 30 minutes.
    /// </summary>
    public int AccessTokenValidMinutes
    {
        get { return _accessTokenValidMinutes; }
        set { _accessTokenValidMinutes = (value <= 0 ? DEFAULT_ACCESSTOKEN_VALIDMINUTES : value); }
    }
    /// <summary>
    /// Gets or sets the desired refresh token entropy size in bytes. Tokens are Base64-encoded and 
    /// will be represented as a string with a length 4/3 the size specified here. 
    /// </summary>
    public int RefreshTokenSize
    {
        get { return _refreshTokenSize; }
        set { _refreshTokenSize = (value <= 0 ? DEFAULT_REFRESH_SIZEBYTES : value); }
    }
    /// <summary>
    /// Gets or sets the number of minutes from the time of issue that a refresh token will remain valid.
    /// Set to zero or a negative value to restore the system default of 60 minutes.
    /// </summary>
    public int RefreshTokenValidMinutes
    {
        get { return _refreshValidMinutes; }
        set { _refreshValidMinutes = (value <= 0 ? DEFAULT_REFRESH_VALIDMINUTES : value); }
    }

    /// <summary>
    /// Gets or sets a value determining whether request rate limiting is enabled.
    /// </summary>
    public bool RateLimitEnabled { get; set; }
    /// <summary>
    /// Gets or sets a value determining how many minutes in the past to look for rate-limited events.
    /// </summary>
    public int RateLimitIntervalMinutes
    {
        get { return _rateLimitIntervalMinutes; }
        set { _rateLimitIntervalMinutes = (value <= 0 ? DEFAULT_RATELIMIT_INTERVALMINUTES : value); }
    }
    /// <summary>
    /// Gets or sets a value determining the maximum number of successful authentication requests to 
    /// allow from a single source before triggeriung a cooldown. 
    /// </summary>
    public int RateLimitMaxAuthSuccess
    {
        get { return _rateLimitMaxAuthSuccess; }
        set
        {
            _rateLimitMaxAuthSuccess = (value <= 0 ? DEFAULT_RATELIMIT_MAXAUTHSUCCESS : value);
        }
    }
    public int RateLimitMaxAuthFailure
    {
        get { return _rateLimitMaxAuthFailure; }
        set
        {
            _rateLimitMaxAuthFailure = (value <= 0 ? DEFAULT_RATELIMIT_MAXAUTHFAILURE : value);
        }
    }
    public int RateLimitMaxTotalCalls
    {
        get { return _rateLimitMaxTotalCalls; }
        set
        {
            _rateLimitMaxTotalCalls = (value <= 0 ? DEFAULT_RATELIMIT_MAXCALLS : value);
        }
    }
    public int RateLimitCooldownMinutes
    {
        get { return _rateLimitCooldownMinutes; }
        set
        {
            _rateLimitCooldownMinutes = (value <= 0 ? DEFAULT_RATELIMIT_COOLDOWNMINUTES : value);
        }
    }

    #endregion

    #region Sub-Classes

    /// <summary>
    /// Represents the information for an API key.
    /// </summary>
    public class ApiKey
    {
        /// <summary>
        /// The "non-secret" unique ID of the key, for referential purposes.
        /// </summary>
        public Guid ID { get; set; }
        /// <summary>
        /// The secret key possessed by the client.
        /// </summary>
        public string Key { get; set; }
        /// <summary>
        /// The date and time the key was issued.
        /// </summary>
        public DateTime Issued { get; set; }
        /// <summary>
        /// The earliest date and time the key is valid (for pre-generating "pads" of multiple keys).
        /// </summary>
        public DateTime NotBefore { get; set; }
        /// <summary>
        /// The date and time the key will expire.
        /// </summary>
        public DateTime Expires { get; set; }
        /// <summary>
        /// The name of the actual person who requested creation of this key.
        /// </summary>
        public string Requestor { get; set; }
        /// <summary>
        /// The name of the business entity on whose behalf the requestor is acting.
        /// </summary>
        public string OnBehalfOf { get; set; }
        /// <summary>
        /// The intended purpose/use of the key (i.e. what system is expected to present it).
        /// </summary>
        public string Intent { get; set; }
        /// <summary>
        /// The name of the actual person who approved creation of this key.
        /// </summary>
        public string Approver { get; set; }
        /// <summary>
        /// Indicates whether this API key has been revoked (if so, do not validate)
        /// </summary>
        public bool IsRevoked { get; internal set; }
    }

    /// <summary>
    /// Represents the information in an authorization token.
    /// </summary>
    public class AuthToken
    {
        /// <summary>
        /// The access token - to be passed in to most authenticated requests.
        /// </summary>
        public string AccessToken { get; set; }
        /// <summary>
        /// The date and time the token will expire.
        /// </summary>
        public DateTime Expires { get; set; }
        /// <summary>
        /// The refresh token - to be used to generate a replacement access token when the auth token expires.
        /// </summary>
        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string RefreshToken { get; set; }
        /// <summary>
        /// The data and time the refresh token can no longer be used to refresh the auth token.
        /// </summary>
        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public DateTime RefreshExpires { get; set; }
    }

    /// <summary>
    /// Represents one row in the audit log for authentication attempts.
    /// </summary>
    public class AuthLog
    {
        /// <summary>
        /// The type of token being validated.
        /// </summary>
        public string Type { get; set; }
        /// <summary>
        /// The token passed in for validation.
        /// </summary>
        public string Token { get; set; }
        /// <summary>
        /// The source IP address of the request.
        /// </summary>
        public string Source { get; set; }
        /// <summary>
        /// The method triggering the authentication request.
        /// </summary>
        public string Method { get; set; }
        /// <summary>
        /// Whether the authentication attempt was successful.
        /// </summary>
        public bool Success { get; set; }
        /// <summary>
        /// The date and time of the authentication request.
        /// </summary>
        public DateTime Timestamp { get; set; }
    }

    /// <summary>
    /// Represents a "void" service method response, containing the metadata of the request
    /// </summary>
    public class Response
    {
        public string MethodName { get; set; }
        public string Source { get; set; }

        public Response() { }
        public Response(string source, string methodName)
        {
            MethodName = methodName;
            Source = source;
        }
    }

    /// <summary>
    /// Represents a service method response with a strong return type, containing the return value of the method 
    /// and the metadata of the request.
    /// </summary>
    /// <typeparam name="T">The type of the expected return value from the service method.</typeparam>
    public class Response<T> : Response
    {
        public T Value { get; set; }

        public Response() : base() { }
        public Response(string source, string methodName, T value)
            : base(source, methodName)
        {
            Value = value;
        }
    }

    #endregion

    #region Singleton

    static AuthProvider() { }
    private AuthProvider()
    {
        AutoRoll = false;
        _apiKeySize = DEFAULT_APIKEY_SIZEBYTES;
        _apiKeyExpireDays = DEFAULT_APIKEY_EXPIREDAYS;
        _accessTokenSize = DEFAULT_ACCESSTOKEN_SIZEBYTES;
        _accessTokenValidMinutes = DEFAULT_ACCESSTOKEN_VALIDMINUTES;
        _refreshTokenSize = DEFAULT_REFRESH_SIZEBYTES;
        _refreshValidMinutes = DEFAULT_REFRESH_VALIDMINUTES;
    }
    private static readonly Lazy<AuthProvider> _instance = new Lazy<AuthProvider>(() => new AuthProvider());
    /// <summary>
    /// Gets the singleton AuthProvider instance.
    /// </summary>
    public static AuthProvider Instance { get { return _instance.Value; } }
    #endregion

    #region Private Helpers
    /// <summary>
    /// Produces a string containing the Base64 encoded representation of the desired number of nonzero random bytes.
    /// </summary>
    /// <param name="entropyBytes">The number of bytes of entropy to generate. The string produced will be 4/3 
    /// characters longer than this number (rounded up to the nearest multiple of 4)</param>
    /// <returns>A Base-64 string representation of cryptographically-random nonzero bytes.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown if entropyBytes is zero or negative.</exception>
    private string GenerateCryptoString(int entropyBytes)
    {
        if (entropyBytes < 0) throw new ArgumentOutOfRangeException("entropyBytes", "Argument must be a positive integer.");

        using (var rng = RandomNumberGenerator.Create())
        {
            var bytes = new byte[entropyBytes];
            rng.GetNonZeroBytes(bytes);
            return Convert.ToBase64String(bytes, 0, bytes.Length);
        }
    }

    /// <summary>
    /// Retrieves a secret key to use in signing JWT tokens with an HMAC algorithm.
    /// </summary>
    /// <param name="asOf">Optional; if specified, retrieves the secret key that was used for key signing as of the 
    /// specified date. If not specified, the currently-valid signing key is retrieved.</param>
    /// <returns>A string representing the secret HMAC key.</returns>
    private string GetSecretHmacKey(DateTime? asOf = null)
    {
        return new ChecklistRepository().GetSigningKeyModel(asOf ?? DateTime.UtcNow);
    }

    /// <summary>
    /// Created and stores a secret key to use in signing JWT tokens with an HMAC algorithm.
    /// </summary>    
    public void GenerateSecretHmacKey(DateTime? asOf = null)
    {
        //TODO: Implement properly (store in DB with versioning system)
        var repo = new ChecklistRepository();
        using (var rnd = RandomNumberGenerator.Create())
        {
            //TODO: extend to allow keys for different algs
            var bytes = new byte[32];
            rnd.GetNonZeroBytes(bytes);
            var keyString = BitConverter.ToString(bytes).Replace("-", "");
            repo.PersistSigningKeyModel(keyString, asOf ?? DateTime.UtcNow);
        }

    }
    #endregion

    #region Public Interface
    /// <summary>
    /// Creates and persists an API key. This key is used for initial authentication of a remote actor.
    /// </summary>
    /// <param name="intent">The intended system, remote actor or other purpose for which the key is being generated.</param>
    /// <returns>A string representing the key expected when authenticating a communication channel with the API.</returns>
    public ApiKey CreateApiKey(string requestor, string onBehalfOf, string approver, string intent, DateTime? notBefore = null)
    {
        //This is a simple "random noise key"
        var apiKeyString = GenerateCryptoString(ApiKeySize);

        var utcNow = DateTime.UtcNow;

        var apiKey = new ApiKey()
        {
            ID = Guid.NewGuid(),
            Key = apiKeyString,
            Issued = utcNow,
            NotBefore = notBefore ?? utcNow,
            Expires = utcNow.AddDays(ApiKeyExpireDays),

            Requestor = requestor,
            Approver = approver,
            OnBehalfOf = onBehalfOf,
            Intent = intent,
            IsRevoked = false
        };

        var checklistRepo = new ChecklistRepository();
        checklistRepo.PersistAPIKey(apiKey);

        return apiKey;
    }

    public ApiKey RetrieveApiKey(Guid guid)
    {
        return new ChecklistRepository().GetApiKey(guid);
    }

    public ApiKey RetrieveApiKey(string apiKey)
    {
        return new ChecklistRepository().GetApiKey(apiKey);
    }

    /// <summary>
    /// Validates an API key, authenticating its accessToken as a valid API user.
    /// </summary>
    /// <param name="key">the API key to validate.</param>
    /// <returns>A Boolean value indicating whether the API key is valid.</returns>
    public bool VerifyApiKey(string key, string source, [CallerMemberName] string methodName = null)
    {
        try { AssertApiKey(key, source, methodName); return true; } catch { return false; }
    }

    /// <summary>
    /// Tests assertion that an API key is valid, throwing an exception if not.
    /// </summary>
    /// <param name="key">The API key to validate</param>
    public void AssertApiKey(string key, string source, [CallerMemberName] string methodName = null)
    {
        var success = true;
        try
        {
            var apiKeyObj = new ChecklistRepository().GetApiKey(key);

            if (apiKeyObj == null) throw new HttpException(401, "API key invalid");
            if (apiKeyObj.Issued > DateTime.UtcNow) throw new HttpException(401, "API key invalid");
            if (apiKeyObj.IsRevoked) throw new HttpException(401, "API key invalid");
            if (apiKeyObj.Expires < DateTime.UtcNow) throw new HttpException(401, "API key expired");
        }
        catch { success = false; throw; }
        finally
        {
            try
            {
                //rate limiting
                if (RateLimitEnabled && GetApiKeyAuthLogs != null)
                {
                    AuthLog[] auths = GetApiKeyAuthLogs(key, source, RateLimitIntervalMinutes);

                    if ((success && auths.Where(a => a.Success).Count() > RateLimitMaxAuthSuccess)
                        || (!success && auths.Where(a => !a.Success).Count() > RateLimitMaxAuthFailure))
                        throw new HttpException(429, $"Too many requests; try again after {DateTime.UtcNow.AddMinutes(RateLimitCooldownMinutes):u}");
                }
            }
            finally
            {
                if (LogApiAuth != null)
                    LogApiAuth(key, source, methodName, success);
            }
        }
    }

    /// <summary>
    /// Creates and returns an authentication token to identify an authenticated user in future API requests.
    /// </summary>    
    /// <returns>An AuthToken instance containing a accessToken and refresh token, and metadata about issuance and expiration.</returns>
    public AuthToken GenerateAccessToken(string subject)
    {
        var accessClaims = new Dictionary<string, string>();
        var tokenExp = DateTime.UtcNow.AddMinutes(AccessTokenValidMinutes);
        SimpleJwt.AddRegisteredClaims(accessClaims, sub: subject, exp: tokenExp);
        var refreshClaims = new Dictionary<string, string>();
        var refreshExp = DateTime.UtcNow.AddMinutes(RefreshTokenValidMinutes);
        SimpleJwt.AddRegisteredClaims(refreshClaims, sub: subject, exp: refreshExp);
        var key = GetSecretHmacKey();
        var token = new AuthToken
        {
            AccessToken = SimpleJwt.MakeString(accessClaims, key),
            Expires = tokenExp,
            RefreshToken = SimpleJwt.MakeString(refreshClaims, key),
            RefreshExpires = refreshExp,
        };

        return token;
    }

    /// <summary>
    /// Refreshes an authentication token, producing a new authentication token to be used in future API requests.
    /// </summary>
    /// <param name="refreshToken">The refresh token string of the authentication token to renew.</param>
    /// <returns>An AuthToken instance containing a accessToken and refresh token, and metadata about issuance and expiration.</returns>
    /// <exception cref="HttpException">Thrown when there is any error in validating the existing token. The token must exist 
    /// and the refresh request must be made prior to the token's RefreshExpires timestamp value.</exception>
    public AuthToken RollAccessToken(string refreshToken, string source, [CallerMemberName] string methodName = null)
    {
        var success = true;
        AuthLog[] auths = null;

        try
        {
            if (RateLimitEnabled && GetRefreshAuthLogs != null)
            {
                auths = GetRefreshAuthLogs(refreshToken, source, RateLimitIntervalMinutes);

                //Splitting success and failure cases; rolling the key and *then* erroring would lock the user out completely.
                //Using the auth limit for initial auth; they shouldn't be rolling that many times either.
                if (auths.Where(a => a.Success).Count() > RateLimitMaxAuthSuccess)
                    throw new HttpException(429, $"Too many requests; try again after {DateTime.UtcNow.AddMinutes(RateLimitCooldownMinutes):u}");
            }

            var tokenObj = SimpleJwt.FromString(refreshToken);
            var utcNow = DateTime.UtcNow;

            if (tokenObj == null)
                throw new HttpException(401, "access token invalid");
            if (DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["exp"])) < utcNow)
                throw new HttpException(401, "access token expired");
            if (DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["nbf"])) > utcNow)
                throw new HttpException(401, "access token invalid");
            if (tokenObj.Payload.Claims["aud"] != ConfigurationManager.AppSettings["ApiDefaultAudience"])
                throw new HttpException(401, "access token invalid");

            var sub = new ChecklistRepository().GetApiKey(Guid.Parse(tokenObj.Payload.Claims["sub"]));
            if (sub == null) throw new HttpException(401, "access token invalid");

            var iat = DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["iat"]));
            if (iat > utcNow) throw new HttpException(401, "access token invalid");

            var key = GetSecretHmacKey(iat);

            if (tokenObj.Verify(key))
                throw new HttpException(401, "access token invalid");

            return GenerateAccessToken(sub.ID.ToString());
        }
        catch
        {
            success = false;

            if (RateLimitEnabled && GetRefreshAuthLogs != null)
            {
                if (auths != null && auths.Where(a => !a.Success).Count() > RateLimitMaxAuthFailure)
                    throw new HttpException(429, $"Too many requests; try again after {DateTime.UtcNow.AddMinutes(RateLimitCooldownMinutes):u}");
            }

            throw;
        }
        finally
        {
            if (LogAuthRefresh != null)
                LogAuthRefresh(refreshToken, source, methodName, success);
        }
    }

    /// <summary>
    /// Determines whether the provided access token string is valid.
    /// </summary>
    /// <param name="accessToken">The access token string to verify.</param>
    /// <returns>A Boolean value indicating validity; true if the auth token 
    /// identified by the accessToken string exists and has not expired, otherwise false.</returns>
    public bool VerifyAccessToken(string accessToken, string source, [CallerMemberName] string methodName = null)
    {
        try { AssertAccessToken(accessToken, source, methodName); return true; } catch { return false; }
    }

    /// <summary>
    /// Asserts that the provided access token is valid.
    /// </summary>
    /// <param name="accessToken">The access token string to verify.</param>
    /// <exception cref="HttpException">Thrown on any failure to validate the access token; the auth token must 
    /// exist and must not have expired, otherwise this exception is thrown.</exception>
    public void AssertAccessToken(string accessToken, string source, [CallerMemberName] string methodName = null)
    {
        var success = true;
        try
        {
            //rate limiting - success or failure, don't let them try too many times.
            if (RateLimitEnabled && GetAccessTokenAuthLogs != null)
            {
                AuthLog[] auths = GetAccessTokenAuthLogs(accessToken, source, RateLimitIntervalMinutes);

                if (auths.Length > RateLimitMaxTotalCalls)
                    throw new HttpException(429, $"Too many requests; try again after {DateTime.UtcNow.AddMinutes(RateLimitCooldownMinutes):u}");
            }

            var tokenObj = SimpleJwt.FromString(accessToken);
            var utcNow = DateTime.UtcNow;

            if (tokenObj == null)
                throw new HttpException(401, "access token invalid");
            if (DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["exp"])) < utcNow)
                throw new HttpException(401, "access token expired");
            if (DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["nbf"])) > utcNow)
                throw new HttpException(401, "access token invalid");
            if (tokenObj.Payload.Claims["aud"] != ConfigurationManager.AppSettings["ApiDefaultAudience"])
                throw new HttpException(401, "access token invalid");

            var iat = DateTime.FromFileTimeUtc(long.Parse(tokenObj.Payload.Claims["iat"]));
            if (iat > utcNow) throw new HttpException(401, "access token invalid");

            var key = GetSecretHmacKey(iat);

            if (!tokenObj.Verify(key))
                throw new HttpException(401, "access token invalid");
        }
        catch
        {
            success = false;
            throw;
        }
        finally
        {
            if (LogAccessTokenAuth != null)
                LogAccessTokenAuth(accessToken, source, methodName, success);
        }
    }

    /// <summary>
    /// Helper method to create a Response instance and desired return value.
    /// </summary>
    /// <typeparam name="T">The type of the result value or instance.</typeparam>
    /// <param name="accessToken">The access token used for the API call.</param>
    /// <param name="result">The desired value or object instance to return from the call.</param>
    /// <returns>A Response instance to return to the caller from the API method.</returns>
    public Response<T> CreateResponse<T>(T result, string source, [CallerMemberName] string methodName = null)
    {
        var response = new Response<T>(source, methodName, result);
        return response;
    }
    #endregion
}

/// <summary>
/// Lightweight self-contained class for JWT creation, parsing and verification. 
/// Credit to Do Tran of Saigon Technology's blog, 2023-Jun-15 for the bulk of the internal logic. 
/// https://saigontechnology.com/blog/json-web-token-using-c
/// </summary>
public class SimpleJwt
{
    #region Nested Classes
    /// <summary>
    /// Represents the header of a JWT token. Contains two string fields, the algorithm and the token type.
    /// </summary>
    public class JwtHeader
    {
        public string Alg { get; set; }
        public string Typ { get; set; }
    }

    /// <summary>
    /// Represents the payload of a JWT. Contains a Dictionary of claim names and values.
    /// </summary>
    public class JwtPayload
    {
        public Dictionary<string, string> Claims { get; set; }
    }

    /// <summary>
    /// A helper class implementing a Strategy pattern of signing and verification algorithms for JWT tokens.
    /// </summary>
    public static class SigningAlgorithms
    {
        /// <summary>
        /// Represents a signing algorithm.
        /// </summary>
        /// <param name="plainText">The data from which to generate the signature.</param>
        /// <param name="key">The secret key used to generate the signature.</param>
        /// <returns>A string containing the digest of the plaintext, signed with the key.</returns>
        public delegate string SigningAlgorithm(string plainText, string key);
        /// <summary>
        /// Represents a signature verification algorithm.
        /// </summary>
        /// <param name="plainText">A string containing the data to be verified against the signature.</param>
        /// <param name="signature">The string representing the signed digest against which to verify the plaintext.</param>
        /// <param name="key">The key required for verification.</param>
        /// <returns>A Boolean value indicating whether the signature is correct for the plaintext given the key.</returns>
        public delegate bool VerificationAlgorithm(string plainText, string signature, string key);

        private static readonly Dictionary<string, SigningAlgorithm> _signingAlgorithms
            = new Dictionary<string, SigningAlgorithm>
        {
                { "HS256", SignHmacSha256 }
        };

        private static readonly Dictionary<string, VerificationAlgorithm> _verificationAlgorithms
            = new Dictionary<string, VerificationAlgorithm>
        {
                { "HS256", (p,s,k)=> s == SignHmacSha256(p,k) }
        };

        /// <summary>
        /// Adds a new custom signature algorithm to the collection, making it available for use to sign JWT tokens.
        /// </summary>
        /// <param name="name">A string representing the algorithm name.</param>
        /// <param name="signWith">A function conforming to the SigningAlgorithm delegate definition, used to create signatures.</param>
        /// <param name="verifyWith">A function conforming to the VerificationAlgorithm delegate definition, used to verify signatures. 
        /// Optional; if not specified, a default implementation based on the signing algorithm will be used for verification.</param>
        public static void Add(string name, SigningAlgorithm signWith, VerificationAlgorithm verifyWith = null)
        {
            _signingAlgorithms.Add(name, signWith);
            if (verifyWith != null) _verificationAlgorithms.Add(name, verifyWith);
            //Default scheme - re-sign input and compare to sig (assumes symmetric-key)
            else _verificationAlgorithms.Add(name, (p, s, k) => signWith(p, k) == s);
        }
        public static void Has(string name) => _signingAlgorithms.ContainsKey(name);
        public static SigningAlgorithm GetSigningAlgorithm(string name) => _signingAlgorithms[name];
        public static VerificationAlgorithm GetVerificationAlgorithm(string name) => _verificationAlgorithms[name];

        #region Built-Ins
        private static string SignHmacSha256(string plainText, string key)
        {
            using (var hmacSha256Alg = new HMACSHA256(Encoding.UTF8.GetBytes(key)))
            {
                var digest = hmacSha256Alg.ComputeHash(Encoding.UTF8.GetBytes(plainText));

                return Base64UrlEncode(digest);
            }
        }
        #endregion
    }
    #endregion

    /// <summary>
    /// The header section of the JWT.
    /// </summary>
    public JwtHeader Header { get; set; }
    /// <summary>
    /// The payload section of the JWT.
    /// </summary>
    public JwtPayload Payload { get; set; }
    /// <summary>
    /// The signature (if any) of the JWT.
    /// </summary>
    public string Signature { get; set; }

    #region Static Interface

    static SimpleJwt()
    {
        DefaultClaims = new Dictionary<string, Func<string>>()
            {
                {"iss", ()=>"QProcessAPI"},
                {"sub", ()=>""},
                {"aud", ()=>SerializeObject(new [] {"QProcessAPI"})},
                {"exp", ()=>DateTime.UtcNow.AddMinutes(60).ToFileTimeUtc().ToString()},
                {"nbf", ()=>DateTime.UtcNow.ToFileTimeUtc().ToString()},
                {"iat", ()=>DateTime.UtcNow.ToFileTimeUtc().ToString()},
                {"jti", ()=>CryptoGuid.NewV7Guid().ToString()},
            };
    }

    /// <summary>
    /// Creates a SimpleJwt object instance from an encoded JWT string representation.
    /// </summary>
    /// <param name="tokenString">A base64-encoded JWT token string.</param>
    /// <returns></returns>
    public static SimpleJwt FromString(string tokenString)
    {
        var parts = tokenString.Split('.');

        return new SimpleJwt
        {
            Header = DeserializeObject<JwtHeader>(Base64UrlDecode(parts[0])),
            Payload = DeserializeObject<JwtPayload>(Base64UrlDecode(parts[1])),
            Signature = parts[2]
        };
    }

    /// <summary>
    /// Creates a SimpleJwt object instance from a Dictionary of claims information.
    /// </summary>
    /// <param name="claims">A dictionary of name-value pairs representing the claims to encode in the token.</param>
    /// <param name="key">The signing key to use. Optional, but if not specified the JWT will not be signed, 
    /// and so will not be verifiable once encoded to a string.</param>
    /// <param name="alg">The algorithm name to use for token signing. Defaults to "HS256" (HMAC-SHA256).</param>
    /// <returns>A SimpleJwt instance representing the provided claims, optionally signed using the provided key and algorithm.</returns>
    public static SimpleJwt FromClaims(Dictionary<string, string> claims, string key = null, string alg = "HS256")
    {

        if (alg == null) alg = "HS256";

        var jwt = new SimpleJwt
        {
            Header = new JwtHeader { Alg = alg, Typ = "JWT" },
            Payload = new JwtPayload { Claims = claims },
        };

        if (!String.IsNullOrWhiteSpace(key))
            jwt.Sign(key);

        return jwt;
    }

    /// <summary>
    /// Creates an encoded string representation of a JWT token from a Dictionary of claims information.
    /// </summary>
    /// <param name="claims">A dictionary of name-value pairs representing the claims to encode in the token.</param>
    /// <param name="key">The signing key to use. Optional, but if not specified the JWT will not be signed, 
    /// and so will not be verifiable.</param>
    /// <param name="alg">The algorithm name to use for token signing. Defaults to "HS256" (HMAC-SHA256).</param>
    /// <returns>A string representing the provided claims, Base64-encoded and optionally signed using the provided key and algorithm.</returns>
    public static string MakeString(Dictionary<string, string> claims, string key = null, string alg = "HS256")
    {
        return FromClaims(claims, key, alg).ToString();
    }

    private static Dictionary<string, Func<string>> DefaultClaims { get; set; }

    public static void SetDefaultClaim(string name, Func<string> valueFunc) => DefaultClaims[name] = valueFunc;

    public static void AddRegisteredClaims(Dictionary<string, string> claims,
        string iss = null, string sub = null, string[] aud = null,
        DateTime? exp = null, DateTime? nbf = null, DateTime? iat = null, Guid? jti = null)
    {
        claims["iss"] = iss ?? DefaultClaims?["iss"]() ?? "QProcessAPI";
        claims["sub"] = sub ?? DefaultClaims?["sub"]() ?? "";
        claims["aud"] = aud != null
            ? SerializeObject(aud)
            : DefaultClaims?["aud"]()
                ?? SerializeObject(new[] { "QProcessAPI" });
        claims["exp"] = exp?.ToFileTimeUtc().ToString()
            ?? DefaultClaims?["exp"]()
            ?? DateTime.UtcNow.AddMinutes(60).ToFileTimeUtc().ToString();
        claims["nbf"] = nbf?.ToFileTimeUtc().ToString()
            ?? DefaultClaims?["nbf"]()
            ?? DateTime.UtcNow.AddMinutes(60).ToFileTimeUtc().ToString();
        claims["iat"] = iat?.ToFileTimeUtc().ToString()
            ?? DefaultClaims?["iat"]()
            ?? DateTime.UtcNow.AddMinutes(60).ToFileTimeUtc().ToString();
        claims["jti"] = jti?.ToString()
            ?? DefaultClaims?["jti"]()
            ?? Guid.NewGuid().ToString();
    }
    #endregion

    #region Instance Interface
    /// <summary>
    /// Creates an encoded string representation of a JWT token from the current instance.
    /// </summary>
    public override string ToString()
    {
        var b64Header = Base64UrlEncode(SerializeObject(Header));
        var b64Payload = Base64UrlEncode(SerializeObject(Payload));
        var signature = String.IsNullOrWhiteSpace(Signature)
            ? Base64UrlEncode("((--UNSIGNED DO NOT TRUST--))")
            : Signature;
        return $"{b64Header}.{b64Payload}.{signature}";
    }

    /// <summary>
    /// Populates the Signature property of the current instance with a signature generated 
    /// using the algorithm specified in the Header.Alg property, and the provided key.
    /// </summary>
    /// <param name="key">A string representing the cryptographic key required for the signature algorithm.</param>
    public void Sign(string key)
    {
        var b64Header = Base64UrlEncode(SerializeObject(Header));
        var b64Payload = Base64UrlEncode(SerializeObject(Payload));
        var plainText = $"{b64Header}.{b64Payload}";

        Signature = SigningAlgorithms.GetSigningAlgorithm(Header.Alg)(plainText, key);
    }

    /// <summary>
    /// Verifies the data in the current instance is consistent with the Signature digest, using the provided key.
    /// </summary>
    /// <param name="key">The required key for verification of the signature algorithm. 
    /// For symmetric-key methods i.e. HMACs, this should be the signing key. For public-key methods 
    /// like DSA, this should be the public key of the keypair.</param>
    /// <returns>A Boolean indicating whether the instance's data matches the signature.</returns>
    public bool Verify(string key)
    {
        var b64Header = Base64UrlEncode(SerializeObject(Header));
        var b64Payload = Base64UrlEncode(SerializeObject(Payload));
        var plainText = $"{b64Header}.{b64Payload}";

        var alg = SigningAlgorithms.GetVerificationAlgorithm(Header.Alg);

        try
        {
            return alg(plainText, Signature, key);
        }
        catch { return false; }
    }

    /// <summary>
    /// Verifies the data in the current instance is consistent with the Signature digest, using the provided key.
    /// </summary>
    /// <param name="key">The required key for verification of the signature algorithm. 
    /// For symmetric-key methods i.e. HMACs, this should be the signing key. For public-key methods 
    /// like DSA, this should be the public key of the keypair.</param>
    /// <exception cref="InvalidCredentialException">Thrown on any failure to verify the signature.</exception>
    public void Assert(string key)
    {
        if (!Verify(key)) throw new InvalidCredentialException("JWT token failed signature validation.");
    }
    #endregion

    #region Helpers
    /// <summary>
    /// Encodes the provided string using Base-64, removing padding and replacing characters that are not URL-safe.
    /// </summary>
    /// <param name="theString">The string to encode.</param>
    /// <returns>A Base64-encoded string representation of the input string, without '=' padding and with any '+' 
    /// and '/' characters substituted.</returns>
    private static string Base64UrlEncode(string theString)
    {
        var bytes = Encoding.UTF8.GetBytes(theString);
        return Base64UrlEncode(bytes);
    }
    /// <summary>
    /// Encodes the provided byte array using Base-64, removing padding and replacing characters that are not URL-safe.
    /// </summary>
    /// <param name="theBytes">The byte array to encode.</param>
    /// <returns>A Base64-encoded string representation of the input bytes, without '=' padding and with any '+' 
    /// and '/' characters substituted.</returns>
    private static string Base64UrlEncode(byte[] theBytes)
    {
        var base64 = Convert.ToBase64String(theBytes);
        var base64Url = base64.TrimEnd('=').Replace("+", "-").Replace('/', '_');
        return base64Url;
    }

    /// <summary>
    /// Decodes a Base46-encoded, URL-safe string into a UTF-8 string of the original data.
    /// </summary>
    /// <param name="theString">A Base64-encoded string. It is expected that the string will not be '='-padded 
    /// and that '+' and '/' characters of the standard Base64 library have been replaced by '-' and '_' respectively.</param>
    /// <returns>A UTF-8 string representing the original unencoded data.</returns>
    private static string Base64UrlDecode(string theString)
    {
        var unescaped = theString.Replace("-", "+").Replace('_', '/');
        //Base64-encoded strings will always be 0, 2 or 3 bytes longer than a multiple of 4.
        //For 2 and 3, we add "=" padding to get to a multiple of 4.
        unescaped = unescaped.PadRight(unescaped.Length + (4 - unescaped.Length % 4) % 4, '=');

        var bytes = Convert.FromBase64String(unescaped);
        string plainText = Encoding.UTF8.GetString(bytes);
        return plainText;
    }

    /// <summary>
    /// A JsonSerializerSettings instance containing a configuration for Newtonsoft.Json that is compatible with JWT tokens.
    /// </summary>
    private static JsonSerializerSettings jsonSettings = new JsonSerializerSettings
    {
        ContractResolver =
            new DefaultContractResolver
            {
                NamingStrategy = new CamelCaseNamingStrategy()
            },
        Formatting = Formatting.Indented,
    };

    /// <summary>
    /// Uses Newtonsoft.Json to serialize the provided object instance into a JSON string compatible with the JWT specification.
    /// </summary>
    /// <param name="obj">The object to serialize.</param>
    /// <returns>A string containing the JSON serialization of the object.</returns>
    private static string SerializeObject(object obj)
    {
        return JsonConvert.SerializeObject(obj, jsonSettings);
    }

    /// <summary>
    /// Uses Newtonsoft.Json to create an instance of the generic object type from the provided JSON string representation.
    /// </summary>
    /// <typeparam name="T">The type of the expected object serialized in the JSON string.</typeparam>
    /// <param name="theString">the JSON string to deserialize.</param>
    /// <returns>An object of the generic type containing the data serialized in the JSON string.</returns>
    private static T DeserializeObject<T>(string theString)
    {
        return JsonConvert.DeserializeObject<T>(theString, jsonSettings);
    }
    #endregion

    public class ApiKey
    {
        public Guid ID { get; set; }
        public string Api_Key { get; set; }
        public string Requestor { get; set; }
        public string Approver { get; set; }
        public string OnBehalfOf { get; set; }
        public string Intent { get; set; }
        public DateTime Issued { get; set; }
        public DateTime Expires { get; set; }
        public DateTime NotBefore { get; set; }
        public DateTime AsOf { get; set; }
        public bool IsRevoked { get; set; }
    }
}

/* Copyright © 2024 Renegade Swish, LLC */

