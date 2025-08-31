<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportLineEmail.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_ReportLineEmail" %>
<%@ Import Namespace="QProcess.Enums" %>
<%@ Import Namespace="QProcess.Configuration" %>
<%@ Import Namespace="QProcess.Repositories" %>
<% if (Line.LineType == StatusReportLine.Type.Header){ %>
    <% if (IsMobile) { %>
	<tr nowrap="nowrap" align="Left">
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 25pt; COLOR: #000; TEXT-ALIGN: center;""><%= Line.Description %></td>
	</tr>
    <% } else { %>
	<tr nowrap="nowrap" align="Left">
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 25pt; COLOR: #000; TEXT-ALIGN: center; width: 1000px" colspan="<%=ColSpan%>"><%= Line.Description %></td>
	</tr>
    <% } %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Subheader){ %>
    <% if (IsMobile) { %>
    <tr nowrap="nowrap" align="Left">
		<td class="emailHeads" style="border:solid 1px #000000;"><%= Line.Description %></td>
	</tr>
    <% } else { %>
	    <%if (Line.Description == "General Comments") {%>
		    <% if (!excludeGeneralComments)
		       { %>
			    <tr nowrap="nowrap" align="Left">
				    <td style="COLOR: #000;text-decoration:underline;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 18pt;" colspan="<%=ColSpan%>"><%= Line.Description %></td>
			    </tr>
		    <% } %>
	    <% } %>
	    <%else if (Regex.Match(Line.Description, @"^(\w+\b.*?){1}").ToString() == "Completed") {%>
		    <tr nowrap="nowrap" align="Left">
			    <td style="COLOR: #000;text-decoration:underline;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 18pt;font-style:italic;color:#969;" colspan="<%=ColSpan%>"><%=Line.Description%></td>
		    </tr>
	    <% } %>
	    <%else{%>
		    <tr nowrap="nowrap" align="Left">
			    <td style="COLOR: #000;text-decoration:underline;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 18pt;" colspan="<%=ColSpan%>"><%=Line.Description%></td>
		    </tr>
	    <% } %>
    <% } %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Headings){ %>
    <% if (!IsMobile) { %>
	<tr>
		<td colspan="6">"Reply" - must use "==" or hit enter key if your name is put in [brackets]</td>
	</tr>
	<tr nowrap="nowrap" align="Left" style="cursor:e-resize;">
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 18pt;FONT-WEIGHT:BOLD;" class="c1" ></td>
        <td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 18pt;FONT-WEIGHT:BOLD;" class="c2" >Task<span style="color: #ece9d8;">_______________</span></td>
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 18pt;FONT-WEIGHT:BOLD;" class="c3" >Due</td>
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;FONT-WEIGHT:BOLD;" class="c4" >Assignees</td>
		<td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 18pt;FONT-WEIGHT:BOLD;" class="c5" >Progress<span style="color: #ece9d8;">___________________________________</span></td>
        <td style="border:solid 1px #000;background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 18pt;FONT-WEIGHT:BOLD;" class="c6" >Reply</td>
	</tr>
    <% } %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Spacer){ %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Ender){ %>
	<tr nowrap="nowrap" align="Left">
		<td style="BORDER-TOP: solid 2px #000; Height: 10px;" colspan="<%=ColSpan%>"></td>
	</tr>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.SpecialHeadings){ %>
    <% if (!IsMobile) { %>
    <tr nowrap="nowrap" align="Left">
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;" colspan="<%=ColSpan%>">
            "Reply" - must use "==" or hit enter key if your name is put in [brackets]
        </td>
	</tr>
    <% } %>
<% } %>
<%else if (Line.LineType == StatusReportLine.Type.Task && Line.MyTaskType == TaskType.GeneralComment){ %>
	<tr nowrap="nowrap" align="Left">
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;" colspan="<%=ColSpan%>">
			<table class="wordwrap fixedtable" cellspacing="0" border="0" id="dgStatusReport__ctl5_dgComments" style="border-width:0px;border-style:None;width:100%;border-collapse:collapse;">
				<asp:Repeater ID="Repeater1" DataSource=<%# (Line.Comments == null) ? null : from StatusReportLine.Comment c in Line.Comments select c %> runat="server">
					<ItemTemplate>
						<tr style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
							<td style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
								<div style='margin-left:<%# 22.5 * ((StatusReportLine.Comment)Container.DataItem).TabIn %>pt' id="acid:<%=Line.ID %>">
									<a<%# (((StatusReportLine.Comment)Container.DataItem).Date >= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddHours(-24)) ? " style=\"color: red;\"" : " style=\"color: black;\"" %> 
										href="<%: AppUrl %>&TaskID=<%: Line.ID %>&CommentID=<%# ((StatusReportLine.Comment)Container.DataItem).Id %>">
										[<%# QProcess.Session.CurrentSession.UserTimeZone.GetSystemTime(((StatusReportLine.Comment)Container.DataItem).Date).AddHours(-24).ToShortDateString() %>] 
										[<%# DataBinder.Eval(Container, "DataItem.Initials") %>] 
										<%# DataBinder.Eval(Container, "DataItem.Text") %>
									</a>
								</div>
							</td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</table>
		</td>
	</tr>
<% } %>
<%else if(Line.LineType == StatusReportLine.Type.Task) { %>
    <% //if (!OnlyTasksWithComments || (OnlyTasksWithComments && VisibleComments.Count > 0)) { %>

    <% if (IsMobile) { %>
    <tr>
        <td style="border: 1px solid black;background-color:#ffffed">
            <table>
	        <tr>
		        <td class="task eb">
					<%=Line.Description %>
					<% if (IsIncludeDetails && Line.TaskDetails != null && Line.TaskDetails.Count > 0) { %>
						<div style="color: black; border: 1px solid #444; padding: 10px 14px 14px 14px; margin-top: 8px;">
							<div style="font-weight:bold; text-decoration:underline; padding-bottom:6px; text-align:center;">Details</div>
							<% foreach (var detail in Line.TaskDetails) { %>
								<% if (detail.ItemType == "Spacer") { %>
									<div style="height:20px;"></div>
								<% } else if (detail.ItemType == "Checkbox") { %>
									<div>
										<%= detail.IsCompleted ? "&#x2611;" : "&#x2610;" %>
										<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
									</div>
								<% } else if (detail.ItemType == "Heading") { %>
									<div style="font-weight:bold;font-size:12pt;">
										<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
									</div>
								<% } else if (detail.ItemType == "Notes") { %>
									<div style="font-style:italic;font-size:0.9em;">
										<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
									</div>
								<% } else if (detail.ItemType == "Sub Heading") { %>
									<div style="font-weight:bold;font-style:italic;font-size:0.9em;">
										<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
									</div>
								<% } else { %>
									<div>
										<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
									</div>
								<% } %>
							<% } %>
						</div>
						<div style='height:6px;'></div>
					<% } %>
			        <div class="taskinfo">
				        Due: <span<%# (Line.DueDate.HasValue && Line.DueDate.Value < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() && Line.MyTaskType != TaskType.Completed && Line.MyTaskType != TaskType.Deleted) ? " style=\"BACKGROUND-COLOR:#ff1;\"": "" %>><%=Line.DueDate.Value.ToShortDateString() %></span><br>
				        Assn: <%=Line.AssignedTo %>
			        </div>
		        </td>
	        </tr>
            <tr>
	            <td class="comments eb">
			        <table class="wordwrap fixedtable" cellspacing="0" border="0" style="border-width:0px;border-style:None;width:100%;border-collapse:collapse;">
						<asp:Repeater ID="Repeater3" DataSource=<%# (Line.Comments == null) ? null : from StatusReportLine.Comment c in Line.Comments select c %> runat="server">
							<ItemTemplate>
								<tr style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
									<td style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
										<div style='margin-left:<%# 22.5 * ((StatusReportLine.Comment)Container.DataItem).TabIn %>pt;'>
											<a<%# (((StatusReportLine.Comment)Container.DataItem).Date >= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddHours(-24)) ? " style=\"color: red;\"" : " style=\"color: black;\"" %> 
												href="<%: AppUrl %>&TaskID=<%: Line.ID %>&CommentID=<%# ((StatusReportLine.Comment)Container.DataItem).Id %>">
												[<%# QProcess.Session.CurrentSession.UserTimeZone.GetLocalTime(((StatusReportLine.Comment)Container.DataItem).Date).ToShortDateString() %>] 
												[<%# DataBinder.Eval(Container, "DataItem.Initials") %>] 
												<%# DataBinder.Eval(Container, "DataItem.Text") %> <span></span>
											</a>
										</div>
									</td>
								</tr>
							</ItemTemplate>
						</asp:Repeater>
			        </table>
                </td>
            </tr>
	        <tr>
		        <td class="reply eb">
			        <div id="acid:<%=Line.ID %>" class="CommentDiv">
				        <span class="replyicon">?</span>
				        <span class="CommentReply"></span>
			        </div>
		        </td>
	        </tr></table>
        </td>
    </tr>
    <% } else { %>
	<tr nowrap="nowrap" align="Left">
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
			<div><%=Line.Priority.ToString() %></div>
		</td>
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
			<%=Line.Description %>
			<% if (IsIncludeDetails && Line.TaskDetails != null && Line.TaskDetails.Count > 0) { %>
				<div style="color: black; border: 1px solid #444; padding: 10px 14px 14px 14px; margin-top: 8px;">
					<div style="font-weight:bold; text-decoration:underline; padding-bottom:6px; text-align:center;">Details</div>
					<% foreach (var detail in Line.TaskDetails) { %>
						<% if (detail.ItemType == "Spacer") { %>
							<div style="height:20px;"></div>
						<% } else if (detail.ItemType == "Checkbox") { %>
							<div>
								<%= detail.IsCompleted ? "&#x2611;" : "&#x2610;" %>
								<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
							</div>
						<% } else if (detail.ItemType == "Heading") { %>
							<div style="font-weight:bold;font-size:12pt;">
								<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
							</div>
						<% } else if (detail.ItemType == "Notes") { %>
							<div style="font-style:italic;font-size:0.9em;">
								<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
							</div>
						<% } else if (detail.ItemType == "Sub Heading") { %>
							<div style="font-weight:bold;font-style:italic;font-size:0.9em;">
								<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
							</div>
						<% } else { %>
							<div>
								<%= System.Net.WebUtility.HtmlEncode(detail.ItemName) %>
							</div>
						<% } %>
					<% } %>
				</div>
				<div style='height:6px;'></div>
			<% } %>
		</td>
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 10pt;">
			<span<%# (Line.DueDate.HasValue && Line.DueDate.Value < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() && Line.MyTaskType != TaskType.Completed && Line.MyTaskType != TaskType.Deleted) ? " style=\"BACKGROUND-COLOR:#ff1;\"": "" %>><%=Line.DueDate.Value.ToShortDateString() %></span>
		</td>
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 10pt;">
			<span><%=Line.AssignedTo %></span>
		</td>
		<td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">		
			<table class="wordwrap fixedtable" cellspacing="0" border="0" style="border-width:0px;border-style:None;width:100%;border-collapse:collapse;">
				    <asp:Repeater ID="Repeater2" DataSource=<%# (Line.Comments == null) ? null : from StatusReportLine.Comment c in Line.Comments select c %> runat="server">
					<ItemTemplate>
						<tr style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
							<td style="background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;">
								<div style='margin-left:<%# 22.5 * ((StatusReportLine.Comment)Container.DataItem).TabIn %>pt;'>
									<a<%# (((StatusReportLine.Comment)Container.DataItem).Date >= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddHours(-24)) ? " style=\"color: red;\"" : " style=\"color: black;\"" %> 
										href="<%: AppUrl %>&TaskID=<%: Line.ID %>&CommentID=<%# ((StatusReportLine.Comment)Container.DataItem).Id %>">
										[<%# QProcess.Session.CurrentSession.UserTimeZone.GetLocalTime(((StatusReportLine.Comment)Container.DataItem).Date).ToShortDateString() %>] 
										[<%# DataBinder.Eval(Container, "DataItem.Initials") %>] 
										<%# DataBinder.Eval(Container, "DataItem.Text") %> <span></span>
									</a>
								</div>
							</td>
						</tr>
					</ItemTemplate>

				</asp:Repeater>
			</table>
		</td>
            <td style="border:solid 1px #000;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;"><div id="acid:<%=Line.ID %>" class="CommentReply">&nbsp;<%=Line.LineType %></div></td>
	</tr>
    <% } %>
    <% //} %>
<% } %>
<!-- Copyright © 2024 Renegade Swish, LLC -->

