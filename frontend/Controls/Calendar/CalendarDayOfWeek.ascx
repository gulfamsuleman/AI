<%@ Control Language="C#" AutoEventWireup="true" Codebehind="CalendarDayOfWeek.ascx.cs" Inherits="QProcess.Controls.Controls_Calendar_CalendarDayOfWeek" %>
<%@ Import Namespace="QProcess.Repositories" %>

<div class="day-of-week-panel white <%= BackgroundStyle %>" data-date="<%= WeekDate.ToShortDateString() %>">
    <div class="day-of-week">
        <%= WeekDate.ToString("dddd, MMMM, d") %>
    </div>
    <div class="checklist-list">
        <asp:Repeater ID="Repeater1" runat="server">
            <ItemTemplate>
                <div class="dayofweekDiv">
                    <a style="display: inline;" href="#" 
                        onclick="return calendarModule.itemClicked($(this), <%#Eval("Id") %>, '<%#Eval("TaskStage") %>', <%#Eval("IsAlert").ToString().ToLower() %>, <%#Eval("IsEmailScheduled").ToString().ToLower() %>)"
                        draggable="<%#(bool)Eval("Active") && !(bool)Eval("IsAlert") && Eval("TaskStage").ToString() == "Current"%>" 
                        ondragstart="calendarModule.itemDragStart(event)" 
                        data-id="<%#Eval("ChecklistId") %>" data-type="<%#Eval("TaskStage") %>"
                        data-alert-id="<%#Eval("AlertId") %>"
                        data-unique-id="<%#Eval("Id") %>"
                        data-date="<%#GetDisplayDate((CalendarChecklist)Container.DataItem)%>"                        
                        data-upcoming-id="<%# GetUpcomingID((TaskStage)Eval("TaskStage"), (int)Eval("Id")) %>"
                        data-active-checklist-id="<%# GetActiveChecklistID((TaskStage)Eval("TaskStage"), (int)Eval("Id")) %>"
                        class="<%# GetLinkStyle((bool) Eval("Active"), (DateTime) Eval("DueTime"), (DateTime) Eval("ReminderDate"), (TaskStage)Eval("TaskStage"),
						(((DateTime)Eval("ReminderDate")).Date == WeekDate.Date && ((DateTime)Eval("DueTime")).Date != WeekDate.Date) 
                        ||  ((DateTime)Eval("ReminderDate")).Date != DateTime.MinValue 
                            && ((DateTime)Eval("ReminderDate")).Date < WeekDate.Date && ((DateTime)Eval("DueTime")).Date > WeekDate.Date, (bool)Eval("IsAlert")) %>">
                        <%#GetDisplayDate((CalendarChecklist)Container.DataItem).ToShortTimeString() %>
                        <span id="images">
                            <%# (bool)Eval("IsManager") ? "<i class='fa fa-users'></i>" : "" %>
                            <%# (bool)Eval("IsAssigned") ? "<i class='fa fa-male'></i>" : "" %>
                            <%# (bool)Eval("IsEmailScheduled") ? "<i class='fa fa-envelope'></i>" : "" %>
                            <%# !(bool)Eval("IsEmailScheduled") && (bool)Eval("IsAlert") ? "<i class='fa fa-window-close'></i>" : "" %>
                            <%# (bool)Eval("IsRecurring") ? "<i class='fa fa-refresh'></i>" : "" %>
                            <%# (bool)Eval("IsNA") ? "<span class='IsNA'>[N/A]</span>" : "" %>
                        </span>
                        <span class="itemName" draggable="<%#(bool)Eval("Active") && !(bool)Eval("IsAlert") && Eval("TaskStage").ToString() == "Current"%>" 
                        ondragstart="calendarModule.itemDragStart(event)" ><%#Eval("ChecklistName") %></span>
                        <span id="pending-change">
                            <%# (bool)Eval("PendingChange") ? "<i class='fa fa-forward' " +
							"title='A new deadline of " + ((DateTime)Eval("NewDeadline")).ToShortDateString() + " " + ((DateTime)Eval("NewDeadline")).ToShortTimeString()
														  + " has been requested for this task'></i>" : "" %>
                        </span>
                    </a>
                </div>
            </ItemTemplate>
        </asp:Repeater>
    </div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

