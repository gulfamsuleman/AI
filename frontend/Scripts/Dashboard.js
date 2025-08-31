let activeChart = null;
let historyChart = null;
let parentUserIds = [];
let userIds = [];
let allUsersSelected = true;
let firm = "";
let slider = null;
let useTreeView = false;
let backgroundColor = '';
let altBackgroundColor = '';
let lastGenerated = '';



$().ready(function () {

    allUsersSelected = true;
    resize();
    window.onresize = resize;

    backgroundColor = getCssColor('env-specific-btn','background-color');
    altBackgroundColor = getCssColor('env-specific-alt', 'background-color');

    getLastGeneratedTimestamp();

    firm = $("#systemFirm").val();

    $("#slider").bootstrapSwitch({
        size: 'mini',
        animate: false,
        onColor: 'primary',
        offColor: 'primary',
        offText: '--',
        onText: '--',
        onSwitchChange: function (event, state) {
            populateTreeView(state);
        }
    });
    //slider = $("#slider").slider({
    //    min: 0,
    //    max: 1,
    //    value: 0,
    //    step: 1,
    //    stop: function (event, ui) {
    //            populateTreeView(ui.value);
    //    }
    //});
    

    $("#supervisedGroupsSelect").change(getAllSupervisedUsersInGroup);
    $("#runSearch").on('click', populateGraphs);

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }
})

function getCssColor(className, property) {
    const tempElement = document.createElement('div');
    tempElement.className = className;
    document.body.appendChild(tempElement);

    const style = window.getComputedStyle(tempElement);
    const color = style.getPropertyValue(property);

    document.body.removeChild(tempElement);
    return color;
}

