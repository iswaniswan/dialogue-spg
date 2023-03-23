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
		max: 90,
		disable: [1]
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
			sweetadd(controller);
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