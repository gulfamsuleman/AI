<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ManageEmails.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_ManageEmails" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Import Namespace="QProcess.Enums" %>

<div id="manage-emails-panel">
	<h4>Email of Overdue Items</h4>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendOverdue] ? "checked='checked'" : "" %> 
			data-type="<%= EmailPreferenceType.SendOverdue %>"/>
		 Send Overdue Items email for status reports I supervise.
	</p>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendOverdueWithInterestedParty] ? "checked='checked'" : "" %>
			data-type="<%= EmailPreferenceType.SendOverdueWithInterestedParty %>"/>
		 Include those reports on which I am an interested party.
	</p>
	<h4>Email of Unread Reports</h4>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendUnread] ? "checked='checked'" : "" %> 
			data-type="<%= EmailPreferenceType.SendUnread %>"/>
		 Send Unread Reports email for status reports I supervise.
	</p>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendUnreadWithInterestedParty] ? "checked='checked'" : "" %> 
			data-type="<%= EmailPreferenceType.SendUnreadWithInterestedParty %>"/>
		 Include those reports on which I am an interested party.
	</p>
	<h4>Email of Due Date Changes</h4>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendDueDateChange] ? "checked='checked'" : "" %> 
			data-type="<%= EmailPreferenceType.SendDueDateChange %>"/>
		 Send Due Date Changes email for status reports I supervise.
	</p>
	<p>
		<input type="checkbox" 
			<%=EmailPreferences[EmailPreferenceType.SendDueDateChangeWithInterestedParty] ? "checked='checked'" : "" %> 
			data-type="<%= EmailPreferenceType.SendDueDateChangeWithInterestedParty %>"/>
		 Include those reports on which I am an interested party.
	</p>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/InboxManageEmails.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

