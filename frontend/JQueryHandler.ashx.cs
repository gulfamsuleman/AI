using System;
using System.Linq;
using System.Web;
using System.Web.SessionState;
using QProcess.Helpers;

namespace QProcess
{
    /// <summary>
    /// Summary description for JQueryHandler
    /// </summary>
    public class JQueryHandler : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            using (var dummyPage = new DummyPage())
            {
                try
                {
                    context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                    string strPath = context.Request.QueryString["ControlName"];
                    
                    foreach (var key in context.Request.Form.AllKeys.Where(key => context.Request.Form[key] != null))
                    {
                        context.Request.Headers["X-" + key] = context.Request.Form[key];
                    }
                    
                    var ctl = dummyPage.LoadControl(strPath);
                    dummyPage.Controls.Add(ctl);
                    dummyPage.DataBind();
                    context.Server.Execute(dummyPage, context.Response.Output, true);                    
                }
                catch(Exception /*ex*/) {
                    context.Response.Output.Write(
                        "An error occurred with your session. Refresh the page and try this action again, "
                        +"and if you continue to see this error, report it to "
                        +"<a href='mailto:it@acmewidget.com'>it@acmewidget.com</a>.");
                }
            }
        }

        public bool IsReusable { get { return true; } }
    }
}