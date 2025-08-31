<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TaskSearch.aspx.cs" Inherits="QProcess.TaskSearch" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Task Search</title>
    <style type="text/css">
		#txtSearch {
			width: 600px;
		}
		
		table, th, td {
			border: 1px solid black;
		}
		
		table {
			border-collapse: collapse;
			margin-top: 20px;
		}
		
		th, td {
			padding: 5px;
		}
		
		th {
			background-color: #ece9d8;
		}
		
		td {
			background-color: #ffffed;
		}
		
		b {
			color: Red;
		}
		
		.msg {
			color: Red;
			font-size: 14pt;
			font-weight: bold;
			display: none;
		}
    </style>
    <script src="Scripts/jquery-1.9.1.min.js"></script>
    <script src="Scripts/json2.js"></script>
    <script type="text/javascript">
        String.prototype.trim = function () { return this.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g, '').replace(/\s+/g, ' '); };
        function asyncPostEx(methodName, parameters, successCallBack, errorCallBack) {
            if (errorCallBack == null) {
                $.ajax({
                    type: "POST",
                    url: "/DataService.asmx/" + methodName,
                    data: parameters,
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: successCallBack
                });
            } else {
                $.ajax({
                    type: "POST",
                    url: "/DataService.asmx/" + methodName,
                    data: parameters,
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: successCallBack,
                    error: errorCallBack
                });
            }
        }

        var ctrlKey = 17, enterKey = 13, tabKey = 9;
        var textDelay = 300;        // in (ms) for the delay between typed character before calling web service
        var timeoutRef = null;      // pointer to search timeout function
        var prevText = "";          // previous typed text to search for in bond selection dialog
        var searchBox = null;       // pointer to searchbox on right nav bar
        var refreshTimestamp = new Date(); //harmless - nonce

        function search_click(obj, evt) {
            if (evt.keyCode == enterKey || evt.keyCode == tabKey || evt.keyCode == ctrlKey) return;
            if (obj == null) { return; }

            searchBox = obj;

            if (timeoutRef != null) { clearTimeout(timeoutRef); }
            timeoutRef = setTimeout(searchText, textDelay);
        }

        function searchText() {
            if ($(searchBox).val().trim().toLowerCase() == prevText) return;
            prevText = $(searchBox).val().trim().toLowerCase();

            $("#divSearchResult").html("").hide();
            $("div.msg").hide();

            if (prevText == "") return;

            refreshTimestamp = new Date(); //harmless; nonce

            asyncPostEx("TaskSearch", JSON.stringify({ search: prevText, timestamp: refreshTimestamp.getTime() }), function (msg) {
                if (msg.d.Data == null) return;

                // prevent race condition
                if (refreshTimestamp.getTime() != msg.d.Timestamp) return;
                if (msg.d.Data.length == 0) return;
                if (msg.d.ActualCount > 100)  $("div.msg").show();

                var tbl = "<table border='1'><tr><th>Task Name</th><th>Due</th><th>Completed</th><th>Assignees</th><th>Controllers</th><th>Schedule</th><th nowrap>Last Completed By</th><th nowrap>Last Completed Date</th></tr>";
                for (var i = 0; i < msg.d.Data.length; i++) {
                    tbl += "<tr>";
                    tbl += " <td>" + msg.d.Data[i].TaskName + "</td>";
                    tbl += " <td nowrap>" + msg.d.Data[i].Due + "</td>";
                    tbl += " <td>" + msg.d.Data[i].Completed + "</td>";
                    tbl += " <td>" + msg.d.Data[i].Assignees + "</td>";
                    tbl += " <td>" + msg.d.Data[i].Controllers + "</td>";
                    tbl += " <td>" + msg.d.Data[i].Schedule + "</td>";
                    tbl += " <td nowrap>" + msg.d.Data[i].LastCompletedBy + "</td>";
                    tbl += " <td nowrap>" + msg.d.Data[i].LastCompletedDate + "</td>";
                    tbl += "</tr>";
                }

                $("#divSearchResult").html(tbl + "</table>").show();
            });
        }

        $().ready(function () {
            $("#txtSearch").focus();
        });
    </script>
</head>
<body>
    <form id="Form1" method="post" runat="server" onsubmit="return false">
		<h1>Find Tasks</h1>
		<input type="text" id="txtSearch" onkeyup="search_click(this, event);"/>
		<div class="msg">More than 100 tasks found, showing the first 100</div>
		<div id="divSearchResult"></div>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

