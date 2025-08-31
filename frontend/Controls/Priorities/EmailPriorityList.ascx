<%@ Control Language="C#" AutoEventWireup="true" Codebehind="EmailPriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_EmailPriorityList" %>
<%@ Register TagPrefix="priority" TagName="PriorityList" Src="~/Controls/Priorities/PriorityList.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="email-priority-list-panel">
	<button data-role="send-email" class="btn btn-default"><img alt="" src="/images/inbox.gif"/> Send Email</button>
    <div style="float:right;" class="additional-recipients">
        Add Additional Recipients:
        <select id="addl-recipients">
            <option value=""></option>
            <asp:Repeater ID="Repeater2" runat="server">
			<ItemTemplate>
                <option value="<%#Eval("Email") %>"><%#Eval("FullName") %></option>
			</ItemTemplate>
		</asp:Repeater>
        </select>
        <input type="button" id="add-recipient" value="Add" />
    </div>
	<div id="email-priority-list-table">
		<asp:Repeater ID="Repeater1" runat="server">
			<ItemTemplate>
                <div id="email-listing">
                    <input id="<%#Eval("FullName").ToString().Replace(" ", "").Replace("'", "") %>" name="<%#Eval("FullName").ToString().Replace(" ", "").Replace("'", "") %>" data-role="include-email" data-email="<%#Eval("Email") %>" type="checkbox" />
					<label for="<%#Eval("FullName").ToString().Replace(" ", "").Replace("'", "") %>" ><%#Eval("FullName") %></label>
                </div>
			</ItemTemplate>
		</asp:Repeater>
	</div>
	<textarea id="email-body" style="width: 100%"></textarea>
	<br/>
    <div id="include-comments">
        <span>Include Comments Since <input id="comments-since" data-role="datepicker" value="<%if (commentSince.HasValue) { Response.Write(commentSince.Value.ToShortDateString()); } %>" class="input-sm" /></span>
        <span>&nbsp;&nbsp;&nbsp;Include Comments From Everyone <input id="comments-everyone" type="checkbox" <%if (includeEveryone) {%> checked <%} %> /></span>
	</div>
	<div id="priority-list" class="border">
		<priority:PriorityList ID="PriorityListControl" runat="server"/>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/EmailPrioritiesList.js?v=3"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

