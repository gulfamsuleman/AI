<%@ Control Language="C#" AutoEventWireup="true" Codebehind="SchedulingPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_SchedulingPanel" %>
<div class="scheduling-panel" data-status='<%=SerializedSchedule() %>'>
    <input type="hidden" class="schedule-user-id" value="<%=User.Id %>" />
	<div class="form-inline">
		<div class="task-type-panel">
			<span class="scheduling-note"><b>Note--to save scheduling changes, you must use this button: </b></span>
            <a data-role="save" id="scheduling-save" class="btn btn-default btn-sm" ><img id="Img1" src="/Images/save_sm.gif" runat="server" /> Save</a><br />
			<p>One time or recurring task?
			<select data-item="recurring" class="form-control input-sm">
				<option value="once">one time</option>
				<option value="recurring">recurring</option>
			</select>
			<select name="dtz-resize" style="display: none">
				<option name="dtz-resize-option" selected></option>
			</select>
			</p>
		</div>
		<div class="single-task-panel">
			<p>Due On: 
			<input data-role="datepicker" name="due-on" class="input-sm input-date"/>
				at 
			<select class="form-control input-sm" name="due-time">
				<asp:repeater ID="Repeater1" DataSource=<%# TimeOptions %> runat="server">
					<itemtemplate>
						<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
					</itemtemplate>
				</asp:repeater>
			</select>&nbsp;
				<% if (User.MyTimeZone.LastTimeZone != "America/Chicago" || User.MyTimeZone.TimeZoneOverride != "America/Chicago")
					{ %>
				<select name="due-time-zone" class="form-control input-sm">
				<asp:repeater ID="Repeater4" DataSource=<%# TimeZoneOptions %> runat="server">
					<itemtemplate>
						<option <%#Container.ItemIndex < QProcess.Domain.SYSTEM.TimeZoneHelper.CommonTimeZones.Count ? "style='font-weight:bold'" : "" %> value=<%#Eval("Key") %><%#MySchedule.TimeZone == Eval("Key").ToString() ? " selected=\"selected\"" : "" %> ><%#Eval("Value") %></option>
						<%#Container.ItemIndex == QProcess.Domain.SYSTEM.TimeZoneHelper.CommonTimeZones.Count - 1 ? "<option disabled value=''>-----</option>" : "" %>
					</itemtemplate>
				</asp:repeater>
			</select>
				<% } %>
			</p>
            <p>Soft Due: <input data-role="datepicker" name="soft-due" class="input-sm input-date"/></p>
		</div>
		<div class="recurring-task-panel hidden">
			<p>How often should the task be completed?
			<select data-item="recurrence-type" class="form-control input-sm">
				<option value="2" <%: MySchedule.FrequencyType <= 2 || MySchedule.FrequencyType > 6 ? "selected=\"selected\"" : "" %>>Daily</option>
				<option value="3" <%: MySchedule.FrequencyType == 3 ? "selected=\"selected\"" : "" %>>Weekly</option>
				<option value="4" <%: MySchedule.FrequencyType == 4 ? "selected=\"selected\"" : "" %>>Monthly</option>
				<option value="6" <%: MySchedule.FrequencyType == 6 ? "selected=\"selected\"" : "" %>>Quarterly</option>
				<option value="5" <%: MySchedule.FrequencyType == 5 ? "selected=\"selected\"" : "" %>>Yearly</option>
			</select></p>
			<div class="daily-recurring-panel hidden">
				<p>Every <input type="text" name="freq-recurrence" class="form-control input-sm" style="max-width:35px;"/> Day(s)</p>
			</div>
			<div class="weekly-recurring-panel hidden">
				<p>Every <input type="text" name="freq-recurrence" value="1" class="form-control input-sm" style="max-width:35px;"/> Week(s) on:</p>
				<div class="row">
				<div class="col-xs-4">
					<div class="checkbox"><label><input data-val="1" name="weekday" type="checkbox"/> Sunday </label></div>
					<div class="checkbox"><label><input data-val="2" name="weekday" type="checkbox"/> Monday </label></div>
					<div class="checkbox"><label><input data-val="4" name="weekday" type="checkbox"/> Tuesday </label></div>
					<div class="checkbox"><label><input data-val="8" name="weekday" type="checkbox"/> Wednesday </label></div>
				</div>
				<div class="col-xs-4">
					<div class="checkbox"><label><input data-val="16" name="weekday" type="checkbox"/> Thursday </label></div>
					<div class="checkbox"><label><input data-val="32" name="weekday" type="checkbox"/> Friday </label></div>
					<div class="checkbox"><label><input data-val="64" name="weekday" type="checkbox"/> Saturday </label></div>
				</div>
				</div>
				<p></p>
			</div>
			<div class="monthly-recurring-panel hidden">
				<p>Every <input type="text" name="freq-recurrence" class="form-control input-sm" style="max-width:35px;"/> Month(s)</p>
			</div>
			<div class="yearly-recurring-panel hidden">
				<p>Every <input type="text" name="freq-recurrence" value="1" class="form-control input-sm" style="max-width:35px;"/> Year(s) on:</p>
				<div class="row">
					<div class="col-xs-4">
						<div class="checkbox"><label><input data-val="1" name="month" type="checkbox"/> January </label></div>
						<div class="checkbox"><label><input data-val="2" name="month" type="checkbox"/> February </label></div>
						<div class="checkbox"><label><input data-val="4" name="month" type="checkbox"/> March </label></div>
						<div class="checkbox"><label><input data-val="8" name="month" type="checkbox"/> April </label></div>
						<div class="checkbox"><label><input data-val="16" name="month" type="checkbox"/> May </label></div>
						<div class="checkbox"><label><input data-val="32" name="month" type="checkbox"/> June </label></div>
					</div>
					<div class="col-xs-4">
						<div class="checkbox"><label><input data-val="64" name="month" type="checkbox"/> July </label></div>
						<div class="checkbox"><label><input data-val="128" name="month" type="checkbox"/> August </label></div>
						<div class="checkbox"><label><input data-val="256" name="month" type="checkbox"/> September </label></div>
						<div class="checkbox"><label><input data-val="512" name="month" type="checkbox"/> October </label></div>
						<div class="checkbox"><label><input data-val="1024" name="month" type="checkbox"/> November </label></div>
						<div class="checkbox"><label><input data-val="2048" name="month" type="checkbox"/> December </label></div>
					</div>
				</div>
				<p></p>
			</div>
			<div class="recurring-task-details-panel">
				<div>How will the schedule be affected by weekends and holidays?
					<div class="radio"><label><input type="radio" data-item='weekend-fallback' name="weekend-fallback<%=InstanceId.ToString() %>" value="0" checked="checked"/> This task can be due on a weekend/holiday</label></div>
					<div class="radio"><label><input type="radio" data-item='weekend-fallback' name="weekend-fallback<%=InstanceId.ToString() %>" value="1"/> If it falls on a weekend or holiday, <strong>skip it</strong></label></div>
					<div class="radio"><label><input type="radio" data-item='weekend-fallback' name="weekend-fallback<%=InstanceId.ToString() %>" value="2"/> If it falls on a weekend or holiday, move it to the <strong>previous</strong> business day</label></div>
					<div class="radio"><label><input type="radio" data-item='weekend-fallback' name="weekend-fallback<%=InstanceId.ToString() %>" value="3"/> If it falls on a weekend or holiday, move it to the <strong>next</strong> business day</label></div>
					<div class="radio bus-day-month hidden"><label><input type="radio" data-item='weekend-fallback' name="weekend-fallback<%=InstanceId.ToString() %>" value="4"/></label> Use business days, 
                            <select name="bus-day-val" style="display: inline-block; float: none; vertical-align: middle">
                                <option value="1">1st</option>
                                <option value="2">2nd</option>
                                <option value="3">3rd</option>
                                <option value="4">4th</option>
                                <option value="5">5th</option>
                                <option value="6">6th</option>
                                <option value="7">7th</option>
                                <option value="8">8th</option>
                                <option value="9">9th</option>
                                <option value="10">10th</option>
                                <option value="11">11th</option>
                                <option value="12">12th</option>
                                <option value="13">13th</option>
                                <option value="14">14th</option>
                                <option value="15">15th</option>
                                <option value="16">16th</option>
                                <option value="17">17th</option>
                                <option value="18">18th</option>
                                <option value="19">19th</option>
                                <option value="20">20th</option>
                            </select> 
                        business day of the month</div>
				</div>
				<p>First Due Date <input data-item="first-date" type="text" class="input-sm input-date" data-role="datepicker" value="<%:QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.AddDays(1).ToString("d") %>"/></p>
				<p>Final Due Date <input data-item="last-date" type="text" class="input-sm input-date" data-role="datepicker"/></p>
				<p>The task must be completed by 
				<select data-item="due-time" class="form-control input-sm">
					<asp:repeater ID="Repeater2" DataSource=<%# TimeOptions %> runat="server">
						<itemtemplate>
							<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
						</itemtemplate>
					</asp:repeater>
				</select>&nbsp;
					<select data-item="due-time-zone" class="form-control input-sm">
					<asp:repeater ID="Repeater3" DataSource=<%# TimeZoneOptions %> runat="server">
						<itemtemplate>
							<option <%#Container.ItemIndex < QProcess.Domain.SYSTEM.TimeZoneHelper.CommonTimeZones.Count ? "style='font-weight:bold'" : "" %> value=<%#Eval("Key") %><%#MySchedule.TimeZone == Eval("Key").ToString() ? " selected=\"selected\"" : "" %> ><%#Eval("Value") %></option>
							<%#Container.ItemIndex == QProcess.Domain.SYSTEM.TimeZoneHelper.CommonTimeZones.Count - 1 ? "<option disabled value=''>-----</option>" : "" %>
						</itemtemplate>
					</asp:repeater>
				</select>
				</p>
				<p>Soft due date should be <input type="text" data-item="soft-due" class="form-control input-sm" style="max-width:35px;"/> days before the due date.</p>
			</div>
		</div>
	</div>
</div>

<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector ID="DOMInjector1" runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/SchedulingPanel.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/SchedulingPanel.js")).Ticks.ToString() %>"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

