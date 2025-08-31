var changeRequestDenyEmailModule = (function () {
    var self = {};

    $().ready(function () {
        $("#changeRequestDeny input.btn").click(function () {
            self.sendEmail();
        });
    });

    self.sendEmail = function () {
        var emailArea = $("div[data-role='email-area']");
        var requestId = $("#changeRequestDeny input.request-id").val();
        var changeRequest = $("div[data-request-id=" + requestId + "]");
        var checklistname = changeRequest.find("div.checklist-name td.cr-header-task").text();
        var comments = $("#changeRequestDeny textarea.reply-comments").val();
        var email = $("#changeRequestDeny input.email-address").val();
        var myname = $("#user-full-name").val();
        //move the contents to the email area
        emailArea.html("");

        emailArea.prepend("<div>" + myname + "'s comments: " + comments + "</div><br/>");

        $("a", emailArea).remove();
        $("textarea", emailArea).remove();
        $("input", emailArea).remove();
        $("i.fa", emailArea).remove();

        $.get("/Content/" + "ChangeRequestEmail.css", function (css) {
            $('<style type="text/css"></style>')
               .html(css)
               .prependTo(emailArea);

            var body = emailArea.html();
            emailArea.html("");

            $.ajax({
                url: "/DataService.asmx/SendChangeRequestEmail",
                type: "POST",
                data: {
                    to: email,
                    checklistname: checklistname,
                    body: body
                },
                error: function (request, status, error) {
                    alert(request.responseText);
                }
            }).done(function () {
                notifier.setMessage("Email Sent.", "green", 1000);
                window.modalModule.hide();
            });
        });
    };

    return self;

})();
/* Copyright © 2024 Renegade Swish, LLC */

