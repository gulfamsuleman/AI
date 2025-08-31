<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="AuthTokenEmailRequest.aspx.cs" Inherits="QProcess.AuthTokenEmailRequest" MasterPageFile="~/Site.master" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link rel="stylesheet" href="Content/AuthTokenEmailRequest.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/AuthTokenEmailRequest.css")).Ticks.ToString() %>" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <link rel="stylesheet" href="Content/datepicker.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/datepicker.css")).Ticks.ToString() %>" />
    <script type="text/javascript" src="Scripts/AuthTokenEmailRequest.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/AuthTokenEmailRequest.js")).Ticks.ToString() %>"></script>
    <script tpe="text/javascript" src="Scripts/jquery.lw-datepicker.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.lw-datepicker.js")).Ticks.ToString() %>""></script>
    <link href="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.css" rel="stylesheet">
    <script src="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <form id="form1" runat="server">
        <div id="auth-container" class="row">
            <div id="form-container" class="col-med-6">
                <h3>3rd Party Access Request</h3>

                <p>
                    Please enter the full name of the user associated this access request, the approving party, as well as the related domain for which this key is intended.<br />
                    <br />
                    Upon submission, you will recieve credentials to provide to the user in a secured email.
                </p>

                <div class="col-med-6">
                    <label for="fullName">Full Name:</label>
                    <input class="form-control" id="fullName" type="text" />
                    <label for="approvedBy">Approved By:</label>
                    <input class="form-control" id="approvedBy" type="text" />
                    <label for="onBehalfOf">On Behalf Of:</label>
                    <input class="form-control" id="onBehalfOf" type="text" />
                    <label for="Intent">Domain:</label>
                    <input class="form-control" id="intent" type="text" />
                </div>
                <br />
                <label for="postDatePicker">Not active before this date (optional):</label>
                <input type="text" id="postDatePicker" />

                <button id="emailSubmit" class="btn env-specific-btn" onclick="sendEmail()">Submit Request</button>
            </div>

            <div id="infoNotice-container" class="col-med-6">
            </div>

        </div>
    </form>
    <div id="allKeys">
    </div>
    <div id="signingKey-container">
        <div id="signingKeys">
        </div>
        <div id="signingKeyNotice">
            <p>
                Creating a new signing key will create a new key by which all future API keys will be derived from.
                Upon creating this new key, all previously generated API keys will continue to work only until their set expiration dates.
            </p>

            <button id="signingKeyBtn" class="btn env-specific-btn" onclick="createNewSigningKey()">Create Signing Key</button>
        </div>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

