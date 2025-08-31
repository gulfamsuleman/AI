<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Timeline.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_Timeline" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="timeline-panel">
	<select id="report-select" class="hidden">
		<asp:repeater ID="Repeater1" runat="server">
			<itemtemplate>
				<option value=<%#Eval("Id") %> <%#Convert.ToInt32(Eval("Id")) == SelectedReportId ? "selected='selected'" : "" %>>
					<%#Eval("Name") %>
				</option>
			</itemtemplate>
		</asp:repeater>
	</select>
	<h3>Status Timeline -- <span id="report-name"></span></h3>
	<span id="loading" class="hidden">Loading . . .</span>
	<table id="timeline-table" class="hidden">
		<thead><tr>
			<th>Due Date</th>
			<th>Task</th>
		</tr></thead>
		<tbody></tbody>
	</table>
	<p id="no-timeline" class="hidden">No timeline available for this report.</p>
</div>

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script>var controller = <%=Controller %>;</script>
	<script src="Scripts/StatusTimeline.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

