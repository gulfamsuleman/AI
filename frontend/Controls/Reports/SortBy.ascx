<%@ Control Language="C#" AutoEventWireup="true" Codebehind="SortBy.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_SortBy" %>

Sort By: 
<select data-role="sort-by" class="form-control input-sm">
	<asp:Repeater ID="Repeater1" runat="server">
		<ItemTemplate>
			<option value="<%#Eval("Value") %>" <%#Convert.ToString(Eval("Value")) == Sort ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
		</ItemTemplate>
	</asp:Repeater>
</select>
<!-- Copyright © 2024 Renegade Swish, LLC -->

