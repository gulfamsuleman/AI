<%@ Page Title="Complete Checklist" Language="C#"%>
<%@ Import namespace="QProcess.Extensions" %>
<%@ Import namespace="DataAccessLayer" %>
<HTML>
  <HEAD>
    <title>Complete Checklist</title>
  </HEAD>
  <body >
	<%
    string popup = "";
    if ((Request["na"] == "1"))
    {
        Response.Redirect("na.aspx?ac="
                        + Request["ac"] + "&UserID="
                        + Request["userID"] + "&mobile=0");
    }
    else
    {
        if (Request["userID"] == null)
        {
            Response.Redirect("../mytasks.aspx");
        }
        int userID = (Request["userID"]).ToIntEx().Value;
        
        using (var db = new DBCommand("QCheck_CompletionPopup"))
        {
            popup = db.Add("@userId", userID).ExecuteScalar().ToBlank();
        }
        string agent = Request.ServerVariables["HTTP_USER_AGENT"].ToUpper();
        if (popup == "")
        {
            Response.Redirect("complete.aspx?ac="
                            + Request["ac"] + "&UserID="
                            + Request["userID"] + "&mobile=0&na=0&nareason=");
        }
     }
	%>
    <form id="Form1" method="post" action="complete.aspx?ac=<%=Request["ac"]%>&userID=<%=Request["userID"]%>&na0&mobile=0&nareason=">
	<% 
        Response.Write(popup);
	%>
    <br /><br /><input type="submit" value="Yes, Complete" />&nbsp;&nbsp;&nbsp;<input type="button" value="No" onclick="javascript:window.location.href='../mytasks.aspx';" />
    </form>
  </body>
</HTML>
<!-- Copyright © 2024 Renegade Swish, LLC -->

