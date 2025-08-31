<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="GroupReassignment.ascx.cs" Inherits="QProcess.Controls.Shared.GroupReassignment" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<h4>Add or Remove User From Groups:</h4>
<div>
    <div id="modalGroupsTable"></div>
</div>

<input type="hidden" id="userId" value="<%= UserId %>" />
<input type="hidden" id="supervisorId" value="<%= SupervisorID %>" />

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/GroupReassignments.js"></script>
</QPH:DOMInjector>
