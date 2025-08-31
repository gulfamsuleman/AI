<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="MobileChangeRequest.ascx.cs" Inherits="QProcess.Controls.Shared.MobileChangeRequest" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mytasks" TagName="ChangeRequestItemAddition" Src="~/Controls/ChangeRequests/ChangeRequestItemAddition.ascx" %>
<%@ Register TagPrefix="mytasks" TagName="ChangeRequestItemChange" Src="~/Controls/ChangeRequests/ChangeRequestItemChange.ascx" %>
<%@ Register TagPrefix="mytasks" TagName="ChangeRequestItemRemoval" Src="~/Controls/ChangeRequests/ChangeRequestItemRemoval.ascx" %>
<%@ Register TagPrefix="mytasks" TagName="ChangeRequestItemChangeNatural" Src="~/Controls/ChangeRequests/ChangeRequestItemChangeNatural.ascx" %>
<div class="change-request collapsible-item" data-collapse-state="collapsed" data-request-id="<%:ChangeRequest.ID%>" data-request-checklist-id="<%:ChangeRequest.ChecklistId%>" data-email="<%:ChangeRequest.Email %>">
    <div class="change-request-header">

        <div class="checklist-name">

            <table style="table-layout: fixed; width: 100%; text-overflow: clip" data-role="change-request-table">
                <tr>
                    <td class="cr-header-date">
                        <i class="fa fa-plus-square-o" data-role="expand-indicator" data-collapse-target="true"></i>
                        <a data-role="expand"></a>
                        <span class="hidden data-label">Date</span>
                        <span><%:ChangeRequest.RequestDate.ToShortDateString() %></span>

                    </td>
                    <td class="cr-header-requestor">
                        <span class="hidden data-label">Requestor</span>
                        <span><%: ChangeRequest.FullName %></span>
                    </td>
                    <td class="cr-header-task">
                        <span class="hidden data-label">Task</span>
                        <span><%= ChangRequestFormattedName() %></span>
                    </td>
                    <td class="cr-header-overview">
                        <span class="hidden data-label">Request Type / Comments</span>
                        <span><%= ChangeRequestOverview() %></span>
                    </td>
                </tr>
            </table>
        </div>
        <div class="float-right cr-header-actions">
            <%if (CanApprove)
                { %>
            <a data-role="approve" title="Approve" class="btn btn-default btn-sm">Approve</a>
            <a data-role="deny" title="Deny" class="btn btn-default btn-sm">Deny</a>
            <% } %>

            <a data-role="cancel" title="Cancel" class="btn btn-default btn-sm">Cancel</a>
            <a data-role="change-view" title="Change/View" class="btn btn-default btn-sm">Change</a>
        </div>
    </div>
    <div class="change-request-body collapsed">

        <%if (CanApprove)
            { %>
        <div class="reply-section">
            <textarea class="reply-comments"></textarea><br />
            <br />
            <input type="button" value="Send Reply Email" data-role="email" class="btn btn-secondary" />
            <input type="hidden" class="email-address" value="<%#ChangeRequest.Email %>" />
            <hr />
        </div>
        <% } %>

        <% if (ChangeRequest.ExtensionDays > 30)
            { %>
        <span style="color: red; font-weight: bold;">*** This task has been extended more than 30 days past its original deadline! ***<br>
        </span>
        <% } %>

        <% if (ChangeRequest.ExtensionCount > 3)
            { %>
        <span style="color: darkred; font-weight: bold;">*** This task has been extended more than 3 times! ***<br>
        </span>
        <% } %>
        <% if (ChangeRequest.DatePassedMessage.Length > 0)
            { %>
        <span style="font-weight: bold; color: darkmagenta;">***<%=ChangeRequest.DatePassedMessage %>***</span>
        <% } %>
        <br />

        Change requested by:
        <label class="details-label"><%:ChangeRequest.FullName%></label><br />
        Change requested on:
        <label class="details-label"><%:ChangeRequest.RequestDate%></label><br />

        <% if (ChangeRequest.Comment.Length > 0)
            { %><br />
        Comment:
        <label class="details-label"><%:ChangeRequest.Comment%></label><% } %>

        <div style="border: 1px solid #a0a0a0; padding: 5px;">
            <h4>Old:</h4>

            <div class="oldTaskDiv">
                <asp:Repeater runat="server" DataSource="<%# ChangeRequest.CurrentAssignments %>" ID="currentAssignmentsRepeater">
                    <ItemTemplate>
                        <span <%# Container.ItemIndex == 0 ? "" : " style='display:none'" %>>
                            <b><%# DataBinder.Eval(Container, "DataItem.ChecklistName")%> </b>
                            <br />
                            <br />
                            Controllers: <%# DataBinder.Eval(Container, "DataItem.Controllers")%><br />
                        </span>
                        <em>Assignment <%# Container.ItemIndex + 1%>: </em>
                        <br />
                        <div style="margin-left: 10px;">
                            Assigned To: <%# DataBinder.Eval(Container, "DataItem.AssigneeList") ?? "(No Assignees)"%><br />
                            Schedule: <%# DataBinder.Eval(Container, "DataItem.ScheduleString") ?? "(No Schedule)"%>
                        </div>
                        <br />
                    </ItemTemplate>
                </asp:Repeater>
                <table>
                    <thead>
                        <tr></tr>
                    </thead>
                    <tbody>
                        <asp:Repeater runat="server" DataSource="<%# ChangeRequest.CurrentChecklistItems %>" ID="currentChecklistRepeater">
                            <ItemTemplate>
                                <tr>
                                    <%#(string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Heading" 
                                            ? "<td colspan=\"2\"><h3>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</h3>"
                                            :(string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Sub Heading"
                                            ? "<td colspan=\"2\"><b><em>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</em>"
                                            : (string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Checkbox"
                                            ? "<td style=\"vertical-align: top;\">&#9744;</td><td>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "")
                                            : (string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Notes"
                                        ? "<td colspan=\"2\"><em>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</em>"
                                        : "<td colspan=\"2\">"
                                    %>

                                    <%#String.IsNullOrWhiteSpace((string)DataBinder.Eval(Container, "DataItem.Url"))
                                    ? ""
                                    : " <a href=\""+DataBinder.Eval(Container, "DataItem.Url")+"\">(More Info)</a>"
                                    %>
                                </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
                <br />
            </div>
        </div>

        <h4>Requested Changes:</h4>

        <table class="changes-table table table-condensed">
            <thead>
                <tr>
                    <th>Change</th>
                    <%if (CanApprove)
                        { %>
                    <th class="approval-column">Approval</th>
                    <% } %>
                </tr>
            </thead>
            <tbody>
                <asp:Repeater runat="server" DataSource="<%# ChangeRequest.ChangedItems%>" ID="changesRepeater">
                    <ItemTemplate>
                        <mytasks:ChangeRequestItemChangeNatural IncludeApprovalIndicator="<%#CanApprove %>" ChangeRequestItem="<%#Container.DataItem as ChangeRequestItem%>" ID="ChangeRequestItem1" runat="server" />
                    </ItemTemplate>
                </asp:Repeater>
            </tbody>
        </table>

        <div style="border: 1px solid #a0a0a0; padding: 5px;">
            <h4>New:</h4>

            <div class="newTaskDiv">
                <% if (ChangeRequest.ChangedItems.Any(i => i.Requested.ToString().StartsWith("Deleting entire checklist")))
                    { %>
                <em>(Checklist Deleted)</em>
                <% }
                    else
                    { %>
                <asp:Repeater runat="server" DataSource="<%# ChangeRequest.RequestedAssignments %>" ID="requestedAssignmentsRepeater">
                    <ItemTemplate>
                        <span <%# Container.ItemIndex == 0 ? "" : " style='display:none'" %>>
                            <b><%# DataBinder.Eval(Container, "DataItem.ChecklistName")%> </b>
                            <br />
                            <br />
                            Controllers: <%# DataBinder.Eval(Container, "DataItem.Controllers")%><br />
                        </span>
                        <em>Assignment <%# Container.ItemIndex + 1%>: </em>
                        <br />
                        <div style="margin-left: 10px;">
                            Assigned To: <%# DataBinder.Eval(Container, "DataItem.AssigneeList") ?? "(No Assignees)"%><br />
                            Schedule: <%# DataBinder.Eval(Container, "DataItem.ScheduleString") ?? "(No Schedule)"%>
                        </div>
                        <br />
                    </ItemTemplate>
                </asp:Repeater>
                <table>
                    <thead>
                        <tr></tr>
                    </thead>
                    <tbody>
                        <asp:Repeater runat="server" DataSource="<%# ChangeRequest.RequestedChecklistItems %>" ID="requestedChecklistRepeater">
                            <ItemTemplate>
                                <tr>
                                <tr>
                                    <%#(string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Heading" 
                                            ? "<td colspan=\"2\"><h3>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</h3>"
                                            :(string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Sub Heading"
                                            ? "<td colspan=\"2\"><b><em>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</em>"
                                            : (string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Checkbox"
                                            ? "<td style=\"vertical-align: top;\">&#9744;</td><td>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "")
                                            : (string) DataBinder.Eval(Container, "DataItem.ItemTypeName") == "Notes"
                                        ? "<td colspan=\"2\"><em>" + (DataBinder.Eval(Container, "DataItem.Text") ?? "") + "</em>"
                                        : "<td colspan=\"2\">"
                                    %>

                                    <%#String.IsNullOrWhiteSpace((string)DataBinder.Eval(Container, "DataItem.Url"))
                                    ? ""
                                    : " <a href=\""+DataBinder.Eval(Container, "DataItem.Url")+"\">(More Info)</a>"
                                    %>
                                </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
                <br />
                <% } %>
            </div>
        </div>

        <span class="sectionWithHeader">
            <h4>Deadline History:</h4>

            <table class="previous-table table table-condensed table-responsive">
                <thead>
                    <tr>
                        <th class="date-column">History</th>
                        <th>Comment</th>
                        <th class="name-column">Requested By</th>
                        <th class="date-column">Requested Date</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptHistory" runat="server">
                        <ItemTemplate>
                            <tr>
                                <td valign="top"><%# DataBinder.Eval(Container, "DataItem.DueTime") %>&nbsp;</td>
                                <td><%# DataBinder.Eval(Container, "DataItem.Comment") %>&nbsp;</td>
                                <td valign="top"><%# DataBinder.Eval(Container, "DataItem.RequestedBy") %>&nbsp;</td>
                                <td valign="top"><%# DataBinder.Eval(Container, "DataItem.RequestDate") %>&nbsp;</td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </span>
    </div>
</div>
