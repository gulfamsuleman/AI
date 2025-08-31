using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace ChaatApp
{
    public partial class Chatpage : System.Web.UI.Page
    {
        private static readonly HttpClient httpClient = new HttpClient();
        private const string API_BASE_URL = "http://localhost:8000";

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                await LoadUsers();
                SetApiBaseUrl();
            }
        }

        private async Task LoadUsers()
        {
            try
            {
                var response = await httpClient.GetAsync($"{API_BASE_URL}/api/users/");
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var users = JsonConvert.DeserializeObject<List<string>>(json);

                    // Find the repeater control safely - try multiple approaches
                    var repeater = FindControl("UsersRepeater") as Repeater;
                    if (repeater == null)
                    {
                        // Try to find it in the form
                        var form = FindControl("form1");
                        if (form != null)
                        {
                            repeater = form.FindControl("UsersRepeater") as Repeater;
                        }
                    }
                    if (repeater == null)
                    {
                        // Try to find it by searching recursively
                        repeater = FindControlRecursive(this, "UsersRepeater") as Repeater;
                    }
                    
                    if (repeater != null)
                    {
                        var userList = users.Select(u => new { Name = u }).ToList();
                        repeater.DataSource = userList;
                        repeater.DataBind();
                        
                        // Add debug output
                        System.Diagnostics.Debug.WriteLine($"Loaded {users.Count} users into repeater");
                        
                        // Also register startup script to ensure JavaScript can access users
                        var usersJson = JsonConvert.SerializeObject(users);
                        ClientScript.RegisterStartupScript(this.GetType(), "LoadUsers", 
                            $"console.log('Server-side loaded users:', {usersJson}); window.serverLoadedUsers = {usersJson};", true);
                        
                        // Force select first user after a delay
                        if (users.Count > 0)
                        {
                            ClientScript.RegisterStartupScript(this.GetType(), "ForceSelectUser", 
                                $"setTimeout(() => {{ if (window.forceSelectFirstUser) window.forceSelectFirstUser(); }}, 2000);", true);
                            
                            // Also add immediate test
                            ClientScript.RegisterStartupScript(this.GetType(), "TestSelectUser", 
                                $"setTimeout(() => {{ if (window.testSelectFirstUser) window.testSelectFirstUser(); }}, 1000);", true);
                        }
                    }
                    else
                    {
                        // Fallback: register startup script to populate users via JavaScript
                        var usersJson = JsonConvert.SerializeObject(users);
                        ClientScript.RegisterStartupScript(this.GetType(), "LoadUsers", 
                            $"console.log('Fallback loading users:', {usersJson}); window.loadUsersList({usersJson});", true);
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine($"Failed to load users. Status: {response.StatusCode}");
                    // Fallback to test users
                    var testUsers = new List<string> { "Test User 1", "Test User 2", "Test User 3" };
                    var repeater = FindControlRecursive(this, "UsersRepeater") as Repeater;
                    if (repeater != null)
                    {
                        var userList = testUsers.Select(u => new { Name = u }).ToList();
                        repeater.DataSource = userList;
                        repeater.DataBind();
                        
                        var usersJson = JsonConvert.SerializeObject(testUsers);
                        ClientScript.RegisterStartupScript(this.GetType(), "LoadTestUsers", 
                            $"console.log('Using test users:', {usersJson}); window.serverLoadedUsers = {usersJson};", true);
                    }
                }
            }
            catch (Exception ex)
            {
                // Log error or handle gracefully
                System.Diagnostics.Debug.WriteLine($"Error loading users: {ex.Message}");
                
                // Always provide test users as fallback
                var testUsers = new List<string> { "Test User 1", "Test User 2", "Test User 3" };
                var repeater = FindControlRecursive(this, "UsersRepeater") as Repeater;
                if (repeater != null)
                {
                    var userList = testUsers.Select(u => new { Name = u }).ToList();
                    repeater.DataSource = userList;
                    repeater.DataBind();
                    
                    var usersJson = JsonConvert.SerializeObject(testUsers);
                    ClientScript.RegisterStartupScript(this.GetType(), "LoadTestUsersCatch", 
                        $"console.log('Using test users from catch:', {usersJson}); window.serverLoadedUsers = {usersJson};", true);
                }
            }
        }

        private Control FindControlRecursive(Control parent, string controlId)
        {
            if (parent.ID == controlId)
                return parent;

            foreach (Control child in parent.Controls)
            {
                var found = FindControlRecursive(child, controlId);
                if (found != null)
                    return found;
            }
            return null;
        }

        private void SetApiBaseUrl()
        {
            // Find the hidden field safely
            var apiBaseUrlField = FindControl("hdnApiBaseUrl") as HiddenField;
            if (apiBaseUrlField != null)
            {
                apiBaseUrlField.Value = API_BASE_URL;
            }
            else
            {
                // Fallback: register startup script
                ClientScript.RegisterStartupScript(this.GetType(), "SetApiBaseUrl", 
                    $"window.apiBaseUrl = '{API_BASE_URL}';", true);
            }
        }

        // Helper method that matches your exact pattern
        private async Task<string> SendChatMessageAsync(string message, string user)
        {
            using (var client = new HttpClient())
            {
                var json = $"{{\"message\":\"{message}\",\"user\":\"{user}\"}}";
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
                var response = await client.PostAsync($"{API_BASE_URL}/api/chat/", content);
                return await response.Content.ReadAsStringAsync();
            }
        }

        [System.Web.Services.WebMethod(EnableSession = false)]
        [System.Web.Script.Services.ScriptMethod(ResponseFormat = System.Web.Script.Services.ResponseFormat.Json)]
        public static string SendChatMessage(string message, string user, string timezone)
        {
            try
            {
                // Create the request data object
                var requestData = new
                {
                    message = message,
                    user = user,
                    timezone = timezone
                };

                // Serialize to JSON
                var json = JsonConvert.SerializeObject(requestData);
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                // Make the HTTP request to Django backend synchronously
                var response = httpClient.PostAsync($"{API_BASE_URL}/api/chat/", content).Result;
                
                if (response.IsSuccessStatusCode)
                {
                    var responseJson = response.Content.ReadAsStringAsync().Result;
                    System.Diagnostics.Debug.WriteLine($"Django API Response: {responseJson}");
                    return responseJson;
                }
                else
                {
                    var errorContent = response.Content.ReadAsStringAsync().Result;
                    System.Diagnostics.Debug.WriteLine($"Django API Error: {response.StatusCode} - {errorContent}");
                    return JsonConvert.SerializeObject(new { error = $"API Error: {response.StatusCode} - {errorContent}" });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Exception in SendChatMessage: {ex.Message}");
                return JsonConvert.SerializeObject(new { error = $"Network error: {ex.Message}" });
            }
        }

        [System.Web.Services.WebMethod(EnableSession = false)]
        [System.Web.Script.Services.ScriptMethod(ResponseFormat = System.Web.Script.Services.ResponseFormat.Json)]
        public static string GetUsers()
        {
            try
            {
                var response = httpClient.GetAsync($"{API_BASE_URL}/api/users/").Result;
                if (response.IsSuccessStatusCode)
                {
                    return response.Content.ReadAsStringAsync().Result;
                }
                return "[]";
            }
            catch (Exception ex)
            {
                return "[]";
            }
        }

        // Simple test method to verify WebMethod accessibility
        [System.Web.Services.WebMethod(EnableSession = false)]
        [System.Web.Script.Services.ScriptMethod(ResponseFormat = System.Web.Script.Services.ResponseFormat.Json)]
        public static string TestConnection()
        {
            return JsonConvert.SerializeObject(new { status = "success", message = "WebMethod is accessible" });
        }

        // Even simpler test method
        [System.Web.Services.WebMethod]
        public static string SimpleTest()
        {
            return "Hello from WebMethod!";
        }
    }
}
