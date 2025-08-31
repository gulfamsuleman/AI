<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Outprocessing.aspx.cs" Inherits="QProcess.Outprocessing" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <script src="Scripts/Outprocessing.js"></script>
    <link href="Content/Outprocessing.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <h3><%=ConfigurationManager.AppSettings["Firm"] %> System User Outprocessing</h3>
    <h4>Please select employee to begin outprocessing and reassignment of tasks:</h4>

    <div class="parent-container">
        <div class="select-container">
            <label for="outprocess-employee-target-select">Choose supervised<br />User:</label>
            <select class="max-content" id="outprocess-employee-target-select" size="10">
                <asp:Repeater ID="SupervisedEmployees" runat="server">
                    <ItemTemplate>
                        <option value="<%#Eval("Id") %>"><%#Eval("FullName") %></option>
                    </ItemTemplate>
                </asp:Repeater>
            </select>
        </div>
        <div class="select-container">
            <label for="supervised-all-employee-select">Choose User<br /> To Reassign Tasks To:</label>
            <select class="max-content" id="supervised-all-employee-select" size="10">
                <asp:Repeater ID="AllEmployees" runat="server">
                    <ItemTemplate>
                        <option value="<%#Eval("Id") %>"><%#Eval("FullName") %></option>
                    </ItemTemplate>
                </asp:Repeater>
            </select>
        </div>
        
        <span>
            <button onclick="outprocessUserConfirm()" id="outprocess-user" class="btn btn-default">Begin User Outprocess</button>
        </span>

    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

