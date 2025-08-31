<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Preferences.ascx.cs" Inherits="QProcess.Controls.Controls_Footer_Preferences" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="preferences-panel">
	<h4><b>Emailed Task Creation Details</b></h4>
	<hr />
	<p>The following preferences determine the defaults that will be used when you create a task through email automation.</p>
	<div class="form-horizontal">
		<!-- Existing form groups -->
		<div class="form-group">
			<label class="col-xs-2">Assignee</label>
			<div class="col-xs-6">
				<select data-role="assignee" class="input-sm">
					<asp:repeater ID="Repeater1" DataSource=<%# Assignees %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Controller</label>
			<div class="col-xs-6">
				<select data-role="controller" class="input-sm">
					<asp:repeater ID="Repeater2" DataSource=<%# Controllers %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Deadline</label>
			<div class="col-xs-6">
				<select data-role="deadline" class="input-sm">
					<asp:repeater ID="Repeater3" DataSource=<%# Deadlines %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Soft Deadline</label>
			<div class="col-xs-6">
				<select data-role="soft-deadline" class="input-sm">
					<asp:repeater ID="Repeater7" DataSource=<%# SoftDeadlines %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Report</label>
			<div class="col-xs-6">
				<select data-role="report" class="input-sm">
					<asp:repeater ID="Repeater4" DataSource=<%# Reports %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Priority</label>
			<div class="col-xs-6">
				<select data-role="priority" class="input-sm">
					<asp:repeater ID="Repeater5" DataSource=<%# Priorities %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label class="col-xs-2">Alert</label>
			<div class="col-xs-6">
				<select data-role="alert" class="input-sm">
					<asp:repeater ID="Repeater6" DataSource=<%# Alerts %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>
			</div>
		</div>

		<!-- Dividing line -->
		<hr />

		<!-- Bulk Task Upload Section -->
		<div id="bulk-task-upload-section">
			<h4><b>Bulk Task Upload</b></h4>
			<hr />
			<p>The following preferences determine the defaults that will be used when you bulk upload tasks.</p>
			<div class="form-group">
				<label class="col-xs-2">Assignee</label>
				<div class="col-xs-6">
					<select data-role="bulk-assignee" class="input-sm">
						<asp:repeater ID="RepeaterBulkAssignee" DataSource=<%# BulkAssignees %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="col-xs-2">Controller</label>
				<div class="col-xs-6">
					<select data-role="bulk-controller" class="input-sm">
						<asp:repeater ID="RepeaterBulkController" DataSource=<%# BulkControllers %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="col-xs-2">Due Date</label>
				<div class="col-xs-6">
					<select data-role="bulk-due-date" class="input-sm">
						<asp:repeater ID="RepeaterBulkDueDate" DataSource=<%# BulkDueDates %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="col-xs-2">Soft Due Date</label>
				<div class="col-xs-6">
					<select data-role="bulk-soft-due-date" class="input-sm">
						<asp:repeater ID="RepeaterBulkSoftDueDate" DataSource=<%# BulkSoftDueDate %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="col-xs-2">Report</label>
				<div class="col-xs-6">
					<select data-role="bulk-report" class="input-sm">
						<asp:repeater ID="RepeaterBulkReport" DataSource=<%# BulkReports %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="col-xs-2">Priority</label>
				<div class="col-xs-6">
					<select data-role="bulk-priority" class="input-sm">
						<asp:repeater ID="RepeaterBulkPriority" DataSource=<%# BulkPriorities %> runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%#(bool)Eval("IsSelected") ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
		</div>

		<!-- Dividing line -->
		<hr />

		<h4><b>Optional Email Summary</b></h4>
		<div class="form-group">
			<div class="col-xs-12">
				<input type="checkbox" id="chkWeeklySummaryEmail" runat="server" data-role="weeklySumEmail"/> Send Weekly Task Summary Email
			</div>
			<div class="col-xs-12">
				<p>Checking this box will opt you into an email sent on Monday mornings (8 AM Central US time) displaying all tasks assigned to you that are due within the next 7 days.</p>
			</div>
		</div>

		<!-- Save and Close Button -->
		<div class="form-group" style="margin-top:20px;">
			<div class="text-center">
				<button data-action="save-close" class="btn btn-sm btn-default">Save and Close</button>
			</div>
		</div>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/Preferences.js"></script>
</QPH:DOMInjector>
