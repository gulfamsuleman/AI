<%@ WebHandler Language="C#" Class="EmailHandler"  %>

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.SessionState;
using QProcess;
using QProcess.Extensions;
using DataAccessLayer;

public class EmailHandler : IHttpHandler, IReadOnlySessionState  {
    public void ProcessRequest (HttpContext context) {
        string preview = context.Request.Form["Preview"] ?? "0";
        var form = context.Request.Form["Form"] ?? context.Request.Headers["X-Form"];
        var requestUrl = context.Request.Url.GetLeftPart(System.UriPartial.Authority) + "/" + form;
        var controlRequest = (HttpWebRequest)WebRequest.Create(requestUrl);
        CookieContainer cookies = new CookieContainer();
        controlRequest.UseDefaultCredentials = true;
        controlRequest.CookieContainer = cookies;
        controlRequest.KeepAlive = true;
        foreach (var datum in context.Request.Form.AllKeys)
        {
            //First pass; replace known common non-ASCII characters with their ASCII equivalent.
            var theData = context.Request.Form[datum]
                    .Replace("\n", "<br/>")
                    .Replace("’", "'")
                    .Replace("“", "\"")
                    .Replace("”", "\"")
                    .Replace("–", "-");

            //Catch-all; explicitly convert what's left from UTF-8 to ASCII.
            //if (theData.ToCharArray().Any(c => (int) c > 255))
            {
                byte[] byteArray = Encoding.UTF8.GetBytes(theData);
                byte[] asciiArray = Encoding.Convert(Encoding.UTF8, Encoding.ASCII, byteArray);
                theData = Encoding.ASCII.GetString(asciiArray);
            }

            controlRequest.Headers["X-" + datum] = theData;
        }

        if (context.Request["LoginName"].ToBlank() == "")
        {
            var _session = HttpContext.Current.Session;
            var user = _session["CurrentUser"] as QProcess.Models.IUser;
            if (user == null)
                _session["CurrentUser"] = new QProcess.Repositories.UserRepository().GetUser(Session.CurrentSession.QUser.Username.ToLower().Replace(QProcess.Configuration.AppSettings.Get("Domain") + "\\", ""));
            var iuser = _session["CurrentUser"] as QProcess.Models.IUser;
            int userid = iuser.Id;
            controlRequest.Headers["X-UserID"] = userid.ToString();
            controlRequest.Headers["X-Username"] = iuser.Username;
        }
        else
        {
            var _session = HttpContext.Current.Session;
            var user = _session["CurrentUser"] as QProcess.Models.IUser;
            if (user == null)
                _session["CurrentUser"] = new QProcess.Repositories.UserRepository().GetUser(context.Request["LoginName"].ToBlank());
            var iuser = _session["CurrentUser"] as QProcess.Models.IUser;
            int userid = iuser.Id;
            controlRequest.Headers["X-UserID"] = userid.ToString();
            controlRequest.Headers["X-Username"] = iuser.Username;
        }

        var response = (HttpWebResponse) controlRequest.GetResponse();
        var responseStream = response.GetResponseStream();
        var streamReader = new StreamReader(responseStream, Encoding.UTF8);
        string resultBody = streamReader.ReadToEnd();

        var subject = context.Request.Form["Subject"] ?? context.Request.Headers["X-Subject"];
        var temp = context.Request.Form["EmailAddresses"] ?? context.Request.Headers["X-EmailAddresses"];
        var emailAddresses = temp.Split(',');        
        var emailFrom = response.Headers["X-EmailFrom"];

        if (response.Headers["X-SubjectLine"] != null)
            subject = response.Headers["X-SubjectLine"];        

        if (response.Headers["X-Error"] == "true")
        {
            context.Response.Clear();
            context.Response.Write(resultBody);
        }
        else
        {
            if (preview == "1")
            {
                context.Response.Clear();
                context.Response.AddHeader("X-Error", "true");
                context.Response.Write(resultBody);
            }
            else
            {
				if (subject.StartsWith("Today")) 
				{
                var iuser = HttpContext.Current.Session["CurrentUser"] as QProcess.Models.IUser;
                for (int i = 0; i < emailAddresses.Length; i++)
                {
                    try
                    {
                        Log.Write("Email From:" + emailFrom.ToString() + ";To:" + emailAddresses[i].ToString());
                    }
                    catch (Exception)
                    {
                            //do nothing here - if we can't write to the log that shouldn't cause the user to be unable to use the app
                    }

                    using (var db = new DBCommand("InsertEmailLog"))
                    {
                        db.Add("@fromId",iuser.Id);
                        db.Add("@toAddress", emailAddresses[i].ToString());
                        db.Add("@subject", "PriorityList");

                        db.ExecuteNonQuery();
                    }
                }
				}
                SendEmail(emailFrom, emailAddresses, subject, resultBody);
            }
        }
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

    public void SendEmail(string from, string[] to, string subject, string body)
    {
		var tolist = "";
		foreach (var address in to)
		{
			tolist += address + ';';
		}
		
		using (var db = new DBCommand("QCheck_Sendmail"))
        {
            db.Add("@From", from);
            db.Add("@To", tolist);
            db.Add("@Subject", subject);
            db.Add("@Message", body);
            db.Add("@replyTo", QProcess.Configuration.AppSettings.QPCAddress);
            db.ExecuteNonQuery();
        }
		
        /*
			var smtp = new SmtpClient(QProcess.Configuration.AppSettings.Get("SMTPServer"), Convert.ToInt32(QProcess.Configuration.AppSettings.Get("smtpport")));

			smtp.EnableSsl = true;
			smtp.UseDefaultCredentials = false;
			smtp.Credentials = new NetworkCredential(QProcess.Configuration.AppSettings.Get("smtpuser"), QProcess.Configuration.AppSettings.Get("smtppass"));

			using (var message = new MailMessage
				{
					From = new MailAddress(from),
					Subject = subject,
					Body = body,
					BodyEncoding = System.Text.Encoding.UTF8,
					IsBodyHtml = true
				})
			{
				message.ReplyToList.Add(QProcess.Configuration.AppSettings.QPCAddress);
				message.ReplyToList.Add(from);
				foreach (var address in to)
				{
					message.To.Add(new MailAddress(address));
				}
				smtp.Port = int.Parse(QProcess.Configuration.AppSettings.Get("smtpport").ToString());
				smtp.Credentials = new System.Net.NetworkCredential(QProcess.Configuration.AppSettings.Get("smtpuser").ToString(), QProcess.Configuration.AppSettings.Get("smtppwd").ToString());
				smtp.EnableSsl = true;
				smtp.Send(message);
			}
		*/
    }

}