<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportLineExport.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_ReportLineExport" %>
<%@ Import Namespace="QProcess.Enums" %>
<%@ Import Namespace="QProcess.Configuration" %>
<%@ Import Namespace="QProcess.Repositories" %>
<% if (Line.LineType == StatusReportLine.Type.Header){ %>
	<tr nowrap="nowrap" align="Left">
		<td class="emailHeader" colspan="5"><%= Line.Description %></td>
	</tr>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Subheader){ %>
	<%if (Line.Description == "General Comments") {%>
		<% if (!excludeGeneralComments)
		   { %>
			<tr nowrap="nowrap" align="Left">
				<td class="emailSubHeader" colspan="5"><%= Line.Description %></td>
			</tr>
		<% } %>
	<% } %>
	<%else if (Regex.Match(Line.Description, @"^(\w+\b.*?){1}").ToString() == "Completed") {%>
		<tr nowrap="nowrap" align="Left">
			<td class="emailSubHeader" colspan="5" style="font-style:italic;color:#969;"><%=Line.Description%></td>
		</tr>
	<% } %>
	<%else{%>
		<tr nowrap="nowrap" align="Left">
			<td class="emailSubHeader" colspan="5"><a href="#" style="text-decoration:underline;"><%=Line.Description%></a></td>
		</tr>
	<% } %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Headings){ %>
	<tr nowrap="nowrap" align="Left" style="cursor:e-resize;">
		<td class="emailHeads" style="width:2%;"></td><td class="emailHeads" style="width:10%;">Task</td>
		<td class="emailHeads" style="width:5%;">Deadline</td>
		<td class="assigneeColumnHeads" style="width:5%;">Assignees / Controllers</td>
		<td class="progressColumnHeads" style="width:70%;">Progress</td>
	</tr>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Spacer){ %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Ender){ %>
	<tr nowrap="nowrap" align="Left">
		<td class="reportender" colspan="5"></td>
	</tr>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Task && Line.MyTaskType == TaskType.GeneralComment){ %>
	<tr nowrap="nowrap" align="Left">
		<td class="assigneeColumn">/</td>
		<td class="eb" colspan="5">						
			<table class="wordwrap fixedtable" cellspacing="0" border="0" id="dgStatusReport__ctl5_dgComments" style="border-width:0px;border-style:None;width:100%;border-collapse:collapse;">
				<asp:Repeater ID="Repeater1" DataSource=<%# (Line.Comments == null) ? null : from StatusReportLine.Comment c in Line.Comments where c.Date >= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)) select c %> runat="server">
					<ItemTemplate>
						<tr class="eb"><td class="eb"><div class='p'>[<%# DataBinder.Eval(Container, "DataItem.Date", "{0:d}") %>] [<%# DataBinder.Eval(Container, "DataItem.Initials") %>] <%# DataBinder.Eval(Container, "DataItem.Text") %></div></td></tr>
					</ItemTemplate>
				</asp:Repeater>
			</table>
		</td>
	</tr>
<% } %>
<%else if(Line.LineType == StatusReportLine.Type.Task) { %>
	<tr nowrap="nowrap" align="Left">
		<td class="eb">
			<div><%=Line.Priority.ToString() %></div>
		</td>
		<td class="eb">
			<a href='#'>
				<%=Line.Description %>
			</a>
		</td>
		<td class="eb">
			<span<%= Line.DueDate.Value < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() && Line.MyTaskType != TaskType.Completed && Line.MyTaskType != TaskType.Deleted ? " class=\"overduespan\"" : "" %>><%=Line.DueDate.Value.ToShortDateString() %></span>
		</td>
		<td class="assigneeColumn">
			<span><%=Line.AssignedTo %></span> / <span><%=Line.Controllers %></span> 
		</td>
		<td class="progressColumn">		
			<table class="wordwrap fixedtable" cellspacing="0" border="0" style="border-width:0px;border-style:None;width:100%;border-collapse:collapse;">
				<asp:Repeater ID="Repeater2" DataSource=<%# (Line.Comments == null) ? null : from StatusReportLine.Comment c in Line.Comments where c.Date >= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)) select c %> runat="server">
					<ItemTemplate>
						<tr class="eb"><td class="eb"><div class='p'>[<%# DataBinder.Eval(Container, "DataItem.Date", "{0:d}") %>] [<%# DataBinder.Eval(Container, "DataItem.Initials") %>] <%# DataBinder.Eval(Container, "DataItem.Text") %></div></td></tr>
					</ItemTemplate>
				</asp:Repeater>
			</table>
		</td>
	</tr>
<% } %>
<!-- Copyright © 2024 Renegade Swish, LLC -->

