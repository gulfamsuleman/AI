<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingPeriods.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingPeriods" %>

<select id="grading-periods" class="form-control input-sm">
	<asp:Repeater ID="Repeater1" DataSource=<%# GradingPeriods %> runat="server">
		<ItemTemplate>
			<option value="<%#Eval("Id") %>" <%# (int)Eval("Id") == PeriodId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
		</ItemTemplate>
	</asp:Repeater>
</select>
<!-- Copyright © 2024 Renegade Swish, LLC -->

