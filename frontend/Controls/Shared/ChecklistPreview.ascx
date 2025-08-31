<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChecklistPreview.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ChecklistPreview" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mytasks" TagName="ItemBase" Src="~/Controls/Shared/ItemBase.ascx" %>
<div class="checklist-preview active-checklist">
	<div class="preview-header">
		<div class="preview-title-bar title-bar">
			<label><%:Name%></label>
		</div>
		<div></div>
	</div>
	<div class="preview-body checklist-items">
		<table class="table table-condensed">
			<thead>
				<tr>
					<th></th>
					<th></th>
					<th>Comments</th>
					<th>Completed By</th>
					<th>Completed On</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater1" DataSource=<%# ChecklistItems %> runat="server">
					<ItemTemplate>
						<mytasks:ItemBase ID="ItemBase1" Item=<%#(ChecklistItem) Container.DataItem %> runat="server" />
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	</div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

