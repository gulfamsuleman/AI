var controllersModule = (function () {
    var self = {};
    self.controllersPanel = $("#controllers-panel");
    var controllersTable = $("#controllers-table");
    var controllerSelect = $("#controller-select");
    self.reportId = -1;

    $().ready(function () {
        self.controllersPanel.on('click', "button[data-role='add-controller']", function () { self.addController(); });
        self.controllersPanel.on('click', "a[data-role='delete-controller']", function (e) { self.deleteController(e); });
    });

    self.getControllers = function () {
        $.ajax({
            url: "/DataService.asmx/GetControllersList",
            type: "POST",
            data: JSON.stringify({ reportId: self.reportId }),
            contentType: "application/json",
            success: function (data) {
                var controllers = data.d;
                controllersTable.find("tbody").html("");
                for (var i = 0; i < controllers.length; i++) {
                    addControllerTableRow(controllers[i]);
                }
                if (typeof supervisorsAdminModule != "undefined") {
                    supervisorsAdminModule.controllerReturn(self.reportId);
                }
            }
        });
    };

    function addControllerTableRow(controller) {
        var rowTemplate =
			"<tr data-id='{0}'>" +
				"<td data-item='actions'>" +
					"<a href='#' data-role='delete-controller'><img src='/Images/delete.gif' title='Remove' /></a>" +
				"</td>" +
				"<td data-item='name'>{1}</td>" +
			"</tr>";
        var newElem = $(format(rowTemplate, controller.ID, controller.Name));
        controllersTable.find("tbody").append(newElem);
        controllersTable.removeClass("hidden");
        return newElem;
    }

    function removeControllersTableRow(jqElem) {
        jqElem.remove();
        var rows = controllersTable.find("tbody tr");
        if (rows.length == 0) {
            controllersTable.addClass("hidden");
        }
    }

    function addControllerAjax(controller) {
        $.ajax({
            url: "/DataService.asmx/AddController",
            type: "POST",
            data: JSON.stringify({
                reportId: self.reportId,
                groupId: controller.ID
            }),
            dataType: "json",
            contentType: "application/json",
            success: function (response) {
                self.getControllers();
            },
            error: function () {
                alert("An error occurred while processing your request.");
            }
        });
    }

    function deleteControllerAjax(controllerId) {
        $.ajax({
            url: "/DataService.asmx/DeleteController",
            type: "POST",
            data: JSON.stringify({ id: controllerId }),
            contentType: "application/json",
            success: function (response) {

            },
            error: function () {
                alert("An error occurred while processing your request.");
            }
        });
    }

    self.addController = function () {
        var newController = {
            ID: controllerSelect.val(),
            Name: controllerSelect.find("option:selected").text(),
        };
        if (newController.groupId == -1) {
            alert("Please select a user from the list");
            return;
        }
        if (self.reportId == -1) {
            alert("Please select a report from the list");
            return;
        }
        addControllerTableRow(newController);
        addControllerAjax(newController);
    };

    self.deleteController = function (e) {
        var status = $(e.target).closest("tr");
        deleteControllerAjax(status.data("id"));
        removeControllersTableRow(status);
    };

    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

