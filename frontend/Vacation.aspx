<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Vacation.aspx.cs" Inherits="QProcess.Vacation" MasterPageFile="Site.master" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link href="Content/Vacation.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/Vacation.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/BulkAssignments.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <input type="hidden" id="currentUserId" value="<%=CurrentUserId %>" />
    <div style="margin: 10px;">
        <div class="form-group" id="user-select-group" style="display: none;">
            <label for="user-select">Viewing tasks for:</label>
            <select id="user-select" class="input-sm"></select>
        </div>
        <div class="filters-controls">
            <div class="form-group">
                Search for tasks starting on
                <input id="start-date" type="text" class="input-sm" data-role="datepicker" name="start-date" value="<%=StartDateString %>" />
                at 12:00 AM through 
                    <input id="end-date" type="text" class="input-sm" data-role="datepicker" name="start-date" value="<%=EndDateString %>" />
                at 12:00 AM.
					<br>
                Note - when reassigned, the tasks will be switched to the temp assignee at midnight on the start date, and will revert back to you at midnight on the end date listed above.
            </div>
            <div class="form-group">
                <hr />
                Include tasks that are:
            
                <div>
                    <input type="radio" id="AssignedToMe" name="AssignmentType" class="AssignmentType" value="1"
                        checked>
                    <label for="AssignedToMe" data-default="Assigned only to me.">Assigned only to me.</label>
                </div>
                <div>
                    <input type="radio" id="AssignedToOthers" name="AssignmentType" class="AssignmentType" value="2">
                    <label for="AssignedToOthers" data-default="Assigned to me and others.">Assigned to me and others.</label>
                </div>
                <div>
                    <input type="radio" id="Group" name="AssignmentType" class="AssignmentType" value="3">
                    <label for="AssignmentType">Assigned through groups including multiple employees (take caution - this reassigns the entire group).</label>
                </div>

            </div>
        </div>

        <hr />
        Reassign selected tasks to:
        <select id="grouplist"></select>
        <input type="button" id="reassignbtn" class="reassignbtn" value="Reassign" />
        <hr />
        <div class="TaskResults">
        </div>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

