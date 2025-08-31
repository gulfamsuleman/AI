$(document).ready(function () {
    resize();
    window.onresize = resize;
    $("#postDatePicker").lwDatepicker()

    getAllKeys();
    getAllSigningKeys();
});

function resize() {
    $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
    $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
}

function sendEmail() {

    event.preventDefault();
    var apiIntent = document.getElementById("intent").value;
    var fullName = document.getElementById("fullName").value;
    var approvalParty = document.getElementById("approvedBy").value;
    var onBehalfOf = document.getElementById("onBehalfOf").value;
    var postDate = document.getElementById("postDatePicker").value;
    var secToken = "";
    var resultDiv = "";

    $.ajax({
        url: "ApiService.asmx/RequestAccessToken",
        type: "POST",
        data: JSON.stringify({
            requestor: fullName,
            onBehalfOf: onBehalfOf,
            approver: approvalParty,
            intent: apiIntent,
            notBefore: postDate
        }),
        contentType: "application/json",
        async: true,
        success: function (data) {
            secToken = data.d.Key;
            resultDiv = `<p style='font-weight: bold;'>Through a secured communications channel, please provide the following message to the requesting user:</p>
                            <div id='message-container'>
                                <span style='font-weight: bold;'>Request for:</span> ${fullName}<br />
                                <span style='font-weight: bold;'>Approved by:</span> ${approvalParty}<br />
                                <span style='font-weight: bold;'>On behalf of:</span> ${onBehalfOf}<br />
                                <span style='font-weight: bold;'>For the following domain:</span> ${apiIntent}<br />
                                <span style='font-weight: bold;'>Unavailable for use before:</span> ${moment(postDate).format("YYYY-MM-DD")}<br />
                                <span style='font-weight: bold;'>API Token:</span> ${secToken}<br />
                            </div>
                            <hr color='darkgrey'>
                            <p style='margin-top: 10px;'>Please include this token as part of your API requests to any Q resource you have access to.<br />
                            If this key is believed to have been compromised, or if there are any questions, <br />
                            please contact the Q IT Help Desk at test@test.com.<br />
                            Thank you.</p>`;

            $("#infoNotice-container").html(resultDiv);
            getAllKeys();
        },
        error: function (xhr, status, error) {
            alert("Error generating key.");
        }
    });
}

function getAllKeys() {
    event.preventDefault();
    let userDataTable = '';
    userDataTable = `<div class="key-container">
                             <label for="currentKeys"><b>All Active API Keys</b></label>
                             <table id="currentKeys" class="display compact" style="width:100%"></table><br>
                         </div>`;


    $("#allKeys").html(userDataTable);


    $.ajax({
        url: "DataService.asmx/GetAllApiKeys",
        type: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        async: true,
        success: function (msg) {
            console.log(msg);
            let parsedData = JSON.parse(msg.d);
            console.log(parsedData);

            var newTable = new DataTable("#currentKeys", {
                dom: 't',
                paging: false,
                lengthChange: false,
                searching: false,
                autoFill: false,
                columnDefs: [
                    { targets: [0, 1, 2, 3, 4, 5, 6, 7], orderable: false },
                ],
                responsive: true,
                data: parsedData,
                columns: [
                    { title: "Access Domain", data: 'Intent' },
                    { title: "Requesting User", data: 'Requestor' },
                    { title: "Approved By", data: 'Approver' },
                    { title: "On Behalf Of", data: 'OnBehalfOf' },
                    {
                        title: "Issued On",
                        data: 'Issued',
                        render: function (data) {
                            if (data === null)
                                return '--';
                            return moment(data).format('YYYY-MM-DD h:mm A');
                        }
                    },
                    {
                        title: "Expires On",
                        data: 'Expires',
                        render: function (data) {
                            if (data === null)
                                return '--';
                            return moment(data).format('YYYY-MM-DD h:mm A');
                        }
                    },
                    {
                        title: "Not In Use Before",
                        data: 'NotBefore',
                        render: function (data) {
                            if (data === null)
                                return '--';
                            return moment(data).format('YYYY-MM-DD h:mm A');
                        }
                    },
                    {
                        title: "Key Revoked?",
                        data: 'IsRevoked',
                        render: function (IsRevoked) {
                            if (IsRevoked)
                                return 'Revoked';
                            else
                                return '--';
                        }
                    },
                    {
                        title: "Revoke Key",
                        data: null,
                        render: function (data) {
                            if (!data.IsRevoked)
                                return '<button class="btn env-specific-btn">Revoke</button>';
                            else
                                return '--';
                        }
                    }

                ]
            });

            newTable.on('click', 'button', function (e) {
                let data = newTable.row(e.target.closest('tr')).data();
                revokeKey(data);
            });


        },
        error: function () {
            $("#allKeys").html("No Keys available.");
        }
    });
}

