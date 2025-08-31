var preferencesModule = (function() {
	var self = {};
	var modal = window.modalModule;
	
	$().ready(function() {
		$("button[data-action='save-close']").click(function () {
			setPreferences();
		});
	});

    function setPreferences() {
        try {
            $.ajax({
                url: "/DataService.asmx/SetPreferences",
                type: "POST",
                data: {
                    assignee: $("select[data-role='assignee']").val() || -1,
                    controller: $("select[data-role='controller']").val() || -1,
                    due: $("select[data-role='deadline']").val() || -1,
                    report: $("select[data-role='report']").val() || -1,
                    priority: $("select[data-role='priority']").val() || -1,
                    alert: $("select[data-role='alert']").val() || -1,
                    softDue: $("select[data-role='soft-deadline']").val() || -1,
                    eChecklist: $("select[data-role='echecklist']").val() || -1,
                    weeklySumEmail: $("input[data-role='weeklySumEmail']").prop("checked")
                },
                contentType: "application/x-www-form-urlencoded",
                success: function (data) {
                    setBulkImportPreferences();
                },
                error: function (xhr, status, error) {
                    alert(
                        "AJAX error:\n" +
                        "Status: " + status + "\n" +
                        "Error: " + error + "\n" +
                        "Response: " + xhr.responseText
                    );
                }
            });
        } catch (ex) {
            alert("JavaScript error: " + ex.message);
        }
    }

	function setBulkImportPreferences() {
		$.ajax({
			url: "/DataService.asmx/SetBulkImportPreferences",
			type: "POST",
			data: {
                bulkAssignee: $("select[data-role='bulk-assignee']").val() || -1,
                bulkController: $("select[data-role='bulk-controller']").val() || -1,
                bulkDue: $("select[data-role='bulk-due-date']").val() || null,
                bulkReport: $("select[data-role='bulk-report']").val() || -1,
                bulkPriority: $("select[data-role='bulk-priority']").val() || -1,
                bulkSoftDue: $("select[data-role='bulk-soft-due-date']").val() || -1
			},
			contentType: "application/x-www-form-urlencoded",
			success: function (data) {
				modal.hide();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

