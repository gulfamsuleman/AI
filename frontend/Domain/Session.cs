using System;
using System.Web;
using System.Web.SessionState;
using QProcess.Models;
using System.Security.Claims;
using System.Linq;
using QProcess.Extensions;
using System.Runtime.CompilerServices;
using QProcess.Domain.Models;

namespace QProcess
{
    public class Session
	{
		public static Session CurrentSession { get { return new Session(HttpContext.Current?.Session); } }

        public UserTimeZone UserTimeZone => 
            !string.IsNullOrEmpty(HttpContext.Current?.Request.Headers["apiRequest"]) 
                ? new UserTimeZone("UTC", "UTC", "UTC") 
                : HttpContext.Current?.Request.IsAuthenticated ?? false
                    ? QUser.MyTimeZone
                    : (_session?["CurrentUser"] as IUser)?.MyTimeZone
                ?? new UserTimeZone("America/Chicago", null, "UTC");

        private readonly HttpSessionState _session;
		public Session(HttpSessionState session)
		{
			_session = session;
		}

		private const string USER_KEY = "CurrentUser";
		private const string GET_ALL_COMMENTS_FLAG = "GetAllCommentsFlag";

		public IUser QUser 
		{
			get
			{
				if (HttpContext.Current.Request.IsAuthenticated == false)
				{
					return null;
				}				

                //OWIN/OpenID Claims Auth
                var user = _session[USER_KEY] as IUser;

				if (user == null)
				{
					var claimIdent = HttpContext.Current.User.Identity as ClaimsIdentity;
					var userEmail = claimIdent.Claims.FirstOrDefault(c => c.Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress")?.Value;

                    //Testing
                    //userEmail = "graynor@acmewidget.com";
                    var repo = new Repositories.UserRepository();

                    // Some tenants/tokens may not include an email claim.
                    // Avoid calling the email-based lookup with a null which
                    // causes the underlying proc to throw (expects @Email).
                    if (!String.IsNullOrWhiteSpace(userEmail))
                        user = repo.GetUserByEmail(userEmail);
                    else
                        user = new QProcess.Repositories.User();

                    //User may not exist; pack relevant claims info in user obj for inprocessing
                    if (user.Id == 0)
                    {
                        user.FullName = claimIdent.Claims.FirstOrDefault(c => c.Type == "name")?.Value;
                        var userName = claimIdent.Claims.FirstOrDefault(c => c.Type == "preferred_username")?.Value;

                        //Testing more
                        //user.FullName = "Test User";
                        //userName = "tuser@acmewidget.com";

                        if (userName.Contains("@phi")) userName = "phi-" + userName;
                        else if (userName.Contains("@txexbank")) userName = "teb-" + userName;
                        else if (userName.Contains("@acme")) userName = "q-" + userName;
                        else userName = userName.Split('@').Last().Split('.').First() + "-" + userName;

                        userName = userName.Left(userName.IndexOf("@"));

                        user.Username = userName;
                        user.Email = userEmail;

                        //The username we just generated may exist; if it does, use that user
                        var user2 = repo.GetUser(userName);
                        if (user2 != null && user2.Id != 0)
                            user = user2;

                    }

                    _session[USER_KEY] = user;

                }

				return _session[USER_KEY] as IUser;

				//Win/Kerberos auth
				//var user = _session[USER_KEY] as IUser;
				//if (user == null)
				//    _session[USER_KEY] = new Repositories.UserRepository().GetUser(HttpContext.Current.User.Identity.Name.ToLower().Replace(QProcess.Configuration.AppSettings.Get("Domain") + "\\", ""));
				//return _session[USER_KEY] as IUser;
			}
        }

		public bool GetAllCommentsFlag
		{
			get { return Convert.ToBoolean(_session[GET_ALL_COMMENTS_FLAG]); }
			set { _session[GET_ALL_COMMENTS_FLAG] = value; }
		}

		public string SessionId
		{
			get { return _session.SessionID; }
		}		

		public bool ForceDesktop(HttpRequest request = null)
		{
            if (request != null && !request.QueryString["ViewMode"].IsNullOrBlank())
                _session["ViewMode"] = request.QueryString["ViewMode"];

            return _session["ViewMode"]?.ToString() == "desktop";
        }

        public bool ForceMobile(HttpRequest request = null)
        {
            if (request != null && !request.QueryString["ViewMode"].IsNullOrBlank())
                _session["ViewMode"] = request.QueryString["ViewMode"];

            return _session["ViewMode"]?.ToString() == "mobile";
        }
    }
}
/* Copyright � 2024 Renegade Swish, LLC */

