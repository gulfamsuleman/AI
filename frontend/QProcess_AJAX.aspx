<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="QProcess_AJAX.aspx.cs" Inherits="QProcess.QProcess_AJAX" %>
<asp:datagrid id="dgComments" runat="server" autogeneratecolumns="False" width="100%" showheader="False"
	borderstyle="None" borderwidth="0" gridlines="None" enableviewstate="False" cssclass="wordwrap fixedtable">
	<columns>
		<asp:boundcolumn datafield="ID" visible="False" readonly="True" />
		<asp:templatecolumn itemstyle-cssclass="eb">
			<itemtemplate></itemtemplate>
		</asp:templatecolumn>
	</columns>
</asp:datagrid>
<!-- Copyright © 2024 Renegade Swish, LLC -->

