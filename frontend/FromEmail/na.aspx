<%@ Page Language="C#" AutoEventWireup="true" Codebehind="na.aspx.cs" Inherits="QProcess.FromEmail_na" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <script src="jquery-1.9.1.min.js"></script>
    <script>
        $().ready(function () {
            $("#not-a-submit").click(function () {
                if ($.trim($("#na-reason").val().replace("Reason for N/A", "")) == "") {
                    alert("You must provide a reason");
                } else {
                    document.getElementById("Form1").submit();
                }
            });
        });
    </script>
</head>
<body>
	<form id="Form1" action="Complete.aspx" method="post">
        <textarea name="nareason" id="na-reason" placeholder="Reason for N/A" rows="5" cols="50">Reason for N/A</textarea><br />
        <input type="button" value="N/A - Close Task" id="not-a-submit" />
        <input type="hidden" name="na" value="1"/>
		<input type="hidden" name="ac" value="<%=ac.ToString()%>"/>
        <input type="hidden" name="UserID" value="<%=UserID.ToString()%>"/>
        <input type="hidden" name="mobile" value="<%=mobile.ToString()%>"/>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

