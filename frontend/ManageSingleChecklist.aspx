<%@ Page Title="" Language="C#" MasterPageFile="BlankMaster.master" AutoEventWireup="true"  CodeBehind="ManageSingleChecklist.aspx.cs" Inherits="QProcess.ManageSingleChecklist"%>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Import Namespace="QProcess.Extensions" %>
<%@ Register TagPrefix="mytasks" TagName="Checklist" Src="Controls/Shared/Checklist.ascx" %>
<%@ Register TagPrefix="modal" TagName="Modal" Src="Controls/Shared/ModalFramework.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet" />
	<link href="Content/MyTasks.css?v=4" rel="stylesheet" />
	<link href="Content/<%=Firm%>/ColorScheme.css?v=4" rel="stylesheet" />
	<style>
		html, body {
			overflow: auto;
			min-width: 0px !important;
		}

		.container {
			min-width: 0px !important;
		}

		.checklist-date-section {
			display: inline-block;
			vertical-align: top;
			margin: 5px;
			border: 1px solid black !important;
		}

		.checklist-delete {
			display: inline-block;
			margin: 5px;
			border: 1px solid black !important;
		}

		.checklist-title {
			width: auto;
			min-width: 0px;
		}

		.checklist-group {
			width: auto;
			margin-left: 10px;
		}

		.checklist-status {
			width: auto;
		}

		#RequestNewDue {
			margin-top: 17px;
			margin-bottom: 17px;
			margin-left: 50px;
			margin-right: 50px;
		}

		.control-label {
			font-weight: bold;
		}

		.active-checklist {
			margin-right: 20px;
		}

		.red {
			color: red;
		}

		@media (max-width: 767px) {
			.active-checklist .checklist-items .table-condensed {
				max-width: 250vw;
			}

				.active-checklist .checklist-items .table-condensed > tbody > tr > td {
					white-space: revert;
				}

					.active-checklist .checklist-items .table-condensed > tbody > tr > td > label {
						min-width: 88vw;
					}

					.active-checklist .checklist-items .table-condensed > tbody > tr > td > .notes
					{
						width: 90vw;
						display:inline-block;
					}

					.active-checklist .checklist-items .table .submission-row td {
						text-align: left;	
						padding-left: 28.4px;
					}
		}
	</style>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
	<script src="Scripts/common.js?<%# Utils.AppendAutoVersion("Scripts/common.js")%>"></script>
	<script src="Scripts/ManageSingleChecklist.js?2<%# Utils.AppendAutoVersion("Scripts/ManageSingleChecklist.js")%>"></script>	
	<modal:Modal runat="server" ID="ModalFramework" />
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="manage-single-checklist">
		<div class="row due-date-controls <%= Checklist1.Checklist.TaskStage == TaskStage.Future ? "hidden show-on-open" : "" %>">
			<div id="update-reminder-date" class="checklist-date-section">
				<div class="form-inline">
					<div class="form-group">
						<label class="control-label">Soft Due &nbsp;</label>
						<input id="reminder-datepicker" data-role="datepicker" class="input-dt"/>
						<select id="reminder-time" class="input-dt">
							<asp:repeater ID="Repeater1" DataSource=<%# TimeOptions %> runat="server">
								<itemtemplate>
									<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
								</itemtemplate>
							</asp:repeater>
						</select>
					</div>
					<div class="form-group">
						<a data-action="update-reminder" class="btn btn-sm btn-default">Update</a>
					</div>
				</div>
			</div>
			<% if (Controller)
				{ %>
			<div id="update-due-date" class="checklist-date-section">
				<div class="form-inline">
					<div class="form-group">
						<label>New Due &nbsp;</label>
						<input id="update-datepicker" data-role="datepicker" class="input-dt"/>
						<select id="update-time" class="input-dt">
							<asp:repeater ID="Repeater3" DataSource=<%# TimeOptions %> runat="server">
								<itemtemplate>
									<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
								</itemtemplate>
							</asp:repeater>
						</select>
					</div>
					<div class="form-group">
						<a data-action="update-due" class="btn btn-sm btn-default">Update</a>
					</div>
				</div>
			</div>
			<div class="checklist-delete">
				<label>Delete&nbsp;</label>
				<button data-action="delete" class="btn btn-sm btn-default"><i class="fa fa-times" style="color:Red;"></i></button>
			</div>
			<% }
				 else
				 { %>
			<div class="checklist-date-section">
				<input type="hidden" id="newDueDateQS" value="<%=Request.QueryString["newDueDate"]%>""/>
				<div class="text-center">
					<button id="RequestNewDue" data-action="request" class="btn btn-sm btn-default"><i class="fa fa-calendar orange"></i>Request New Due Date</button>
				</div>
				<div id="request-new-due-date" class="hidden">
					<div class="form-inline">
						<div class="form-group">
							<label>New Due &nbsp;</label>
							<input id="request-datepicker" data-role="datepicker" class="input-dt"/>
							<select id="request-time" class="input-dt">
								<asp:repeater ID="Repeater2" DataSource=<%# TimeOptions %> runat="server">
									<itemtemplate>
										<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
									</itemtemplate>
								</asp:repeater>
							</select>
						</div>
						<div class="form-group">
							<label>Comment &nbsp;</label>
							<textarea id="request-comment" maxlength="1000" style="width: 275px; height: 100px; vertical-align: top;"></textarea>
						</div>
						<%if (PendingChange)
							{ %>
                        <div class ="form-group">
							<i class="fa fa-warning" style="color: goldenrod"></i><label class="red">Deadline Extension Pending!</label>
						</div>
							<%} %>
						<div class="form-group">
							<button data-action="send-request" class="btn btn-sm btn-default">Send Request</button>							
						</div>
					</div>
				</div>
			</div>
			<% } %>
		</div>
		<% if (Checklist1.Checklist.IsVisible && !HeaderOnly)
			{ %>
			<mytasks:Checklist ID="Checklist1" runat="server"></mytasks:Checklist>
		<% } %>
		<input id="task-id" type="hidden" value="<%= TaskId %>"/>
        <input id="change-id" type="hidden" value="<%= ChangeId %>"/>
		<input id="due-date" type="hidden" value="<%= DueDate %>"/>
		<input id="reminder-date" type="hidden" value="<%= ReminderDate %>"/>
		<input id="hide-change-deadline" type="hidden" value="<%= HideChangeDeadline %>"/>
        <input id="add-priority" type="hidden" value="<%= AddPriority ? "1" : "0" %>"/>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

