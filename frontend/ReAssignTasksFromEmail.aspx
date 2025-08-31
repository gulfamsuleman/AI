<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ReAssignTasksFromEmail.aspx.cs" Inherits="QProcess.ReAssignTasksFromEmail" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
     <script src="Scripts/jquery-1.9.1.min.js"></script>
     <script src="Scripts/json2.js"></script>
     <script src="Scripts/common.js"></script>
     <script type="text/javascript">
        $(document).ready(function () {
            syncPost("ReAssignTasksWithQptPreferences", JSON.stringify({ activeChecklistId: getParameterByName('ActiveChecklistId'), assigneeGroupId: getParameterByName('AssigneeGroupId'), assignedById: getParameterByName('AssignedById') }));
            if (syncPostSuccess) {
                alert("Task Assigned Successfully");
                window.close();
            }


          
            
        });
        function getParameterByName(name, url) {
            if (!url) url = window.location.href;
            name = name.replace(/[\[\]]/g, "\\$&");
            var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
                results = regex.exec(url);
            if (!results) return null;
            if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, " "));
        }
       
    </script>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

