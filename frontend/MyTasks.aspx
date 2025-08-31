<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="MyTasks.aspx.cs" Inherits="QProcess.MyTasks" MasterPageFile="Site.master"%>

<%@ Register TagPrefix="mytasks" TagName="Checklist" Src="~/Controls/Shared/Checklist.ascx" %>
<%@ Register TagPrefix="mytasks" TagName="ChecklistHeader" Src="~/Controls/Shared/ChecklistHeader.ascx" %>

<asp:Content runat="server" ContentPlaceHolderID="HeadContent">
	<link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet">
	<link href="Content/MyTasks.css?v=4" rel="stylesheet" />
	<link href="Content/jquery.validity.css" rel="stylesheet" />
    <style type="text/css">
        .filters-controls .form-group input[type=text] {
            width: 80px;
            border: 1px solid black;
            padding: 1px 2px;
        }

        .filters-controls button.btn {
            padding: 2px 8px;
            color: black;
            font-weight: bold;
            border: 1px solid black;
        }
	</style>
</asp:Content>

<asp:Content runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
	<script src="Scripts/MyTasks.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/MyTasks.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/jquery.validity.js"></script>
	<script type="text/javascript">
		$.validity.setup({ outputMode: "summary" });
		$(function () {
			$("form").validity(function () {
				$("#start-date")
					.require()
					.match("date")
					.range(new Date(1753, 1, 1), new Date(9999, 12, 31));
				$("#end-date")
					.require()
					.match("date")
					.range(new Date(1753, 1, 1), new Date(9999, 12, 31));
			});
		});

		var acID = "<%=AcID%>";

	    $(document).ready(function () {
	        resize();
	        window.onresize = resize;
	        if (acID > 0) {
	        	$("div[data-unique-id=" + acID + "] i.fa-plus-square-o").click();
	        }
		});
				
        function resize() {
            $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
            $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        }
    </script>
</asp:Content>

<asp:Content runat="server" ContentPlaceHolderID="MainContent">
	<div class="filters-bar panel panel-default row">
		<div class="panel-body">
			<div class="filters-actions" style="margin-bottom: 5px;">
				<a data-role="collapse-all"><img src="~/Images/minus.gif" style="width: 16px; height: 16px; margin: 0 3px 1px 0;" runat="server"/></a>
				<a data-role="expand-all"><img src="~/Images/plus.gif" style="width: 16px; height: 16px; margin: 0 3px 1px 0;" runat="server"/></a>
				<a data-role="excel-export"><img src="~/Images/excel.gif" style="width: 16px; height: 16px; margin: 2px 2px 0 0" runat="server"/></a>
				<a data-role="save-all"><img src="~/Images/save_sm.gif" runat="server" style="width: 16px; height: 16px; margin-bottom: 1px;"/></a>
			</div>
			<div class="filters-controls">
				<form action="MyTasks.aspx" method="post" class="form-inline" role="form">
					<div class="form-group">
						<select id="task-recurrance" name="recurrance" class="form-control input-sm">
							<option value="0" <%= RecurrenceValue == 0 ? "selected" : "" %>>All</option>
							<option value="1" <%= RecurrenceValue == 1 ? "selected" : "" %>>One Time</option>
							<option value="2" <%= RecurrenceValue == 2 ? "selected" : "" %>>Recurring</option>
							<option value="3" <%= RecurrenceValue == 3 ? "selected" : "" %>>Open</option>
						</select>
					</div>
					<div class="form-group">
						<label for="start-date">Tasks with due date between</label>
						<input id="start-date" type="text" class="form-control input-sm" data-role="datepicker" name="start-date" value="<%=StartDateString %>"/>
					</div>
					<div class="form-group">
						<label for="end-date">and</label>
						<input id="end-date" type="text" class="form-control input-sm" data-role="datepicker" name="end-date" value="<%=EndDateString %>"/>
					</div>
					<button class="btn btn-default btn-sm" type="submit" name="filter-submit" style="line-height: 19px;"><i class="fa fa-filter"></i>Filter</button>
				</form>
			</div>
		</div>
		<div><input type="button" style="margin-bottom:10px;" value="Get Task Extensions" onclick="GetQuickDeadlineExtensions()" /></div> <%--added by venkat 10/31/2017--%>
	</div>
	<div id="otherOverdueDiv" class="collapsible collapsed" style="display: none;">
		<i class="collapse-clicker fa fa-arrow-up" style="font-size: 17px; font-style: normal; font-weight: bold; width: 100%; margin: 4px 0 4px 0;"><span style="font-family: Tahoma, Verdana; color: #ff2451; margin-left: 12px;">&nbsp;OTHER OVERDUE</span></i>
		<div class="collapse-grid">
			<div class="collapse-content">
				<div id="divOtherOverdueTaskList" data-role="checklist-holder"></div>
			</div>
		</div>
	</div>
	<% if (ExpandAll) { %>
		<asp:repeater id="taskRepeater1" runat="server">
			<itemtemplate>
				<div data-role="checklist-holder">
					<mytasks:Checklist ID="Checklist" IsMyTasks=<%#IsMyTasks %> Checklist="<%#GetDataItem() %>" runat="server" />
				</div>
			</itemtemplate>
		</asp:repeater>
	<% } else { %>
		<div id="divTaskList" data-role="checklist-holder">Loading...Please wait</div>
	<% } %>
	<input id="expand-all" type="hidden" value="<%= ExpandAll %>"/>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

