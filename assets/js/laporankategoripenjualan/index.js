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
    var cek = $("#id_customer").val();

    //alert(cek);

    if (cek == "") {
        swalInit("Maaf :(", "Pilih toko terlebih dahulu! :(", "error");
        return false;
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

    $("#id_customer").select2({
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
    }).change(function() {
        $('#id_brand').val(null).trigger('change');
    });

    $("#id_brand").select2({
        placeholder: "Cari Brand",
        width: "100%",
        allowClear: true,
        maximumSelectionSize: 1,
        ajax: {
            url: base_url + link + "/get_user_customer_brand",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                    id_customer: $('#id_customer').val()
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

    $('#btn-export').click(function() {
        const base_url = $('#url').val();

        $id_customer = $('#id_customer').val();
        $id_brand = $('#id_brand').val();

        if ($id_customer === undefined) {            
            swalInit("Maaf :(", "Pilih toko terlebih dahulu! :(", "error");
            return false;
        }

        let url = `${base_url}/${$id_customer}/${$id_brand}`;
        window.location.href = url;
    })

});