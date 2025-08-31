<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Calendar.aspx.cs" Inherits="QProcess.Calendar" MasterPageFile="Site.master"%>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="QProcess.Extensions" %>
<%@ Register TagPrefix="calendar" TagName="DayOfWeek" Src="~/Controls/Calendar/CalendarDayOfWeek.ascx" %>
<%@ Reference Control="~/Controls/Calendar/OverdueCalendarDay.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Calendar.css?<%=Utils.AppendAutoVersion($"Content/Calendar.css")%>" rel="stylesheet" />
	<link href="Content/calendar-datepicker.css?<%=Utils.AppendAutoVersion($"Content/calendar-datepicker.css")%>" rel="stylesheet" />    
    <script type="text/javascript" src="Scripts/common.js"></script>    
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/caldate.js?<%= Utils.AppendAutoVersion("Scripts/caldate.js")%>"></script>
    <script src="Scripts/common.js?<%= Utils.AppendAutoVersion("Scripts/common.js")%>"></script>
	<script src="Scripts/jquery.lw-datepicker.calendar.js?<%= Utils.AppendAutoVersion("Scripts/jquery.lw-datepicker.calendar.js")%>"></script>
    <script src="Scripts/Calendar.js?<%= Utils.AppendAutoVersion("Scripts/Calendar.js")%>"></script>
    
    <script type="text/javascript">
        $(document).ready(function () {
            resize();
            window.onresize = resize;
        });

        function resize() {
            $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
            $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        }
    </script>
    <style>        
        #calendar {
            min-width: 1000px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <input type="hidden" id="filterMask" value="<%=FilterMask %>"/>
	<div id="calendar" style="min-width: 1200px; padding-right:10px;">
         <div><input type="button" style="margin-bottom:5px;margin-top:5px;" value="Get Task Extensions" onclick="GetQuickDeadlineExtensions()" /></div> <%--added by venkat 10/31/2017--%>
		<div class="row">
            <table class="standard">
                <tr>
                    <td style="width:296px; padding-right: 20px">
				        <div id="date-selection-calendar">
					        <input data-role="calendar" type="hidden" value="<%= SelectedDate.ToShortDateString() %>"/>
				        </div>
				        <ul id="legend" class="list-unstyled">
					        <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-male"></i> - My Task</li>
					        <li><input type="checkbox" data-action="toggleControl" checked="checked"/>&nbsp;<i class="fa fa-users"></i> - Task I Control</li>
					        <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-forward"></i> - Extension Requested</li>
                            <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-envelope"></i> - Email Alert Scheduled</li>
                            <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-window-close"></i> - Email Alert Muted</li>
					        <li><span class="checkSpacer"></span>&nbsp;<i class="fa fa-refresh"></i> - Recurring Task</li>
				            <li class="blue bold"><input type="checkbox" data-action="toggleActive" checked="checked"/> Active Task</li>
                            <li class="green"><input type="checkbox" data-action="toggleSoft" checked="checked"/> Soft Deadlines</li>
                            <li class="green bold"><input type="checkbox" data-action="toggleSoftReminder" checked="checked"/> Recurring Soft Deadlines</li>
					        <li class="red bold"><input type="checkbox" data-action="toggleOverdue" checked="checked"/> Overdue Task</li>
                            <li class="lightblue bold"><input type="checkbox" data-action="toggleAlerts"/> Alert Emails</li>
                            <li class="grey strikethrough"><input type="checkbox" data-action="toggleCompleted"/> Completed Tasks</li>
					        
					        <li class="grey italic"><input type="checkbox" data-action="toggleFuture" checked="checked"/> Future Task - Not Yet Active</li>
				        </ul>
                         <div style="visibility:<%=PrintVisiblity%>"> <%--added by venkat--%>
                         <input type="button" value="Print" onclick="ShowPrintPopUP()" />
                        </div>
				        <div id="assignment-filter">
					        <select data-role="assignees" class="form-control input-sm" multiple="multiple">
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
						<div id="overdue-panel">
							<asp:PlaceHolder runat="server" ID="phOverdue"></asp:PlaceHolder>
						</div>
                    </td>
                    <td class="pad5">
                        <table class="standard calendarBlock" border="1">
                            <tr>
                                <td class="<%= DayOfWeek1.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek1" runat="server"/></td>
                                <td class="<%= DayOfWeek4.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek4" runat="server"/></td>
                            </tr>
                            <tr>
                                <td class="<%= DayOfWeek2.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek2" runat="server" /></td>
                                <td class="<%= DayOfWeek5.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek5" runat="server"/></td>
                            </tr>
                            <tr>
                                <td class="<%= DayOfWeek3.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek3" runat="server"/></td>
                                <td class="<%= DayOfWeek6.BackgroundStyle %>" ondragover="calendarModule.itemAllowDrop(event)" ondrop="calendarModule.itemDrop(event)"><calendar:DayOfWeek ID="DayOfWeek6" runat="server"/></td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
		</div>
	</div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


