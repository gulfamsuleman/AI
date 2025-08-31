<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AssigneesMultiSelect.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_AssigneesMultiSelect" %>
<select multiple id="reassign-select" class="form-control" size="12">
	<asp:repeater ID="Repeater1" DataSource=<%# PossibleAssignees %> runat="server">
		<itemtemplate>
			<option value=<%#Eval("Id") %> <%#InitialSelections.Contains(Convert.ToInt32(Eval("Id")))?"selected='selected'":""%> ><%#Eval("Name") %></option>
		</itemtemplate>
	</asp:repeater>
</select>
<!-- Copyright © 2024 Renegade Swish, LLC -->

