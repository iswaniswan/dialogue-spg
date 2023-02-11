// Setup module
// ------------------------------

var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
});

function check() {
    var cek = $("#icustomer").val();

    //alert(cek);

    if (cek == "") {
        swalInit("Maaf :(", "Pilih toko terlebih dahulu! :(", "error");
        return false;
    } else {
        var url = $("#url").val() + '/' + cek;
        window.location.href = url;
        //alert(cek);
    }
}

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val() + "/serverside";
    var link = "laporankategoripenjualan";
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


    $("#icustomer").select2({
        placeholder: "Cari Nama Toko",
        width: "100%",
        allowClear: true,
        maximumSelectionSize: 1,
        ajax: {
            url: base_url + link + "/get_customer",
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

    $("#icustomer").on('change', function() {
        id = $(this).val();
        var new_href = $('#export').attr('href') + '/' + id;
        $('#export').attr('href', new_href);
    })

});