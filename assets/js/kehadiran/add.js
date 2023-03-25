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

	$("#d_pengajuan_mulai_tanggal").pickadate({
		labelMonthNext: "Go to the next month",
		labelMonthPrev: "Go to the previous month",
		labelMonthSelect: "Pick a month from the dropdown",
		labelYearSelect: "Pick a year from the dropdown",
		selectMonths: true,
		selectYears: true,
		formatSubmit: "yyyy-mm-dd",
		format: "yyyy-mm-dd",
		min: today,
		max: 90,
		disable: [1]
	}).change(function() {
		$('#d_pengajuan_selesai_tanggal').pickadate('picker').set('min',$(this).val());
	});

	$("#d_pengajuan_selesai_tanggal").pickadate({
		labelMonthNext: "Go to the next month",
		labelMonthPrev: "Go to the previous month",
		labelMonthSelect: "Pick a month from the dropdown",
		labelYearSelect: "Pick a year from the dropdown",
		selectMonths: true,
		selectYears: true,
		formatSubmit: "yyyy-mm-dd",
		format: "yyyy-mm-dd",
		min: 1,
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

var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Ya',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> Tidak',
});


document.addEventListener("DOMContentLoaded", function () {
	var controller = $("#path").val();
	$("#submit").on("click", function () {

		if (!isDateRangeValid()) {
			swalInit("Error ", "Periode tanggal salah", "error");
			return false;
		}

		var form = $('.form-validation').valid();
		if(form){
			sweetadd(controller);
		}
	});

	function isDateRangeValid() {
		let d_pengajuan_mulai_tanggal = $('#d_pengajuan_mulai_tanggal').val();
		let d_pengajuan_mulai_pukul = $('#d_pengajuan_mulai_pukul').val();
		let d_pengajuan_selesai_tanggal = $('#d_pengajuan_selesai_tanggal').val();
		let d_pengajuan_selesai_pukul = $('#d_pengajuan_selesai_pukul').val();

		let d_mulai = `${d_pengajuan_mulai_tanggal} ${d_pengajuan_mulai_pukul}`;
		let d_selesai = `${d_pengajuan_selesai_tanggal} ${d_pengajuan_selesai_pukul}` ;

		/** jika lebih lama dari hari ini */
		if (moment(d_mulai) < moment().valueOf()) {
			return false;
		}

		// console.log(moment(d_mulai), moment(d_selesai));

		return moment(d_mulai) < moment(d_selesai);
	}

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
    }).change(function() {
		const value = $(this).val();
		/** sakit & tidak masuk*/
		if (value == 5 || value == 2) {
			$('#d_pengajuan_mulai_pukul').val('08:00');
			$('#d_pengajuan_selesai_pukul').val('16:00');
			return;
		}
		$('#d_pengajuan_mulai_pukul').val('00:00');
		$('#d_pengajuan_selesai_pukul').val('00:00');
	});	
})