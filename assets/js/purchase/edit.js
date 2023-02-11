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
var Detail = $(function() {
    var i = $("#jml").val();
    $("#addrow").on("click", function() {
        i++;
        var no = $("#tablecover tbody tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no+1}</spanx></td>`;
        cols += `<td><select data-urut="${i}" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_product[]" id="i_product${i}" required data-fouc></select></td>`;
        cols += `<td><input type="number" required class="form-control form-control-sm" min="1" id="qty${i}" onkeyup="hetang();" placeholder="Qty" name="qty[]"></td>`;
        cols += `<td hidden><input type="number" required class="form-control form-control-sm" onblur=\'if(this.value==""){this.value="0";}\' onfocus=\'if(this.value=="0"){this.value="";}\' value="0" id="diskon${i}" onkeyup="hetang();" placeholder="Diskon" name="vdiskon[]"></td>`;
        // cols += `<td><input type="number" required class="form-control form-control-sm harga" id="harga${i}" placeholder="Harga" name="harga[]"  onblur=\'if(this.value==""){this.value="0";}\' onfocus=\'if(this.value=="0"){this.value="";}\' value="0" onkeyup="hetang();" ></td>`;
        cols += `<td>
					<input type="text" class="form-control form-control-sm" placeholder="Keterangan" name="enote[]">
					<input type="hidden" class="form-control form-control-sm" id="e_product${i}" name="e_product[]">
					<input type="hidden" class="form-control form-control-sm" id="i_company${i}" name="i_company[]">
				</td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tablecover").append(newRow);
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
                            id_company: $('#customeritem').val(),
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
            .change(function(event) {
                var z = $(this).data("urut");
                var ada = false;
                for (var x = 1; x <= $("#jml").val(); x++) {
                    if ($(this).val() != null) {
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
                    var product = $(this).val();
                    produk = product.split(" - ");
                    product = produk[0];
                    brand = produk[1];
                    $.ajax({
                        type: "POST",
                        url: base_url + controller + "/get_detail_product",
                        data: {
                            i_product: product,
                            i_brand: brand,
                            id_customer: $('#idcustomer').val(),
                        },
                        dataType: "json",
                        success: function(data) {
                            //$("#harga" + z).val(formatcemua(data["detail"][0]["v_price"]));
                            $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                            $("#i_company" + z).val(data["detail"][0]["i_company"]);
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
        //hetang();
        $("#jml").val(i);
        var obj = $("#tablecover tr:visible").find("spanx");
        $.each(obj, function(key, value) {
            id = value.id;
            $("#" + id).html(key + 1);
        });
    });
});

// function hetang() {
//     var bruto = 0;
//     var diskonrp = 0;
//     var diskonpersen = 0;
//     var dpp = 0;
//     var ppn = 0;
//     var netto = 0;
//     for (var i = 1; i <= $('#jml').val(); i++) {
//         if (typeof $('#i_product' + i).val() != 'undefined') {
//             if (!isNaN(parseFloat($('#qty' + i).val()))) {
//                 var qty = parseFloat($('#qty' + i).val());
//             } else {
//                 var qty = 0;
//             }
//             var jumlah = formatulang($('#harga' + i).val()) * qty;
//             if (!isNaN(parseFloat($('#diskon' + i).val()))) {
//                 var diskon = $('#diskon' + i).val();
//             } else {
//                 var diskon = 0;
//             }
//             var ndiskon = parseFloat(jumlah * (diskon / 100));
//             var vjumlah = jumlah;

//             /*$('#vtotaldiskon'+i).val(vtotaldis);
//             $('#vtotal'+i).val(formatcemua(jumlah));
//             $('#vtotalnet'+i).val(formatcemua(vtotal));*/
//             /* totaldis += vtotaldis;
//             vjumlah += jumlah; */

//             bruto += jumlah;
//             diskonrp += ndiskon;
//         }
//     }
//     diskonpersen = (diskonrp / bruto) * 100;
//     dpp = bruto - diskonrp;
//     ppn = dpp * 0.1;
//     netto = Math.round(dpp + ppn);
//     $('#sbruto').text(formatcemua(bruto));
//     $('#bruto').val(bruto);
//     $('#sdiskon').text(formatcemua(diskonrp));
//     $('#diskon').val(diskonrp);
//     $('#sdiskonpersen').text(formatcemua(diskonpersen));
//     $('#diskonpersen').val(diskonpersen);
//     $('#sdpp').text(formatcemua(dpp));
//     $('#dpp').val(dpp);
//     $('#sppn').text(formatcemua(ppn));
//     $('#ppn').val(ppn);
//     $('#snetto').text(formatcemua(netto));
//     $('#netto').val(netto);
// }

function number() {
    $.ajax({
        type: "post",
        data: {
            'tgl': $('#ddocument').val(),
        },
        url: base_url + controller + "/number",
        dataType: "json",
        success: function(data) {
            $('#idocument').val(data);
        },
        error: function() {
            swalInit("Maaf :(", "Ada kesalahan :(", "error");
        }
    });
}


document.addEventListener("DOMContentLoaded", function() {
    Plugin.init();
    Detail.init();
    //hetang();
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
    }).change(function() {
        $("#tablecover tbody tr:gt(0)").remove();
        $("#jml").val(0);
        /* $.ajax({
            type: "POST",
            url: base_url + controller + "/get_detail_customer",
            data: {
                id_customer: $(this).val(),
            },
            dataType: "json",
            success: function(data) {
                $("#alamat").val(data.e_customer_address);
                $("#nama").val(data.e_customer_name);
            },
            error: function() {
                swalInit(
                    "Maaf :(",
                    "Ada kesalahan saat mengambil data :(",
                    "error"
                );
            },
        }); */
    });

    for (let i = 1; i <= $("#jml").val(); i++) {
        $("#i_product" + i)
            .select2({
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
                            id_company: $('#customeritem').val(),
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
            .change(function(event) {
                var z = $(this).data("urut");
                var ada = false;
                for (var x = 1; x <= $("#jml").val(); x++) {
                    if ($(this).val() != null) {
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
                    var product = $(this).val();
                    produk = product.split(" - ");
                    product = produk[0];
                    brand = produk[1];
                    $.ajax({
                        type: "POST",
                        url: base_url + controller + "/get_detail_product",
                        data: {
                            i_product: product,
                            i_brand: brand,
                            id_customer: $('#idcustomer').val(),
                        },
                        dataType: "json",
                        success: function(data) {
                            $("#harga" + z).val(formatcemua(data["detail"][0]["v_price"]));
                            $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                            $("#i_company" + z).val(data["detail"][0]["i_company"]);
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
    }

    $("#submit").on("click", function() {
        let tabel = $("#tablecover tbody tr").length;
        let ada = false;

        if (tabel < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        $("#tablecover tbody tr td .harga").each(function() {
            if ($(this).val() <= 0) {
                ada = true;
            }
        });

        var form = $(".form-validation").valid();
        if (form) {
            if (!ada) {
                sweetedit(controller);
            } else {
                swalInit("Maaf :(", "Harga harus lebih besar dari 0 :(", "error");
            }
        }
    });
});