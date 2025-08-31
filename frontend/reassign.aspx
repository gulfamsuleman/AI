<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Reassign.aspx.cs" Inherits="QProcess.Reassign" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" Runat="Server">
	<link href="Content/Reassign.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ScriptContent" Runat="Server">
	<script src="Scripts/Reassign.js"></script>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" Runat="Server">
    <div id="reassign-panel" class="reassign-panel">
		<h2>Reassign tasks for <%=ReassignName%></h2>
		<span>
            <span class="leftLabel">
			    Reassign All Selected To
            </span>
            <span>
                <select id="reassign-member-select" class="input-sm">
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
					</ItemTemplate>
				</asp:Repeater>
			    </select>
                
                <button data-action="reassign" class="btn btn-sm btn-default">Reassign</button>

                <input id="addToStatusChk" data-role="addStatus" type="checkbox"/> Add to Status Report
            </span>
		</span>
		<br/>
		<br/>
        <span>
		    <span class="leftLabel">
			    Remove All Selected Assignments 
            </span>
            <span>
                 <button data-action="removeAssignment" class="btn btn-sm btn-default">Remove</button>
            </span>
        </span>
        <br/>
		<br/>
        <span>
		    <span class="leftLabel">
			    Delete All Selected Tasks
            </span>
            <span>
                 <button data-action="deleteTask" class="btn btn-sm btn-default">Delete</button>
            </span>
        </span>
        <br /><br />
        <span class="wideLabel">
			<span class="bold">How to use this tool:</span> For each task below, the goal is to either reassign the task/status report or remove the assignment/association. 
            If more than one person is assigned to the task and no one new is taking over the task, it may be ok to simply remove the assignment/association by checking the box next to the task and clicking the Remove button at the top of the page. 
            Otherwise, you should probably reassign the task to someone else using the dropdown at the top.
            <br /> <br />
            If nobody needs to do the task anymore, you can use the Delete button to completely delete tasks.  This is more rare, and should only be done for tasks that clearly only apply to this one person.
            <br /> <br />
            Reassigning is complete when there are no more tasks or status reports listed on this page.
        </span>
        <br /><br />
        <div class="wideIndent">
            <span class="bold">Controlled Status Reports</span>
		    <table id="reassign-status-controllers-table" class="table-condensed reassigntable">
			    <thead>
				    <tr>
					    <th><input type="checkbox" data-action="check-all-status-controller" /></th>
					    <th>Status Report</th>
					    <th>Controllers</th>
					    <th>Supervisors/IP</th>
				    </tr>
			    </thead>
			    <tbody>
				    <asp:Repeater ID="Repeater2" runat="server">
					    <ItemTemplate>
						    <tr data-role="status-controller-id" data-id="<%#Eval("ReportID") %>">
							    <td><input data-role="status-controller" type="checkbox"/></td>
							    <td><%#Eval("ReportName") %></td>
							    <td><%#Eval("Controllers") %></td>
							    <td><%#Eval("SupervisorsIP") %></td>
						    </tr>
					    </ItemTemplate>
				    </asp:Repeater>
			    </tbody>
		    </table>
        </div>
        <br /><br />
        <div class="wideIndent">
            <span class="bold">Status Reports Supervised/Interested Party </span>
		    <table id="reassign-status-supervisor-table" class="table-condensed reassigntable">
			    <thead>
				    <tr>
					    <th><input type="checkbox" data-action="check-all-status-supervisor" disabled = "disabled"/></th>
					    <th>Status Report</th>
					    <th>Controllers</th>
					    <th>Supervisors/IP</th>
				    </tr>
			    </thead>
			    <tbody>
				    <asp:Repeater ID="Repeater3" runat="server">
					    <ItemTemplate>
						    <tr data-role="status-supervisor-id" data-id="<%#Eval("ReportID") %>">
							    <td><input data-role="status-supervisor" type="checkbox" disabled = "disabled"/></td>
							    <td><%#Eval("ReportName") %></td>
							    <td><%#Eval("Controllers") %></td>
							    <td><%#Eval("SupervisorsIP") %></td>
						    </tr>
					    </ItemTemplate>
				    </asp:Repeater>
			    </tbody>
		    </table>
        </div>
        <br /><br />
        <div class="wideIndent">
            <span class="bold">Tasks Assigned</span>
		    <table id="reassign-assigned-table" class="table-condensed reassigntable">
			    <thead>
				    <tr>
					    <th><input type="checkbox" data-action="check-all-task-assigned" /></th>
					    <th>Name</th>
					    <th>Assignees</th>
					    <th>Controllers</th>
					    <th>Status Reports</th>
				    </tr>
			    </thead>
			    <tbody>
				    <asp:Repeater ID="Repeater4" runat="server">
					    <ItemTemplate>
						    <tr data-role="task-assigned-id" data-id="<%#Eval("Id") %>">
							    <td><input data-role="task-assigned" type="checkbox"/></td>
							    <td><%#Eval("Name") %></td>
							    <td><%#Eval("Assignees") %></td>
							    <td><%#Eval("Controllers") %></td>
							    <td><%#Eval("Alertees") %></td>
						    </tr>
					    </ItemTemplate>
				    </asp:Repeater>
			    </tbody>
		    </table>
        </div>
        <br /><br />
        <span class="wideIndent">
            <span class="bold">Tasks Controlled</span>
		    <table id="reassign-controlled-table" class="table-condensed reassigntable">
			    <thead>
				    <tr>
					    <th><input type="checkbox" data-action="check-all-task-controlled" /></th>
					    <th>Name</th>
					    <th>Assignees</th>
					    <th>Controllers</th>
					    <th>Status Reports</th>
				    </tr>
			    </thead>
			    <tbody>
				    <asp:Repeater ID="Repeater5" runat="server">
					    <ItemTemplate>
						    <tr  data-role="task-controlled-id" data-id="<%#Eval("Id") %>">
							    <td><input data-role="task-controlled" type="checkbox"/></td>
							    <td><%#Eval("Name") %></td>
							    <td><%#Eval("Assignees") %></td>
							    <td><%#Eval("Controllers") %></td>
							    <td><%#Eval("Alertees") %></td>
						    </tr>
					    </ItemTemplate>
				    </asp:Repeater>
			    </tbody>
		    </table>
        </span>
        <br /><br />
        <span class="wideIndent">
            <span class="bold">Alertee</span>
		    <table id="reassign-alert-table" class="table-condensed reassigntable">
			    <thead>
				    <tr>
					    <th><input type="checkbox" data-action="check-all-task-alertee" /></th>
					    <th>Name</th>
					    <th>Assignees</th>
					    <th>Controllers</th>
					    <th>Status Reports</th>
				    </tr>
			    </thead>
			    <tbody>
				    <asp:Repeater ID="Repeater6" runat="server">
					    <ItemTemplate>
						    <tr data-role="task-alertee-id" data-id="<%#Eval("Id") %>">
							    <td><input data-role="task-alertee" type="checkbox"/></td>
							    <td><%#Eval("Name") %></td>
							    <td><%#Eval("Assignees") %></td>
							    <td><%#Eval("Controllers") %></td>
							    <td><%#Eval("Alertees") %></td>
						    </tr>
					    </ItemTemplate>
				    </asp:Repeater>
			    </tbody>
		    </table>
        </span>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