function getAllSupervisedUsersInitial() {

    var supervisorId = parseInt($("#supervisorId").val(), 10);

    $.ajax({
        url: "../DataService.asmx/GetSupervisedUsers",
        type: "POST",
        data: JSON.stringify({ supervisorId: supervisorId }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;

            let badCases = ["Raynor", "Project Nanny"];
            if (data.length > 0) {
                $("#controls-container").prepend(`
                    <div style="margin: 10px;" id="searchActions">
                        <button class="env-specific-btn" id="searchFilters">Choose Employees</button>
                        <button class="env-specific-btn" id="viewMyDashboard" style="margin-left: 10px;">My Dashboard</button>
                    </div>
                    <div style="margin: 10px;" id="helpText">
                        <span><em>*Click on bar next to user name to view detailed dashboard.</em></span>
                    </div>
                    <div style="margin: 10px;" id="timestamp">
                        <span><em>*KPI metrics last generated on: ${lastGenerated}.</em></span>
                    </div>
                `);

                $("#viewMyDashboard").on('click', function () {
                    var userId = $("#supervisorId").val();
                    window.location.href = "DashboardDetailedView.aspx?userId=" + encodeURIComponent(userId);
                });

                var isSupervisor = $("#isSupervisor").val() === "true";
                var dashboardMode = $("#dashboardMode").val();
                console.log("isSupervisor:", isSupervisor, "dashboardMode:", dashboardMode);
                if (!isSupervisor && dashboardMode === "mine") {
                    $("#searchActions").hide();
                    console.log("Hiding #searchActions");
                }

                data.forEach(function (user) {
                    if (!badCases.some(value => user.FullName.includes(value))) {
                        $("#userCheckBoxes").append(`<div><input type="checkbox" data-user-Id=${user.Id} checked="true" id="user-${user.Id}" name="user-${user.Id}" value="${user.Id}" />
                            <label style="font-size:12px; font-weight:bold;" for="user-${user.Id}">${user.FullName}</label></div>`);
                        parentUserIds.push(user.Id);
                        userIds.push(user.Id);
                    }
                });
                $('#userCheckBoxes input[type="checkbox"]').on('click', populateUsers);

                selectAll();
                $('#selectAllUsers').on('click', selectAll);
                $("#searchFilters").on('click', openFilters);
                $("#populateEntireTree").change(populateTreeView);

                populateGraphs();
            }
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });
}

function getLastGeneratedTimestamp() {


    $.ajax({
        url: "../DataService.asmx/GetLastMetricsRun",
        type: "POST",
        data: JSON.stringify({ procedureName: 'QCheck_KPITotalsCalc' }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;
            if (data.length > 0)
                lastGenerated = data;
            getAllSupervisedUsersInitial();
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });
}

function openFilters() {
    $("#filterDialog").toggle();
}
function getAllSupervisedUsersInGroup() {

    var groupId = $("#supervisedGroupsSelect").val();

    $.ajax({
        url: "../DataService.asmx/GetUsersInGroup",
        type: "POST",
        data: JSON.stringify({ groupId: groupId }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;

            if (data.length > 0) {
                userIds = [];
                let userCheckboxes = $('#userCheckBoxes input[type="checkbox"], #allUserCheckBoxes input[type="checkbox"]');
                allUsersSelected = false;
                selectAll();
                data.forEach(function (user) {
                    userCheckboxes.each(function () {
                        let idValue = $(this).data("userId");
                        if (idValue == user.UserId) {
                            $(this).prop('checked', true);
                        }
                    });
                });
                populateUsers();
            }
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });
}

function selectAll() {
    userIds = [];
    if (allUsersSelected == true) {
        $('#userCheckBoxes input[type="checkbox"], #allUserCheckBoxes input[type="checkbox"]').each(function () {
            $(this).prop('checked', true);
        });
        $("#supervisedGroupsSelect").val(0);
    } else {
        $('#userCheckBoxes input[type="checkbox"], #allUserCheckBoxes input[type="checkbox"]').each(function () {
            $(this).prop('checked', false);
        });
    }

    populateUsers();
    allUsersSelected = !allUsersSelected;
}

function populateUsers() {
    userIds = [];
    $('#userCheckBoxes input[type="checkbox"], #allUserCheckBoxes input[type="checkbox"]').each(function () {
        if($(this).is(':checked'))
        userIds.push($(this).val());
    });

}

function createUserTree(supervisorIds) {

    $.ajax({
        url: "../DataService.asmx/GetAllOtherUsers",
        type: "POST",
        data: JSON.stringify({ supervisorIds: supervisorIds }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            let data = response.d;
            
            if (data.length > 0) {
                let parentCheckbox = $("#allUserCheckBoxes");

                let list = ``;
                data.forEach(function (user) {
                    list += `<div><input type="checkbox" data-user-Id=${user.Id} id="user-${user.Id}" name="user-${user.Id}" value="${user.Id}">
                            <label style="font-size:12px;"for="user-${user.Id}">${user.FullName}</label></div>`;
                    userIds.push(user.Id);
                });

                parentCheckbox.append(list);
                
            }

            $('#allUserCheckBoxes input[type="checkbox"]').on('click', populateUsers);
        },
        error: function (error) { }
    });
}

function populateTreeView(useTreeView) {

    if (!useTreeView) {
        var supervisorIds = parentUserIds;
        createUserTree(supervisorIds);
    } else {
        $("#allUserCheckBoxes").html("");
        populateUsers();

    }
}

function populateActiveGraph() {

    if (activeChart !== null) 
        activeChart.destroy();

    $("#activeLabel").hide();

    $("#activeProgress").show();

    populateGraph(30, function (values) {
        setupActiveCanvas(values);
    });
}

function populateHistoryGraph() {

    if (historyChart !== null) 
        historyChart.destroy();

    $("#historyLabel").hide();

    $("#historyProgress").show();

    if (firm == "PHI" || firm == "PFS") {
        $("#historyLabel").text("Points Accrued (Over 30 Days)");
        populateGraph(30, function (values) {
            setupHistoryCanvasPhi(values);
        });
    }
    else {
        populateGraph(30, function (values) {
            setupHistoryCanvas(values);
        });
    }

}


function populateGraphs() {
    populateActiveGraph();
    populateHistoryGraph();
}


function populateGraph(numdays, callback) {


    var userIdsToSend = userIds;
    var supervisorId = $("#supervisorId").val();

        $.ajax({
            url: "../DataService.asmx/GetGroupUsersAndTasks",
            type: "POST",
            data: JSON.stringify({ userIds: userIdsToSend, supervisorId: supervisorId, numberOfDays: numdays }),
            dataType: "json",
            contentType: "application/json",
            success: function (response) {
                callback(response.d);
            },
            error: function (error) {
                alert(`the following error occurred: ${error}`);
            }
        });
}

function setupActiveCanvas(values) {

    activeChart = new Chart($("#activeEmployeeTasks"), {
        type: "horizontalBar",
        data: {
            labels: values.map(row => row.FullName),
            datasets: [
                {
                    label: "Active",
                    data: values.map(row => row.Tasks),
                    backgroundColor: backgroundColor,
                    borderColor: backgroundColor,
                    borderWidth: 1
                },
                {
                    label: 'Past Due',
                    data: values.map(row => row.OverdueTasks),
                    backgroundColor: altBackgroundColor,
                    borderColor: altBackgroundColor,
                    borderWidth: 1
                }
            ]
        },
        options: {
            indexAxis: 'y',
            scales: {
                xAxes: [{
                    ticks: {
                        fontSize: 10
                    },
                    stacked: true
                }],
                yAxes: [{
                    ticks: {
                        fontSize: 10
                    },
                    stacked: true
                }]
            },
            plugins: {
                legend: {
                    labels: {
                        font: {
                            size: 10 // Change this to your desired font size for legend labels
                        }
                    }
                }
            },
            onClick: function (event) {
                let activePoints = this.getElementAtEvent(event);
                let temp = values;
                if (activePoints.length > 0) {
                    let clickedElementIndex = activePoints[0]._index;
                    let label = this.data.labels[clickedElementIndex];
                    let id = values.find(u => u.FullName == label).UserId;

                    if (id) window.location.replace(`DashboardDetailedView.aspx?userId=${id}`);
                }
            },
            onHover: function (event, chartElement) {
                if (chartElement.length) {
                    event.target.style.cursor = 'pointer';
                } else {
                    event.target.style.cursor = 'default';
                }
            }
        }
    });
    $("#activeLabel").show();
    $("#activeProgress").hide();
}

function setupHistoryCanvas(values) {

    historyChart = new Chart($("#taskHistory"), {
        type: "bar",
        data: {
            labels: values.map(row => row.FullName),
            datasets: [
                {
                    label: "On-Time",
                    data: values.map(row => row.TasksCompleted),
                    backgroundColor: backgroundColor,
                    borderColor: backgroundColor,
                    borderWidth: 1
                },
                {
                    label: 'Completed After Deadline',
                    data: values.map(row => row.LateTasks),
                    backgroundColor: altBackgroundColor,
                    borderColor: altBackgroundColor,
                    borderWidth: 1
                }
            ]
        },
        options: {
            scales: {
                xAxes: [{
                    ticks: {
                        fontSize: 10
                    },
                    stacked: true
                }],
                yAxes: [{
                    ticks: {
                        fontSize: 10
                    },
                    stacked: true
                }]
            },
            onClick: function (event) {
                let activePoints = this.getElementAtEvent(event);
                let temp = values;
                if (activePoints.length > 0) {
                    let clickedElementIndex = activePoints[0]._index;
                    let label = this.data.labels[clickedElementIndex];
                    let id = values.find(u => u.FullName == label).UserId;

                    if (id) window.location.replace(`DashboardDetailedView.aspx?userId=${id}`);
                }
            },
            onHover: function (event, chartElement) {
                if (chartElement.length) {
                    event.target.style.cursor = 'pointer';
                } else {
                    event.target.style.cursor = 'default';
                }
            }
        }
    });

    $("#historyLabel").show();
    $("#historyProgress").hide();
}

function setupHistoryCanvasPhi(values) {

    historyChart = new Chart($("#taskHistory"), {
        type: "bar",
        data: {
            labels: values.map(row => row.FullName),
            datasets: [
                {
                    label: "Total Points",
                    data: values.map(row => row.TotalPoints < 0 ? 0 : Math.round(row.TotalPoints)),
                    backgroundColor: backgroundColor,
                    borderColor: backgroundColor,
                    borderWidth: 1
                }
            ]
        },
        options: {
            scales: {
                xAxes: [{
                    stacked: true
                }],
                yAxes: [{
                    stacked: true
                }]
            },
            onClick: function (event) {
                let activePoints = this.getElementAtEvent(event);
                let temp = values;
                if (activePoints.length > 0) {
                    let clickedElementIndex = activePoints[0]._index;
                    let label = this.data.labels[clickedElementIndex];
                    let id = values.find(u => u.FullName == label).UserId;

                    if (id) window.location.replace(`DashboardDetailedView.aspx?userId=${id}`);
                }
            },
            onHover: function (event, chartElement) {
                if (chartElement.length) {
                    event.target.style.cursor = 'pointer';
                } else {
                    event.target.style.cursor = 'default';
                }
            }
        }
    });

    $("#historyLabel").show();
    $("#historyProgress").hide();
}