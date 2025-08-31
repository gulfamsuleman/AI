var supervisorsModule = (function () {
    var self = {};
    self.supervisorsPanel = $("#supervisors-panel");
    var supervisorsTable = $("#supervisors-table").addClass("hidden");
    var supervisorSelect = $("#supervisor-select");
    self.reportId = $("#report-id").val() != null ? $("#report-id").val() : -1;

    $().ready(function () {
        $("button[data-role='add-supervisor']", self.supervisorsPanel).off('click').click(function () {
            self.addSupervisor();
        });
        $(document).off('click', "a[data-role='delete-supervisor']").on('click', "a[data-role='delete-supervisor']", function (e) {
            e.preventDefault();
            e.stopPropagation();
            self.deleteSupervisor(e);
        });
        $(document).off('click', "input[data-role='interested-party']").on('click', "input[data-role='interested-party']", function (e) { toggleInterestedParty(e); });
        $(document).off('click', "input[data-role='supervisor']").on('click', "input[data-role='supervisor']", function (e) { toggleSupervisor(e); });
    });

    self.getSupervisors = function () {
        $.ajax({
            url: "/DataService.asmx/GetSupervisorsList",
            type: "POST",
            data: JSON.stringify({ reportId: self.reportId }),
            contentType: "application/json",
            success: function (data) {
                var supervisors = data.d;
                supervisorsTable.find("tbody").html(""); // Clear the table content
                for (var i = 0; i < supervisors.length; i++) {
                    addSupervisorTableRow(supervisors[i]);
                }
                if (supervisorsTable.find("tbody tr").length > 0) {
                    supervisorsTable.removeClass("hidden"); // Show the table only after all data is loaded
                }
                if (typeof supervisorsAdminModule != "undefined") {
                    supervisorsAdminModule.supervisorReturn(self.reportId);
                }
                if (typeof inprocessModule != "undefined") {
                    inprocessModule.supervisorReturn(self.reportId);
                }
            }
        });
    };

    function addSupervisorTableRow(supervisor) {
        var rowTemplate =
            "<tr data-id='{0}'>" +
            "{1}" +
            "<td data-item='name'>{2}</td>" +
            "<td class='text-center'>" +
            "<input data-role='interested-party' type='checkbox' {3} {4}>" +
            "</td>" +
            "<td class='text-center'>" +
            "<input data-role='supervisor' type='checkbox' {5} {6}>" +
            "</td>" +
            "</tr>";

        var isCorrectPermission = true;

        var deleteButton = isCorrectPermission ? "<td><a href='' data-role='delete-supervisor'><img src='/Images/delete.gif' title='Remove' /></a></td>" : '';
        var isInterestedParty = supervisor.IsInterestedParty ? "checked='checked'" : '';
        var isSupervisor = supervisor.IsSupervisor ? "checked='checked'" : '';
        var disabled = !isCorrectPermission ? "disabled" : '';
        var newElem = $(format(rowTemplate, supervisor.ID, deleteButton, supervisor.Name, disabled, isInterestedParty, disabled, isSupervisor));
        supervisorsTable.find("tbody").append(newElem);
        return newElem;
    }

    function removeSupervisorTableRow(jqElem) {
        jqElem.remove();
        var rows = supervisorsTable.find("tbody tr");
        if (rows.length == 0) {
            supervisorsTable.addClass("hidden");
        }
    }

    function addSupervisorAjax(supervisor) {
        $.ajax({
            url: "/DataService.asmx/AddSupervisor",
            type: "POST",
            data: JSON.stringify({
                reportId: self.reportId,
                groupId: supervisor.ID
            }),
            dataType: "json",
            contentType: "application/json",
            success: function (response) {
                self.getSupervisors();
            },
            error: function () {
                alert("An error occurred while processing your request.");
            }
        });
    }

    function deleteSupervisorAjax(supervisorId) {
        $.ajax({
            url: "/DataService.asmx/DeleteSupervisor",
            type: "POST",
            data: JSON.stringify({ id: supervisorId }),
            contentType: "application/json",
            success: function (response) {

            },
            error: function () {
                alert("An error occurred while processing your request.");
            }
        });
    }

    self.addSupervisor = function () {
        var newSupervisor = {
            ID: supervisorSelect.val(),
            Name: supervisorSelect.find("option:selected").text(),
        };

        if (newSupervisor.groupId == -1) {
            alert("Please select a user from the list");
            return;
        }
        if (self.reportId == -1) {
            alert("Please select a report from the list");
            return;
        }
        var tableRow = addSupervisorTableRow(newSupervisor);
        addSupervisorAjax(newSupervisor);
    };

    self.deleteSupervisor = function (e) {
        var status = $(e.target).closest("tr");
        var isSupervisor = status.find("input[data-role='supervisor']").prop("checked");
        var remainingSupervisors = $("#supervisors-table input[data-role='supervisor']:checked").length;

        if (isSupervisor && remainingSupervisors === 1) {
            $.ajax({
                url: "/DataService.asmx/IsPersonalReportByReportID",
                type: "POST",
                data: JSON.stringify({ reportId: self.reportId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (data) {
                    if (data.d) {
                        alert("Please add a new supervisor before deleting the current one.");
                    } else {
                        removeSupervisorTableRow(status);
                        deleteSupervisorAjax(status.data("id"));
                    }
                },
                error: function () {
                    alert("An error occurred while processing your request.");
                }
            });
        } else {
            removeSupervisorTableRow(status);
            deleteSupervisorAjax(status.data("id"));
        }
    };

    function toggleInterestedParty(e) {
        var supervisorRow = $(e.currentTarget).closest("tr");
        var isChecked = $(e.currentTarget).prop("checked");

        // Count the number of checked supervisor checkboxes before the change
        var remainingSupervisors = $("#supervisors-table input[data-role='supervisor']:checked").length;

        //alert('remainingSupervisors: ' + remainingSupervisors);
        //alert('isChecked: ' + isChecked);

        // Check if this is the only supervisor and it is being checked
        if (remainingSupervisors === 1 && isChecked) {
            $.ajax({
                url: "/DataService.asmx/IsPersonalReportByReportID",
                type: "POST",
                data: JSON.stringify({ reportId: self.reportId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (data) {
                    if (data.d) {
                        alert("There must always be at least one supervisor of personal status reports. Please add a new supervisor before changing the current one.");
                        // Revert
                        $(e.currentTarget).prop("checked", false);
                        supervisorRow.find("[data-role='supervisor']").prop("checked", true);
                        supervisorRow.find("[data-role='interested-party']").prop("checked", false);
                    } else {
                        // Allow
                        supervisorRow.find("[data-role='supervisor']").prop("checked", !isChecked);
                        toggleInterestedPartyAjax(supervisorRow.data("id"), isChecked);
                    }
                },
                error: function () {
                    alert("An error occurred while processing your request.");
                    // Revert
                    $(e.currentTarget).prop("checked", false);
                    supervisorRow.find("[data-role='supervisor']").prop("checked", true);
                    supervisorRow.find("[data-role='interested-party']").prop("checked", false);
                }
            });
        } else {
            // Allow
            supervisorRow.find("[data-role='supervisor']").prop("checked", !isChecked);
            toggleInterestedPartyAjax(supervisorRow.data("id"), isChecked);
        }
    }

    function toggleSupervisor(e) {
        var supervisorRow = $(e.currentTarget).closest("tr");
        var isChecked = $(e.currentTarget).prop("checked");

        // Count the number of checked supervisor checkboxes before the change
        var remainingSupervisors = $("#supervisors-table input[data-role='supervisor']:checked").length;

        //alert('remainingSupervisors: ' + remainingSupervisors);
        //alert('isChecked: ' + isChecked);


        // Check if this is the only supervisor and it is being unchecked
        if (remainingSupervisors === 0 && !isChecked) {
            $.ajax({
                url: "/DataService.asmx/IsPersonalReportByReportID",
                type: "POST",
                data: JSON.stringify({ reportId: self.reportId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (data) {
                    if (data.d) { // data.d contains the result from the web service
                        alert("There must always be at least one supervisor of personal status reports. Please add a new supervisor before changing the current one.");

                        // Revert the checkbox state
                        $(e.currentTarget).prop("checked", true);
                        supervisorRow.find("[data-role='supervisor']").prop("checked", true);
                        supervisorRow.find("[data-role='interested-party']").prop("checked", false); // Ensure Interested Party checkbox is unchecked
                    } else {
                        // Allow the change
                        supervisorRow.find("[data-role='interested-party']").prop("checked", !isChecked);
                        toggleInterestedPartyAjax(supervisorRow.data("id"), !isChecked);
                    }
                },
                error: function () {
                    alert("An error occurred while processing your request.");
                    // Revert the checkbox state in case of error
                    $(e.currentTarget).prop("checked", true);
                }
            });
        } else {
            // Allow the change
            supervisorRow.find("[data-role='interested-party']").prop("checked", !isChecked);
            toggleInterestedPartyAjax(supervisorRow.data("id"), !isChecked);
        }
    }

    function toggleInterestedPartyAjax(supervisorId, isInterestedParty) {
        $.ajax({
            url: "/DataService.asmx/ToggleInterestedParty",
            type: "POST",
            data: JSON.stringify({ id: supervisorId, isInterestedParty: isInterestedParty }),
            contentType: "application/json",
            success: function (data) {
                // Handle success if needed
            },
            error: function () {
                alert("An error occurred while processing your request");
            }
        });
    }

    return self;
})();
