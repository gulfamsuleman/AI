<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportToolbar.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ReportToolbar" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<style>
	.tool-bar-dropdown {
		z-index: 10000;
	}
</style>
<link href="Content/ReportToolbar.css" rel="stylesheet" />
<nav class="navbar report-navbar-default" role="navigation">
	<div class="container-fluid">
        <input type="hidden" id="IsArchive" value="<%: IsArchive ? "true" : "" %>" />
		<ul class="nav navbar-nav reportmenu">
			<% if (IsMyStatus || IsArchive || IsMyInboxStatus) { %>
				<li class="topmenu"><a href="#" class="dropdown-toggle" data-toggle="dropdown"><img src="images/mystatus.gif" /> Report</a>
					<ul class="dropdown-menu tool-bar-dropdown">
						<li class="dropdown-submenu">
							<a href="#" class="dropdown-toggle" data-toggle="dropdown" title="Open A Different Report"><img src="images/reopen_sm.gif" /> Change Report</a>
							<ul class="dropdown-menu">
								<% if (MyReports.Any()) { %>
								<li><a><h4>My Reports</h4></a></li>
									<% foreach (var report in MyReports) { %>
										<li title="Open A Different Report"><a href="#" data-action="change-report" data-report-type="my-report" data-id="<%: report.ID %>"><%: report.Name %></a></li>
									<% } %>
								<% } %>
								<% if (InterestedPartyReports.Any()) { %>
									<li class="divider"></li>
									<li><a><h4>Interested Parties</h4></a></li>
									<% foreach (var report in InterestedPartyReports) { %>
										<li title="Open A Different Report"><a href="#" data-action="change-report" data-report-type="ip-report" data-id="<%: report.ID %>"><%: report.Name %></a></li>
									<% } %>
								<% } %>
								<% if (SupervisedReports.Any()) { %>
									<li class="divider"></li>
									<li><a><h4>Supervised Reports</h4></a></li>
									<% foreach (var report in SupervisedReports) { %>
										<li title="Open A Different Report"><a href="#" data-action="change-report" data-report-type="sup-report" data-id="<%: report.ID %>"><%: report.Name %></a></li>
									<% } %>
								<% } %>
							</ul>
						</li>
						<% if (!IsMyInbox) { %>
							<li><a href="#" data-action="supervisors" title="View Supervisors For This Report"><img src="images/managed_cl.gif" /> Supervisors</a></li>
							<li><a href="#" data-action="sections" title="View Sections For This Report"><img src="images/paper.gif" /> Sections</a></li>
							<li><a href="#" data-action="controllers" title="View Controllers For This Report"><img src="images/my_cl.gif" /> Controllers</a></li>
							<li><a href="#" data-action="manage-reports" title="Add Reports, Alter Report Names and Delete Reports"><img src="images/edit.gif" /> Add/Delete/Edit Reports</a></li>
							<li><a href="#" data-action="attorney-client" title="Attorney Client Confidentiality"><img src="images/conf.gif" /> Attorney Client</a></li>
							<% if (IsArchive)
								{ %>
							<li><a href="<%: ResolveUrl("~/MyStatus.aspx") %>" title="Go Back to My Status Reports"><img src="images/mystatus.gif" /> My Status</a></li>
							<% }
								else
								{ %>
							<li><a href="<%: ResolveUrl("~/MyStatus.aspx?archive=1") %>" title="View My Archived Tasks"><img src="images/magnify.gif" /> Archive</a></li>
							<% } %>
						<% } %>
					</ul>
				</li>
				<%if (!IsArchive && !IsMyInbox) {%>
				<li><a href="#" class="dropdown-toggle topmenu" data-toggle="dropdown" title="Add a Task To This Report"><img src="images/plus_sm.gif"/> Add</a>
					<ul class="dropdown-menu tool-bar-dropdown">
						<li class="dropdown-submenu">
							<a href="#" class="dropdown-toggle" data-toggle="dropdown">New Task</a>
							<ul class="dropdown-menu">
								<%if (TaskTypes.Any()) {%>
									<asp:Repeater ID="Repeater1" runat="server">
										<ItemTemplate>
											<li><a href="#" data-action="new-task" data-id="<%#Eval("Id") %>"><%#Eval("Name") %></a></li>	
										</ItemTemplate>
									</asp:Repeater>
								<% } %>
							</ul>
						</li>
						<li class="dropdown-submenu">
							<a href="#" class="dropdown-toggle" data-toggle="dropdown">Existing Task</a>
							<ul class="dropdown-menu tool-bar-dropdown">
								<%if (TaskTypes.Any()) {%>
									<asp:Repeater ID="Repeater2" runat="server">
										<ItemTemplate>
											<li><a href="#" data-action="existing-task" data-id="<%#Eval("Id") %>"><%#Eval("Name") %></a></li>	
										</ItemTemplate>
									</asp:Repeater>
								<% } %>
							</ul>
						</li>
					</ul>
				</li>
				<%}%>
				<% if (IsMyInbox) { %>
				<li><a href="#" data-action="mark-read" title="Mark This Report As Read"><i class="fa fa-thumbs-up"></i> Mark Read</a></li>
				<% } %>
				<%if (!IsArchive) {%>
				<li><a href="#" data-action="email-comments" title="Email All Comments I Added in the Last Hour"><img src="images/reply.gif"/> Email Comments</a></li>
				<li><a href="#" data-action="timeline" title="Timeline View of This Report"><img src="images/timeline.gif"/> Timeline</a></li>
				<%}%>
				<li><a href="#" class="dropdown-toggle topmenu" data-toggle="dropdown"><img src="images/magnify.gif"/> View</a>
					<ul class="dropdown-menu tool-bar-dropdown">
						<% if (IsMyInbox) { %>
						<li><a href="#" data-action="due-date-changes" title="Show all the due dates that were changed on this report over the last 24 hours">Due Dates</a></li>
						<li><a href="#" data-action="visibility" title="Show Who Can View This Report">Visibility</a></li>
						<% } %>
						<li><a href="#" data-action="assignees" assigneesHidden="true" title="Toggle Assignees Column"><img src="images/magnify.gif" /> Assignees</a></li>
                        <li><a href="#" data-action="taskFilter" title="Toggle Task Filter"><img src="images/filter.gif" /> Task Filter</a></li>
                    </ul>
				</li>
			<% } %>
			<li><a href="#" class="dropdown-toggle topmenu" data-toggle="dropdown"><img src="images/tools.gif"/> Tools</a>
				<ul class="dropdown-menu tool-bar-dropdown">
					<% if (IsMyStatus) { %>
					<li><a href="#" data-action="tool-delete" title="Remove Task"><img src="images/delete.gif" /> Remove</a></li>
					<% } %>
					<% if (IsMyInbox) { %>
					<li><a href="#" data-action="manage-emails"><img src="images/inbox.gif" /> Manage Emails</a></li>
					<% } %>
					<% if (IsMyStatus || IsMyInboxStatus) { %>
					<li><a href="#" data-action="email-all" title="Email Entire Report"><img src="images/reply.gif" /> Email All</a></li>
					<li><a href="#" data-action="email-today" title="Email Today's Comments"><img src="images/reply.gif" /> Email Today's Comments</a></li>
					<li><a href="#" data-action="export" title="Export To Excel"><img src="images/export.png" /> Export</a></li>
					<%}%>
					<li><a href="#" data-action="change-fonts"><img src="images/font.gif" /> Change Fonts</a></li>
					<% if (IsMyInbox) { %>
						<% if (IsDepartmentAdmin)
							{ %>
							<li><a href="#" data-action="manage-confidential-email">Manage Confidential Email</a></li>
						<% } %>
					<% } %>
					<%if (IsMyStatus) { %>
					<li><a href="#" data-action="bulk-update"><img src="images/plus.gif" /> Bulk Update</a></li>
					<% } %>
				</ul>
			</li>
			<% if (IsMyInbox && !IsMyInboxStatus) { %>
			<li><a href="#" data-action="supervisors-list"><i class="fa fa-users"></i> Supervisor</a></li>
			<li><a href="#" data-action="interested-party-list"><i class="fa fa-user"></i> Interested Party</a></li>
				<% if (HasDepartments) { %>
				<li><a href="#" data-action="all-firm-list"><i class="fa fa-users"></i> All Firm Reports</a></li>
				<% } %>
			<li><a href="#" data-action="my-favorites-list"><i class="fa fa-star"></i> My Favorites</a></li>
			<% } %>
			<li><a href="#" class="dropdown-toggle topmenu" data-toggle="dropdown"><img src="images/print.gif"/>Print</a>
				<ul class="dropdown-menu tool-bar-dropdown">
					<li><a href="#" data-action="print" title="Print on Normal Paper">Print</a></li>
					<li><a href="#" data-action="printXL" title="Print on 11 x 17 Paper">Large Print</a></li>
					<%if (IsMyStatus || IsMyInboxStatus) {%>
					<li><a href="#" data-action="printBW" title="Print on Normal Paper - Black and White">B&amp;W Print</a></li>
					<li><a href="#" data-action="printXLBW" title="Print on 11 x 17 Paper - Black and White">Large B&amp;W Print</a></li>
                    <li><a target="_blank" href="PrintStatusPage.aspx" title="Print with Details">Print with Details</a></li>
					<%}%>
				</ul>
			</li>
			<% if (CurrentSession.QUser.IsSupervisor) { %>
				<li>
					<a href="Dashboard.aspx" data-action="dashboard" title="Dashboard">
						<i class="fa fa-dashboard"></i>
						Supervisor Dashboard
					</a>
				</li>
			<% } else { %>
				<li>
					<a href='DashboardDetailedView.aspx?userId=<%= CurrentSession.QUser.Id %>' data-action="dashboard" title="Dashboard">
						<i class="fa fa-dashboard"></i>
						Dashboard
					</a>
				</li>
			<% } %>
			<li><a href="Help.aspx" target="help_page"><img src="images/help.gif"/> Help</a></li>
		</ul>
		<ul class="nav navbar-nav navbar-right">
			<li class="todays-date"><%= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToShortDateString() %></li>
		</ul>
	</div>
</nav>
<input id="report-id" type="hidden" value="<%= ReportId %>"/>
<!-- Copyright © 2024 Renegade Swish, LLC -->

