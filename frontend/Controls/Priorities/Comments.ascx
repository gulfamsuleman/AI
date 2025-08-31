<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Comments.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_Comments" %>

<div class="priority-comment">
    <asp:Repeater ID="Repeater1" runat="server">
        <ItemTemplate>
                <div
                    data-role="reply-to-comment"
                    data-id="<%# Eval("CommentId") %>"
                    data-user-id="<%# Eval("CommentUserId") %>"
                    data-commenter='<%# GetCommenterDisplay(Eval("FullName"), Eval("Initials"), Eval("CommentUserId")) %>'
                    data-date='<%# Eval("CommentDate", "{0:yyyy-MM-dd}") %>'
                    class='comment-line <%# GetCommentColorClass(Eval("Color"), Eval("CommentDate")) %><%# IsEmailing ? "" : (ShouldHideComment(Eval("CommentDate")) ? " hidden" : "") %> tab-<%# Eval("TabIn") %>'
                    <%# ShouldMarkOld(Eval("CommentDate")) ? "data-comment='old'" : "" %>
                    style="padding-left: <%# 30 * Convert.ToInt32(Eval("TabIn")) %>px">
                    <span data-role="comment-text">
                        <%# GetCommenterDisplay(Eval("FullName"), Eval("Initials"), Eval("CommentUserId")) %><%# ParseLinks(Eval("Comment").ToString()) %>
                    </span>
                </div>
        </ItemTemplate>
    </asp:Repeater>
</div>

<!-- Copyright © 2024 Renegade Swish, LLC -->

