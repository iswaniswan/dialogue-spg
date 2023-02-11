/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */

document.addEventListener("DOMContentLoaded", function () {
	var controller = $("#path").val();
	$("#submit").on("click", function () {
		var form = $('.form-validation').valid();
		if(form){
			sweetadd(controller);
		}
	});
});
