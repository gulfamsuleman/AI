let activeChart = null;
let statusReportsChart = null;
let finesChart = null;
let supervisorChart = null;
let commentsChart = null;
let prioritiesChart = null;
let pointsChart = null;
let checklistIds = [];
let currentDate = new Date();
let modal = null;
let firm = "";
let taskTip = "Number of tasks the user has completed on-time relative to the average employee.";
let overdueTip = "Number of tasks that the user has overdue relative to the average employee.";
let chargedTip = "This is the number of tasks that have gone overdue that a user has been charged for.";
let supervisedTip = "Percentage of tasks the user has assigned that are controlled by their supervisor relative to the average employee.";
let commentsTip = "Number of comments the user has made through the application relative to the average employee.";
let prioritiesTip = "Number of priority emails that have been sent to a user's supervisor relative to the average employee.";
let pointsTip = "Number of points the user has accumulated for a specific period relative to the average employee.";

const maxPointsPerDay = 30;

let backgroundColor = '';


$().ready(function () {
    modal = window.modalModule;
    resize();
    window.onresize = resize;
    $(".graph-tooltip").hide();
    populateGraphs();
    getUserKpis(30);
    firm = $("#systemFirm").val();

    backgroundColor = getCssColor('env-specific-btn', 'background-color');

    $("button[data-role='date-range-change']").on('click', function (e) {
        let numOfDays = e.target.dataset.value;
        getUserKpis(numOfDays);
    })

    $(".graph-tooltip").on('mouseenter', function (e) {
        let tooltipId = e.target.id;
        switch (tooltipId) {
            case "activeTool":
                setTooltip(tooltipId, taskTip);
                break;
            case "overdueTool":
                setTooltip(tooltipId, overdueTip);
                break;
            case "finesTool":
                if (firm == "PHI" || firm == "PFS")
                    setTooltip(tooltipId, pointsTip);
                else 
                    setTooltip(tooltipId, chargedTip);
                break;
            case "supervisorTool":
                setTooltip(tooltipId, supervisedTip);
                break;
            case "commentsTool":
                setTooltip(tooltipId, commentsTip);
                break;
            case "prioritiesTool":
                setTooltip(tooltipId, prioritiesTip);
                break;
            case "pointsTool":
                setTooltip(tooltipId, pointsTip);
                break;
        }
    });


    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }
})

function setTooltip(id, text) {
    $(`.graph-tooltip`).attr('data-tooltip', text);
}
function populateGraphs() {
    var supervisorId = $("#supervisorId").val();
    var userId = $("#userId").val();
    var isOwnDashboard = (userId === supervisorId);
    console.log("DashboardDetailedView.js AJAX payload:", { userId: userId, supervisorId: supervisorId });

    var requestData = {
        userId: userId,
        supervisorId: supervisorId,
        isOwnDashboard: isOwnDashboard
    };

    $.ajax({
        url: "../DataService.asmx/GetRedactedTaskList",
        type: "POST",
        data: JSON.stringify(requestData),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;

            if (data && Array.isArray(data)) {
                populateAssignments(data);
            } else {
                console.error("Unexpected data format:", data);
            }
        },
        error: function (error) {
            console.error("AJAX error:", error);
        }
    });
}


