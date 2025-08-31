<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TaskEditPanel.ascx.cs" Inherits="QProcess.Controls.Controls_ManageTasks_TaskEditPanel" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Register TagPrefix="uc1" TagName="ChecklistItemsPanel" Src="~/Controls/Shared/ChecklistItemsPanel.ascx" %>
<%@ Register TagPrefix="uc1" TagName="ControllersPanel" Src="~/Controls/Shared/ControllersPanel.ascx" %>
<%@ Register Src="~/Controls/ManageTasks/AssignmentPanel.ascx" TagPrefix="uc1" TagName="AssignmentPanel" %>

<div id="task-container" class="row" data-checklist-id="<%:TaskId %>" data-change-id="<%: ChangeId %>">
    <div class="col-xs-12">
        <div class="panel panel-default main-panel">
            <div class="panel-heading main-heading">
                <span class="actions">
                    <a data-role="delete-checklist">
                        <img id="Img1" src="/Images/delete.gif" title="Remove" runat="server" style="margin-top: -3px;" /></a>
                    <a data-role="copy-checklist">
                        <img id="Img2" src="/Images/copy.gif" title="Copy" runat="server" style="margin-top: -3px;" /></a>
                </span>
                <h3 class="panel-title" data-role="checklist-header"><%:ChecklistName %></h3>
                <span class="view-controls text-right">
                    <a data-role="expand-all">
                        <img id="Img3" src="/Images/plus.gif" runat="server" /></a>
                    <a data-role="collapse-all">
                        <img id="Img4" src="/Images/minus.gif" runat="server" /></a>
                </span>
            </div>
            <div class="panel-body main-body">
                <div class="mtform-naming panel panel-default collapsible-item" data-collapse-state="collapsed">
                    <div class="panel-heading" data-collapse-target="true">
                        <span class="actions"><i class='fa fa-plus-square-o' data-role='expand-indicator'></i></span>
                        <h3 class="panel-title">Naming</h3>
                    </div>
                    <div id="name-panel" class="panel-body collapsed">
                        <div class="form-inline">
                            <input type="text" value="<%:ChecklistName %>" class="form-control input-sm input-name" />
                            <a data-role="save" id="save-name-icon" title="Save" class="btn btn-default btn-xs" style="line-height: 21px;">
                                <img src="/Images/save_sm.gif" />
                                Save</a>
                        </div>
                    </div>
                </div>
                <div class="mtform-controllers panel panel-default collapsible-item" data-collapse-state="collapsed">
                    <div class="panel-heading" data-collapse-target="true">
                        <span class="actions"><i class='fa fa-plus-square-o' data-role='expand-indicator'></i></span>
                        <h3 class="panel-title">Controllers</h3>
                    </div>
                    <div class="panel-body collapsed">
                        <uc1:ControllersPanel runat="server" ChecklistId="<%#TaskId %>" ID="ControllersPanel" ChangeId="<%# ChangeId %>" />
                    </div>
                </div>
                <div class="mtform-items panel panel-default collapsible-item" data-collapse-state="collapsed">
                    <div class="panel-heading" data-collapse-target="true">
                        <span class="actions"><i class='fa fa-plus-square-o' data-role='expand-indicator'></i></span>
                        <h3 class="panel-title">Items</h3>
                    </div>
                    <div class="panel-body collapsed">
                        <uc1:ChecklistItemsPanel runat="server" ChecklistId="<%#TaskId %>" ID="ChecklistItemsPanel" ChangeId="<%# ChangeId %>" />
                    </div>
                </div>
                <asp:Repeater ID="AssignmentRepeater" DataSource="<%# MyInstances %>" runat="server">
                    <ItemTemplate>
                        <uc1:AssignmentPanel runat="server" InstanceId='<%# DataBinder.Eval(Container.DataItem, "ID") %>' UserId="<%#UserId %>" AssignmentNumber="<%# ++AssignmentNumber %>" ID="AssignmentPanel" ChangeId="<%# ChangeId %>"></uc1:AssignmentPanel>
                    </ItemTemplate>
                </asp:Repeater>
                <h4 data-role="add-assignment-header" style="margin-top: 20px;"><i class="fa fa-plus" data-role="add-assignment"></i>Add an assignment.</h4>
                <a class="btn btn-xs btn-default" title='History' data-action="view-history" data-checklist-id="<%: TaskId %>" style="cursor: pointer;">
                    <i class="fa fa-history light-blue"></i>History
                </a>
                <asp:Panel ID="pnlSendRequest" runat="server">
                    Comments:
                    <textarea data-role="change-comments" style="width: 100%; height: 100px;"></textarea>
                    <br />
                    <button data-role="send-request" type="button" value="Request Change" class="btn-default">Request Change</button>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					<button data-role="cancel-request" type="button" value="Cancel Change" class="btn-default">Cancel Change</button>
                </asp:Panel>
                <asp:Panel ID="pnlApproval" runat="server" Visible="False">
                    <button data-role="approve-request" type="button" value="Approve" class="btn-default">Approve</button>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					<button data-role="reject-request" type="button" value="Deny" class="btn-default">Deny</button>
                </asp:Panel>
            </div>
        </div>
    </div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

