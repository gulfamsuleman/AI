<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportsOverview.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_ReportsOverview" %>

<div class="row">
	<div id="reports-overview-panel">
		<h4 class="report-page-title">Overview</h4>
		<div class="panel panel-default">
			<div class="panel-body">
				<b><a href="#" onclick="reportsModule.loadOverdue(this)" data-role="overdue">Overdue</a> report</b>
				<p>Display all tasks which have gone past due.</p>
				<b><a href="#" onclick="reportsModule.loadHistory(this)" data-role="history">History</a> report</b>
				<p>Display a history of completed tasks.</p>
				<%if (QProcess.Session.CurrentSession.QUser.IsOverdueAdmin) { %>
					<b><a href="#" data-role="three-day-overdue">3 Day Overdue</a> reports</b>
					<p>Displays tasks that controllers have allowed to go overdue by more than 3 days.</p>
					<b><a href="#" data-role="tasks-by-person">Tasks by Person</a> report</b>
					<p>Displays all the tasks assigned to a person you choose.</p>
				<% } %>
				<br/>
				<p class="small">*Note - reports will show tasks that you are assigned to, or tasks you control.</p>
			</div>
		</div>
	</div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

