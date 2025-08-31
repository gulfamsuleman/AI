<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TimezoneConversion.aspx.cs" Inherits="QProcess.TimezoneConversion" MasterPageFile="Site.master" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="Server">
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css">
    <link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet">
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
    <script src="/Scripts/jquery-ui-1.13.2.min.js?2<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/jquery-ui-1.13.2.min.js")).Ticks.ToString() %>"></script>

    <link href="/Content/TimezoneConversion.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Content/TimezoneConversion.css")).Ticks.ToString() %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ScriptContent" runat="Server">
    <script src="/Scripts/TimezoneConversion.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/TimezoneConversion.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <div>
        <h2>Tasks currently controlled by <%= UserName %></h2>

        <h4>How to use this tool:</h4>

        <p>
            This is a time zone converter tool. 
            This tool is designed for task controllers to alter the time zone of a given task’s deadline.
            For example, a task with a due date of Nov. 11, 2024, at 7pm CST (America/Chicago Time),
            could be easily changed to a due date of Nov. 11, 2024, at 7pm EST (America/New York Time),
            with the click of a button.
            This is helpful for assignees who may be traveling or working in a different location.<br />
            <br />

            <b><u>To change time zones on tasks controlled by you:</u></b><br />
            <br />

            <u>Change the time zone on an individual task:</u><br />
            <br />

            &emsp;<b><em>1.</em></b> Find the task you want to convert in the list below.<br />
            &emsp;<b><em>2.</em></b>  Select your preferred time zone in the “Change Time zone To” column.<br />
            &emsp;<b><em>3.</em></b>  Click the “Change” button on the right.<br />
            <br />

            <%--- You can change the time zone or due time for a single task using the drop-downs displayed in the row for that task. 
            Once you've made your selections, click the "Change" button at the end of that row to apply them to the task. 
            The view will update to reflect the new settings.<br /><br />--%>

            <u>“Bulk Change” time zones on many tasks:</u><br />
            <br />

            &emsp;<b><em>1.</em></b>  Select the tasks you want to convert.<br />

            &emsp;&emsp;a. You can change multiple tasks to one time zone by clicking the checkbox next to the task's name.<br />
            &emsp;&emsp;b. You can change all tasks to one time zone by clicking the checkbox at the top left of the table.<br />

            <%--2.	Choose if you also want to change the due time<br />

            &emsp;a. Select the new due time from the drop-down menu in the “bulk update” section <br />
            &emsp;&emsp;&emsp;i. Click “Convert All Selected Due Times”<br />
            <br />--%>

            &emsp;<b><em>2.</em></b>  Choose the time zone you want to convert your tasks to under the "Bulk Update" dropdown<br />
            &emsp;<b><em>3.</em></b>  Click “Convert All Selected Time Zones”<br />
            <br />

            <%--- You can change multiple tasks to one time zone by clicking the checkboxes for each row you wish to change.<br />
              &emsp;&emsp;Choose the desired time zone from the drop down at the top (not the one on the row in the table), then click "Convert All Selected."<br />
            - The checkbox at the top left of the table is a "Select All" control that checks the checkboxes of every row in the table, 
              which is useful for changing most or all displayed tasks.--%>
        </p>
    </div>
    <br />
    <div id="progress-dialog">
        <div id="progressTitle">Converting Timezones. Please Wait...</div>
        <div id="progressBar"></div>
    </div>
    <div id="existingTaskContainer" class="table-container">
    </div>
    <input type="hidden" id="userId" value="<%= UserId %>" />
    <input type="hidden" id="userName" value="<%= UserName %>" />

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

