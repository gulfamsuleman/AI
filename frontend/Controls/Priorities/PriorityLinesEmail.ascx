<%@ Control Language="C#" AutoEventWireup="true" Codebehind="PriorityLinesEmail.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_PriorityLine" %>
<%@ Register TagPrefix="priority" TagName="PriorityComments" Src="~/Controls/Priorities/Comments.ascx" %>

<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<tr style="background:#ffffed;padding:3.0pt 3.0pt 3.0pt 3.0pt">
            <td style="border:1px solid black;font-size:14.0pt;padding:3.0pt 3.0pt 3.0pt 3.0pt;"><%#Eval("Priority") %></td>
			<td style="border:1px solid black;font-size:14.0pt;padding:3.0pt 3.0pt 3.0pt 3.0pt;width:700px;">
				<%#Eval("Name") %> <a href="<%# QProcess.Configuration.AppSettings.PrioritiesLink %>?Redirect=1&ReportUserID=<%#Eval("UserID") %>&TaskID=<%#Eval("ActiveChecklistID") %>">...</a>
                <span style="color: red;"><priority:PriorityComments IsEmailing="true" Comments=<%#Eval("Comments") %> runat="server" /></span>
				
			</td>
			<% if(!Condensed) { %>
            <td class="priorities-email-reply" style="border:1px solid black;font-size:14.0pt;padding:3.0pt 3.0pt 3.0pt 3.0pt;width:400px;"><div id="acid:<%#Eval("ActiveChecklistId") %>" class="CommentReply">&nbsp;</div></td>
			<% } %>
			<td style="border:1px solid black;font-size:14.0pt;padding:3.0pt 3.0pt 3.0pt 3.0pt;"><%#Eval("DueDate", "{0:MM/dd/yyyy}") %></td>
		</tr>
	</ItemTemplate>
</asp:Repeater>
<!-- Copyright © 2024 Renegade Swish, LLC -->

