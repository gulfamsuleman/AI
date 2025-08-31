<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Export.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_Export" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="export-panel">
	<table id="export-table" class="hidden">
		<thead><tr>
			<th></th>
			<th>Report</th>
			<th>Include Archive?</th>
		</tr></thead>
		<tbody></tbody>
	</table>
	<button data-role="all-reports">Check All Reports</button>
	<button data-role="all-archives">Check All Archives</button>
	<table id="export-options">
		<thead>
			<tr>
				<th></th>
				<th>From:</th>
				<th>To:</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td>Task Due Date Range:</td>
				<td><input id="due-date-from" data-role="datepicker"/></td>
				<td><input id="due-date-to" data-role="datepicker"/></td>
			</tr>
			<tr>
				<td>Comment Range:</td>
				<td><input id="comment-date-from" data-role="datepicker"/></td>
				<td><input id="comment-date-to" data-role="datepicker"/></td>
			</tr>
		</tbody>
	</table>
	<span>Exclude General Comments<input id="exclude-general" type="checkbox"/></span>
	<p>
		<span><input id="excel-export" name="export-choice" type="radio" value="msexcel" checked="checked"/>Excel</span>
		<span><input id="word-export" name="export-choice" type="radio" value="msword"/>Word</span>
	</p>
	
	<button data-role="export" disabled>Go</button>
</div>

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/StatusExport.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

