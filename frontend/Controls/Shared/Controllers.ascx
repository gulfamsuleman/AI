<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Controllers.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_Controllers" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="controllers-panel">
	<div class="form-inline">
		<button data-role="add-controller" class="btn btn-sm btn-default">
						<i class="fa fa-plus"></i> Add
		</button>
		<select id="controller-select" class="form-control input-sm">
			<asp:repeater ID="Repeater1" DataSource=<%# Assignees %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
	</div>
    <br />
	<table id="controllers-table" class="table table-condensed hidden">
		<thead><tr>
			<th></th>
			<th>Name</th>
		</tr></thead>
		<tbody></tbody>
	</table>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/Controllers.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

