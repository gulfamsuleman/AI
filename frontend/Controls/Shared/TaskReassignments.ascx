<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TaskReassignments.ascx.cs" Inherits="QProcess.Controls.Shared.TaskReassignments" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<h4>Choose Users to reassign tasks to:</h4>
<div>
    <div id="userAssignmentsTable"></div>
</div>

<input type="hidden" id="userId" value="<%= UserId %>" />
<input type="hidden" id="supervisorId" value="<%= SupervisorID %>" />

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/TaskReassignments.js"></script>
</QPH:DOMInjector>
