var Switch = (function() {
    // Bootstrap switch
    var _componentBootstrapSwitch = function() {
        if (!$().bootstrapSwitch) {
            console.warn("Warning - bootstrap_switch.min.js is not loaded.");
            return;
        }

        // Initialize
        $(".form-input-switch").bootstrapSwitch({
            onSwitchChange: function(state) {
                if ($(this).is(":checked")) {
                    $(".cover").attr("hidden", true);
                    $("#tablecover tr:gt(0)").remove();
                    $("#jml").val(0);
                } else {
                    $(".cover").attr("hidden", false);
                }
                if (state) {
                    $(this).valid(true);
                } else {
                    $(this).valid(false);
                }
            },
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentBootstrapSwitch();
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


document.addEventListener("DOMContentLoaded", function() {
    Switch.init();
    var controller = $("#path").val();
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });


    $("#submit").on("click", function() {
        var form = $(".form-validation").valid();
        if (form) {
            _sweetedit(controller);
        }
    });

    function _sweetedit(link) {
        var swalInit = swal.mixin({
            buttonsStyling: false,
            confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
            cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
            confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
            cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
        });
        swalInit({
            title: "Are you sure?",
            text: "This data will be update :)",
            type: "info",
            showCancelButton: true,
            buttonsStyling: false,
        }).then(function(result) {
            if (result.value) {
                $.ajax({
                    type: "POST",
                    data: $("form").serialize(),
                    url: base_url + link + "/edit_password",
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
                        if (data.sukses == true && data.ada == false) {
                            swalInit("Success!", "Data update successfully :)", "success").then(
                                function(result) {
                                    window.location = base_url + "dashboard";
                                }
                            );
                        } else if (data.sukses == false && data.ada == true) {
                            swalInit("Sorry :(", "The data already exists :(", "error");
                        } else {
                            swalInit("Sorry :(", "Data failed to update :(", "error");
                        }
                        $(".page-content").unblock();
                    },
                    error: function() {
                        swalInit("Sorry", "Data failed to update :(", "error");
                        $(".page-content").unblock();
                    },
                });
            }
        });
    }
});

$(document).ready(function() {
    $("#show_hide_password a").on('click', function(event) {
        event.preventDefault();
        if($('#show_hide_password input').attr("type") == "text"){
            $('#show_hide_password input').attr('type', 'password');
            $('#show_hide_password i').addClass( "icon-eye-blocked" );
            $('#show_hide_password i').removeClass( "icon-eye" );
        }else if($('#show_hide_password input').attr("type") == "password"){
            $('#show_hide_password input').attr('type', 'text');
            $('#show_hide_password i').removeClass( "icon-eye-blocked" );
            $('#show_hide_password i').addClass( "icon-eye" );
        }
    });

    $("#show_hide_password_repeat a").on('click', function(event) {
        event.preventDefault();
        if($('#show_hide_password_repeat input').attr("type") == "text"){
            $('#show_hide_password_repeat input').attr('type', 'password');
            $('#show_hide_password_repeat i').addClass( "icon-eye-blocked" );
            $('#show_hide_password_repeat i').removeClass( "icon-eye" );
        }else if($('#show_hide_password_repeat input').attr("type") == "password"){
            $('#show_hide_password_repeat input').attr('type', 'text');
            $('#show_hide_password_repeat i').removeClass( "icon-eye-blocked" );
            $('#show_hide_password_repeat i').addClass( "icon-eye" );
        }
    });
})