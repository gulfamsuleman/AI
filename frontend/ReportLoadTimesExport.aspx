<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ReportLoadTimesExport.aspx.cs" Inherits="QProcess.ReportLoadTimesExport" %>
<table cellspacing="0" cellpadding="3" rules="all" border="1" id="grdReport" style="background-color:White;border-color:#CCCCCC;border-width:1px;border-style:None;font-family:Tahoma;font-size:10pt;border-collapse:collapse;">
	<th>
		<tr align="center" style="color:White;background-color:#006699;font-weight:bold;">
			<td>User</td>
			<td>UserID</td>
			<td>Page Name</td>
			<td>Server Time</td>
			<td>Client Time</td>
			<td>Total Load Time</td>
			<td>DateTime</td>
			<td>Report Name</td>
			<td>LastOpened</td>
			<td>Browser</td>
		</tr>
	</th>
	<tbody>
		<asp:Repeater ID="Repeater1" DataSource=<%# LoadTimes %> runat="server">
			<ItemTemplate>
			<%# Container.ItemIndex % 2 == 0 ? "<tr style='color:#000066;'>" : "<tr style='color:#000066;background-color:#D2DEE0;'>" %>
				<td><%#Eval("User") %></td>
				<td><%#Eval("UserId") %></td>
				<td><%#Eval("PageName") %></td>
				<td><%#Eval("ServerTime") %></td>
				<td><%#Eval("ClientTime") %></td>
				<td><%#Eval("TotalLoadTime") %></td>
				<td><%#Eval("DateTime") %></td>
				<td><%#Eval("ReportName") %></td>
				<td><%#Eval("LastOpened") %></td>
				<td><%#Eval("Browser") %></td>
			</tr>
			</ItemTemplate>
		</asp:Repeater>
	</tbody>
</table>
<!-- Copyright © 2024 Renegade Swish, LLC -->

