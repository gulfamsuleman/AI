<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="ReassignControllers.aspx.cs" Inherits="QProcess.ReassignControllers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" Runat="Server">
	<link href="Content/ReassignControllers.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ScriptContent" Runat="Server">
	<script src="Scripts/ReassignControllers.js"></script>
    <script src="Scripts/jquery.tablesorter.min.js"></script>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" Runat="Server">
	<input type="hidden" id="username" value="<%=username %>" />
    <div id="reassign-panel" class="reassign-panel">
        <h2>Reassign Controllers</h2>
        <span class="leftLabel">
			Show Tasks Controlled By: 
        </span>
        <span>
            <select id="member-select" class="input-sm">
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
				</ItemTemplate>
			</asp:Repeater>
			</select>

        </span>
        <br />
        <br />
            <span class="leftLabel">
			Change Controller To:
        </span>
        <span>
            <select id="new-member-select" class="input-sm" size="10" multiple="multiple">
			<asp:Repeater ID="Repeater2" runat="server">
				<ItemTemplate>
					<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
				</ItemTemplate>
			</asp:Repeater>
			</select>

        </span>
        <br />
        <br />
        <span class="leftLabel">
			<button data-action="reassign" class="btn btn-sm btn-default">Change Controller</button>
        </span>
        <br />
        <br />
        <span>
            <span class="bold" style="display:block;">Tasks Controlled</span>
            <span class="wideIndent">
                Tasks highlighted in YELLOW are new or have changed controllers since the last time you used this tool.
            </span>
            <br />
            <br />
            <span class="wideIndent">
                <input id="toggle-show-new" type="checkbox"/> Only show new / changed
            </span>
            <br />
            <br />
            <span class="wideIndent">
                <input id="toggle-show-non-complete" type="checkbox"/> Only show tasks not completed
            </>
            <br />
            <br />
            </span>
        </span>
        <div id="throbber" class="throbber">
	        <img src="/Images/loading.gif"/>
	        <span>Loading...</span>	
        </div>
        <div class="wideIndent">
            <table id="controlledTasksTable" class="reassigntable">
                <thead>
                    <tr>
                        <th><input type="checkbox" id="check-all" data-action="check-all" /></th>
                        <th>Task</th>
                        <th>Controllers</th>
                        <th>Assignees</th>
                    </tr>
                </thead>
                <tbody>
                   
                </tbody>
            </table>
        </div>
		<br/>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

