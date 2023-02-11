var Plugin = (function() {

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
            min: [2021, 1, 1],
            max: [date],
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentPickadate();
        },
    };
})();

var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Ya',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> Tidak',
});

var controller = $("#path").val();

document.addEventListener("DOMContentLoaded", function() {
    Plugin.init();
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });

    $(".select-search").select2();

    $("#idcustomer").select2({
        placeholder: "Cari Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_customer",
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
    })

    $("#fpkp").on("change", function() {
        if ($(this).val() == "f") {
            $("#ecustomernpwp").attr("disabled", true);
            $("#eaddressnpwp").attr("disabled", true);
        } else {
            $("#ecustomernpwp").attr("disabled", false);
            $("#eaddressnpwp").attr("disabled", false);
        }
    });

    $("#submit").on("click", function() {
        /* let checkbox = $(".form-input-switch:checkbox:checked").length;
        let tabel = $("#tablecover tr").length;

        if (checkbox < 1 && tabel <= 1) {
        	swalInit("Maaf :(", "Item Toko Harus Diisi! :(", "error");
        	return false;
        } */

        var form = $(".form-validation").valid();
        if (form) {
            sweetadd(controller);
        }
    });
});