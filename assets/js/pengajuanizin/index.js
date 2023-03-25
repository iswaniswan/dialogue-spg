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
            format: "yyyy-mm-dd",
            min: [2021, 1, 1],
            max: 365,
        });
    };

    return {
        init: function() {
            _componentPickadate();
        },
    };
})();

function _sweetcancel(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be canceled :)",
        type: "error",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                },
                url: $("#path").val() + "/cancel",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
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
                            "Data successfully to cancel:)",
                            "success"
                        ).then(function(result) {
                            window.location = $("#path").val();
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to canceled :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to cancel :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

document.addEventListener("DOMContentLoaded", function () {
    Kalender.init();
	var controller = $("#path").val() + "/serverside";
	var linkadd = $("#path").val() + "/add";
	var column = 4;
    var params = {
        dfrom: $("#dfrom").val(),
        dto: $("#dto").val(),
    };
	var id_menu = $("#id_menu").val();
	var color = $("#color").val();
	if (id_menu != "") {
		datatableaddparams(controller, column, linkadd, params, color);
	} else {
		datatable(controller, column);
	}
	/* Setting.init(); */
});