<%@ Control Language="C#" AutoEventWireup="true" Codebehind="CommentList.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_CommentList" %>
<%@ Import Namespace="QProcess.Configuration" %>

<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<div <%# (Convert.ToDateTime(Eval("Date")) > QUser.MyTimeZone.GetLocalTimeNow().Date.AddDays(-1) && Convert.ToInt32(Eval("UserId"))==QUser.Id) ? "data-role='edit-comment'" : "data-role='reply-to-comment'" %> data-id="<%# Eval("Id") %>" data-user-id="<%# Eval("UserId") %>" data-commenter="<%#Eval("FullName") %>" data-date="<%#Eval("Date") %>" class="comment-line <%# Convert.ToDateTime(Eval("Date")) >  LastViewed ? "sd" + Eval("Color") : "sd" + Eval("Color") + "HighlightDate" %> <%# !QProcess.Session.CurrentSession.GetAllCommentsFlag && Convert.ToDateTime(Eval("Date")) <  LastViewed.AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)) ? "hidden" : "" %>" <%# Convert.ToDateTime(Eval("Date")) <  LastViewed.AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)) ? "data-comment='old'" : "" %> style="padding-left: <%# 30*(int)Eval("TabIn")%>px">
				[<span class="comment-date"><%# Eval("Date", "{0:d}") %></span>] [<%# Eval("Initials") %>] <span data-role="comment-text"><%# Eval("Text") %></span>
        </div>
	</ItemTemplate>
</asp:Repeater>
<a data-action="injection-point"></a><a data-action="add-comment">...</a>
<!-- Copyright © 2024 Renegade Swish, LLC -->

