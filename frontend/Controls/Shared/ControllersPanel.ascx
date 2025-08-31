<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ControllersPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ControllersPanel" %>
<div id="controllers-panel" data-status='<%=SerializedControllers()%>'>
	<p>Who can alter the setup of this task?</p>
	<div class="form-inline">
		<button data-role="add" class="btn btn-sm btn-default">Add</button>
		<select data-role="complex-select" data-set="controllers" class="form-control input-sm">
			<asp:repeater ID="Repeater1" DataSource=<%# Controllers %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
		<select data-role="complex-select" data-set="controllers-with-groups" class="form-control input-sm">
			<asp:repeater ID="Repeater2" DataSource=<%# ControllersWithGroups %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
		<a data-role="show-all">(show all)</a>
	</div>
	<table id="controllers-table" class="table table-condensed hidden table-listing">
		<thead><tr>
			<th></th>
			<th>Controller</th>
		</tr></thead>
		<tbody></tbody>
	</table>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/ControllersPanel.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

