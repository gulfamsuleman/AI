<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingUsers.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingUsers" %>

<select id="user-select" class="form-control input-sm">
	<asp:Repeater ID="Repeater1" DataSource=<%# Users %> runat="server">
		<ItemTemplate>
			<option value="<%#Eval("ID") %>" <%#(int)Eval("ID") == SelectedUserId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
		</ItemTemplate>
	</asp:Repeater>
</select>
<!-- Copyright © 2024 Renegade Swish, LLC -->

