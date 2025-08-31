<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileReports.aspx.cs" Inherits="QProcess.Mobile.MobileReports" MasterPageFile="Mobile.master" %>
<%@ Register TagPrefix="report" TagName="ReportsOverview" Src="~/Controls/Reports/ReportsOverview.ascx" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
	<link href="../Content/Reports.css?v=2" rel="stylesheet" />
	<style type="text/css">
		.text-header {
			height: 10px;
		}
		#reports-overview > .row {
			margin: 0;
		}
		#overdue-panel .filters-bar,
		#history-panel .filters-bar {
			margin: 0;
			padding: 10px;
			border-radius: 5px;
			margin-bottom: 10px;
		}
		#overdue-alert {
			width: 100% !important;
			border-radius: 5px;
			padding: 5px;
		}
		.q-table tr td,
		.q-table tr th {
			border: 1px solid #000000;
		}
		.q-table thead {
			background-color: #ECE9D8;
		}
		.q-table tbody {
			background-color: #FFFFED;
		}
		#message-panel .close {
			position: absolute;
			right: 14px;
		}
		#message-body.message-size {
			width: 100% !important;
		}
		button.close{
			z-index: 100;
		}
		@media screen and (min-width: 768px) {
			#message-body.message-size {
				margin-top: 30px;
			}
		}
	</style>
    <script>
        var mobileTitle = "Reports";
    </script>
</asp:Content>

<asp:Content ID="main" runat="server" ContentPlaceHolderID="mainContent">
	<input type="hidden" id="oldOverdue" value="<%=Request.QueryString["o"] %>" />
	<input type="hidden" id="oid" value="<%=Request.QueryString["oid"] %>" />

		<div class="mt-3 mb-3">
			<div id="report-nav" class="list-group">
				<a href="#" class="list-group-item active" data-role="reports-overview">Reports Overview</a>
				<a href="#" class="list-group-item" data-role="overdue">Overdue</a>
				<a href="#" class="list-group-item" data-role="history">History</a>
				<%if (CurrentSession.QUser.IsOverdueAdmin) { %>
					<a href="#" class="list-group-item" data-role="three-day-overdue">3 Day Overdue</a>
					<a href="#" class="list-group-item" data-role="tasks-by-person">Tasks by Person</a>
				<% } %>
			</div>
		</div>
		<div>
			<div id="reports-overview" data-view="control">
				<report:ReportsOverview runat="server" />
			</div>
			<div id="overdue" class="hidden" data-view="control"></div>
			<div id="history" class="hidden" data-view="control"></div>
			<div id="three-day-overdue" class="hidden" data-view="control"></div>
			<div id="tasks-by-person" class="hidden" data-view="control"></div>
		</div>

	<div id="throbber" class="hidden center" style="width: 100%;">
		<img src="/Images/hourglass.gif"/>
		<br/>
		<span id="wait-message">Please Wait . . .</span>
	</div>
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
	<script src="../Scripts/Reports.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/Reports.js")).Ticks.ToString() %>"></script>

	
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

