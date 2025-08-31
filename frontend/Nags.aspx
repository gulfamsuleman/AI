<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Nags.aspx.cs" Inherits="Nags" %>
<%@ Import Namespace="QProcess.Extensions" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" Runat="Server">
    <script src="Scripts/jquery-ui-1.10.1.js"></script>
    <script src="Scripts/jquery.ui.timepicker.js"></script>
    <script src="Scripts/common.js?v=<%= Utils.AppendAutoVersion("~/Scripts/common.js")%>" type="text/javascript"></script>
    <script src="Scripts/Nags.js?v=<%= Utils.AppendAutoVersion("~/Scripts/Nags.js")%>" type="text/javascript"></script>
    <link rel="stylesheet" href="Content/<%=Firm %>/Nags.css?v=<%=Utils.AppendAutoVersion($"~/Content/{Firm}/Nags.css")%>"/>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" Runat="Server">
    <div id="SearchContent">
    <input type="hidden" id="filter" />
    <button type="button" class="showAll hidden" title="Clear Filter (Shows All Nags)">Show All</button>
    </div>
    <div id="NagsIReceive">
        <h4>Nags Sent To Me</h4>
        <div class="tableDiv">
            <table class="displayTable bordered">
                <thead>
                    <tr>
                        <th></th>
                        <th>Status</th>
                        <th>Subject</th>
                        <th>From</th>
                        <th>Days of Week</th>
                        <th class="avoidBreaks">Days Of Month</th>
                        <th>Interval</th>
                        <th>Start Time</th>
                        <th>End Time</th>
                        <th>Specific Times</th>
                        <th>Start Date</th>
                        <th>End Date</th>
                    </tr>
                </thead>
                <tbody>
                </tbody>
            </table>
            <table class="rowTemplate">
                <tr>
                    <td>
                        <input type="hidden" name="NagID" />
                        <button type="button" class="remove" title="Remove Me From Nag">Remove</button>
                        <button type="button" class="snooze" title="Don't Nag Me Again Today">Snooze</button>
                        <button type="button" class="playpause" title="Toggle Nag On/Off (Just Me)">Turn On/Off</button>
                    </td>
                    <td><span name="Status"></span></td>
                    <td><span name="Subject"></span></td>
                    <td><span name="From"></span></td>
                    <td><span name="DaysOfWeek"></span></td>
                    <td><span name="DaysOfMonth"></span></td>
                    <td><span name="Interval"></span></td>
                    <td><span name="StartTime"></span></td>
                    <td><span name="EndTime"></span></td>
                    <td><span name="TimesOfDay"></span></td>
                    <td><span name="StartDate"></span></td>
                    <td><span name="EndDate"></span></td>
                </tr>
            </table>
        </div>
    </div>
    <div id="NagsIControl">
        <h4>Nags I Manage</h4>
        <div class="tableDiv">
            <table class="displayTable bordered">
                <thead>
                    <tr>
                        <th></th>
                        <th>Status</th>
                        <th>Subject</th>
                        <th>Days of Week</th>
                        <th class="avoidBreaks">Days Of Month</th>
                        <th>Interval</th>
                        <th>Start Time</th>
                        <th>End Time</th>
                        <th>Specific Times</th>
                        <th>Start Date</th>
                        <th>End Date</th>
                        <th>Recipients</th>
                    </tr>
                </thead>
                <tbody>
                </tbody>
                <tfoot>
                    <tr>
                        <td>
                            <button type="button" class="new" title="Create New Nag">New</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
            <table class="rowTemplate">
                <tr>
                    <td>
                        <input type="hidden" name="NagID" />
                        <button type="button" class="edit" title="Edit Nag">Edit</button>
                        <button type="button" class="delete" title="Delete Nag">Delete</button>
                        <button type="button" class="playpause" title="Toggle Nag On/Off (All Recipients)">Turn On/Off</button>
                    </td>
                    <td><span name="Status"></span></td>
                    <td><span name="Subject"></span></td>
                    <td><span name="DaysOfWeek"></span></td>
                    <td><span name="DaysOfMonth"></span></td>
                    <td><span name="Interval"></span></td>
                    <td><span name="StartTime"></span></td>
                    <td><span name="EndTime"></span></td>
                    <td><span name="TimesOfDay"></span></td>
                    <td><span name="StartDate"></span></td>
                    <td><span name="EndDate"></span></td>
                    <td>
                        <ul name="Recipients" class="nobullet"></ul>
                    </td>
                </tr>
            </table>
        </div>
    </div>
    <div id="nagDetailDialog" class="dialogContent" title="Nag Details">
        <input type="hidden" id="NagID" />
        <h4>Message:</h4>
        <table class="dialogFieldTable">
            <tbody>
                <tr>
                    <th>Subject:</th>
                    <td>
                        <input id="NagSubject" type="text" /></td>
                </tr>
                <tr>
                    <th class="align-top">Body Text:</th>
                    <td>
                        <textarea id="NagBodyText" cols="40" rows="4"></textarea></td>
                </tr>
                <tr>
                    <th>Controller:</th>
                    <td>
                        <select id="NagController"></select>
                    </td>
                </tr>
            </tbody>
        </table>
        <h4>Schedule:</h4>
        <table>
            <tbody>
                <tr>
                    <th>Start Date:</th>
                    <td>
                        <input id="NagStartDate" type="date" /></td>
                    <th>End Date:</th>
                    <td>
                        <input id="NagEndDate" type="date" /></td>
                </tr>
                <th>Schedule Nag For:</th>
                    <td colspan="100">
                        <input type="radio" name="nagOnDays" id="NagMonthlySchedule" />
                        <label for="NagMonthlySchedule">Days of Month</label>
                        <input type="radio" name="nagOnDays" id="NagWeeklySchedule" />
                        <label for="NagWeeklySchedule">Days of Week</label>
                    </td>
                <tr class="monthlySchedRow">
                    <th class="align-top">Monthly Schedules:</th>
                    <td></td>
                </tr>
                <tr class="monthlySchedRow">
                    <td colspan="100">
                        <span class="scrollable-y centerBlock">
                            <table id="NagSchedTable" class="dialogListTable">
                                <tbody></tbody>
                                <tfoot>
                                    <tr>
                                        <td>
                                            <button type="button" class="add" title="Add Schedule">Add</button>
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                        </span>
                    </td>
                </tr>
                <tr class="daysOfWeekRow">
                    <th>Days Of Week:</th>
                    <td colspan="100">
                        <button class="blue noicon" id="DaysOfWeekClear">None</button>
                        <button class="blue noicon" id="DaysOfWeekAll">All</button>
                        <button class="blue noicon" id="DaysOfWeekWeekdays">Weekdays</button>
                        <button class="blue noicon" id="DaysOfWeekMWF">MWF</button>
                        <button class="blue noicon" id="DaysOfWeekTuTh">TuTh</button>
                    </td>
                </tr>
                <tr class="daysOfWeekRow">
                    <th></th>
                    <td colspan="100" class="centerText">
                        <input type="checkbox" id="NagSunday" /><label for="NagSunday">Sunday</label>
                        <input type="checkbox" id="NagMonday" /><label for="NagMonday">Monday</label>
                        <input type="checkbox" id="NagTuesday" /><label for="NagTuesday">Tuesday</label>
                        <input type="checkbox" id="NagWednesday" /><label for="NagWednesday">Wednesday</label>
                        <br />
                        <input type="checkbox" id="NagThursday" /><label for="NagThursday">Thursday</label>
                        <input type="checkbox" id="NagFriday" /><label for="NagFriday">Friday</label>
                        <input type="checkbox" id="NagSaturday" /><label for="NagSaturday">Saturday</label>
                    </td>
                </tr>
                <tr>
                    <th>Schedule Type:</th>
                    <td colspan="100">
                        <input type="radio" name="nagScheduleType" id="NagScheduleInterval" />
                        <label for="NagScheduleInterval">Interval</label>
                        <input type="radio" name="nagScheduleType" id="NagScheduleSpecific" />
                        <label for="NagScheduleInterval">Specific Times</label>
                    </td>
                </tr>
                <tr class="intervalRow">
                    <th>Interval:</th>
                    <td colspan="100">
                        <input type="number" id="NagInterval" />
                         minutes (Must be multiple of 5)</td>
                </tr>
                <tr class="intervalRow">
                    <th>Start Time Of Day:</th>
                    <td colspan="100">
                        <input id="NagStartTime" type="time" /></td>
                </tr>
                <tr class="intervalRow">
                    <th>End Time Of Day:</th>
                    <td colspan="100">
                        <input id="NagEndTime" type="time" /></td>
                </tr>
                <tr class="specificRow">
                    <th class="align-top">Specific Times:</th>
                    <td></td>
                </tr>
                <tr class="specificRow">
                    <td colspan="100">
                        <span class="scrollable-y centerBlock">
                            <table id="NagTimeTable" class="dialogListTable">
                                <tbody></tbody>
                                <tfoot>
                                    <tr>
                                        <td>
                                            <button type="button" class="add" title="Add Time">Add</button>
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                        </span>
                    </td>
                </tr>
            </tbody>
        </table>
        <table class="rowTemplate" id="nagTimeTemplate">
            <tr>
                <td>
                    <button type="button" class="remove" title="Remove Time">Remove</button>
                </td>
                <td>
                    <input type="time" /></td>
            </tr>
        </table>
        <table class="rowTemplate" id="nagSchedTemplate">
            <tr>
                <td>
                    <button type="button" class="remove" title="Remove Schedule">Remove</button>
                </td>
                <td>
                    <input type="hidden"/>
                    <select class="ordinalSelect"></select> 
                    <select class="daySelect"></select> of 
                    <select class="monthSelect"></select> 
                    <span class="nMonth">(<input type="number" class="nMonthInput"/>)</span>
                </td>
            </tr>
        </table>
        <h4>Recipients:</h4>
        <div class="scrollable-y centerBlock">
            <table id="NagRecipientTable" class="dialogListTable">
                <tbody></tbody>
                <tfoot>
                    <tr>
                        <td>
                            <button type="button" class="add" title="Add Recipient">Add</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </div>
        <table class="rowTemplate" id="nagUserTemplate">
            <tr>
                <td>
                    <button type="button" class="remove" title="Remove Recipent">Remove</button>
                </td>
                <td>
                    <select name="Recipient"></select>
                </td>
            </tr>
        </table>
        <br />
        <button type="button" class="save" title="Save Nag">Save</button>
        <button type="button" class="delete" title="Delete Nag">Delete</button>
    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" Runat="Server">
</asp:Content>

<!-- Copyright © 2024 Renegade Swish, LLC -->

