var emailPrioritiesModule = (function() {
	var self = {};
	var sendEmailButton = $("[data-role='send-email']");
	var panel = $("#email-priority-list-panel");
	var modal = window.modalModule;
	
	$().ready(function() {
		if (typeof slider !== 'undefined') {
			//problemaic new Date(); leaving in place as it's just a default value for the picker.
			const date = new Date();
			let day = date.getDate();
			let month = date.getMonth() + 1;
			let year = date.getFullYear();
			let currentDate = `${month}/${day}/${year}`;
			$("input[data-role='datepicker']").val(currentDate).mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal',
				onSelect: updatePreference
			});
		} else {
			$("input[data-role='datepicker']").lwDatepicker({ autoFillToday: true, onChange: updatePreference });
		}

	    sendEmailButton.click(function () { sendEmail(); });
	    $("#comments-everyone").click(updatePreference);
	    $("#add-recipient").click(addRecipient);
	    $('#email-priority-list-table').find('input[type=checkbox]').attr('checked',true);//added by venkat 10/13/2017
		$('.loggedInUser').attr('disabled', 'disabled');
	});

	function addRecipient() {
	    var name = $("#addl-recipients option:selected").text();
	    var id = name.replace(" ", "").replace("'", "");
	    var email = $("#addl-recipients").val();
	    if ($("#" + id).length == 0) {
	        $("#email-priority-list-table").append('<div id="email-listing">\n<input name="' + id + '" id="' + id + '" type="checkbox" data-role="include-email" data-email="' + email + '" checked>\n<label for="' + id + '">' + name + '</label>\n</div>');
	    }
	    
	}

	function updatePreference() {
		if (typeof slider !== 'undefined') {
			var prevDate = $("#comments-since").val();
			var includeEveryone = $("#comments-everyone").is(':checked');
			slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="/images/loading.gif" /></div>`);
			slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/EmailPriorityList.ascx"),
				{
					SetId: prioritiesModule.setId,
					Since: prevDate,
					Everyone: includeEveryone
				}, function () {
				slider.prepend("<h3>Email Priorities List</h3><hr>");
				slider.find("button").addClass("btn").addClass("btn-dark").addClass("mb-1");
				slider.find("button[data-role=send-email]").after(`<button class="btn btn-secondary close-button" style="float:right;width:90px">Cancel</button>`);
				slider.find("input[type=button]").addClass("btn").addClass("btn-dark").addClass("email-add-button");
				slider.find("select").addClass("form-control").css("width", "80%");
				slider.find(".close-button").on("click", function () {
					slider.toggleClass('open');
				});
				$("#comments-since").val(prevDate);
			});
			return;
		}

	    modal.init({
	        controlName: "Controls/Priorities/EmailPriorityList.ascx",
	        titleText: "Email Priorities List",
	        remoteParams: { SetId: prioritiesModule.setId, Since: $("#comments-since").val(), Everyone: $("#comments-everyone").is(':checked') }
	    });
	}

	function sendEmail() {
		var addresses = getEmailAddresses();
		if (addresses.length > 0) {
			var subject = "Today's Priorities: " + $("#label-name").text();
			$.ajax({
				url: "../EmailHandler.ashx",
				type: "POST",
				data: {
					Form: "PrioritiesEmailForm.aspx",
					Subject: subject,
					EmailAddresses: addresses,
					ShowBody: true,
					Body: panel.find("#email-body").val(),
					CommentsSince: panel.find("#comments-since").val(),
					SetId: window.prioritiesModule.setId,
					Everyone: $("#comments-everyone").is(':checked')
				},
				success: function (data) {
					if (typeof slider !== 'undefined') {
						alert(`Priorities email sent to ${addresses}.`);
						slider.toggleClass('open');
						return;
					}

				    modal.hide();
					setTimeout(function () {

				        modal.init({
				            titleText: "Priority Message",
				            controlName: "Controls/Priorities/EmailConfirmation.ascx",
				            remoteParams: { message: addresses }
				        });
				    }, 500);
				},
				error: function (jqXHR, textStatus, errorThrown) {
				    alert(jqXHR.responseText);
				}
			});
		} else {
			alert("No Email Recipients Selected.");
		}
	}
	
	function getEmailAddresses() {
		var checkedEmails = panel.find("[data-role='include-email']:checked");
		var emails = "";
		checkedEmails.each(function() {
			emails += $(this).data("email") +  "," ;
		});
        if(emails.length > 0)
		    emails = emails.substr(0, emails.length - 1);
		return emails;
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

