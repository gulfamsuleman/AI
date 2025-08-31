<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Checklist.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_Checklist" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mytasks" TagName="ItemBase" Src="~/Controls/Shared/ItemBase.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<div class="active-checklist collapsible-item row" data-collapse-state="collapsed" data-status="<%=CompletionCssClass %>" data-role="checklist"
    data-unique-id="<%=Checklist.UniqueId %>"
    data-identifier="<%=Checklist.Identifier %>"
    data-task-stage="<%=Checklist.TaskStage %>"
    data-checklist-id="<%=Checklist.ChecklistId %>">
    <input class="is-daily" type="hidden" value="<%= IsDaily %>" />
    <div class="title-bar clear-fix" data-collapse-target="true">
        <div class="float-left">
            <i class="fa fa-plus-square-o" data-role="expand-indicator"></i>
            <% if (!(Checklist.ControllerPartOfAssignee ?? true))
                { %>
            <span class="checklist-title" style="color: #ee9020" title="<%=Checklist.Name %>"><% if (Checklist.Name.Length > 47) { Response.Write(Checklist.Name.Substring(0, 47) + "..."); } else { Response.Write(Checklist.Name); }  %></span>
            <% }
            else
            {%>
            <span class="checklist-title" title="<%=Checklist.Name %>"><% if (Checklist.Name.Length > 47) { Response.Write(Checklist.Name.Substring(0, 47) + "..."); } else { Response.Write(Checklist.Name); }  %></span>
            <%} %>
            <%--<span class="checklist-title" title="<%=Checklist.Name %>"><% if (Checklist.Name.Length > 47) { Response.Write(Checklist.Name.Substring(0, 47) + "..."); } else { Response.Write(Checklist.Name); }  %></span>--%>
        </div>
        <div>
            <span class="checklist-group"><%=CompletionString %></span>
            <span class="checklist-status"><%=DisplayDate.ToString("MM/dd/yyyy") + " " + DisplayDate.ToShortTimeString() %></span>
            <%if (Checklist.PendingChange)
                { %><i class="fa fa-forward pending-indicator" title='A new deadline of <%=(Checklist.NewDeadline?.ToShortDateString() + " " + Checklist.NewDeadline?.ToShortTimeString())%> has been requested for this task'></i><% } %>
            <%if (Checklist.IsRecurring)
                { %><i class="fa fa-refresh recurring-indicator"></i><% } %>
        </div>
    </div>
    <div data-role="checklist-body">
        <div class="checklist-summary collapsed clear-fix">
            <div class="float-left checklist-header">
                <div class="management-actions">
                    <a href="#" class="btn btn-xs btn-default" data-action="view-alerts"><i class="fa fa-bell amber"></i>Alerts</a>
					<a href="#" class="btn btn-xs btn-default" data-action="manage-tasks"><i class="fa fa-edit dark-blue"></i>Manage Task</a>	
                    <a href="#" class="btn btn-xs btn-default" data-action="add-to-priorities"><i class="fa fa-plus green"></i>Add to Priorities</a>
					<a href="#" class="btn btn-xs btn-default" data-action="change-deadline"><i class="fa fa-calendar orange"></i>Change Deadline</a>
                    <a class="btn btn-xs btn-default" title='History' data-action="view-history" style="cursor: pointer;">
                        <i class="fa fa-history light-blue"></i>History
                    </a>
                    <%--<a href="#" data-action="view-alerts">View Alerts</a>
                    <a href="#" data-action="manage-tasks">Manage Task</a>
                    <a href="#" data-action="add-to-priorities">Add to Priorities</a>
                    <a href="#" data-action="change-deadline">Change Deadline</a>--%>
                </div>
                <table style="border-collapse: collapse; border: 0px;">
                    <tr>
                        <td>Controllers:</td>
                        <td><%=Checklist.Controllers %></td>
                    </tr>
                    <% if (!String.IsNullOrEmpty(Checklist.StatusReportString))
                        { %>
                    <tr>
                        <td>Status Reports:</td>
                        <td><%=Checklist.StatusReportString %></td>
                    </tr>
                    <% }%>
                    <tr>
                        <td style="padding-right: 6px;">Assigned To:</td>
                        <td><%=Checklist.Assignees %></td>
                    </tr>
                    <tr>
                        <td>Created:</td>
                        <td><%=Checklist.CreateDate.ToShortDateString() %></td>
                    </tr>
                    <%if (Checklist.RecurranceSchedule != "One Time")
                        {%>
                    <tr>
                        <td>Schedule:</td>
                        <td><%=Checklist.RecurranceSchedule %></td>
                    </tr>
                    <% } %>
                </table>
            </div>
            <%if (Checklist.IsNA)
                { %>
            <br />
            <div class="na-message float-left" style="color: #ff2451; font-weight: bold; clear: both">
                <span class="na-message-text">This task has been marked as N/A.</span><br />
                <span class="na-message">REASON: <%=Checklist.NAReason %></span><br />
            </div>
            <%}%>
        </div>
        <div class="checklist-items collapsed table-responsive">
            <table class="table table-condensed">
                <thead>
                    <tr>
                        <th style="width: 5%;"></th>
                        <th style="width: 60%;"></th>
                        <th>Comments</th>
                        <th>Completed By</th>
                        <th>Completed On</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="Repeater1" runat="server">
                        <ItemTemplate>
                            <mytasks:ItemBase ID="ItemBase1" Item="<%#(ChecklistItem) Container.DataItem %>" runat="server" />
                        </ItemTemplate>
                    </asp:Repeater>
                    <tr class="submission-row">
                        <td colspan="5">
                            <span id="save-block" <%= Checklist.TaskStage == TaskStage.Current && !Checklist.IsCompleted ? "" : "class='hidden'" %>>
                                <a data-action="save" class="btn btn-default">
                                    <img src="/Images/save_sm.gif" runat="server" style="margin-top: -2px" />
                                    Save</a>
                                <a data-action="complete" class="btn btn-default" <%= !IsCompletable ? "disabled='disabled'" : "" %>><i class="fa fa-check-square-o" style="color: #21A121"></i>Complete</a>
                                <a data-action="na" class="btn btn-default"><i class="fa fa-ban" style="color: #FF2551"></i>N/A - Close Task</a>
                            </span>
                            <a data-action="reopen" class="btn btn-default <%=Checklist.TaskStage == TaskStage.Current && Checklist.IsCompleted ? "" : "hidden" %>">
                                <i class="fa fa-reply"></i>Reopen</a>
                            <a data-action="start" class="btn btn-default <%= Checklist.TaskStage == TaskStage.Future ? "" : "hidden" %>">
                                <i class="fa fa-reply"></i>Open</a>
                            <a data-action="export" class="btn btn-default">
                                <img id="Img1" src="/Images/excel.gif" runat="server" style="margin-top: -2px" />
                                Export</a>
                        </td>
                    </tr>
                    <tr class="na-row">
                        <td colspan="5">
                            <textarea class="na-reason" placeholder="Reason for N/A" rows="5"></textarea></td>
                    </tr>
                    <tr class="na-row">
                        <td colspan="5">
                            <a data-action="na-submit" class="btn btn-default"><i class="fa fa-ban" style="color: #FF2551"></i>N/A - Close Task</a>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="Scripts/Checklist.js?v=16"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

