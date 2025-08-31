<%@ Control Language="C#" AutoEventWireup="true" Codebehind="SwitchPriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_SwitchPriorityList" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="switch-priority-panel">
	<table id="switch-table" class="table table-condensed">
		<asp:Repeater ID="Repeater1" runat="server">
			<ItemTemplate>
				<tr data-id="<%#Eval("Id") %>">
					<td>
						<%#Eval("Name") %>
					</td>
				</tr>
			</ItemTemplate>
		</asp:Repeater>
	</table>
	<% if (Info.IsSupervisor) { %>
	<div class="form-inline">
		<label>New Set:</label>
		 <input id="new-list" type="text" maxlength="100" class="form-control input-sm"/>
	</div>
	<% } %>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/SwitchPriorityList.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

