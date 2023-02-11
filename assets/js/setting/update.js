// Initialize module
// ------------------------------

document.addEventListener("DOMContentLoaded", function () {
    var controller = $("#path").val();
    var color = $("#color").val();
    $("#submit").on("click", function () {
        var form = $('.form-validation').valid();
        if(form){
            sweetadd(controller);
        }
    });
    $('.form-check-input-styled-'+color).uniform({
        wrapperClass: 'border-teal-'+color+' text-'+color
    });
});