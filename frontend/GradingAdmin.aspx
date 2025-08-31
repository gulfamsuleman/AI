<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="GradingAdmin.aspx.cs" Inherits="QProcess.GradingAdmin" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="grading" TagName="GradingPeriods" Src="~/Controls/Grading/GradingPeriods.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/GradingAdmin.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/GradingAdmin.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="grading-admin-panel">
		<h2>Grading Admin</h2>
		<br/>
		<a href="GradingApprovals.aspx">Approvals Page</a>
		<br/>
		<grading:GradingPeriods ID="GradingPeriodsControl" runat="server" />
		<table id="grading-grid" class="table table-condensed">
			<thead>
				<tr>
					<th data-sort="FullName"><a href="#">Name</a></th>
					<th data-sort="Score"><a href="#">Score</a></th>
					<th data-sort="Grade"><a href="#">Grade</a></th>
					<th data-sort="GradePrevious"><a href="#">Previous Grade</a></th>
					<th data-sort="ControllerDeductions"><a href="#">Controller Deductions</a></th>
					<th data-sort="SupervisorDeductions"><a href="#">Supervisor Deductions</a></th>
					<th data-sort="StatusOverdue"><a href="#">Overdue Deductions</a></th>
					<th data-sort="ChecklistOverdue"><a href="#">Checklist Overdue Deductions</a></th>
					<th data-sort="IPBonus"><a href="#">IP Bonus</a></th>
					<th data-sort="TenDayDeduction"><a href="#">Ten Day Deduction</a></th>
					<th data-sort="AdjustmentPoints"><a href="#">Adjustment</a></th>
					<th data-sort="AdjustmentReason"><a href="#">Adjustment Reason</a></th>
					<th data-sort="TotalComments"><a href="#">Total Comments</a></th>
					<th data-sort="TotalCharacters"><a href="#">Total Characters</a></th>
					<th data-sort="TotalTime"><a href="#">Total Time (mins)</a></th>
					<th data-sort="ControllerComments"><a href="#">Controller Comments</a></th>
					<th data-sort="ControllerCharacters"><a href="#">Controller Characters</a></th>
					<th data-sort="ControllerTime"><a href="#">Controller Time (mins)</a></th>
					<th data-sort="SupervisorComments"><a href="#">Supervisor Comments</a></th>
					<th data-sort="SupervisorCharacters"><a href="#">Supervisor Characters</a></th>
					<th data-sort="IPComments"><a href="#">IP Comments</a></th>
					<th data-sort="IPCharacters"><a href="#">IP Characters</a></th>
					<th data-sort="SupervisortTime"><a href="#">Supervisor/IP Time (mins)</a></th>
				</tr>	
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater1" DataSource=<%# GridLines %> runat="server">
					<ItemTemplate>
						<tr data-id="<%#Eval("Id") %>">
							<td><a href="#" onclick="gradingAdminModule.openGradingDetail(this)"><%#Eval("FullName") %></a></td>
							<td><%#Eval("Score") %></td>
							<td><%#Eval("Grade") %></td>
							<td><%#Eval("GradePrevious") %></td>
							<td><%#Eval("ControllerDeductions") %></td>
							<td><%#Eval("SupervisorDeductions") %></td>
							<td><%#Eval("StatusOverdue") %></td>
							<td><%#Eval("ChecklistOverdue") %></td>
							<td><%#Eval("IPBonus") %></td>
							<td><%#Eval("TenDayDeduction") %></td>
							<td><%#Eval("AdjustmentPoints") %></td>
							<td><%#Eval("AdjustmentReason") %></td>
							<td><%#Eval("TotalComments") %></td>
							<td><%#Eval("TotalCharacters") %></td>
							<td><%#Eval("TotalTime") %></td>
							<td><%#Eval("ControllerComments") %></td>
							<td><%#Eval("ControllerCharacters") %></td>
							<td><%#Eval("ControllerTime") %></td>
							<td><%#Eval("SupervisorComments") %></td>
							<td><%#Eval("SupervisorCharacters") %></td>
							<td><%#Eval("IPComments") %></td>
							<td><%#Eval("IPCharacters") %></td>
							<td><%#Eval("SupervisorTime") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
		<input id="sort-column" type="hidden" value="<%=SortedColumn %>"/>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