function setupKpiCanvas(values, numberOfDays) {

    let base = values[0];
    let min = values[1];
    let max = values[2];
    let average = values[3];

    if (activeChart !== null) activeChart.destroy();
    if (statusReportsChart !== null) statusReportsChart.destroy();
    if (finesChart !== null) finesChart.destroy();
    if (supervisorChart !== null) supervisorChart.destroy();
    if (commentsChart !== null) commentsChart.destroy();
    if (prioritiesChart !== null) prioritiesChart.destroy();
    if (pointsChart !== null) pointsChart.destroy();

    activeChart = new Chart($("#activeGraph"), {
        type: "gauge",
        data: {
            datasets: [
                {
                    value: Math.min(base.TasksCompleted,average.TasksCompleted * 2),
                    minValue: 0,
                    maxValue: average.TasksCompleted * 2,
                    data: [(average.TasksCompleted > 0 ? average.TasksCompleted * 2 : 1) * .33,
                        (average.TasksCompleted > 0 ? average.TasksCompleted * 2 : 1) * .66,
                        (average.TasksCompleted > 0 ? average.TasksCompleted * 2 : 1)],
                    backgroundColor: (chartContext) => {
                        const canvasCtx = chartContext.chart.ctx;
                        const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                        /*gradient.addColorStop(0.22, "#541E1B");*/

                        gradient.addColorStop(0.18, "crimson");
                        gradient.addColorStop(0.38, "yellow");
                        gradient.addColorStop(0.64, "#CCFD7F");
                        gradient.addColorStop(0.8, "darkgreen");
                        return gradient;
                    },
                    borderColor: ['#000000', '#000000', '#000000'],
                    borderWidth: 1
                }
            ]
        },
        options: {
            responsive: true,
            cutoutPercentage: 90,
            title: {
                display: true,
                text: 'Tasks Completed',
                fontSize: 15,
                position: 'bottom'
            },
            needle: {
                radiusPercentage: 2,
                widthPercentage: 3.2,
                lengthPercentage: 80,
                color: 'rgba(0, 0, 0, 1)'
            },
            valueLabel: {
                display: true,
                formatter: (value) => {
                    return base.TasksCompleted < 0 ? 0 : base.TasksCompleted;
                },
                color: 'white',
                backgroundColor: '#2c2c2c',
                borderRadius: 5,
                padding: {
                    top: 10,
                    bottom: 10
                }
            }
        }
    });

    statusReportsChart = new Chart($("#statusReportsGraph"), {
        type: "gauge",
        data: {
            datasets: [
                {
                    value: Math.min(base.OverdueTasks, average.OverdueTasks * 2),
                    minValue: 0,
                    maxValue: average.OverdueTasks * 2,
                    data: [(average.OverdueTasks > 0 ? average.OverdueTasks * 2 : 1) * .33,
                        (average.OverdueTasks > 0 ? average.OverdueTasks * 2 : 1) * .66,
                        (average.OverdueTasks > 0 ? average.OverdueTasks * 2 : 1)],
                    backgroundColor: (chartContext) => {
                        const canvasCtx = chartContext.chart.ctx;
                        const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                        gradient.addColorStop(0.18, "green");
                        gradient.addColorStop(0.30, "#CCFD7F");
                        gradient.addColorStop(0.64, "yellow");
                        gradient.addColorStop(0.8, "crimson");



                        return gradient;
                    },
                    borderColor: ['#000000', '#000000', '#000000'],
                    borderWidth: 1
                }
            ]
        },
        options: {
            responsive: true,
            cutoutPercentage: 90,
            title: {
                display: true,
                text: 'Overdue Tasks',
                fontSize: 15,
                position: 'bottom'
            },
            needle: {
                radiusPercentage: 2,
                widthPercentage: 3.2,
                lengthPercentage: 80,
                color: 'rgba(0, 0, 0, 1)'
            },
            valueLabel: {
                display: true,
                formatter: (value) => {
                    return base.OverdueTasks < 0 ? 0 : base.OverdueTasks;
                },
                color: 'white',
                backgroundColor: '#2c2c2c',
                borderRadius: 5,
                padding: {
                    top: 10,
                    bottom: 10
                }
            }
        }
    });
    if (firm == "PHI" || firm == 'PFS') {
        finesChart = new Chart($("#finesGraph"), {
            type: "gauge",
            data: {
                datasets: [
                    {
                        value: Math.min(Math.round(base.TotalPoints), Math.round(max.TotalPoints)),
                        minValue: 0,
                        maxValue: Math.round(max.TotalPoints),
                        data: [(maxPointsPerDay * numberOfDays) * .33, (maxPointsPerDay * numberOfDays) * .66, (maxPointsPerDay * numberOfDays)],
                        backgroundColor: (chartContext) => {
                            const canvasCtx = chartContext.chart.ctx;
                            const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                            gradient.addColorStop(0.18, "crimson");
                            gradient.addColorStop(0.38, "yellow");
                            gradient.addColorStop(0.64, "#CCFD7F");
                            gradient.addColorStop(0.8, "darkgreen");

                            return gradient;
                        },
                        borderColor: ['#000000', '#000000', '#000000'],
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                cutoutPercentage: 90,
                title: {
                    display: true,
                    text: 'Points Total',
                    fontSize: 15,
                    position: 'bottom'
                },
                needle: {
                    radiusPercentage: 2,
                    widthPercentage: 3.2,
                    lengthPercentage: 80,
                    color: 'rgba(0, 0, 0, 1)'
                },
                valueLabel: {
                    display: true,
                    formatter: (value) => {
                        return base.TotalPoints < 0 ? 0 : base.TotalPoints;
                    },
                    color: 'white',
                    backgroundColor: '#2c2c2c',
                    borderRadius: 5,
                    padding: {
                        top: 5,
                        bottom: 5
                    }
                }
            }
        });
    } else {
        finesChart = new Chart($("#finesGraph"), {
            type: "gauge",
            data: {
                datasets: [
                    {
                        value: Math.min(base.ChargedTasks, average.ChargedTasks * 2),
                        minValue: 0,
                        maxValue: average.ChargedTasks * 2,
                        data: [(average.ChargedTasks > 0 ? average.ChargedTasks * 2 : 1) * .33,
                            (average.ChargedTasks > 0 ? average.ChargedTasks * 2 : 1) * .66,
                            (average.ChargedTasks > 0 ? average.ChargedTasks * 2 : 1)],
                        backgroundColor: (chartContext) => {
                            const canvasCtx = chartContext.chart.ctx;
                            const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                            gradient.addColorStop(0.18, "green");
                            gradient.addColorStop(0.30, "#CCFD7F");
                            gradient.addColorStop(0.64, "yellow");
                            gradient.addColorStop(0.8, "crimson");

                            return gradient;
                        },
                        borderColor: ['#000000', '#000000', '#000000'],
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                cutoutPercentage: 90,
                title: {
                    display: true,
                    text: 'Charged Tasks',
                    fontSize: 15,
                    position: 'bottom'
                },
                needle: {
                    radiusPercentage: 2,
                    widthPercentage: 3.2,
                    lengthPercentage: 80,
                    color: 'rgba(0, 0, 0, 1)'
                },
                valueLabel: {
                    display: true,
                    formatter: (value) => {
                        return base.ChargedTasks < 0 ? 0 : base.ChargedTasks;
                    },
                    color: 'white',
                    backgroundColor: '#2c2c2c',
                    borderRadius: 5,
                    padding: {
                        top: 5,
                        bottom: 5
                    }
                }
            }
        });
    }

    supervisorChart = new Chart($("#supervisorGraph"), {
        type: "gauge",
        data: {
            datasets: [
                {
                    value: Math.min(base.SupervisorControlledPct, average.SupervisorControlledPct * 2),
                    minValue: 0,
                    maxValue: average.SupervisorControlledPct * 2,
                    data: [(average.SupervisorControlledPct > 0 ? average.SupervisorControlledPct * 2 : 1) * .33,
                        (average.SupervisorControlledPct > 0 ? average.SupervisorControlledPct * 2 : 1) * .66,
                        (average.SupervisorControlledPct > 0 ? average.SupervisorControlledPct * 2 : 1)],
                    backgroundColor: (chartContext) => {
                        const canvasCtx = chartContext.chart.ctx;
                        const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);



                        gradient.addColorStop(0.18, "crimson");
                        gradient.addColorStop(0.38, "yellow");
                        gradient.addColorStop(0.64, "#CCFD7F");
                        gradient.addColorStop(0.8, "darkgreen");

                        return gradient;
                    },
                    borderColor: ['#000000', '#000000', '#000000'],
                    borderWidth: 1
                }
            ]
        },
        options: {
            responsive: true,
            cutoutPercentage: 90,  // Controls the size of the hole in the center
            title: {
                display: true,
                text: 'Supervisor Controlled Tasks %',
                fontSize: 15,
                position: 'bottom'
            },
            circumference: Math.PI,  // Half-circle for the gauge (180 degrees)
            needle: {
                radiusPercentage: 2,
                widthPercentage: 3.2,
                lengthPercentage: 80,
                color: 'rgba(0, 0, 0, 1)'
            },
            valueLabel: {
                display: true,
                formatter: (value) => {
                    return base.SupervisorControlledPct < 0 ? 0 : base.SupervisorControlledPct;
                },
                color: 'white',
                backgroundColor: '#2c2c2c',
                borderRadius: 5,
                padding: {
                    top: 10,
                    bottom: 10
                }
            }
        }
    });

    commentsChart = new Chart($("#commentsGraph"), {
        type: "gauge",
        data: {
            datasets: [
                {
                    value: Math.min(base.CommentsMade, average.CommentsMade * 2),
                    minValue: 0,
                    maxValue: average.CommentsMade * 2,
                    data: [(average.CommentsMade > 0 ? average.CommentsMade * 2 : 1) * .33,
                        (average.CommentsMade > 0 ? average.CommentsMade * 2 : 1) * .66,
                        (average.CommentsMade > 0 ? average.CommentsMade * 2 : 1)],
                    backgroundColor: (chartContext) => {
                        const canvasCtx = chartContext.chart.ctx;
                        const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                        gradient.addColorStop(0.18, "crimson");
                        gradient.addColorStop(0.38, "yellow");
                        gradient.addColorStop(0.64, "#CCFD7F");
                        gradient.addColorStop(0.8, "darkgreen");

                        return gradient;
                    },

                    borderColor: ['#000000', '#000000', '#000000'],
                    borderWidth: 1
                }
            ]
        },
        options: {
            responsive: true,
            cutoutPercentage: 90,
            title: {
                display: true,
                text: 'Comments Made',
                fontSize: 15,
                position: 'bottom'
            },
            needle: {
                radiusPercentage: 2,
                widthPercentage: 3.2,
                lengthPercentage: 80,
                color: 'rgba(0, 0, 0, 1)'
            },
            valueLabel: {
                display: true,
                formatter: (value) => {
                    return base.CommentsMade < 0 ? 0 : base.CommentsMade;
                },
                color: 'white',
                backgroundColor: '#2c2c2c',
                borderRadius: 5,
                padding: {
                    top: 10,
                    bottom: 10
                }
            }
        }
    });

        prioritiesChart = new Chart($("#prioritiesGraph"), {
            type: "gauge",
            data: {
                datasets: [
                    {
                        value: Math.min(base.PriorityEmailsTotal, average.PriorityEmailsTotal * 2),
                        minValue: 0,
                        maxValue: average.PriorityEmailsTotal * 2,
                        data: [(average.PriorityEmailsTotal > 0 ? average.PriorityEmailsTotal * 2 : 1) * .33,
                            (average.PriorityEmailsTotal > 0 ? average.PriorityEmailsTotal * 2 : 1) * .66,
                            (average.PriorityEmailsTotal > 0 ? average.PriorityEmailsTotal * 2 : 1)],
                        backgroundColor: (chartContext) => {
                            const canvasCtx = chartContext.chart.ctx;
                            const gradient = canvasCtx.createLinearGradient(0, 0, canvasCtx.canvas.width, 0);

                            gradient.addColorStop(0.18, "crimson");
                            gradient.addColorStop(0.38, "yellow");
                            gradient.addColorStop(0.64, "#CCFD7F");
                            gradient.addColorStop(0.8, "darkgreen");

                            return gradient;
                        },

                        borderColor: ['#000000', '#000000', '#000000'],
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                cutoutPercentage: 90,
                title: {
                    display: true,
                    text: 'Priority Emails',
                    fontSize: 15,
                    position: 'bottom'
                },
                needle: {
                    radiusPercentage: 2,
                    widthPercentage: 3.2,
                    lengthPercentage: 80,
                    color: 'rgba(0, 0, 0, 1)'
                },
                valueLabel: {
                    display: true,
                    formatter: (value) => {
                        return base.PriorityEmailsTotal < 0 ? 0 : base.PriorityEmailsTotal;
                    },
                    color: 'white',
                    backgroundColor: '#2c2c2c',
                    borderRadius: 5,
                    padding: {
                        top: 10,
                        bottom: 10
                    }
                }
            }
        });
    $(".graph-tooltip").show();
    $("#kpiProgress").hide();
}

function getUserKpis(numberOfDays) {

    var userId = $("#userId").val();

    $.ajax({
        url: "../DataService.asmx/GetUserKpis",
        type: "POST",
        data: JSON.stringify({ userId: userId, supervisorId: 0, numberOfDays: numberOfDays }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;
            var test = 0;

            // populateTable();
            setupKpiCanvas(data, numberOfDays);
            $("#kpiLabel").html(`<em>*Current Range: <b>${numberOfDays} days</b></em>`);
            //populateAssignments(data.ActiveChecklists);

        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });
}
function populateAssignments(values) {
    let userDataTable = `
        <div style="text-align: center;">
            <label for="testAssignmentsTable" style="font-size: 15pt"><b>Assignments</b></label>
            <table id="testAssignmentsTable" class="display compact" style="width:100%"></table><br>
        </div>`;

    $("#assignmentsTable").html(userDataTable);

    $.fn.dataTable.ext.order['DueDateSort'] = function (settings, colIndex) {
        return this.api().column(colIndex, { order: 'index' }).nodes().map(function (td) {
            const dateString = $(td).text().trim();
            if (dateString === '') {
                return Number.MAX_SAFE_INTEGER; // Ensure empty dates are always last
            } else {
                const date = new Date(dateString);
                return date.getTime();
            }
        });
    };

    //$.fn.dataTable.ext.order['DueDateSort'] = function (settings, colIndex) {
    //    const dataTableApi = this.api();
    //    const nodes = dataTableApi.column(colIndex, { order: 'index' }).nodes();
    //    const nonEmptyDates = [];
    //    const emptyDates = [];

    //    nodes.each(function (td) {
    //        const dateString = $(td).text().trim();
    //        if (dateString === '') {
    //            emptyDates.push(td);
    //        } else {
    //            const date = new Date(dateString);
    //            nonEmptyDates.push({ node: td, date: date.getTime() });
    //        }
    //    });
    //    nonEmptyDates.sort((a, b) => a.date - b.date);

    //    const sortedNodes = nonEmptyDates.map(item => item.node).concat(emptyDates);

    //    return sortedNodes;
    //};


    var newTable = new DataTable("#testAssignmentsTable", {
        dom: 'Blt',
        paging: false,
        scrollY: '300px',
        pageLength: values.length,
        scrollCollapse: true,
        buttons: [
            {
                extend: 'copyHtml5',
                text: '<i class="fa fa-copy">',
                titleAttr: 'Copy file',
                className: "custom-button"
            },
            {
                extend: 'excelHtml5',
                text: '<img src="Images/excel.gif">',
                titleAttr: 'Export as Excel file',
                className: "custom-button"
            },
            {
                extend: 'csvHtml5',
                text: '<i class="fa fa-file">',
                titleAttr: 'Export as CSV file',
                className: "custom-button"
            },
            {
                extend: 'print',
                text: '<i class="fa fa-print">',
                titleAttr: 'Print file',
                className: "custom-button"
            }
        ],
        initComplete: function () {
            $("#testAssignmentsTable_wrapper .top").append(
                `<div style="float: left;">
                    <button id="reassignTasks" style="margin: 5px;" class="conversion-btn">Tasks Reassignment</button>
                </div>`);
        },
        lengthChange: false,
        searching: true,
        autoFill: false,
        autoWidth: true,
        ordering: false,
        //order: [[1, 'asc']],
        //columnDefs: [
        //    { targets: [1], orderable: false, },
        //    { targets: [0,2,3,4], orderable: false }
        //],
        responsive: true,
        data: values,
        columns: [
            {
                title: "Task", data: null, render: function (data) {
                    if (data.ChecklistName == '<REDACTED>') return `<b>Redacted</b>`;
                    else return `<a href="ManageTasks.aspx?checklistId=${data.ChecklistID}">${data.ChecklistName}</a>`;
                }
            },
            {
                title: "Due Date", data: null, render: function (data) {
                    if (data.IsDue == "YES") {
                        return `<span style="color:red;"><b>${data.DueDate}</b></span>`;
                    } else return data.DueDate;
                }
            },
            { title: "Assignees", data: 'Assignees' },
            { title: "Controllers", data: 'Controllers' },
            { title: "Report", data: 'StatusReportString' },
            //{
            //    title: "Is Due", data: null, render: function (data) {
            //        if (data.IsDue == "YES") {
            //            return `<span style="color:red;"><b>${data.IsDue} (${-data.DaysOutstanding} days past due)</b>`;
            //        } else return `NO`;
            //    }
            //}
        ],
        drawCallback: function () {
            $('#testAssignmentsTable td').each(function () {
                var fullText = $(this).text();
                $(this).attr('title', fullText);
            });
        }
    });

    $("#assignmentsProgress").hide();

    $('#assignmentsTable table td').each(function () {
        var fullText = $(this).text();
        $(this).attr('title', fullText);
    });

    $("#reassignTasks").on('click', taskReassign);

    populateGroups();
    populateStatusReports();
}

function taskReassign() {

    let userId = $("#userId").val();
    var supervisorId = $("#supervisorId").val();

    modal.init({
        titleText: "Task Reassignment",
        controlName: "Controls/Shared/TaskReassignments.ascx",
        remoteParams: { SupervisorId: supervisorId, UserId: userId },
        width: "800px"
    });
}

function groupsReassign() {

    let userId = $("#userId").val();
    var supervisorId = $("#supervisorId").val();

    modal.init({
        titleText: "Group Reassignment",
        controlName: "Controls/Shared/GroupReassignment.ascx",
        remoteParams: { SupervisorId: supervisorId, UserId: userId },
        width: "500px"
    });
}


function getCssColor(className, property) {
    const tempElement = document.createElement('div');
    tempElement.className = className;
    document.body.appendChild(tempElement);

    const style = window.getComputedStyle(tempElement);
    const color = style.getPropertyValue(property);

    document.body.removeChild(tempElement);
    return color;
}

function populateGroups() {

    let userId = $("#userId").val();
    let supervisorId = $("#supervisorId").val();

    $.ajax({
        url: "../DataService.asmx/GetAllGroupsIManageForUser",
        type: "POST",
        data: JSON.stringify({ userId: userId, supervisorId: supervisorId }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var tableData = response.d;
            var test = 0;

            let userDataTable = '';
            userDataTable = `<div style="text-align: center;">
                             <label for="groupsDataTable" style="font-size: 15pt"><b>Groups</b></label>
                             <table id="groupsDataTable" class="display compact" style="width:100%"></table><br>
                         </div>`;


            $("#groupsTable").html(userDataTable);

            var newTable = new DataTable("#groupsDataTable", {
                dom: 'Blt',
                paging: false,
                scrollY: '300px',
                pageLength: tableData.length,
                scrollCollapse: true,
                buttons: [
                    {
                        extend: 'copyHtml5',
                        text: '<i class="fa fa-copy">',
                        titleAttr: 'Copy file',
                        className: "custom-button"
                    },
                    {
                        extend: 'excelHtml5',
                        text: '<img src="Images/excel.gif">',
                        titleAttr: 'Export as Excel file',
                        className: "custom-button"
                    },
                    {
                        extend: 'csvHtml5',
                        text: '<i class="fa fa-file">',
                        titleAttr: 'Export as CSV file',
                        className: "custom-button"
                    },
                    {
                        extend: 'print',
                        text: '<i class="fa fa-print">',
                        titleAttr: 'Print file',
                        className: "custom-button"
                    }
                ],
                initComplete: function () {
                    $("#groupsDataTable_wrapper .top").append(
                        `<div style="float: left;">
                            <button id="reassignGroups" style="margin: 5px;" class="conversion-btn">Groups Reassignment</button>
                        </div>`);
                },
                lengthChange: false,
                searching: false,
                autoFill: false,
                columnDefs: [
                    { targets: [0, 1, 2, 3], orderable: false },
                ],
                responsive: true,
                data: tableData,
                columns: [
                    { title: "Group", data: 'GroupName' },
                    {
                        title: "Is Member?", data: null,
                        render: function (data) {
                            if (data.IsMember)
                                return `<span><i class="gold-star fa fa-star"></i></span>`;
                            else
                                return `--`;
                        }
                    },
                    {
                        title: "Is Owner?", data: null,
                        render: function (data) {
                            if (data.IsOwner)
                                return `<span><i class="gold-star fa fa-star"></i></span>`;
                            else
                                return `--`;
                        }
                    },
                    { title: "Owner", data: 'Owner' }

                ]
            });

            $('#groupsTable table td').each(function () {
                var fullText = $(this).text();  // Assuming the full text is the cell's text
                $(this).attr('title', fullText);
            });

            $("#reassignGroups").on('click', groupsReassign);
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });

    $("#groupsProgress").hide();

}

function gotoReport(reportId, type, taskId) {
    if (type === 'Controller') {
        window.location.replace(`MyStatus.aspx?reportId=${reportId}&taskId=` + taskId);
    }
    else {
        window.location.replace(`MyInbox.aspx?reportId=${reportId}&taskId=` + taskId);
    }
}

function populateStatusReports() {

    $.ajax({
        url: "../DataService.asmx/GetUserStatusReportsWithCounts",
        type: "POST",
        data: JSON.stringify({ userId: $("#userId").val().trim() }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var tableData = response.d;
            var test = 0;

            let userDataTable = '';
            userDataTable = `<div style="text-align: center;">
                             <label for="reportDataTable" style="font-size: 15pt"><b>Status Reports</b></label>
                             <table id="reportDataTable" class="display compact" style="width:100%"></table><br>
                         </div>`;


            $("#statusReports").html(userDataTable);

            var newTable = new DataTable("#reportDataTable", {
                dom: 'Blt',
                paging: false,
                scrollY: '300px',
                pageLength: tableData.length,
                scrollCollapse: true,
                buttons: [
                    {
                        extend: 'copyHtml5',
                        text: '<i class="fa fa-copy">',
                        titleAttr: 'Copy file',
                        className: "custom-button"
                    },
                    {
                        extend: 'excelHtml5',
                        text: '<img src="Images/excel.gif">',
                        titleAttr: 'Export as Excel file',
                        className: "custom-button"
                    },
                    {
                        extend: 'csvHtml5',
                        text: '<i class="fa fa-file">',
                        titleAttr: 'Export as CSV file',
                        className: "custom-button"
                    },
                    {
                        extend: 'print',
                        text: '<i class="fa fa-print">',
                        titleAttr: 'Print file',
                        className: "custom-button"
                    }
                ],
                paging: false,
                lengthChange: false,
                searching: false,
                autoFill: false,
                columnDefs: [
                    { targets: [0, 1], orderable: false },
                ],
                responsive: true,
                data: tableData,
                columns: [
                    {
                        title: "Name", data: null, render: function (data) {
                            return `<a href="MyInbox.aspx?reportId=${data.Id}">${data.Name}</a>`
                        }
                    },
                    {  title: "Tasks in Report", data: 'TaskCount' }
                ]
            });

            $('#statusReports table td').each(function () {
                var fullText = $(this).text();  // Assuming the full text is the cell's text
                $(this).attr('title', fullText);
            });
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });

    $("#statusProgress").hide();

}


