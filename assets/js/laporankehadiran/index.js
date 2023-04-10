// Setup module
// ------------------------------

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

	$("#dfrom").pickadate({
		labelMonthNext: "Go to the next month",
		labelMonthPrev: "Go to the previous month",
		labelMonthSelect: "Pick a month from the dropdown",
		labelYearSelect: "Pick a year from the dropdown",
		selectMonths: true,
		selectYears: true,
		formatSubmit: "yyyy-mm-dd",
		format: "yyyy-mm-dd",
		max: today,
		disable: [1]
	}).change(function() {
		
	});

	$("#dto").pickadate({
		labelMonthNext: "Go to the next month",
		labelMonthPrev: "Go to the previous month",
		labelMonthSelect: "Pick a month from the dropdown",
		labelYearSelect: "Pick a year from the dropdown",
		selectMonths: true,
		selectYears: true,
		formatSubmit: "yyyy-mm-dd",
		format: "yyyy-mm-dd",
		max: today,
		disable: [1]
	});
};

var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
});

function check() {
    return ;
    var cek = $("#id_customer").val();

    //alert(cek);

    if (cek == "") {
        swalInit("Maaf :(", "Pilih toko terlebih dahulu! :(", "error");
        return false;
    } 
}

document.addEventListener("DOMContentLoaded", function() {
    _componentPickadate();
    var controller = $("#path").val() + "/serverside";
    var link = "laporankehadiran";
    var column = 7;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    //if (id_menu != "") {
    //datatableupload(controller, column, link, color);
    //} else {
    datatable(controller, column);
    //}

    console.log(link);

    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });

    $(".select-search").select2();

    $("#id_user").select2({
        placeholder: "Cari Pegawai",
        width: "100%",
        allowClear: true,
        maximumSelectionSize: 1,
        ajax: {
            url: base_url + link + "/get_all_user_bawahan",
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
        
    });
    $('#btn-export').click(function() {
        const base_url = $('#url').val();

        let dfrom = $('#dfrom').val();
        let dto = $('#dto').val();
        let id_user = $('#id_user').val();

        if (id_user === undefined) {
            id_user = $('input[name="id_user"]').val();
        }

        if (dfrom == '' || dfrom == undefined || dto == '' || dto === undefined ||
            moment(dfrom) > moment(dto)
        ) {
            swalInit("Maaf :(", "Periode waktu tidak valid", "error");
            return false;
        }

        let url = `${base_url}/${dfrom}/${dto}/${id_user}`;
        window.location.href = url;
    })

});