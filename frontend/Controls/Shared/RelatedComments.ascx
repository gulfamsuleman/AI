<%@ Control Language="C#" AutoEventWireup="true" Codebehind="RelatedComments.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_RelatedComments" %>
<%@ Import Namespace="QProcess.Configuration" %>

<div>
	<asp:Repeater ID="Repeater1" runat="server">
		<ItemTemplate>
			<div class="comment-line" style="padding-left: <%# 30*(int)Eval("TabIn")%>px">
					[<span class="comment-date"><%# Eval("CommentDate", "{0:d}") %></span>] [<%# Eval("Initials") %>] <span data-role="comment-text"><%# Eval("Comments") %></span>
			</div>
		</ItemTemplate>
	</asp:Repeater>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