function revokeKey(rowData) {
    if (confirm("Are you sure you want to revoke this key?")) {
        $.ajax({
            url: "DataService.asmx/RevokeApiKey",
            type: "POST",
            data: JSON.stringify({
                apiKey: rowData.ID,
            }),
            contentType: "application/json",
            async: true,
            success: function (data) {
                getAllKeys();
            },
            error: function (xhr, status, error) {
                alert("Error Revoking key.");
            }
        });
    }
}

function revokeSigningKey(rowData) {
    if (confirm("Are you sure you want to revoke this key?")) {
        $.ajax({
            url: "DataService.asmx/RevokeSigningApiKey",
            type: "POST",
            data: JSON.stringify({
                apiKey: rowData.ID,
            }),
            contentType: "application/json",
            async: true,
            success: function (data) {
                getAllSigningKeys()
            },
            error: function (xhr, status, error) {
                alert("Error Revoking key.");
            }
        });
    }
}

function getAllSigningKeys() {
    event.preventDefault();
    let keyDataTable = '';
    keyDataTable = `<div class="key-container">
                             <label for="currentSigningKeys"><b>All Active Signing Keys</b></label>
                             <table id="currentSigningKeys" class="display compact" style="width:100%"></table><br>
                         </div>`;


    $("#signingKeys").html(keyDataTable);


    $.ajax({
        url: "DataService.asmx/GetAllSigningKeys",
        type: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        async: true,
        success: function (msg) {
            console.log(msg);
            let parsedData = JSON.parse(msg.d);
            console.log(parsedData);

            var newTable = new DataTable("#currentSigningKeys", {
                dom: 't',
                paging: false,
                lengthChange: false,
                searching: false,
                autoFill: false,
                columnDefs: [
                    { targets: [0, 1, 2], orderable: false },
                ],
                responsive: true,
                data: parsedData,
                columns: [
                    {
                        title: "As Of",
                        data: 'AsOf',
                        render: function (data) {
                            if (data === null)
                                return '--';
                            return moment(data).format('YYYY-MM-DD h:mm A');
                        }
                    },
                    {
                        title: "Key Revoked?",
                        data: 'IsRevoked',
                        render: function (IsRevoked) {
                            if (IsRevoked)
                                return 'Revoked';
                            else
                                return '--';
                        }
                    },
                    {
                        title: "Revoke Key",
                        data: null,
                        render: function (data) {
                            if (!data.IsRevoked)
                                return '<button class="btn env-specific-btn">Revoke</button>';
                            else
                                return '--';
                        }
                    }

                ]
            });

            newTable.on('click', 'button', function (e) {
                let data = newTable.row(e.target.closest('tr')).data();
                revokeSigningKey(data);
            });


        },
        error: function () {
            $("#allKeys").html("No Keys available.");
        }
    });
}

function createNewSigningKey() {
    if (confirm("Are you sure you want to create a new signing key?")) {

        $.ajax({
            url: "ApiService.asmx/CreateSigningKey",
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            data: JSON.stringify({
                asOf: null //defaults to current UTC timestamp, we don't want to mess with any client-side time here
            }),
            async: true,
            success: function (msg) {
                alert("New Key Generatated.")
                getAllSigningKeys();
            },
            error: function () {
                $("#allKeys").html("No Keys available.");
            }
        });

    }
}
/* Copyright © 2024 Renegade Swish, LLC */

