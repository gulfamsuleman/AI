<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MyStatusPrint.aspx.cs" Inherits="QProcess.MyStatusPrint" MasterPageFile="PrintMaster.master" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/PrintBase.css" rel="stylesheet" />
	<link href="Content/PrintBlackAndWhite.css" rel="stylesheet" />
	<link href="Content/PrintLargeFont.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<script>
		var reportId;
		var isArchive;
		var statusReport;

		$().ready(function () {
			reportId = $("#report-id").val();
			isArchive = $("#is-archive").val();
			statusReport = $("#status-report");

			loadStatusReport();
		});

		function doPrint() {
			setPrinting();
			window.print();
		}

		function setPrinting() {
			var factory = document.getElementById("factory");
			factory.printing.leftMargin = .1;
			factory.printing.topMargin = .1;
			factory.printing.rightMargin = .1;
			factory.printing.bottomMargin = .1;
			factory.printing.header = $(".report-line-header").first().text().trim();
			factory.printing.footer = '&b&bPage &p of &P';
		}

		function loadStatusReport() {
			var params = {
				ReportId: reportId,
				IsArchive: isArchive
			};
			statusReport.load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/StatusReport.ascx"), params, function () {
				statusReport.removeClass("hidden");
				$("table.status-table").each(function () {
					var tbl = $(this);
					tbl.find("input[data-role=take-control]").remove();
				});
				// Remove stuff that doesn't need to be printed
				$(".hidden").remove();
				$("th.report-line-headings-action").remove();
				$("a[data-role=complete-task]").closest("td").remove();
				$("a[data-role=reopen-task]").closest("td").remove();
				$("a[data-role=expand-task]").remove();
				$("a[data-role=expand-general]").remove();
				$("a[data-action=add-comment]").remove();
				$("th.report-line-headings-progress").remove();
				$("br").remove();
				$('tr[data-state=view]').each(function () {
					var self = $(this);
					var comment = self.find('td:last').attr("colspan", "3");
					if($(comment).text().trim().length > 0) {
						self.after('<tr class="report-line-content comments-section">').next().append(comment);
					} else {
						$(comment).remove();
					}
				});
			});
		}
	</script>
	<!-- MeadCo ScriptX -->
	<object id="factory" viewastext style="display:none"
		classid="clsid:1663ed61-23eb-11d2-b92f-008048fdd814"
            codebase="smsx.cab#Version=7,5,0,20">
	</object>
	<input type="button" onclick="doPrint();" value="Print" />
	<div id="status-report"></div>
	<input type="hidden" id="user-id" value="<%= UserId %>" />
	<input type="hidden" id="report-id" value="<%= ReportId %>"/>
	<input type="hidden" id="is-archive" value="<%= IsArchive %>"/>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

