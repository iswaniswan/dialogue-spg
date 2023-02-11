/* ------------------------------------------------------------------------------
 *
 *  # CKEditor editor
 *
 *  Demo JS code for editor_ckeditor.html page
 *
 * ---------------------------------------------------------------------------- */

// Setup module
// ------------------------------
var controller = $("#path").val();
var swalInit = swal.mixin({
	buttonsStyling: false,
	confirmButtonClass:
		"btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
	cancelButtonClass:
		"btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
	confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
	cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
});

function hapusfile(id, attachment, path) {
	swalInit({
		title: "Are you sure?",
		text: "This data will be delete :)",
		type: "error",
		showCancelButton: true,
		buttonsStyling: false,
	}).then(function (result) {
		if (result.value) {
			$.ajax({
				type: "POST",
				data: {
					id: id,
					attachment: attachment,
					path: path,
				},
				url: base_url + controller + "/deletefile",
				dataType: "json",
				beforeSend: function () {
					$(".table-borderless").block({
						message:
							'<img src="'+base_url+'/assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>',
						centerX: false,
						centerY: false,
						overlayCSS: {
							backgroundColor: "#fff",
							opacity: 0.8,
							cursor: "wait",
						},
						css: {
							border: 0,
							padding: 0,
							backgroundColor: "none",
						},
					});
				},
				success: function (data) {
					if (data.sukses == true) {
						swalInit("Success!", "Data update successfully :)", "success").then(
							function (result) {
								window.location = base_url + controller;
							}
						);
					} else {
						swalInit("Sorry", "Data failed to update :(", "error");
					}
					$(".table-borderless").unblock();
				},
				error: function () {
					$(".table-borderless").unblock();
				},
			});
		}
	});
}
