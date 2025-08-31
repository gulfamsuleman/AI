var supervisorsAdminModule = (function() {
    var self = {};
    var reportSelect = $("#report-select");
    var peopleSelect = $("#people-select");
    var hideable = $("#hideable-area");
    var peoplehideable = $("#people-hideable-area");
    var throbber = $("#throbber");
    var peopleTable = $("#people-table");

    var gotController = false;
    var gotSupervisor = false;

    self.reportId = -1;
    self.userID = -1;
	
    $().ready(function () {
        reportSelect.change(changeReports);
        peopleSelect.change(changePeople);
    });

    function changeReports() {
        self.reportId = reportSelect.val();
        hideable.addClass("hidden");

        if (self.reportId != -1) {
            gotController = false;
            gotSupervisor = false;
            throbber.removeClass("hidden");
            controllersModule.reportId = self.reportId;
            controllersModule.getControllers();
            supervisorsModule.reportId = self.reportId;
            supervisorsModule.getSupervisors();
        }
        else {
            hideable.addClass("hidden");
        }

    }

    function changePeople() {
        self.userID = peopleSelect.val();


        if (self.userID != -1) {
            throbber.removeClass("hidden");
            $("#people-name").html($("#people-select option:selected").text());
            getPeopleReports();
        }
        else {
            peoplehideable.addClass("hidden");
        }
    }

    self.controllerReturn = function (controllerReportId) {
        if (controllerReportId == self.reportId) {
            gotController=true;
        }
        if (gotSupervisor){
            showPanel();
        }
    }

    self.supervisorReturn = function (supervisorReportId) {
        if (supervisorReportId == self.reportId) {
            gotSupervisor = true;
        }
        if (gotController) {
            showPanel();
        }
    }


    getPeopleReports = function () {
        $.ajax({
            url: "/DataService.asmx/GetReportListSupervisedAndIP",
            type: "POST",
            data: JSON.stringify({ userID: self.userID }),
            contentType: "application/json",
            success: function (data) {
                var reportlist = data.d;
                peopleTable.find("tbody").html("");
                for (var i = 0; i < reportlist.length; i++) {
                    addPeopleSupervisorTableRow(reportlist[i]);
                }
                showPeople();
            }
        });
    };


    function addPeopleSupervisorTableRow(supervisor) {
        var rowTemplate =
            "<tr data-id='{0}'>" +
            "{1}" +
            "<td data-item='groupname'>{2}</td>" +
            "<td data-item='name'>{3}</td>" +
            "<td class='text-center'>" +
            "<input data-role='interested-party' type='checkbox' {4}>" +
            "</td>" +
            "<td class='text-center'>" +
            "<input data-role='supervisor' type='checkbox' {5}>" +
            "</td>" +
            "</tr>";
        var deleteButton = "<td><a href='' data-role='delete-supervisor'><img src='/Images/delete.gif' title='Remove' /></a></td>";
        var isInterestedParty = supervisor.InterestedParty ? "checked='checked'" : '';
        var isSupervisor = supervisor.InterestedParty ? '' : "checked='checked'";
        var groupName = supervisor.GroupName;
        var newElem = $(format(rowTemplate, supervisor.ID, deleteButton, groupName, supervisor.Name, isInterestedParty, isSupervisor));
        peopleTable.find("tbody").append(newElem);
        peopleTable.removeClass("hidden");
    }
    
    function showPanel(){
        throbber.addClass("hidden");
        hideable.removeClass("hidden");
        peoplehideable.addClass("hidden");
    }

    function showPeople() {
        throbber.addClass("hidden");
        peoplehideable.removeClass("hidden");
        hideable.addClass("hidden");
    }

return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

