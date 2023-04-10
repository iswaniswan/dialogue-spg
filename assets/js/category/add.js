/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */

document.addEventListener("DOMContentLoaded", function () {
	var controller = $("#path").val();
	$("#submit").on("click", function () {
		var form = $('.form-validation').valid();
		if(form){
			sweetadd(controller);
		}
	});

	$("#id_category").select2({
        placeholder: "Cari Kategori",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_category",
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
    .change(function() {
        
    });
});
