var statusReportsBox = function (containerElem) {
	var self = {};
	var statusReportsPanel = $("div.status-reports-panel", containerElem);
	var reportDiv = $("div.report-div", statusReportsPanel);
	var reportSelectionDiv = $("div.report-selection-div", statusReportsPanel);
	var statusReportsTable = $("table.status-reports-table", statusReportsPanel);
	function populateStatusReportSectionSelect() {
		$.ajax({
			url: "../DataService.asmx/GetTaskTypesForReport",
			type: "POST",
			data: JSON.stringify({ reportId: $("select[data-set='folders']", reportDiv).val() }),
			dataType: "json",
			contentType: "application/json",
			success: function (response) {
				var select = $("select[data-set='sections']", reportSelectionDiv).html("");
				for (var sectionIndex in response.d) {
					var section = response.d[sectionIndex];
					select.append('<option value="' + section.Id + '" >' + section.Name + '</option>');
				}
			},
			error: function (thing) {
				alert("An error occurred while processing your request.");
			}
		});
	}
	function populateStatusReportSectionSelectHighlight(selectedVal) {
	    $.ajax({
	        url: "../DataService.asmx/GetTaskTypesForReport",
	        type: "POST",
	        data: JSON.stringify({ reportId: $("select[data-set='folders']", reportDiv).val() }),
	        dataType: "json",
	        contentType: "application/json",
	        success: function (response) {
	            var select = $("select[data-set='sections']", reportSelectionDiv).html("");
	            for (var sectionIndex in response.d) {
	                var section = response.d[sectionIndex];
	                select.append('<option value="' + section.Id + '" >' + section.Name + '</option>');
	            }
	            select.val(selectedVal);
	        },
	        error: function (thing) {
	            alert("An error occurred while processing your request.");
	        }
	    });
	}

	function addStatusReportsRow(statusReport) {
		var rowTemplate = "<tr data-status='" + JSON.stringify(statusReport) + "'>" +
								"<td data-item=\"actions\">" +
									"<a data-role=\"delete\" data-id=\"{2}\"><img src=\"/Images/delete.gif\" title=\"Remove\"/></a>" +
								"</td>" +
								"<td data-item=\"report\">{0}</td>" +
								"<td data-item=\"section\">{1}</td>" +
							"</tr>";
		statusReportsTable.find("tbody").append(format(rowTemplate, statusReport.reportName, statusReport.sectionName, statusReport.id));
		if (statusReportsTable.hasClass("hidden")) {
			statusReportsTable.removeClass("hidden");
		}
	}
	function removeStatusReportRow(jqElem) {
		$(jqElem).remove();
		var rows = statusReportsTable.find("tbody tr");
		if (rows.length == 0) {
			if (!statusReportsTable.hasClass("hidden")) {
				statusReportsTable.addClass("hidden");
			}
		}
	}
	function showReportDetailsDiv() {
		if (reportSelectionDiv.hasClass("hidden")) {
			reportSelectionDiv.removeClass("hidden");
		}
	}
	self.folderChanged = function () {
		populateStatusReportSectionSelect();
		showReportDetailsDiv();
	};
	self.populateStatusReports = function(instanceId) {
		$.ajax({
			url: "../DataService.asmx/GetReportsForInstance",
			type: "POST",
			data: JSON.stringify({ instanceId: instanceId }),
			dataType: "json",
			contentType: "application/json",
			success: function(response) {
				var select = $("select[data-set='folders']", reportDiv).html("").append('<option value="-1"></option>');
				for (var groupIndex in response.d) {
					var group = response.d[groupIndex];
					var optgroup = $('<optgroup label="' + group.Name + '"></optgroup>').appendTo(select);
					for (var reportIndex in group.Entities) {
						var report = group.Entities[reportIndex];
						optgroup.append('<option value="' + report.Id + '" >' + report.Name + '</option>');
					}
					if ($("#hidStatusReport").val() != "") {
					    var option = optgroup.find('option[value="' + $("#hidStatusReport").val() + '"]')//added by venkat 06/14/2018

					    option.attr('selected', true);//added by venkat 06/14/2018
					    populateStatusReportSectionSelectHighlight($("#hidStatusReportSection").val());//added by venkat 06/14/2018
					    showReportDetailsDiv();//added by venkat 06/14/2018
					}
					else
					{
					    select.val(-1);
					}
				}
				//select.val(-1);//commented by venkat 06/14/2018
				
				
			},
			error: function(thing) {
				alert("An error occurred while processing your request.");
			}
		});
	};
	self.addReport = function () {
		var newStatusReport = {};
		newStatusReport.reportId = $("select[data-set='folders']", statusReportsPanel).val();
		newStatusReport.reportName = $("select[data-set='folders'] option:selected", statusReportsPanel).text();
		newStatusReport.sectionId = $("select[data-set='sections']", statusReportsPanel).val();
		newStatusReport.sectionName = $("select[data-set='sections'] option:selected", statusReportsPanel).text();
		var data = {};
		data.taskInstanceId = $(statusReportsPanel).closest("[data-instance-id]").attr("data-instance-id");
        data.sectionId = newStatusReport.sectionId;
		$.ajax({
		    url: "../DataService.asmx/AddExistingTaskToSection",
		    type: "POST",
		    data: JSON.stringify(data),
		    dataType: "json",
		    contentType: "application/json; charset=utf-8",
		    success: function (response) {
		        newStatusReport.id = response.d;
		        var existing = $(".status-reports-panel > table > tbody > tr > td[data-item='report']:contains('" + $(".status-reports-panel > div > select[data-set='folders'] option:selected").text() + "')");
		        if (existing.length == 1) {
		            statusReportsTable.addClass("hidden");
		            removeStatusReportRow($(existing).closest("tr"));
		            addStatusReportsRow(newStatusReport);
		            statusReportsTable.removeClass("hidden");
		        }
		        else {
		            addStatusReportsRow(newStatusReport);
		        }
                
		    }
		});
	};
	self.createStatusReportsRow = function(statusReport) {
		addStatusReportsRow(statusReport);
	};
	self.deleteReport = function (e) {
	    var changeId = $(statusReportsPanel).closest("[data-change-id]").data("change-id");
	    var instanceId = $(e.target).closest(".mtform-assignments").data('instance-id');
	    var instanceTaskTypeID = $(e.target).closest("a").attr("data-id");
	    $.ajax({
	        url: "../DataService.asmx/DeleteInstanceTaskType",
	        data: JSON.stringify({ instanceTaskTypeID: instanceTaskTypeID }),
	        type: "POST",
	        dataType: "json",
	        contentType: "application/json",
	        error: function (data, textStatus, jqXhr) {
	            alert("An error occurred while processing your request.");
	        }
	    });
	    event.stopPropagation();
		removeStatusReportRow($(e.target).closest("tr"));
	};
	$().ready(function () {
		$("select[data-set='folders']", reportDiv).change(self.folderChanged);
		$("button[data-role='add']", reportSelectionDiv).click(self.addReport);
		$(statusReportsTable).on('click', "a[data-role='delete']", self.deleteReport);
		if($(statusReportsPanel).data("status")&&$(statusReportsPanel).data("status").length>0) {
			var data = $(statusReportsPanel).data("status");
			for(var i = 0; i<data.length;i++) {
				addStatusReportsRow(data[i]);
			}
		}
	});
	return self;
};
/* Copyright © 2024 Renegade Swish, LLC */

