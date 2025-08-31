var reportLoadTimesModule = (function() {
	var self = {};
	var fromDate = $("#from-date");
	var toDate = $("#to-date");
	var reportSelect = $("#report-select");
	var userSelect = $("#user-select");
	var sortColumn = $("#sort-column");
	var sortBy = queryObj()["sortBy"];
	var sortOrder = queryObj()["sortOrder"];
	
	$().ready(function () {
		$("button[data-role=filter]").click(reloadReportLoadTimes);
		$("a[data-field]").click(function (e) { sortReportLoadTimes(e); });
		$("button[data-role=export]").click(exportExcel);
	});
	
	function reloadReportLoadTimes() {
		var href = "ReportLoadTimes.aspx?startFilter=" + fromDate.val() +
			"&endFilter=" + toDate.val() +
			"&reportName=" + reportSelect.find("option:selected").text() +
			"&userId=" + userSelect.find("option:selected").val();
		if (sortBy)
			href += "&sortBy=" + sortBy;
		if(sortOrder)
			href += "&sortOrder=" + sortOrder;
		window.location.href = href;
	}
	
	function sortReportLoadTimes(e) {
		var field = $(e.currentTarget).data("field");
		var order = getSortOrder(field);
		var href = "ReportLoadTimes.aspx?startFilter=" + fromDate.val() +
			"&endFilter=" + toDate.val() +
			"&reportName=" + reportSelect.find("option:selected").text() +
			"&userId=" + userSelect.find("option:selected").val() +
			"&sortBy=" + field +
			"&sortOrder=" + order;
		window.location.href = href;
	}
	
	function getSortOrder(field) {
		if (field == sortColumn.val())
			return "Desc";
		else
			return "Asc";
	}
	
	function exportExcel() {
		var options = {
			startFilter:	queryObj()["startFilter"] == undefined ? fromDate.val() : queryObj()["startFilter"],
			endFilter:		queryObj()["endFilter"] == undefined ? toDate.val() : queryObj()["endFilter"],
			reportName:		queryObj()["reportName"] == undefined ? reportSelect.find("option:selected").text() : queryObj()["reportName"],
			userId:			queryObj()["userId"] == undefined ? userSelect.find("option:selected").val() : queryObj()["userId"],
			exportType: 'msexcel',
			pageName: 'ReportLoadTimesExport.aspx'
		};

		var queryString = serialize(options);
		
		if (queryObj()["sortBy"])
			queryString += "&sortBy=" + queryObj()["sortBy"];
		if (queryObj()["sortOrder"])
			queryString += "&sortOrder=" + queryObj()["sortOrder"];

		$('<iframe class="hidden" src=OfficeExportHandler.ashx?' + queryString + '/>').appendTo('body');
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

