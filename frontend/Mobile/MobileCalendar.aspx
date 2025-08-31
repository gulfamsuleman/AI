<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileCalendar.aspx.cs" Inherits="QProcess.Mobile.MobileCalendar" MasterPageFile="Mobile.Master" %>

<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="QProcess.Extensions" %>
<%@ Register TagPrefix="calendar" TagName="DayOfWeek" Src="~/Controls/Calendar/CalendarDayOfWeek.ascx" %>
<%@ Reference Control="~/Controls/Calendar/OverdueCalendarDay.ascx" %>

<asp:Content runat="server" ID="head" ContentPlaceHolderID="headContent">
    <link href="/Content/Calendar.css?<%=Utils.AppendAutoVersion($"/Content/Calendar.css")%>" rel="stylesheet" />    
    <link href="/Content/calendar-datepicker.css?<%=Utils.AppendAutoVersion($"/Content/calendar-datepicker.css")%>" rel="stylesheet" />
    <link href="/Content/MobileCalendar.css?<%=Utils.AppendAutoVersion($"/Content/MobileCalendar.css")%>" rel="stylesheet" />
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.14.0/themes/base/jquery-ui.css">
    <script type="text/javascript">
        var mobileTitle = "Calendar";

        var calendarPage = {
            queryDate: "<%=Request.QueryString["date"]%>"
        }
    </script>
    <style>
    #date-selection-calendar {
	    margin-top: revert; /* for some reason lw-datepicker add top:5px to the control, this is to offset that */
	    margin-bottom: revert;
    }
    </style>
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="/Scripts/caldate.js?<%=Utils.AppendAutoVersion($"/Scripts/caldate.js")%>"></script>
    <script src="/Scripts/MobileCalendar.js?<%=Utils.AppendAutoVersion($"/Scripts/MobileCalendar.js")%>"></script>
    <script src="/Scripts/jquery.lw-datepicker.calendar.js?<%=Utils.AppendAutoVersion($"/Scripts/jquery.lw-datepicker.calendar.js")%>"></script>
</asp:Content>

<asp:Content runat="server" ID="main" ContentPlaceHolderID="formContent">
    <input type="hidden" id="filterMask" value="<%=FilterMask %>"/>
    <div class="accordion" id="calendarAccordion">
        <h2>Calendar
        </h2>
        <div class="panel-content" id="date-selection-calendar">
            <input data-role="calendar" type="hidden" value="<%= DateTime.UtcNow.ToShortDateString() %>" />
        </div>
        <h2>Legend
        </h2>
        <div class="panel-content" id="legend-container">
            <ul id="legend" class="list-unstyled">
                <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-male"></i> - My Task</li>
                <li>
                    <input type="checkbox" data-action="toggleControl" checked="checked" />
                    &nbsp;<i class="fa fa-users"></i> - Task I Control
                </li>
                <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-forward"></i> - Extension Requested</li>
                <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-envelope"></i> - Email Alert Scheduled</li>
                <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-window-close"></i> - Email Alert Muted</li>
                <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-refresh"></i> - Recurring Task</li>
                <li class="blue bold">
                    <input type="checkbox" data-action="toggleActive" checked="checked" />
                    Active Task</li>
                <li class="green">
                    <input type="checkbox" data-action="toggleSoft" checked="checked" />
                    Soft Deadlines</li>
                <li class="green bold">
                    <input type="checkbox" data-action="toggleSoftReminder" checked="checked" />
                    Recurring Soft Deadlines
                </li>
                <li class="red bold">
                    <input type="checkbox" data-action="toggleOverdue" checked="checked" />
                    Overdue Task</li>
                <li class="lightblue bold">
                    <input type="checkbox" data-action="toggleAlerts" />
                    Alert Emails</li>
                <li class="grey strikethrough">
                    <input type="checkbox" data-action="toggleCompleted" />
                    Completed Tasks</li>

                <li class="grey italic">
                    <input type="checkbox" data-action="toggleFuture" checked="checked" />
                    Future Task - Not Yet Active</li>
            </ul>

            <div id="assignment-filter">
                <select data-role="assignees" class="form-control input-sm">
                    <asp:repeater ID="Repeater1" DataSource=<%# Assignees %> runat="server">
				        <ItemTemplate>
					        <option value="<%#Eval("Id") %>" 
						        <%# ShowStatus ?
                            ("*" + AssigneeIds == (string)Eval("Id") ? "selected='selected'" : "")
                            :(AssigneeIds.Any(a=>a==int.Parse((string)Eval("Id"))) ? "selected='selected'" : "") %>>
						        <%#Eval("Name") %>
					        </option>
				        </ItemTemplate>
                    </asp:repeater>
                </select>
            </div>
        </div>

    </div>    
    <div class="<%= DayOfWeek1.BackgroundStyle %> task-panel">
        <calendar:DayOfWeek ID="DayOfWeek1" runat="server" />
    </div>

    <input type="hidden" id="user-full-name" value="<%=CurrentSession.QUser.FullName%>" />

    
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

