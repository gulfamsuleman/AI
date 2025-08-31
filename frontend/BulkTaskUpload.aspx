<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="BulkTaskUpload.aspx.cs" Inherits="QProcess.BulkTaskUpload" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="Content/BulkTaskUpload.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/BulkTaskUpload.css")).Ticks.ToString() %>" />
    <script src="Scripts/BulkTaskUpload.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/BulkTaskUpload.js")).Ticks.ToString() %>" type="text/javascript"></script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div id="formContainer">
        <form id="uploadForm" runat="server">
            <div id="uploadContainer">
                <span>
                    <h3>Bulk Task Upload</h3>
                </span>
                <h4>How To Use:</h4>
                &bull; Multiple tasks can be uploaded at once by downloading and filling out the below CSV template file.<br />
                &bull; The required fields are: 
                <ul>
                    <li><b>Task</b></li>
                    <li><b>Due Date (mm/dd/yyyy)</b></li>
                    <li><b>Controller 1</b></li>
                    <li><b>Assignee 1</b></li>
                </ul>
                &bull; If a Status Report Name is included, then it must be accompanied by a valid Status Report Section name.<br />
                &bull; All other fields are optional. If there is an error in one of the rows, the upload will be unsuccessful<br />
                and will alert you of the needed changes.<br />
                &bull; Fields left blank will be autofilled with your set preferences.
                These can be changed by going to the<br />
                Preferences page found at the bottom toolbar.
                <br />
                <span>
                    <asp:Button class="btn btn-secondary bulk-upload-button" ID="downloadTemplateBtn" OnClick="DownloadTemplate" Text="Download Task Template" runat="server" />
                </span>
                <asp:FileUpload ID="taskCsvUpload" CssClass="bulk-upload-button file-upload" runat="server" />
                <asp:Button class="btn btn-secondary bulk-upload-button" ID="btnCsvImport" runat="server" Text="Import Task List" OnClick="ImportCsv" />
            </div>
        </form>
        <div id="resultContainer" style="max-width: 50%;">
            <asp:Label ID="resultMessageLabel" runat="server" Text="" />
        </div>
    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptContent" runat="server">
    <script type="text/javascript">
        $(document).ready(function () {
            resize();
            window.onresize = resize;
        });
        function resize() {
            //console.log("resizing");
            $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
            $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
            //console.log("resized");
        }
    </script>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


