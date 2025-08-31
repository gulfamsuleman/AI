<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="QuickDeadlineExtensions.aspx.cs" Inherits="QProcess.QuickDeadlineExtensions" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
     <script src="Scripts/jquery-1.9.1.min.js"></script>
     <script src="Scripts/json2.js"></script>
     <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script> 
     <script type="text/javascript">
        $(document).ready(function () {
            syncPost("GetOverdueTasksForQuickDeadlineExtension", "");
            
            $("#divTasks").html(syncPostResult);

          
            
        });
        function SendRequestsForOverdueTaskExtensions()
        {
            syncPost("SendRequestsForOverdueTaskExtensions", JSON.stringify({ comment: $("#txtComments").text() }));
            if (syncPostSuccess) {
                alert("Extension Requests Sent Successfully");
                window.close();
            }


        }
        function EmailLateReport() {
            syncPost("EmailPriorityListScheduleReportAll", JSON.stringify({ timeSpan: $("#ddlTimeFrame option:selected").text() }));
            if(syncPostSuccess)
            {
                alert("Mail Sent Successfully");
            }
           


        }
       
    </script>
</head>
<body>
    <form id="form1" runat="server">
    <div>
      <div><h1>Extend Deadline</h1></div>
     <div id="divTasks"></div>
    <div><b>Comments:</b></div>
    <div style="padding-top:5px;"><textarea id="txtComments" rows="10" cols="50"></textarea></div>
    <div style="padding-top:10px;"><input type="button" id="btnSendRequest" value="Send Extension Request" onclick="SendRequestsForOverdueTaskExtensions()"/></div>
    </div>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

