<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="TaskSummary.aspx.cs" Inherits="QProcess.TaskSummary" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="taskSummary" TagName="Throbber" Src="~/Controls/Shared/Throbber.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/TaskSummary.css" rel="stylesheet" />
	 
	<script>
        $().ready(function () {
            $("#start-date").change(updateStartingDate);
			$("#end-date").change(updateEndingDate);
			$("input[data-action='check-all").change(checkAllCheckboxes);
			$("#btnNA").click(DoNAs);
		});

		function updateStartingDate() {
            $("#<%= hidStartDate.ClientID %>").val($("#start-date").val());
            reSubmitForm();
        }

        function updateEndingDate() {
			$("#<%= hidEndDate.ClientID %>").val($("#end-date").val());
			reSubmitForm();
		}

        function reSubmitForm() {
            $("input[type=submit]").click();

		}

        function checkAllCheckboxes() {
            $("input[data-role='nacheck']").prop("checked", $("input[data-action='check-all").prop("checked"));
		}
		function DoNAs() {
			if ($("input[data-role='nacheck']:checked").length == 0) {
				alert("Please select the tasks to mark N/A");
				return;
			}
            if ($("#nareason").val().trim().length == 0) {
                alert("Pleas provide the reason these tasks are being marked N/A");
                return;
			}
			var totalToClose = $("input[data-role='nacheck']:checked").length;
			var closedCount = 0;

            $("input[data-role='nacheck']:checked").each(function (index) {
				$.ajax({
					url: "/DataService.asmx/CompleteChecklist",
					type: "POST",
                    data: JSON.stringify({ uniqueId: $(this).data("val"), na: true, naReason: $("#nareason").val().trim() }),
					dataType: "json",
					contentType: "application/json",
                    async: false,
					success: function (response) {
						closedCount++;
						if (closedCount == totalToClose) {
                            reSubmitForm();
						}
                    },
                    error: function (jqXHR, textStatus, errorThrown) {
						alert("An error occurred while processing your request.");
                        reSubmitForm();
                    }
				});
            });
            reSubmitForm();
		}

    </script>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/TaskSummary.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<form runat="server">
	<div id="task-summary-panel">
		<img src="/Images/reports.gif" class="float-left"/>
		<h3>Task Summary</h3>
		<p>This page displays the vital information on all tasks in which you are an assignee, or a controller.</p>
		<div id="na-panel">
			<span style="font-weight:bold;">Bulk N/A tasks</span>
		</div>
		<asp:HiddenField ID="hidStartDate" runat="server" />
		<asp:HiddenField ID="hidEndDate" runat="server" />
		<asp:Button ID="btnSubmit" runat="server" Text="test" CssClass="hiddenbutton"></asp:button>
		<div>
			<div class="form-group">
				<label for="start-date">Open tasks I control (not assigned to me) with due date between</label>
				<input id="start-date" type="text" style="width: 90px;border: 1px solid black;padding: 1px 2px;" data-role="datepicker" name="start-date" value="<%=StartDateString %>"/>
				<label for="end-date">and</label>
				<input id="end-date" type="text" style="width: 90px;border: 1px solid black;padding: 1px 2px;" data-role="datepicker" name="end-date" value="<%=EndDateString %>"/>
				assigned to 
				<asp:DropDownList ID="assignedtoList" runat="server" AutoPostBack="true"></asp:DropDownList>
			</div>
			<div class="form-group">
				<input type="button" value="N/A selected Tasks" id="btnNA" />
				 <br />Reason: <br /> <textarea id="nareason" rows="4" cols="100"></textarea>
			</div>
			<div id="naresults">
				<table>
					<tr>
					    <th><input type="checkbox" data-action="check-all"></th>
					    <th>Task Name</th>
					    <th>Assignees</th>
					    <th>Deadline</th>
				    </tr>
					<asp:Repeater ID="rptNATasks" runat="server">
						<ItemTemplate>
							<tr><td><input type="checkbox" data-role="nacheck" data-val="<%#Eval("ChecklistId") %>" /></td><td><%#Eval("Name") %></td><td><%#Eval("Assignees") %></td><td><%#DateFormat(Eval("DueDate")) %></td></tr>
						</ItemTemplate>
					</asp:Repeater>
				</table>
			</div>
		</div>
		<br /><br />
		<div id="ts-panel">
			<span style="font-weight:bold;">Summary of Tasks Assigned</span>
		</div>
		<div id="expand-collapse">
			<a data-role="collapse-all"><img id="Img2" src="/Images/minus.gif" runat="server"/></a>
			<a data-role="expand-all"><img id="Img1" src="/Images/plus.gif" runat="server"/></a>
		</div>
		<div id="summary-tasks-table" class="task-table-wrapper" data-drop-sid="-1">
			<div class="collapsible-item row" data-collapse-state="collapsed" data-task-type="1">
				<div class="title-bar" data-collapse-target="true">
					<i class='fa fa-plus-square-o' data-role='expand-indicator'></i>
					<span class="tasks-title">Assigned To Me - No Status</span>
				</div>
				<div class="collapsed clear-fix table-viewport">
					<table class="expanded-table">
						<tbody></tbody>
					</table>
				</div>
			</div>
			<taskSummary:Throbber runat="server" />
		</div>
		<div id="status-tasks-table" class="task-table-wrapper">
			<div class="collapsible-item row" data-collapse-state="collapsed" data-task-type="2">
				<div class="title-bar" data-collapse-target="true">
					<i class='fa fa-plus-square-o' data-role='expand-indicator'></i>
					<span class="tasks-title">Assigned To Me - With Status</span>
				</div>
				<div class="collapsed clear-fix table-viewport">
					<table class="expanded-table">
						<tbody></tbody>
					</table>
				</div>
			</div>
			<taskSummary:Throbber runat="server" />
		</div>
		<div id="managed-tasks-table" class="task-table-wrapper" data-drop-sid="-1">
			<div class="collapsible-item row" data-collapse-state="collapsed" data-task-type="1">
				<div class="title-bar" data-collapse-target="true">
					<i class='fa fa-plus-square-o' data-role='expand-indicator'></i>
					<span class="tasks-title">Assigned To Others</span>
				</div>
				<div class="collapsed clear-fix table-viewport">
					<table class="expanded-table">
						<tbody></tbody>
					</table>
				</div>
			</div>
			<taskSummary:Throbber runat="server" />
		</div>
	</div>
	</form>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


