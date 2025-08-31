<%@ Page Language="C#" AutoEventWireup="true" Codebehind="ExtensionRequest.aspx.cs" Inherits="QProcess.FromEmail_ExtensionRequest" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>QProcess</title>
    <meta name="viewport" content="width=device-width initial-scale=1.0 maximum-scale=1.0 user-scalable=yes" />
    <script type="text/javascript">
    function window.onload() {
		document.getElementById("<%=txtReason.ClientID%>").focus();
    }
    </script>
</head>
<body>
    <form id="form1" runat="server">
		<asp:Panel ID="pnlForm" Runat="server">
			<asp:TextBox ID="txtID" Runat="server" Visible="False"/>
			<asp:TextBox ID="txtUser" Runat="server" Visible="False"/>
			<h1>Extend Deadline</h1>
			<p>
				<b><asp:Label ID="lblTaskName" Runat="server" /></b>
			</p>
			<p>
				New Deadline: <b><asp:Label ID="lblNewDeadline" Runat="server" /></b>
				<asp:TextBox ID="txtNewDeadline" Runat="server" Visible="False"/>
			</p>
			<p id="pReason" runat="server">
				Reason:<br/>
				<asp:TextBox ID="txtReason" Runat="server" TextMode="MultiLine" Rows="10" Columns="50" TabIndex="1" />
			</p>
			<asp:Button ID="btnSend" Runat="server" Text="Send Request" TabIndex="2" OnClick="btnSend_Click" />		
		</asp:Panel>
		<asp:Panel ID="pnlFinish" Runat="server">
			<h1 id="hdrFinish" runat="server">Extension Request Sent</h1>
			<asp:Label ID="lblFinish" Runat="server"></asp:Label>
		</asp:Panel>
		<asp:Panel ID="pnlError" Runat="server">
			<h1>Problem Extending Deadline</h1>
            <asp:label ID="lblError" Runat="server"></asp:label>
		</asp:Panel>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

