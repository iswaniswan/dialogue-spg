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
        cols += `<td class="text-center"><spanx id="snum${i}">${no + 1}</spanx></td>`;
        // cols += `<td><select data-urutan="${i}" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_company[]" id="i_company${i}" required data-fouc></select></td>`;
        cols += `<td><select data-urut="${i}" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_product[]" id="i_product${i}" required data-fouc></select></td>`;
        cols += `<td><input type="text" readonly class="form-control form-control-sm" id="e_company_name${i}" placeholder="Perusahaan" name="e_company_name[]"></td>`;
        cols += `<td><input type="number" required class="form-control form-control-sm" min="1" id="qty${i}" placeholder="Qty" name="qty[]"></td>`;
        cols += `<td>
                    <select required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_alasan[]" id="i_alasan${i}" required data-fouc></select>
					<input type="hidden" class="form-control form-control-sm" id="e_product${i}" name="e_product[]">
					<input type="hidden" class="form-control form-control-sm" id="i_company${i}" name="i_company[]">
				</td>`;
        cols += `<td><input type="file" required class="form-control" id="foto${i}" placeholder="Foto" name="foto${i}"></td><td></td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tablecover").append(newRow);
        /* $("#i_company" + i).select2({
            placeholder: "Pilih Perusahaan",
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
        }).change(function(event) {
            var z = $(this).data("urutan");
            $("#i_product" + z).val("");
            $("#i_product" + z).html("");
        }); */

        $("#i_alasan" + i).select2({
            placeholder: "Pilih Alasan Retur",
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + controller + "/get_alasan",
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
                        /* i_company: $("#i_company" + $(this).data("urut")).val(), */
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
    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tablecover").on("click", ".ibtnDel", function(event) {
        var foto = $('#fotolama' + i).val();
        $.ajax({
            url: base_url + controller + "/hapusfoto",
            type: "POST",
            data: { foto: foto },
            success: function(data) {

            }
        });
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

var FileUpload = function() {

    // Bootstrap file upload
    var _componentFileUpload = function() {
        if (!$().fileinput) {
            console.warn('Warning - fileinput.min.js is not loaded.');
            return;
        }

        // Modal template
        var modalTemplate = '<div class="modal-dialog modal-lg" role="document">\n' +
            '  <div class="modal-content">\n' +
            '    <div class="modal-header align-items-center">\n' +
            '      <h6 class="modal-title">{heading} <small><span class="kv-zoom-title"></span></small></h6>\n' +
            '      <div class="kv-zoom-actions btn-group">{toggleheader}{fullscreen}{borderless}{close}</div>\n' +
            '    </div>\n' +
            '    <div class="modal-body">\n' +
            '      <div class="floating-buttons btn-group"></div>\n' +
            '      <div class="kv-zoom-body file-zoom-content"></div>\n' + '{prev} {next}\n' +
            '    </div>\n' +
            '  </div>\n' +
            '</div>\n';

        // Buttons inside zoom modal
        var previewZoomButtonClasses = {
            toggleheader: 'btn btn-light btn-icon btn-header-toggle btn-sm',
            fullscreen: 'btn btn-light btn-icon btn-sm',
            borderless: 'btn btn-light btn-icon btn-sm',
            close: 'btn btn-light btn-icon btn-sm'
        };

        // Icons inside zoom modal classes
        var previewZoomButtonIcons = {
            prev: '<i class="icon-arrow-left32"></i>',
            next: '<i class="icon-arrow-right32"></i>',
            toggleheader: '<i class="icon-menu-open"></i>',
            fullscreen: '<i class="icon-screen-full"></i>',
            borderless: '<i class="icon-alignment-unalign"></i>',
            close: '<i class="icon-cross2 font-size-base"></i>'
        };

        // File actions
        var fileActionSettings = {
            zoomClass: '',
            zoomIcon: '<i class="icon-zoomin3"></i>',
            dragClass: 'p-2',
            dragIcon: '<i class="icon-three-bars"></i>',
            removeClass: '',
            removeErrorClass: 'text-danger',
            removeIcon: '<i class="icon-bin"></i>',
            indicatorNew: '<i class="icon-file-plus text-success"></i>',
            indicatorSuccess: '<i class="icon-checkmark3 file-icon-large text-success"></i>',
            indicatorError: '<i class="icon-cross2 text-danger"></i>',
            indicatorLoading: '<i class="icon-spinner2 spinner text-muted"></i>'
        };


        //
        // Basic example
        //

        /* $('.file-input').fileinput({
            browseLabel: 'Browse',
            browseIcon: '<i class="icon-file-plus mr-2"></i>',
            uploadIcon: '<i class="icon-file-upload2 mr-2"></i>',
            removeIcon: '<i class="icon-cross2 font-size-base mr-2"></i>',
            layoutTemplates: {
                icon: '<i class="icon-file-check"></i>',
                modal: modalTemplate
            },
            initialCaption: "No file selected",
            previewZoomButtonClasses: previewZoomButtonClasses,
            previewZoomButtonIcons: previewZoomButtonIcons,
            fileActionSettings: fileActionSettings
        }); */

        //
        // AJAX upload
        //

        $('.file-input-ajax').fileinput({
            browseLabel: 'Browse',
            uploadUrl: "http://localhost", // server upload action
            uploadAsync: true,
            maxFileCount: 10,
            initialPreview: [],
            browseIcon: '<i class="icon-file-plus mr-2"></i>',
            uploadIcon: '<i class="icon-file-upload2 mr-2"></i>',
            removeIcon: '<i class="icon-cross2 font-size-base mr-2"></i>',
            fileActionSettings: {
                removeIcon: '<i class="icon-bin"></i>',
                /* uploadIcon: '<i class="icon-upload"></i>', */
                uploadClass: '',
                zoomIcon: '<i class="icon-zoomin3"></i>',
                zoomClass: '',
                indicatorNew: '<i class="icon-file-plus text-success"></i>',
                indicatorSuccess: '<i class="icon-checkmark3 file-icon-large text-success"></i>',
                indicatorError: '<i class="icon-cross2 text-danger"></i>',
                indicatorLoading: '<i class="icon-spinner2 spinner text-muted"></i>',
            },
            layoutTemplates: {
                icon: '<i class="icon-file-check"></i>',
                modal: modalTemplate
            },
            initialCaption: 'No file selected',
            previewZoomButtonClasses: previewZoomButtonClasses,
            previewZoomButtonIcons: previewZoomButtonIcons
        });


        //
        // Misc
        //

        // Disable/enable button
        $('#btn-modify').on('click', function() {
            $btn = $(this);
            if ($btn.text() == 'Disable file input') {
                $('#file-input-methods').fileinput('disable');
                $btn.html('Enable file input');
                alert('Hurray! I have disabled the input and hidden the upload button.');
            } else {
                $('#file-input-methods').fileinput('enable');
                $btn.html('Disable file input');
                alert('Hurray! I have reverted back the input to enabled with the upload button.');
            }
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentFileUpload();
        }
    }
}();


document.addEventListener("DOMContentLoaded", function() {
    Plugin.init();
    Detail.init();
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
    });

    for (let i = 1; i <= $("#jml").val(); i++) {
        /* $("#i_company" + i).select2({
            placeholder: "Pilih Perusahaan",
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
        }).change(function(event) {
            var z = $(this).data("urutan");
            $("#i_product" + z).val("");
            $("#i_product" + z).html("");
        }); */

        $("#i_alasan" + i).select2({
            placeholder: "Pilih Alasan Retur",
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + controller + "/get_alasan",
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
                        /* i_company: $("#i_company" + $(this).data("urut")).val(), */
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

    $('#imageModal').on('show.bs.modal', function(e) {
        var id = e.relatedTarget.id;
        console.log(id);
        var image = $('#fotosrc' + id).val();
        $("#myImage").attr("src", image);
    });

    FileUpload.init();
    $('form').on('submit', function(e) {
        e.preventDefault();

        let tabel = $("#tablecover tbody tr").length;

        if (tabel < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        var formData = new FormData(this);

        var form = $(".form-validation").valid();
        if (form) {
            sweeteditparams(controller, formData);
        }
    });
});