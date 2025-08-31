$(document).ready(function () {
    resize();
    window.onresize = resize;
});

function resize() {
    $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
    $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
}

$(".setuptest").off("click").click(function () {
    var data = {};
    data.testerGroupID = $("#user-select").val();
    data.testDate = $("#test-date").val();
    $.ajax({
        url: "/DataService.asmx/SetupTest",
        type: "POST",
        data: data,
        async: false,
        success: function (data) {
            $("#result").html("Test setup complete");
        },
        error: function () {
            $("#result").html("There was a problem setting up the test");
        }
    });
});

$(".gradetest").off("click").click(function () { gradeTestBreakdown(true) });
$(".viewBreakdown").off("click").click(function () { gradeTestBreakdown(false) });

function gradeTestBreakdown(record) {
    
    if (userIsGrader) { 

        var testerGroupID = $("#user-select").val();

    let userDataTable = `<div class="score-container">
                            <table id="parentTable">
                             <label for="finalScore"><b>Final Score</b></label>
                             <table id="finalScore" class="display compact" style="width:100%"></table><br>
                             <label for="detailedReport"><b>Score Breakdown</b></label>
                             <table id="detailedReport" class="display compact" style="width:100%"></table><br>
                         
                             <h3>Detailed Response Breakdown</h3>
                             <p>This section displays all entered responses to exercises in different sections of the exam.</p><br>

                             <label for="taskCreation">Task Creation And Editing</label>
                             <table id="taskCreation" class="display compact" style="width:100%"></table><br>
                             <label for="detailedTaskChecklist">Detailed Task Checklist</label>
                             <table id="detailedTaskChecklist" class="display compact" style="width:100%"></table><br>
                             <label for="statusReports">Status Reports</label>
                             <table id="statusReports" class="display compact" style="width:100%"></table><br>
                             <label for="sections">Sections</label>
                             <table id="sections" class="display compact" style="width:100%"></table><br>
                             <label for="priorities">Priorities</label>
                             <table id="priorities" class="display compact" style="width:100%"></table><br>
                             <label for="comments">Comments</label>
                             <table id="comments" class="display" style="width:100%"></table><br>
                             <label for="viewsAndTotals">Views & Totals</label>
                             <table id="viewsAndTotals" class="display" style="width:100%; margin-bottom: 10px;"></table>
                             </table>
                         </div>`;


        $("#result").html(userDataTable);
    

        $.ajax({
            url: "/DataService.asmx/GradeTestFullReport",
            type: "POST",
            data: JSON.stringify({
                testerGroupID: $("#user-select").val(),
                testDate: $("#test-date").val(),
                recordScore: record,
            }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            async: false,
            success: function (msg) {

                let parsedData = JSON.parse(msg.d);
                console.log(parsedData);

                new DataTable("parentTable", {
                    dom: 'Bt',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    layout: {
                        topStart: {
                            buttons: ['csv', 'excel']
                        }
                    }
                });

                new DataTable("#finalScore", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    autoFill: false,
                    columnDefs: [
                        { targets: [0], orderable: false },
                    ],
                    responsive: true,
                    data: parsedData.Table9,
                    columns: [
                        { title: "Total Score", data: 'Score' }
                    ]
                });
                new DataTable("#detailedReport", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        { targets: [0, 1, 2, 3, 4, 5, 6, 7], orderable: false },
                    ],
                    responsive: true,
                    data: parsedData.Table8,
                    columns: [
                        { title: "Checklists (14) x2", data: 'Checklists (14) x2' },
                        { title: "Items (10) x2", data: 'Items (10) x2' },
                        { title: "Reports (3) x2", data: 'Reports (3) x2' },
                        { title: "Sections (3) x2", data: 'Sections (3) x2' },
                        { title: "Priorities (10) x2", data: 'Priorities (10) x2' },
                        { title: "Comments (5) x2", data: 'Comments (5) x2' },
                        { title: "Groups (1)", data: 'Groups (1)' },
                        { title: "Written (9)", data: 'Written (9)' }

                    ]
                });

                new DataTable("#taskCreation", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        { targets: [0, 1, 2], orderable: false },
                    ],
                    responsive: true,
                    data: parsedData.Table1,
                    columns: [
                        { title: "Name", data: 'Name' },
                        {
                            title: "Deleted?", data: 'IsDeleted',
                            render: function (data) { return data ? "Y" : "N"; }
                        },
                        {
                            title: "Date Created",
                            data: 'CreateDate',
                            render: function (data) {
                                if (data === null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        }

                    ]
                });
                new DataTable("#detailedTaskChecklist", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        { targets: [0, 1, 2, 3, 4, 5], orderable: false },
                    ],
                    responsive: true,
                    data: parsedData.Table2,
                    columns: [
                        { title: "Name", data: 'Name' },
                        {
                            title: "Deleted?", data: 'IsDeleted',
                            render: function (data) { return data ? "Y" : "N"; }
                        },
                        {
                            title: "Date Created",
                            data: 'CreateDate',
                            render: function (data) {
                                if (data === null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        },
                        { title: "Item Type", data: 'ItemType' },
                        { title: "Description", data: 'Text' },
                        { title: "URL", data: 'URL' }
                    ]
                });
                new DataTable("#statusReports", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        { targets: [0, 1, 2], orderable: false },
                    ],
                    responsive: true,
                    data: parsedData.Table3,
                    columns: [
                        { title: "Name", data: 'Name' },
                        {
                            title: "Last Report Date",
                            data: 'LastReportDate',
                            render: function (data) {
                                if (data === null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        },
                        {
                            title: "Deleted?", data: 'IsDeleted',
                            render: function (data) { return data ? "Y" : "N"; }
                        }
                    ]
                });
                new DataTable("#sections", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        {
                            targets: [0, 1],
                            orderable: false
                        }
                    ],
                    responsive: true,
                    data: parsedData.Table4,
                    columns: [
                        { title: "Report Name", data: 'ReportName' },
                        { title: "Section Name", data: 'SectionName' }
                    ]
                });
                new DataTable("#priorities", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        {
                            targets: [
                                0, 1
                            ],
                            orderable: false
                        },
                    ],
                    responsive: true,
                    data: parsedData.Table5,
                    columns: [
                        { title: "Priority", data: 'Priority' },
                        { title: "Task Name", data: 'Name2' }
                    ]
                });
                new DataTable("#comments", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        {
                            targets: [
                                0, 1, 2, 3
                            ],
                            orderable: false
                        }
                    ],
                    responsive: true,
                    data: parsedData.Table6,
                    columns: [
                        { title: "Task Name", data: 'Name1' },
                        { title: "Comments", data: 'Comments' },
                        {
                            title: "Comment Date",
                            data: 'CommentDt',
                            render: function (data) {
                                if (data === null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        },
                        {
                            title: "Initials",
                            data: 'Initials',
                            render: function (data) {
                                let firstInitial = data.substring(0, 1);
                                let lastName = data.substring(data.indexOf(" ") + 1)
                                let lastInitial = lastName.substring(0, 1);
                                return `${firstInitial} ${lastInitial}`;
                            }
                        }
                    ]
                });
                new DataTable("#viewsAndTotals", {
                    dom: 't',
                    paging: false,
                    lengthChange: false,
                    searching: false,
                    columnDefs: [
                        {
                            targets: [0, 1],
                            orderable: false
                        }
                    ],
                    responsive: true,
                    data: parsedData.Table7,
                    columns: [
                        { title: "Name", data: 'Name' },
                        { title: "Expected", data: 'ExpectedAnswer' },
                        {
                            title: "Create&nbsp;Date",
                            data: 'CreateDate',
                            render: function (data) {
                                if (data === null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        }

                    ]
                });
            },
            error: function () {
                $("#result").html("There was a problem grading the test.");
            }
        });
        }
        else {

            $.ajax({
                url: "/DataService.asmx/GradeTest",
                type: "POST",
                data: JSON.stringify({
                    testerGroupID: $("#user-select").val(),
                    testDate: $("#test-date").val()
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                async: false,
                success: function (msg) {
                    $("#result").html("Test grade: " + msg.d + ".");
                },
                error: function () {
                    $("#result").html("There was a problem grading the test.");
                }
            });
        }
    }

$(".testHistory").off("click").click(function () {

    let testingHistoryTable = `<label for="testingHistory">Testing History For All Users</table>
                               <table id="testingHistory"></table>`;

    $("#result").html(testingHistoryTable);

    $.ajax({
        url: "/DataService.asmx/TestingHistoryReport",
        type: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        async: false,
        success: function (msg) {
            
            if (msg.d !== null && msg.d !== "") {
                let parsedData = JSON.parse(msg.d);               

                $("#testingHistory").dataTable({
                    data: parsedData.Table,
                    columnDefs: [
                        { targets: [0, 1, 2, 3, 4, 5, 6, 7, 8], orderable: true },
                    ],
                    columns: [
                        { title: "User&nbsp;ID", data: 'UserID' },
                        {
                            title: "Employee&nbsp;ID",
                            data: 'EmployeeID',
                            render: function (data) {
                                return data !== -1 ? data : '--';
                            }
                        },
                        { title: "Full&nbsp;Name", data: 'FullName' },
                        {
                            title: "Domain",
                            data: 'Email',
                            render: function (data) {
                                if (data !== null && data.indexOf('@') !== -1) {
                                    let domainSubstring = data.substring(data.indexOf('@') + 1);
                                    return domainSubstring
                                } else {
                                    return '--';
                                }
                            }
                        },
                        {
                            title: "Latest&nbsp;Training",
                            data: 'LatestTraining',
                            render: function (data) {
                                if (data == null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD');
                            }
                        },
                        {
                            title: "First&nbsp;Training",
                            data: 'FirstTraining',
                            render: function (data) {
                                if (data == null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD');
                            }
                        },
                        { title: "#&nbsp;Attempts", data: 'NumAttempts' },
                        { title: "Best&nbsp;Grade", data: 'BestGrade' },
                        {
                            title: "Date&nbsp;of&nbsp;Best&nbsp;Attempt",
                            data: 'GradedDt',
                            render: function (data) {
                                if (data == null)
                                    return '--';
                                return moment(data).format('YYYY-MM-DD HH:mm:ss');
                            }
                        }
                    ],
                    initComplete: function () {
                        var api = this.api();

                        $('.dt-buttons').append(`<label>
                                                    <input type="checkbox" id="showAllUsers" checked='checked'/>
                                                    <span style="margin-left: 5px;">Show Ungraded/Untested Users</span>
                                                </label>`);
                        $('#showAllUsers').change(function () {
                            api.draw();
                        });                        
                    },
                    drawCallback: function (settings) {
                        var api = this.api();

                        if ($('#showAllUsers').is(':checked')) {
                            api.rows().every(function () {
                                $(this.node()).show();
                            });
                        } else {
                            api.rows().every(function () {
                                var data = this.data();
                                if (!isGradedUser(data)) {
                                    $(this.node()).hide();
                                } else
                                    $(this.node()).show();
                            });
                        }
                    },
                    //dom: 'Bfrtip',
                    infoCallback: function (settings, start, end, max, total, pre) {
                        var api = this.api();
                        var visibleRows = api.rows({ filter: 'applied' }).nodes().length;
                        return `Showing ${start}-${end} of ${total}`;
                    },

                    responsive: false,
                    layout: {
                        
                        topStart: {
                            search: {},
                            buttons: [
                                'copy',
                                {
                                    extend: 'csvHtml5',
                                    text: 'CSV',
                                    exportOptions: {
                                        columns: [0, 1, 2, 3, 4, 5, 6, 7, 8],
                                        format: {
                                            header: function (data, columnIdx) {
                                                if (columnIdx === 0)
                                                    return 'User ID';
                                                if (columnIdx === 1)
                                                    return 'Employee ID';
                                                if (columnIdx === 2)
                                                    return 'Full Name';
                                                if (columnIdx === 3)
                                                    return 'Domain';
                                                if (columnIdx === 4)
                                                    return 'Latest Training';
                                                if (columnIdx === 5)
                                                    return 'First Training';
                                                if (columnIdx === 6)
                                                    return '# Attempts';
                                                if (columnIdx === 7)
                                                    return 'Best Grade';
                                                if (columnIdx === 8)
                                                    return 'Date of Best Attempt';

                                                return data;
                                            }
                                        }
                                    }
                                },
                                'excel',
                                {
                                    extend: 'pdfHtml5',
                                    text: 'PDF',
                                    orientation: 'landscape',
                                    pageSize: 'A4'
                                }
                            ]

                        },
                        topEnd: null,
                        bottomStart: ['pageLength', 'paging'],
                        bottomEnd: 'info'
                    },
                    
                }).css("width", "100%")
            } else 
                $("#result").html("Unable to retrieve data.");
            
        },
        error: function () {
            $("#result").html("There was a problem retrieving the report.");
        }
    });
});

function isGradedUser(data) {
    return data.NumAttempts > 0 || data.GradedDt != null;
}

$(".cleanuptest").off("click").click(function () {
    if (!userIsGrader && !confirm("This will delete all tasks and reports created for the app proficiency test. Please be sure you have clicked \"Grade Test\" to obtain a grade, or you may be required to re-take this test.\r\n\r\nThe cleanup process may miss items with misspelled names; please review your task list to ensure all test items are removed after cleanup.\r\n\r\nAre you sure you wish to proceed?"))
        return;

    var data = {};
    data.testerGroupID = $("#user-select").val();
    data.testDate = $("#test-date").val();
    $.ajax({
        url: "/DataService.asmx/CleanupTest",
        type: "POST",
        data: data,
        async: false,
        success: function (data) {
            $("#result").html("Test cleanup complete");
        },
        error: function () {
            $("#result").html("There was a problem cleaning up the test");
        }
    });
});
/* Copyright © 2024 Renegade Swish, LLC */

