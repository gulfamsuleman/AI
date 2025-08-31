

$().ready(function () {
    $("input[data-role='save-width']").click(saveWidth);
});

function saveWidth() {
    var reportId = $("#resizeReportId").val();
    var width = $("#theSlider").val();
    $.ajax({
        url: "/DataService.asmx/SetColumnWidth",
        type: "POST",
        data: { reportId: reportId, width: width },
        success: function () {
            reload();
        },
        error: function (jqXHR, textStatus, errorThrown) {
            alert(textStatus + ": " + errorThrown);
        }
    });
}

function reload() {
    window.location.reload();
}
/* Copyright © 2024 Renegade Swish, LLC */

