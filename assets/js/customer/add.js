var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
});
var controller = $("#path").val();
var Detail = $(function() {
    var i = $("#jml").val();
    $("#addrow").on("click", function() {
        i++;
        var no = $("#tablecover tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no}</spanx></td>`;
        cols += `<td><select data-nourut="${i}" class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_company[]" id="i_company${i}" required data-fouc></select></td>`;
        cols += `<td><select data-urut="${i}" class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_customer[]" id="i_customer${i}" required data-fouc></select></td>`;
        cols += `<td><input type="text" class="form-control form-control-sm text-right" name="v_discount1[]" id="v_discount1${i}" required value="0" readonly></td>`;
        cols += `<td><input type="text" class="form-control form-control-sm text-right" name="v_discount2[]" id="v_discount2${i}" required value="0" readonly></td>`;
        cols += `<td>
                    <input type="text" class="form-control form-control-sm text-right" name="v_discount3[]" id="v_discount3${i}" required value="0" readonly>
                    <input type="hidden" name="i_area[]" id="i_area${i}">
                    <input type="hidden" name="e_customer[]" id="e_customer${i}">
                </td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tablecover").append(newRow);
        $("#i_company" + i)
            .select2({
                placeholder: "Select Company",
                width: "100%",
                allowClear: true,
                ajax: {
                    url: base_url + controller + "/get_company",
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
            .change(function(event) {
                var z = $(this).data("nourut");
                $("#i_customer" + z).val(null);
                $("#i_customer" + z).html(null);
                /* var ada = true;
                for (var x = 1; x <= $("#jml").val(); x++) {
                    if ($(this).val() != null) {
                        if ($(this).val() == $("#i_departement" + x).val() && z != x) {
                            swalInit("Maaf :(", "Departement tersebut sudah ada :(", "error");
                            ada = false;
                            break;
                        }
                    }
                }
                if (!ada) {
                    $(this).val("");
                    $(this).html("");
                } */
            });

        $("#i_customer" + i)
            .select2({
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
                            id: $("#i_company" + $(this).data("urut")).val(),
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
                var x = $(this).data("urut");
                $.ajax({
                    type: "POST",
                    url: base_url + controller + "/get_detail_customer",
                    data: {
                        i_company: $("#i_company" + x).val(),
                        i_customer: $(this).val(),
                    },
                    dataType: "json",
                    success: function(data) {
                        $('#v_discount1' + x).val(data['detail'][0]['v_discount1']);
                        $('#v_discount2' + x).val(data['detail'][0]['v_discount2']);
                        $('#v_discount3' + x).val(data['detail'][0]['v_discount3']);
                        $('#e_customer' + x).val(data['detail'][0]['e_customer_name']);
                        $('#i_area' + x).val(data['detail'][0]['i_area']);
                    },
                    error: function() {
                        swalInit("Maaf :(", "Ada kesalahan saat mengambil data :(", "error");
                    }
                });
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

document.addEventListener("DOMContentLoaded", function() {
    Detail.init();
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });

    $(".select-search").select2();

    $("#fpkp").on("change", function() {
        if ($(this).val() == "f") {
            $("#ecustomernpwp").attr("disabled", true);
            $("#eaddressnpwp").attr("disabled", true);
        } else {
            $("#ecustomernpwp").attr("disabled", false);
            $("#eaddressnpwp").attr("disabled", false);
        }
    });

    $("#submit").on("click", function() {
        var form = $(".form-validation").valid();
        var ada = false;
        if (form) {
            $("#tablecover tbody tr").each(function() {
                $(this).find("td select").each(function() {
                    if ($(this).val()=='' || $(this).val()==null) {
                        swalInit("Maaf :(", "Perusahaan dan Kode Toko tidak boleh kosong", "warning");
                        ada = true;
                    }
                });
            });

            if (ada == true) {
                return false;
            } else {
                sweetadd(controller);
            }
        }
    });
});