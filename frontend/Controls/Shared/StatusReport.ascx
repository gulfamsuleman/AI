<%@ Control Language="C#" AutoEventWireup="true" Codebehind="StatusReport.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_StatusReport" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mystatus" TagName="ReportLine" Src="~/Controls/MyStatus/ReportLine.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>


<QPH:DOMInjector ID="DOMInjector1" runat="server" InjectInto="HeadContent" >
	<link href="../Content/StatusReport.css?v=7" rel="stylesheet" type="text/css" />
	<link href="../Content/PrintBase.css" rel="stylesheet" type="text/css" media="print" />
</QPH:DOMInjector>

	<script>

		function checkchars(tb) {
			if (tb.value.length > 1499) {
				tb.value = tb.value.substring(0, 1499)
			}
		}

	</script>

<% if (LargeFont) { %>
	<style>
		.textboxclass {
			font-size: 14pt;
			font-family: Times New Roman;
		}
		.emailHeader {
			font-family: Times New Roman;
			font-size: 25pt;
		}
		.emailSubHeader {
			font-family: Times New Roman;
			font-size: 18pt;
		}
		.ebsel, .eb, .eb1, .assigneeColumn, .progressColumn {
			font-family: Times New Roman;
			font-size: 14pt;
		}
		.ebchanged {
			font-family: Times New Roman;
			font-size: 14pt;
		}
		.ebWhite {
			font-family: Times New Roman;
			font-size: 14pt;
		}
		.emailButtons { font-family: Times New Roman; }
		.emailHeads, .emailHeads1, .assigneeColumnHeads, .progressColumnHeads {
			font-family: Times New Roman;
			font-size: 14pt;
		}
        a[data-action="add-comment"]{
            color:<%= CommentColor %>;
        }
	</style>
<% } else { %>
	<style>
		.textboxclass { font-size: 10pt; }
		.emailHeader { font-size: 16pt; }
		.emailSubHeader { font-size: 13pt; }
		.ebsel, .eb, .eb1, .assigneeColumn, .progressColumn { font-size: 10pt; }
		.ebchanged { font-size: 14pt; }
		.ebWhite { font-size: 14pt; }
		.emailHeads, .emailHeads1, .assigneeColumnHeads, .progressColumnHeads { font-size: 14pt; }
	</style>
<% } %>

<div id="status-report">
	<div id="main-content" <%=FontClass %>>
		<div id="attorney-client-message" hidden>ATTORNEY CLIENT PRIVILEGED</div>
		<div id="status-report-viewer">
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<mystatus:ReportLine TaskWidth="<%#TaskWidth %>" LastViewed=<%#LastViewTime %> Line=<%#(StatusReportLine)Container.DataItem%> runat="server"></mystatus:ReportLine>
				</ItemTemplate>
			</asp:Repeater>
		</div>
	</div>
	<div class="hidden">
		<input type="hidden" id="user-id" value="<%:UserId%>"/>
	</div>
	
	<menu id="subheader-menu" type="context" style="display:none" class="showcase">
      <%if (IsInbox){ %>
        <command label="No Options"/>
       <%}else{ %>
		<command label="Add New Task" onclick="reportToolbarModule.addNewTaskModal()" icon="fa fa-plus"/>
		<command label="Add Existing Task" onclick="reportToolbarModule.addExistingTaskModal()" icon="fa fa-pencil" />
      <%} %>
	</menu>

	<menu id="task-menu" type="context" style="display:none" class="showcase">
       <%if (IsInbox){ %>
        <command label="No Options"/>
       <%}else{ %>
		<command label="Copy Task" onclick="reportToolbarModule.copyTask()" icon="fa fa-copy" />
		<command label="Move Task" onclick="reportToolbarModule.moveTask()" icon="fa fa-hand-o-up" />
		<command label="Add to Priorities" onclick="statusReportModule.addPriorities()" icon="fa fa-plus" />
      <%} %>
	</menu>
	<input type="hidden" id="last-viewed" value="<%=LastViewTime.ToShortDateString() %>"/>
	<input type="hidden" id="report-id" value="<%= ReportId %>"/>
	<input type="hidden" id="tasks-controlled" value="<%= TasksIControl %>" />
	<input type="hidden" id="comment-color" value="<%= CommentColor %>" />
	<input type="hidden" id="comment-color-num" value="<%= ColorNum %>" />
	<iframe style="width:1024px;height:768px;z-index:20000;display:none" id="divPreview"></iframe>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/StatusReport.js?v=11"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

