var controllersBox = (function () {
    var self = {};
    var panelElem = $("#controllers-panel");
    var tableElem = $("#controllers-table", panelElem);
    function addControllersTableRow(controller) {
        var rowTemplate = "<tr data-status='" + JSON.stringify(controller) + "'>" +
            "<td data-item=\"actions\">" +
            "<a data-role=\"delete\"><img src=\"../Images/delete.gif\" title=\"Remove\"/></a>" +
            "</td>" +
            "<td data-item=\"name\">{0}</td>" +
            "</tr>";
        tableElem.find("tbody").append(format(rowTemplate, controller.name));
        tableElem.removeClass("hidden");
    }
    function removeControllersTableRow(jqElem) {
        $(jqElem).remove();
        var rows = $("tbody tr", tableElem);
        if (rows.length == 0) {
            tableElem.addClass("hidden");
        }
    }
    function addControllerAjax(controllerItem, changeId, checklistId) {
        var data =
        {
            managerGroupId: controllerItem.id,
            changeId: changeId,
            checklistId: checklistId
        };
        $.ajax({
            url: "../DataService.asmx/AddManagerToChecklist",
            type: "POST",
            data: JSON.stringify(data),
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            success: function (response) {
                controllerItem.mapId = response.d;
                addControllersTableRow(controllerItem);
            }

        });
    }
    function deleteControllerAjax(controller, changeId) {
        var data = {
            id: controller.mapId,
            existing: controller.existing,
            changeId: changeId
        };
        $.ajax({
            url: "../DataService.asmx/DeleteManager",
            type: "POST",
            data: data
        });

    }
    self.addControllerRow = function (controller) {
        addControllersTableRow(controller);
    };
    self.addController = function () {
        //gather data
        var newController = {};
        var selectList = $("select", panelElem).not(".hidden");
        var changeId = panelElem.closest("[data-change-id]").data("change-id");
        newController.existing = changeId <= 0 ? true : false;
        newController.id = selectList.val();
        if (newController.id < 0)
            return;
        newController.name = selectList.find("option[value='" + newController.id + "']:selected").text();
        //pass data to new table row
        if (!!panelElem.closest("[data-checklist-id]").length) {
            var checklistId = panelElem.closest("[data-checklist-id]").data("checklist-id");
            addControllerAjax(newController, changeId, checklistId);
        } else {
            addControllersTableRow(newController);
        }
        selectList.val(-1);
    };
    self.deleteRow = function (e) {

        var remainingRows = $("#controllers-table").find("tbody tr").length;
        var checklistId = 0
        if (!!panelElem.closest("[data-checklist-id]").length) {
            checklistId = panelElem.closest("[data-checklist-id]").data("checklist-id");
        }

        if (remainingRows === 1) {
            $.ajax({
                url: "/DataService.asmx/IsLastControllerByChecklistID",
                type: "POST",
                data: JSON.stringify({ taskId: checklistId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (data) {
                    alert("Please add a new controller before deleting the current one.");
                },
                error: function () {
                    alert("An error occurred while processing your request.");
                }
            });
        } else {
            if (window.confirm("Are you sure you want to delete this controller?")) {
                if (!!panelElem.closest("[data-checklist-id]").length) {
                    var changeId = panelElem.closest("[data-change-id]").data("change-id");
                    var controller = $(e.target).closest("tr").data("status");
                    deleteControllerAjax(controller, changeId);
                }
                removeControllersTableRow($(e.target).closest("tr"));
            }
        }
    };
    $().ready(function () {
        $("button[data-role='add']", panelElem).click(self.addController);
        $(tableElem).on('click', "a[data-role='delete']", self.deleteRow);
        $("select[data-set='controllers-with-groups']", panelElem).addClass("hidden");
        if (panelElem.data("status") && panelElem.data("status").length > 0) {
            var data = panelElem.data("status");
            for (var i = 0; i < data.length; i++) {
                addControllersTableRow(data[i]);
            }
        }
        $(document).on('click', "a[data-role='show-all']", function () {
            if ($("select[data-set='controllers-with-groups']", panelElem).hasClass("hidden")) {
                $("select[data-set='controllers-with-groups']", panelElem).removeClass("hidden");
                $("select[data-set='controllers']", panelElem).addClass("hidden");
                $("[data-role='show-all']", panelElem).addClass("hidden");
            }

            if (typeof slider !== 'undefined') {
                $(this).parent().find("button").css("margin-top", "-1px");
            }
        });
    });
    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

