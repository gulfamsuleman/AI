<%@ Control Language="C#" AutoEventWireup="true" Codebehind="StatusTasks.ascx.cs" Inherits="QProcess.Controls.Controls_TaskSummary_StatusTasks" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="taskSummary" TagName="StatusTaskLine" Src="~/Controls/TaskSummary/StatusTaskLine.ascx" %>

<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<taskSummary:StatusTaskLine Line=<%#(TaskStatusLine)Container.DataItem%> runat="server"></taskSummary:StatusTaskLine>
	</ItemTemplate>
</asp:Repeater>
<!-- Copyright © 2024 Renegade Swish, LLC -->

