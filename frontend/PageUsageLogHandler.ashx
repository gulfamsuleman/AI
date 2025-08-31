<%@ WebHandler Language="C#" Class="PageUsageLogHandler" %>

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.SessionState;
using QProcess;
using QProcess.Extensions;
using DataAccessLayer;

public class PageUsageLogHandler : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        try
        {
            var user = QProcess.Session.CurrentSession?.QUser;
            if (user == null)
            {
                context.Response.StatusCode = 401; // Unauthorized 
                context.Response.Write("User not authenticated.");
                context.ApplicationInstance.CompleteRequest();
                return;
            }

            string browser = context.Request.Browser.Browser + " " +
                             context.Request.Browser.MajorVersion + "." +
                             context.Request.Browser.MinorVersion + " / " +
                             context.Request.Browser.Platform;
            if (context.Request.Browser.AOL)
                browser += " (AOL)";
            bool isMobile = false;
            var isMobileParam = context.Request["isMobile"];
            if (!string.IsNullOrEmpty(isMobileParam))
            {
                isMobile = isMobileParam == "true" || isMobileParam == "True" || isMobileParam == "1";
            }
            else
            {
                isMobile = context.Request.Browser.IsMobileDevice;
            }

            string feature = context.Request["feature"];
            string details = context.Request["details"];

            if (string.IsNullOrEmpty(feature))
            {
                context.Response.StatusCode = 400; // Bad Request
                context.Response.Write("Missing feature parameter.");
                context.ApplicationInstance.CompleteRequest();
                return;
            }

            string activity = feature;
            if (!string.IsNullOrEmpty(details))
            {
                string cleanedDetails = CleanUrl(details);
                activity += ": " + cleanedDetails;
            }

            using (var cmd = new CmdObj("LogPageUsage"))
            {
                cmd.Add("@UserId", user.Id);
                cmd.Add("@Dt", DateTime.Now);
                cmd.Add("@Browser", browser ?? (object)DBNull.Value);
                cmd.Add("@IsMobile", isMobile);
                cmd.Add("@Activity", activity ?? (object)DBNull.Value);
                cmd.ExecuteNonQueryWithOutput();
            }

            context.Response.StatusCode = 200;
            context.ApplicationInstance.CompleteRequest();
        }
        catch (Exception ex)
        {
            Log.Write("PageUsageLogHandler error: " + ex.ToString());

            context.Response.StatusCode = 500;
            context.Response.ContentType = "text/plain";
            context.Response.Write("Error: " + ex.ToString());
            context.ApplicationInstance.CompleteRequest();
        }
    }

    private static string CleanUrl(string url)
    {
        if (string.IsNullOrEmpty(url))
            return url;
        if (url.StartsWith("/"))
            url = url.Substring(1);
        if (url.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
            url = url.Substring(0, url.Length - 5);
        return url;
    }

    public bool IsReusable => false;
}
