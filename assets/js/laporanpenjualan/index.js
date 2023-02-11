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

function getcustomer() {
    var controller = $("#path").val();
    var index = $("#idcustomer option:selected").val();
    document.getElementById("export").href = base_url + controller + "/export_excel/" + $('#dfrom').val() + "/" + $('#dto').val() + "/" + index;
};

document.addEventListener("DOMContentLoaded", function() {
    Kalender.init();
    var controller = $("#path").val() + "/serverside";
    var linkadd = $("#path").val() + "/add";
    var params = {
        dfrom: $("#dfrom").val(),
        dto: $("#dto").val(),
        idcustomer: $("#idcustomer").val(),
    };
    var column = 8;
    var right = [5, 6, 7, 8];
    var order = '';
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    $("#idcustomer").select2({});
    if (id_menu != "") {
        datatableparams(controller, column, params, right, order);
    } else {
        datatableparams(controller, column);
    }
    /* Setting.init(); */
});