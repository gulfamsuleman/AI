<%@ Control Language="C#" AutoEventWireup="true" Codebehind="NewTask.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_NewTask" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<link href="../Content/NewTask.css" rel="stylesheet" />
<div class="row">
	<div id="simple-task-form" class="">
		<div class="form-horizontal">
			<div class="form-group">
				<label class="control-label col-xs-3">Task:</label>
				<div class="col-xs-6">
					<input type="text" id="task-name" class="form-control input-sm"/>
				</div>
			</div>
			<div class="form-group">
				<label class="control-label col-xs-3">Assigned To:</label>
				<div class="col-xs-6">
					<select id="task-assignee" class="form-control input-sm">
						<asp:repeater ID="rptAssignees" runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%# FullName == Eval("Name").ToString() ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="control-label col-xs-3">Folder:</label>
				<div class="col-xs-8">
					<select id="task-folder" class="input-sm">
						<asp:repeater ID="rptFolders" runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
			<div class="form-group">
				<label class="control-label col-md-3">Due Date:</label>
				<div class="col-md-6">
					<input type="text" data-role="datepicker" id="task-due-date" class="input-sm input-date"  value="<%: QProcess.Session.CurrentSession.QUser.MyTimeZone.GetLocalTimeNow().Add(new TimeSpan(1,0,0,0)).ToString("M/d/yyyy") %>" />
				</div>
			</div>
			<div class="form-group">
				<label class="control-label col-md-3">Soft Due:</label>
				<div class="col-md-8">
					<input type="text" data-role="datepicker" id="task-soft-due" class="input-sm input-date" value="<%= QProcess.Session.CurrentSession.QUser.MyTimeZone.GetLocalTimeNow().Add(new TimeSpan(1,0,0,0)).ToString("M/d/yyyy") %>" />
					<a id="set-soft-due-date">(make same as due date)</a>
				</div>
			</div>
			<div class="form-group">
				<label class="control-label col-xs-3">From Template:</label>
				<div class="col-xs-8">
					<select id="task-template" class="form-control input-sm" onchange="TaskTemplate_Change(this);">
						<asp:repeater ID="rptTemplate" runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
			</div>
            <br />
			<div id="simple-controller-panel">
				<div class="form-group">
					<label class="control-label col-md-3">Controller:</label>
					<div id="task-controller" class="col-md-6">
						<div id="task-controller-me" class="hidden"><%=QProcess.Session.CurrentSession.QUser.FullName %></div>
						<div id="task-controller-select">
							<select data-set="controllers" class="input-sm">
								<asp:repeater ID="rptControllers" runat="server">
									<itemtemplate>
										<option value="<%#Eval("Id") %>" <%# (int)Eval("Id") == CurrentSession.QUser.SupervisorId ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
									</itemtemplate>
								</asp:repeater>
							</select>
							<select data-set="controllers-with-groups" class="input-sm">
								<asp:repeater ID="rptGroupsControllers" runat="server">
									<itemtemplate>
										<option value=<%#Eval("Id") %> <%# (int)Eval("Id") == CurrentSession.QUser.SupervisorId ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
									</itemtemplate>
								</asp:repeater>
							</select>
							<a data-role="show-all">(show all)</a>
						</div>
						<div id="task-controller2-select" class="<%= CurrentSession.QUser.AllSupervisors.Length > 1 ? "" : "hidden"%>">
							<select data-set="controllers" class="input-sm">
								<asp:repeater ID="rptControllers2" runat="server">
									<itemtemplate>
										<option value="<%#Eval("Id") %>" <%# CurrentSession.QUser.AllSupervisors.Length > 1 && (int)Eval("Id") == CurrentSession.QUser.AllSupervisors[1] ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
									</itemtemplate>
								</asp:repeater>
							</select>
							<select data-set="controllers-with-groups" class="input-sm">
								<asp:repeater ID="rptGroupsControllers2" runat="server">
									<itemtemplate>
										<option value=<%#Eval("Id") %> <%# CurrentSession.QUser.AllSupervisors.Length > 1 && (int)Eval("Id") == CurrentSession.QUser.AllSupervisors[1] ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
									</itemtemplate>
								</asp:repeater>
							</select>
							<a data-role="show-all">(show all)</a>
						</div>
						<div class="radio">
							<label>
								<input type="radio" name="supervisor-controlled" value="true" checked="checked"/>
								Supervisor controlled task
							</label>
						</div>
						<div class="radio">
							<label>
								<input type="radio" name="supervisor-controlled" value="false" />
								I control this task
							</label>
						</div>
						  <div> <%--added by venkat 04/20/2017--%>
                            <label>
                                <input type="checkbox" name="chkAddToPriorityList" id="chkAddToPriorityList"/>
                                Add Task To Priority List
                            </label>

                        </div>
						<%--<br/>--%>
                        <div><%--added by venkat 04/20/2017--%>
						<p class="notice-text"><em>If you should be asking your supervisor for approval to change the task, it should only be controlled by a supervisor.</em></p>
                        </div>
					</div>
				</div>
			</div>
			<% if (ShowPriority) { %>
			<div class="form-group">
				<label class="control-label col-md-3">Priority</label>
				<div class="col-xs-6">
					<input type="number" id="priority" class="form-control input-sm" value="1"/>
				</div>
				<input type="hidden" id="task-type" value="<%= TaskType %>"/>
			</div>
			<% } %>
			<div id="task-complexity-type" class="form-group">
				<div class="col-md-6 col-md-offset-3">
					<div class="radio">
						<label>
							<input type="radio" name="customize" value="false" checked="checked" />
							<strong>Use Defaults (Simple Task)</strong>
						</label>
					</div>
					<div class="radio">
						<label>
							<input type="radio" name="customize" value="true" />
							<strong>Customize (Complex Task)</strong>
						</label>
					</div>
				</div>
			</div>
            <br />
			<div class="form-group">
				<div class="col-md-12 text-center"><button id="create" class="btn btn-submit-simple" disabled="disabled">Create</button></div>
			</div>
		</div>
	</div>
</div>
<div id="complex-task-panel" class="hidden">

</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="/Scripts/NewTask.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/NewTask.js")).Ticks.ToString() %>"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

