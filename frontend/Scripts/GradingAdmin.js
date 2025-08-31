var gradingAdminModule = (function() {
	var self = {};
	var gradingPeriod = $("#grading-periods");
	var sortColumn = $("#sort-column");
	var modal = window.modalModule;
	var sortBy = queryObj()["sortBy"];
	var sortOrder = queryObj()["sortOrder"];

	$().ready(function () {
		gradingPeriod.change(changeGradingPeriod);
		$("[data-sort]").click(function (e) { sortByRow(e); });
		document.addEventListener("modalModuleClose", function () {
			$("#grading-admin-details-panel").off();
		});
	});

	function sortByRow(e) {
		var period = gradingPeriod.find("option:selected").val();
		var field = $(e.currentTarget).data("sort");
		var order = getSortOrder(field);
		window.location.href = "GradingAdmin.aspx?period=" + period + "&sortBy=" + field + "&sortOrder=" + order;
	}

	function getSortOrder(field) {
		if (field == sortColumn.val())
			return "Desc";
		else
			return "Asc";
	}

	self.openGradingDetail = function(e) {
		var rowId = $(e).closest("tr").data("id");
		modal.init({
			titleText: "Grading Details",
			controlName: "Controls/Grading/GradingAdminDetails.ascx",
			remoteParams: { UserId: rowId }
		});
	};

	function changeGradingPeriod() {
		var selected = gradingPeriod.find("option:selected").val();
		var href = "GradingAdmin.aspx?period=" + selected;
		if (sortBy)
			href += "&sortBy=" + sortBy;
		if (sortOrder)
			href += "&sortOrder=" + sortOrder;
		window.location.href = href;
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

