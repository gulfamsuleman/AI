<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="ReportLoadTimes.aspx.cs" Inherits="QProcess.ReportLoadTimes" MasterPageFile="Site.master"%>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/ReportLoadTimes.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/ReportLoadTimes.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="report-load-times-panel">
		<div class="form-inline">
			<div>
				<p>Show data from 
					<input id="from-date" data-role="datepicker" value="<%= WeekAgo.ToShortDateString() %>" class="form-control input-sm"/>
					to
					<input id="to-date" data-role="datepicker" value="<%= Today.ToShortDateString() %>" class="form-control input-sm"/>
					<button data-role="filter" class="btn btn-sm btn-default">Filter</button>
				</p>
			</div>
			<div>
				<p>Show data from report
					<select id="report-select" class="form-control input-sm">
						<asp:Repeater ID="Repeater1" DataSource=<%# Reports %> runat="server">
							<ItemTemplate>
								<option <%#(string)Eval("Name") == ReportName ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</ItemTemplate>
						</asp:Repeater>
					</select>
				</p>
			</div>
			<div>
				<p>Show data from user
					<select id="user-select" class="form-control input-sm">
						<asp:Repeater ID="Repeater2" DataSource=<%#Users %> runat="server">
							<ItemTemplate>
								<option value="<%#Eval("Id") %>" <%#(int)Eval("Id") == UserId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</ItemTemplate>
						</asp:Repeater>
					</select>
				</p>
			</div>
		</div>
		<button data-role="export" class="btn btn-sm btn-default">Export to Excel</button>
		<p></p>
		<table class="table table-condensed">
			<thead>
				<tr>
					<th><a href="#" data-field="User">User</a></th>
					<th><a href="#" data-field="UserId">UserID</a></th>
					<th><a href="#" data-field="Page Name">Page Name</a></th>
					<th><a href="#" data-field="Server Time">Server Time</a></th>
					<th><a href="#" data-field="Client Time">Client Time</a></th>
					<th><a href="#" data-field="Total Load Time">Total Load Time</a></th>
					<th><a href="#" data-field="DateTime">DateTime</a></th>
					<th><a href="#" data-field="Report Name">Report Name</a></th>
					<th><a href="#" data-field="LastOpened">Last Opened</a></th>
					<th><a href="#" data-field="Browser">Browser</a></th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater3" DataSource=<%# LoadTimes %> runat="server">
					<ItemTemplate>
						<tr class="<%# Container.ItemIndex % 2 == 0 ? "" : "alternate" %>">
							<td><%#Eval("User") %></td>
							<td><%#Eval("UserId") %></td>
							<td><%#Eval("PageName") %></td>
							<td><%#Eval("ServerTime") %></td>
							<td><%#Eval("ClientTime") %></td>
							<td><%#Eval("TotalLoadTime") %></td>
							<td><%#Eval("DateTime") %></td>
							<td><%#Eval("ReportName") %></td>
							<td><%#Eval("LastOpened") %></td>
							<td><%#Eval("Browser") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
		<input id="sort-column" type="hidden" value="<%= SortBy %>"/>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

