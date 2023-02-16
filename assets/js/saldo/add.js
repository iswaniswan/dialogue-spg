var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Ya',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> Tidak',
});

var controller = $("#path").val();
var Detail = $(function() {
    $("#addrow").on("click", function() {
        var i = $("#jml").val();
        i++;
        var no = $("#tablecover tbody tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no + 1}</spanx></td>`;
        cols += `<td>
                    <select data-urut="${i}" 
                        class="form-control form-control-sm form-control-select2" 
                        data-container-css-class="select-sm" 
                        name="items[${i}][id_product]"
                        id="i_product${i}" 
                        data-fouc required>
                    </select>
                </td>`;
        cols += `<td>
                    <input type="text" 
                        class="form-control form-control-sm" 
                        id="e_brand_name${i}" 
                        placeholder="Brand" 
                        name="items[${i}][e_brand]"
                        readonly>
                </td>`;
        cols += `<td>                    
                    <input type="number" required class="form-control form-control-sm" min="1" id="qty${i}" placeholder="Qty" name="items[${i}][qty]">
                </td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tablecover tbody").append(newRow);
        $("#i_product" + i).select2({
            placeholder: "Cari Product",
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + controller + "/get_product",
                dataType: "json",
                delay: 250,
                data: function(params) {
                    var query = {
                        q: params.term,
                        id_customer: $('#icustomer').val()
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
        }).change(function(event) {
            var z = $(this).data("urut");
            var ada = false;
            for (var x = 1; x <= $("#jml").val(); x++) {
                if ($(this).val() !== null || $(this).val() !== '') {
                    var product = $(this).val();
                    var productx = $("#i_product" + x).val();
                    console.log(product + " - " + productx);
                    if ((product == productx) && (z != x)) {
                        swalInit("Maaf :(", "Kode Barang tersebut sudah ada :(", "error");
                        ada = true;
                        break;
                    }
                }
            }
            if (!ada) {
                let id_product = $(this).val();
                $.ajax({
                    type: "POST",
                    url: base_url + controller + "/get_detail_product",
                    data: {
                        id_product: id_product,
                    },
                    dataType: "json",
                    success: function(data) {
                        $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                        $("#e_brand_name" + z).val(data["detail"][0]["e_brand_name"]);
                        $("#qty" + z).focus();
                    },
                    error: function() {
                        swalInit(
                            "Maaf :(",
                            "Ada kesalahan saat mengambil data :(",
                            "error"
                        );
                    },
                });
            } else {
                $(this).val("");
                $(this).html("");
            }
        });
    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tablecover").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();    
        
        var obj = $("#tablecover tr:visible").find("spanx");
        $.each(obj, function(key, value) {
            id = value.id;
            $("#" + id).html(key + 1);
        });

        let jmlvalue = $('#jml').val();
        jmlvalue--;
        $('#jml').val(jmlvalue);
        console.log(jmlvalue);
    });
});

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });

    $(document).ready(function() {
        // $("#i_periode").pickadate({
        //     labelMonthNext: "Go to the next month",
        //     labelMonthPrev: "Go to the previous month",
        //     labelMonthSelect: "Pick a month from the dropdown",
        //     labelYearSelect: "Pick a year from the dropdown",
        //     selectMonths: true,
        //     selectYears: true,
        //     formatSubmit: "yyyymm",
        //     format: "dd-mm-yyyy",
        //     hiddenName: true,
        //     min: [2021, 1, 1],
        // });

        $('#month, #year').on('change', function() {
            $('#icustomer').val(null).trigger('change');
        });
    });

    function getPeriode(){
        const year = $('#year').val();
        const month = $('#month').val();
        return `${year}${month}`;
    }

    $("#icustomer").select2({
        placeholder: "Select Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_customer",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                    i_periode: getPeriode()
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

    $("#iproduct").select2({
        placeholder: "Search Product",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_product",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                    i_company: $('#icompany').val(),
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
    $(".select-search").select2();
    $("#submit").on("click", function() {
        let tabel = $("#tablecover tbody tr").length;
        let ada = false;

        if (tabel < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        $("#tablecover tbody tr td .qty").each(function() {
            if ($(this).val() <= 0) {
                ada = true;
            }
        });

        var form = $(".form-validation").valid();
        if (form) {
            if (!ada) {
                sweetadd(controller);
            } else {
                swalInit("Maaf :(", "Qty harus lebih besar dari 0 :(", "error");
            }
        }
    });

});