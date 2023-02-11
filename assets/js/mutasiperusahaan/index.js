// Setup module
// ------------------------------

var Kalender = (function() {
    // Pickadate picker
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
            format: "dd-mm-yyyy",
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

document.addEventListener("DOMContentLoaded", function() {
    Kalender.init();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });
    var controller = $("#path").val() + "/serverside";
    var linkadd = $("#path").val() + "/add";
    var params = {
        dfrom: $("#dfrom").val(),
        dto: $("#dto").val(),
        id_customer: $("#idcustomer").val(),
    };
    var column = 9;
    var right = [4, 5, 6, 7, 8];
    var color = $("#color").val();
    $("#idcustomer").select2({
        placeholder: "Cari Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: $("#path").val() + "/get_customer",
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
    datatableparams(controller, column, params, right);
});