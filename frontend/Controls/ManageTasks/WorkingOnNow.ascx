<%@ Control Language="C#" AutoEventWireup="true" Codebehind="WorkingOnNow.ascx.cs" Inherits="QProcess.Controls.Controls_ManageTasks_WorkingOnNow" %>

<fieldset>
	<legend>Working on now</legend>
	<div class="working-on-now">
		<div id="divInstructions" runat="server" visible="false" style="font-size:.8em;font-weight:bold">
			<span style="color:red">Warning:
			this task has no current due date.</span>
			<ul style="margin:3px 0px 0px 15px">
				<li>
					Update the schedule below to activate the next due date.</li>
				<li id="liOption2" runat="server">
					OR: <a href="#" data-role="activate-instance">Click here</a>
					to open the next task instance, if you are not changing the schedule.</li>
			</ul>
		</div>
		<ul style="margin-left:14px" id="ulTasks" runat="server">
			<asp:repeater id="rptActive" runat="server">
				<itemtemplate>
					<li>
                        <a href="#" data-role="open-due-date" data-due-date-id="<%# (Container.DataItem as QProcess.Repositories.ActiveDueDate).Id %>">
							Due <%# (Container.DataItem as QProcess.Repositories.ActiveDueDate).DueTime.ToString("M/d/yy h:mm tt") %>
						</a>
					</li>
				</itemtemplate>
			</asp:repeater>
		</ul>
	</div>
</fieldset>
<!-- Copyright © 2024 Renegade Swish, LLC -->

