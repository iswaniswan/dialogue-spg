var adjustment = (function() {
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
            min: [2022, 1, 1],
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
    $("#addrow").on("click", function() {
        var i = $("#jml").val();
        i++;
        var no = $("#tablecover tbody tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no + 1}</spanx></td>`;
        cols += `<td><select data-urut="${i}" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_product[]" id="i_product${i}" required data-fouc></select></td>`;
        cols += `<td><input type="text" readonly class="form-control form-control-sm" id="e_brand_name${i}" placeholder="Brand" name="e_brand_name[]" ></td>`;
        cols += `<td>
                    <input type="hidden" class="form-control form-control-sm" id="id_brand${i}" name="id_brand[]" >
                    <input type="hidden" class="form-control form-control-sm" id="e_product${i}" name="e_product[]" >
                    <input type="number" required class="form-control form-control-sm" id="qty${i}" placeholder="Qty" name="qty[]" onblur=\'if(this.value==""){this.value="0";}\' onfocus=\'if(this.value=="0"){this.value="";}\'>
                 </td>`;
        cols += `<td><input type="text" class="form-control form-control-sm" id="e_remark${i}" placeholder="Keterangan" name="e_remark[]" ></td>`;
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
                        i_company: $('#i_company' + z).val(),
                    },
                    dataType: "json",
                    success: function(data) {
                        $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                        $("#e_brand_name" + z).val(data["detail"][0]["e_brand_name"]);
                        $("#id_brand" + z).val(data["detail"][0]["id_brand"]);
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
        $("#jml").val(i);
        var obj = $("#tablecover tr:visible").find("spanx");
        $.each(obj, function(key, value) {
            id = value.id;
            $("#" + id).html(key + 1);
        });
    });
});

function number() {
    $.ajax({
        type: "post",
        data: {
            tgl: $("#ddocument").val(),
        },
        url: base_url + controller + "/number",
        dataType: "json",
        success: function(data) {
            $("#idocument").val(data);
        },
        error: function() {
            swalInit("Maaf :(", "Ada kesalahan :(", "error");
        },
    });
}

function get_item() {
    $.ajax({
        type: "post",
        data: {
            tgl: $("#ddocument").val(),
            id_customer: $("#idcustomer").val(),
        },
        url: base_url + controller + "/get_item",
        dataType: "json",
        success: function(data) {
            if (data['detail_product'].length > 0) {
                $("#tablecover tbody tr").remove();
                $('#jml').val(data['detail_product'].length);
                for (let x = 0; x < data['detail_product'].length; x++) {
                    var i = x + 1;
                    $("#jml").val(i);
                    var newRow = $("<tr>");
                    var cols = "";
                    cols += `<td class="text-center"><spanx id="snum${i}">${i}</spanx></td>`;
                    cols += `<td>
                                <select data-urut="${i}" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_product[]" id="i_product${i}" required data-fouc>
                                    <option value="${data['detail_product'][x]['i_product']}">${data['detail_product'][x]['e_product_name']}</option>
                                </select>
                            </td>`;
                    cols += `<td><input type="text" readonly class="form-control form-control-sm" id="e_brand_name${i}" placeholder="Brand" name="e_brand_name[]" value="${data['detail_product'][x]['e_brand_name']}"></td>`;
                    cols += `<td>
                                <input type="hidden" class="form-control form-control-sm" id="id_brand${i}" name="id_brand[]" value="${data['detail_product'][x]['id_brand']}">
                                <input type="hidden" class="form-control form-control-sm" id="e_product${i}" name="e_product[]" value="${data['detail_product'][x]['e_product_name']}">
                                <input type="number" required class="form-control form-control-sm" id="qty${i}" placeholder="Qty" name="qty[]" value="${data['detail_product'][x]['n_adjustment']}" onblur=\'if(this.value==""){this.value="0";}\' onfocus=\'if(this.value=="0"){this.value="";}\'>
                            </td>`;
                    cols += `<td><input type="text" class="form-control form-control-sm" id="e_remark${i}" placeholder="Keterangan" name="e_remark[]" ></td>`;
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
                                    i_company: $('#i_company' + z).val(),
                                },
                                dataType: "json",
                                success: function(data) {
                                    $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                                    $("#e_company_name" + z).val(data["detail"][0]["e_company_name"]);
                                    $("#i_company" + z).val(data["detail"][0]["i_company"]);
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
                }
            };
        },
        error: function() {
            swalInit("Maaf :(", "Ada kesalahan :(", "error");
        },
    });
}

document.addEventListener("DOMContentLoaded", function() {
    adjustment.init();
    Detail.init();
    number();
    //get_item();
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
        $("#tablecover tbody").remove();
        $("#jml").val(0);
        // get_item();
    });

    $("#ddocument").on("change", function() {
        number();
        get_item();
    });

    $("#submit").on("click", function() {
        let tabel = $("#jml").val();
        let ada = false;

        if (tabel < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        var form = $(".form-validation").valid();
        if (form) {
            sweetadd(controller);
        }
    });
});