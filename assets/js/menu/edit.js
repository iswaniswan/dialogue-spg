/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });
    $("#iparent").select2({
        placeholder: "Select Parent",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_menu",
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
    $("#submit").on("click", function() {
        var form = $('.form-validation').valid();
        if (form) {
            sweetedit(controller);
        }
    });
});