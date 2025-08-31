<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Reports.aspx.cs" Inherits="QProcess.Reports" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="report" TagName="ReportsOverview" Src="~/Controls/Reports/ReportsOverview.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Reports.css?v=2" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content4" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/Reports.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/Reports.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/json2.js"></script>
     <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script> 
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<input type="hidden" id="oldOverdue" value="<%=Request.QueryString["o"] %>" />
	<input type="hidden" id="oid" value="<%=Request.QueryString["oid"] %>" />
	<div class="row">
		<div class="col-xs-2">
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
		<div class="col-xs-10">
			<div id="reports-overview" data-view="control">
				<report:ReportsOverview runat="server" />
			</div>
			<div id="overdue" class="hidden" data-view="control"></div>
			<div id="history" class="hidden" data-view="control"></div>
			<div id="three-day-overdue" class="hidden" data-view="control"></div>
			<div id="tasks-by-person" class="hidden" data-view="control"></div>
		</div>
	</div>
	<div id="throbber" class="hidden center" style="width: 100%;">
		<img src="/Images/hourglass.gif"/>
		<br/>
		<span id="wait-message">Please Wait . . .</span>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

