<%@ WebHandler Language="C#" Class="OfficeExportHandler" %>

using System;
using System.Linq;
using System.Web;
using System.Web.SessionState;

public class OfficeExportHandler : IHttpHandler, IRequiresSessionState
{
    
    public void ProcessRequest (HttpContext context) {

		string pageName = context.Request.QueryString["pageName"];
	    string exportType = context.Request.QueryString["exportType"];

	    switch (exportType)
	    {
			case "msword":
				context.Response.ContentType = "application/msword";
				context.Response.Headers["Content-Disposition"] = "attachment; filename=" + pageName.Split('.').First() + ".doc";
				// Need to change encoding of content or Office cannot display "..." and such characters correctly.
				// Reference: http://theoldsewingfactory.com/2010/12/05/saving-csv-files-in-utf8-creates-a-characters-in-excel/
				context.Response.ContentEncoding = System.Text.Encoding.GetEncoding("Windows-1252");
			    break;
			case "msexcel":
				context.Response.ContentType = "application/vnd.ms-excel";
				context.Response.Headers["Content-Disposition"] = "attachment; filename=" + pageName.Split('.').First() + ".xls";
				// Need to change encoding of content or Office cannot display "..." and such characters correctly.
				// Reference: http://theoldsewingfactory.com/2010/12/05/saving-csv-files-in-utf8-creates-a-characters-in-excel/
			    context.Response.ContentEncoding = System.Text.Encoding.GetEncoding("Windows-1252");
			    break;
			default:
				throw new Exception("The specified export type is not supported.");

	    }
		
		context.Server.Execute(pageName, context.Response.Output, true);
    }
 
	public bool IsReusable { get { return true; } }
}