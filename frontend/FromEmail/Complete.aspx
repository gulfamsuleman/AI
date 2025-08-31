<%@ Page Language="C#" AutoEventWireup="true" Codebehind="Complete.aspx.cs" Inherits="QProcess.FromEmail_Complete" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <script>
		function submitForm()
		{
			var success = <%=success%>;
			if (!success) {
				document.forms(0).submit();
			}
		}
    </script>
</head>
<body>
	<form id="Form1" action="../mytasks.aspx#ac<%=ac.ToString()%>" method="post">
		<input type="hidden" name="open" value="true"/>
		<input type="hidden" name="ac" value="<%=ac.ToString()%>"/>
    </form>

    <%=message %>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

