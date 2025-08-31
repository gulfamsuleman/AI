<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Inprocess.aspx.cs" Inherits="QProcess.Inprocess" MasterPageFile="BlankMaster.master" %>
<%@ Register TagPrefix="sa" TagName="Supervisors" Src="~/Controls/Shared/Supervisors.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Inprocess.css?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/Inprocess.css")).Ticks.ToString() %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/common.js?v=5"></script>
	<script src="Scripts/Inprocess.js?v=2024081402"></script>	
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="supervisor-admin-panel">
		<div class="panel-body">
			<div class="form-inline">
				<%if (QUser.IsAdmin)
					{ %>
					<label class="control-label">Reports: </label>
				<%}
					else
					{ %>
				<label class="control-label">Welcome to <%=AppName %>, <%=QUser.FullName %>! We just need a couple pieces of information to finish setting up your user account.</label>
				<%} %>
				<select id="report-select" class="form-control input-sm" 
					<%if (!QUser.IsAdmin) { %> 
					disabled="disabled" style="display:none;"
					<%} %>>

					<asp:Repeater ID="Repeater1" DataSource=<%# Reports %> runat="server">
						<ItemTemplate>
							<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
						</ItemTemplate>
					</asp:Repeater>
				</select>
				<br/><br/>
			</div>
            <div id="throbber" class="throbber hidden">
	            <img src="/Images/loading.gif"/>
	            <span>Loading...</span>	
           	</div>

			<div id="hideable-area" class="hidden">
				
				<div class="panel panel-default">
					<%if (!QUser.IsAdmin && (Firm == "PHI" || Firm == "PFS"))
					{ %> 
					<div class="panel-body">
					<div style ="margin-bottom:9px;">Please enter your <%=Firm %> Employee ID (if you don't know it, ask your supervisor or your HR department):</div>
						<input type="number" id="empId" />
					</div>
					<%} %>
						<%if (QUser.IsAdmin)
							{ %> 
					<div class="panel-heading">
						Supervisors and Interested Parties
					</div>
						<%}
							else
							{ %>
						<div style="margin-left:16px">Please find the name of your direct supervisor at <%=Firm %> in the dropdown and click "Add", then click "Continue" below:</div>
						<%} %>
					
					<div class="panel-body supervisor-body"><sa:Supervisors ID="Supervisors" runat="server"/></div>
					<%if (!QUser.IsAdmin)
						{ %> 
					<div class="panel-body">
						<button data-role="continue" class="btn btn-sm btn-default btn-continue">
									<i class="fa fa-arrow-right"></i> Continue
						</button>
					</div>
					<%} %>
				</div>
              
			</div>
		</div>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

