/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */


var _componentPickadate = function() {
	if (!$().pickadate) {
		console.warn("Warning - picker.js and/or picker.date.js is not loaded.");
		return;
	}

	// Accessibility labels
	var today = new Date();
	var date =
		today.getFullYear() +
		"," +
		(today.getMonth() + 1) +
		"," +
		today.getDate();
	$(".date").pickadate({
		labelMonthNext: "Go to the next month",
		labelMonthPrev: "Go to the previous month",
		labelMonthSelect: "Pick a month from the dropdown",
		labelYearSelect: "Pick a year from the dropdown",
		selectMonths: true,
		selectYears: true,
		formatSubmit: "yyyy-mm-dd",
		format: "yyyy-mm-dd",
		min: [2022, 1, 1],
		max: [date],
	});
};

var _componentAnytime = function() {
	if (!$().AnyTime_picker) {
		console.warn('Warning - anytime.min.js is not loaded.');
		return;
	}

	$('#d_pengajuan_mulai_pukul').AnyTime_picker({
		format: '%H:%i',
		labelTitle: "Pukul",
		labelHour: "Jam",
		labelMinute: "Menit"
	});

	$('#d_pengajuan_selesai_pukul').AnyTime_picker({
		format: '%H:%i',
		labelTitle: "Pukul",
		labelHour: "Jam",
		labelMinute: "Menit"
	});
};

document.addEventListener("DOMContentLoaded", function () {
	var controller = $("#path").val();
	$("#submit").on("click", function () {
		var form = $('.form-validation').valid();
		if(form){
			sweetedit(controller);
		}
	});
});


$(document).ready(function() {

	_componentPickadate();
	_componentAnytime();

	const controller = $("#path").val();

	$("#id_jenis_izin").select2({
        placeholder: "Pilih Jenis Izin",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_list_jenis_izin",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                };
                return query;
            },
            processResults: function(data) {
                return {
                    results: data,
                };
            },
            cache: false,
        },
    }); 

})

function _sweetreject(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        type: "error",
        input: "textarea",
        inputPlaceholder: "Alasan menolak izin",
        showCancelButton: true,
        inputClass: "form-control",
        inputValidator: function(value) {
            return !value && "You need to write something!";
        },
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                    text: result.value,
                },
                url: base_url + link + "/reject",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
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
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to reject:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to rejected :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to reject :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}