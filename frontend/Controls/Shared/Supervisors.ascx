<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Supervisors.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_Supervisors" %>

<div id="supervisors-panel">
	<% if (IsController || IsSupervisorAdmin) { %>
    <div class="form-inline">
        <button data-role="add-supervisor" class="btn btn-sm btn-default">
            <i class="fa fa-plus"></i>Add
        </button>
        <select id="supervisor-select" title="supervisor-select" class="form-control input-sm">
            <asp:Repeater ID="Repeater1" DataSource="<%# Assignees %>" runat="server">
                <ItemTemplate>
                    <option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
                </ItemTemplate>
            </asp:Repeater>
        </select>
    </div>
	<% } else { %>
		<p>In order to make supervisor or interested party changes, please send a request to 
			<a href="mailto:qprocessgrading@acmewidget.com" target="_top">qprocessgrading@acmewidget.com</a>
		</p>
	<% } %>
   <br />
	<table id="supervisors-table" class="table table-condensed hidden">
		<thead><tr>
			<% if (IsController || IsSupervisorAdmin) { %>
				<th></th>
			<% } %>
			<th>Name</th>
			<th class="text-center">Interested Party</th>
			<th class="text-center">Supervisor</th>
		</tr></thead>
		<tbody></tbody>
	</table>
</div>

<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<script src="/Scripts/Supervisors.js"></script>
<!-- Copyright © 2024 Renegade Swish, LLC -->

