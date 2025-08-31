<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ChangeRequestComments.ascx.cs" Inherits="QProcess.Controls.Shared.ChangeRequestComments" %>

<div>
    <div class="cr-comments-container">
        <form ID="crForm" runat="server">
            <asp:textbox ID="ChangeRequestBody" runat="server" TextMode="MultiLine" placeholder="Enter comments here"></asp:textbox>
            <asp:Button class="btn btn-primary" ID="submitComments" runat="server" Text="Submit Comments" OnClick="SubmitComments" />
        </form>
    </div>
</div>
