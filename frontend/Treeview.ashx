<%@ WebHandler Language="C#" Class="Treeview" %>

using System;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Data;
using System.Web.SessionState;
using QProcess.Extensions;
using QProcess.Repositories;

public class Treeview : IHttpHandler, IReadOnlySessionState {
    
    public void ProcessRequest (HttpContext context) {
		context.Response.ContentType = "text/html";
		var session = QProcess.Session.CurrentSession;
		var userId = session.QUser.Id;
		var memberGroupId = Int32.Parse(context.Request.Form["memberGroupId"] ?? "0");
		var managerGroupId = Int32.Parse(context.Request.Form["managerGroupId"] ?? "0");
		//var isAdmin = session.QUser.IsAdmin;
		var isAdmin = Boolean.Parse(context.Request.Form["adminSearch"] ?? "false");
		var search = context.Request.Form["search"];
		var parentId = Int32.Parse(context.Request.Form["parentId"] ?? "0");

		var userRepo = new UserRepository();
		userRepo.AddPreference(userId, "ControlSearch", search);
		
		var content = GetTree(
			userId,
			memberGroupId,
			managerGroupId,
			isAdmin,
			search,
			parentId
		);
		context.Response.Write(content);
    }

    public string GetFolder(DataSet ds, int folderID)
    {
        StringBuilder sOut = new StringBuilder("");
        DataRow[] subfolders;
        DataRow[] tasks;
        
        subfolders = ds.Tables[0].Select("Type = 3 AND ParentID = " + folderID.ToString()); // Folders
        tasks = ds.Tables[0].Select("Type = 1 AND ParentID = " + folderID.ToString());
				
        if(subfolders.Length > 0 || tasks.Length > 0)
        {
            sOut.Append("<ul>");
            foreach (DataRow folder in subfolders)
            {
                sOut.Append("<li data-id='" + folder["ID"].ToString() + "' data-is-folder='true'>" + folder["NodeName"]);
                sOut.Append(GetFolder(ds, Convert.ToInt32(folder["FolderID"])));
                
            }
            foreach (DataRow task in tasks)
            {
                sOut.Append("<li data-id='" + task["ID"].ToString() + "' data-jstree='{\"icon\":\"fa fa-file-o\"}' ");
                if (task["Template"].ToString() != "0")
                {
                    sOut.Append(" data-is-template='true'");
                }
                else
                {
                    sOut.Append(" data-is-template='false'");
                }
                if (task["Active"].ToString() != "0")
                {
                    sOut.Append(" data-is-active='true'");
                }
                else
                {
                    sOut.Append(" data-is-active='false'");
                }
                if (task["NodeName"].ToString().Length > 50)
                {
                    sOut.Append(">" + task["NodeName"].ToString().Substring(0,50) + "...</li>");
                }
                else
                {
                    sOut.Append(">" + task["NodeName"] + "</li>");
                }
            }
            sOut.Append("</ul>");
        }
       
        return sOut.ToString();
    }
    
	public string GetTree(int userId, int memberGroupId = 0, int managerGroupId = 0, bool isAdmin = false, string search = "", int parentId = 0)
	{
        string sOut = "";
		
		var repo = new TreeViewRepository();
		using (DataSet ds = repo.GetChecklistsByFolder(userId, memberGroupId, managerGroupId, isAdmin, search, parentId))
        {
            sOut = GetFolder(ds, 0);
		}
		return sOut.ToString();
	}
 
    public bool IsReusable {
        get {
            return false;
        }
    }
	
	public string GetSubtree(int userId, int memberGroupId = 0, int managerGroupId = 0, bool isAdmin = false, string search = "", int parentId = 0)
	{
		var repo = new TreeViewRepository();
		repo.GetChecklistsByFolderTV(userId, memberGroupId, managerGroupId, isAdmin, search, parentId).ToHtmlString().ToString();
		return GetTree(userId, memberGroupId, managerGroupId, isAdmin, search, parentId);
	}

	private DateTime? GetIfModifiedSinceUTCTime(HttpContext context)
	{
		DateTime? ifModifiedSinceTime = null;
		string ifModifiedSinceHeaderText = context.Request.Headers.Get("If-Modified-Since");

		if (!string.IsNullOrEmpty(ifModifiedSinceHeaderText))
		{
			ifModifiedSinceTime = DateTime.Parse(ifModifiedSinceHeaderText);
			//DateTime.Parse will return localized time but we want UTC
			ifModifiedSinceTime = ifModifiedSinceTime .Value.ToUniversalTime();
		}
		
		return ifModifiedSinceTime;
	}
	
	private Guid GetDeterministicGuid(string input)
	{
		//use MD5 hash to get a 16-byte hash of the string:
		MD5CryptoServiceProvider provider = new MD5CryptoServiceProvider();

		byte[] inputBytes = Encoding.Default.GetBytes(input);
		byte[] hashBytes = provider.ComputeHash(inputBytes);

		//generate a guid from the hash:
		Guid hashGuid = new Guid(hashBytes);

		return hashGuid;
	}

}