var inprocessModule = (function() {
    var self = {};
    var reportSelect = $("#report-select");
    var hideable = $("#hideable-area");
    var throbber = $("#throbber");

    var gotSupervisor = false;

    self.reportId = -1;
	
    $().ready(function () {
        reportSelect.change(changeReports);
        if (reportSelect.children("option").length == 1) {
            reportSelect.val($(reportSelect.children("option")[0]).attr("value"));            
            changeReports();
            $("button.btn-continue").off("click")
                .click(function () {

                    if (!gotSupervisor) {
                        alert("You need to specify your supervisor by selecting their name from the drop-down and clicking 'Add'.");
                        return;
                    }

                    var empId = $("#empId").val();
                    if (empId == '' || empId <= 0) {
                        alert("You need to enter your Employee ID. If you do not know it, please contact your supervisor or HR.");
                        return;
                    }
                    if (empId === undefined)
                        empId = null;

                    $("body").css("cursor", "wait");
                    asyncPostEx("SetUserEmployeeId",
                        JSON.stringify({ userName: null, empId: empId }),
                        function (msg) {
                            window.location.href = "/MyTasks.aspx";
                        },
                        function (xhr) {
                            alert(xhr.responseText);
                        }
                    );                    
                })
        }
    });

    function changeReports() {
        self.reportId = reportSelect.val();
        hideable.addClass("hidden");

        if (self.reportId != -1) {
            gotSupervisor = false;
            throbber.removeClass("hidden");
            supervisorsModule.reportId = self.reportId;
            supervisorsModule.getSupervisors();
        }
        else {
            hideable.addClass("hidden");
        }

    }

    self.supervisorReturn = function (supervisorReportId) {
        if (supervisorReportId == self.reportId) {
            gotSupervisor = true;
        }
        showPanel();
    }
    
    function showPanel(){
        throbber.addClass("hidden");
        hideable.removeClass("hidden");
    }
    
return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

