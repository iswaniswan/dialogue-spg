// Setup module
// ------------------------------

document.addEventListener("DOMContentLoaded", function () {
	var controller = $("#path").val() + "/serverside";
	var linkadd    = $("#path").val() + "/add";
	var column     = 4;
	var id_menu    = $("#id_menu").val();
	var color      = $("#color").val();
	if (id_menu != "") {
		datatableadd(controller, column, linkadd, color);
	} else {
		datatable(controller, column);
	}
	/* Setting.init(); */
});