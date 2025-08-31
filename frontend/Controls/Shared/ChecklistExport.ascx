<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChecklistExport.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ChecklistExport" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mytasks" TagName="ItemBaseExport" Src="~/Controls/Shared/ItemBaseExport.ascx" %>
<table cellspacing="2" cellpadding="2" rules="all" border="0" id="dgChecklists" style="border-width:0px;width:100%;Z-INDEX: 103; LEFT: 8px">
	<tr>
		<td class="<%= StatusCssClass %>" colspan="5"><%= Checklist.Name %></td>
	</tr>
	<tr>
		<td colspan="5">Assigned To: <%= Checklist.Assignees %></td>
	</tr>
	<tr>
		<td class="both" colspan="5">
			<span class=due>
				<span class=overdue><%= CompletionString %></span> <%= Checklist.DueDate %>
			</span>
		</td>
	</tr>
	<tr class="<%= (Checklist.IsCompleted) ? "SubHead2Completed" : "SubHead2InComplete"%>">
		<td></td>
		<td></td>
		<td style="width:10%;">Comments</td>
		<td style="width:10%;">Completed&nbsp;By</td>
		<td style="width:10%;">Completed&nbsp;On</td>
	</tr>
	<asp:Repeater ID="Repeater1" DataSource=<%# Checklist.Items %> runat="server">
		<ItemTemplate>
			<tr class="<%= (Checklist.IsCompleted) ? "CheckListCompleted" : "CheckListInComplete"%>">
				<mytasks:ItemBaseExport ID="ItemBase1" Item=<%#(ChecklistItem) Container.DataItem %> runat="server" />
			</tr>
		</ItemTemplate>
	</asp:Repeater>
	<tr>
		<td colspan="5" style="height:25px;"><hr></td>
	</tr>
</table>
<!-- Copyright © 2024 Renegade Swish, LLC -->

