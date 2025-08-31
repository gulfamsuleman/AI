<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="MessageToUser.ascx.cs" Inherits="MessageToUser" %>

<%if(ShowMessage) {%>
<script>
	var beforeload = window.onload;
	window.onload = alertOnLoad;
	function alertOnLoad() {
		if (beforeload) beforeload();
		alert(<%= "'" + Message + "'" %>);
	}
</script>
<%}%>
<!-- Copyright © 2024 Renegade Swish, LLC -->

