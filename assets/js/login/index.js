/* ------------------------------------------------------------------------------
 *
 *  # Checkboxes and radios
 *
 *  Demo JS code for form_checkboxes_radios.html page
 *
 * ---------------------------------------------------------------------------- */


// Setup module
// ------------------------------

var InputsCheckboxesRadios = function () {


    //
    // Setup components
    //

    // Uniform
    var _componentUniform = function() {
        if (!$().uniform) {
            console.warn('Warning - uniform.min.js is not loaded.');
            return;
        }

        // Default initialization
        $('.form-check-input-styled').uniform();


        //
        // Contextual colors
        //

        // Slate
        $('.form-check-input-styled-slate').uniform({
            wrapperClass: 'border-slate-600 text-slate-800'
        });

        // Primary
        $('.form-check-input-styled-primary').uniform({
            wrapperClass: 'border-primary-600 text-primary-800'
        });

        // Danger
        $('.form-check-input-styled-danger').uniform({
            wrapperClass: 'border-danger-600 text-danger-800'
        });

        // Success
        $('.form-check-input-styled-success').uniform({
            wrapperClass: 'border-success-600 text-success-800'
        });

        // Warning
        $('.form-check-input-styled-warning').uniform({
            wrapperClass: 'border-warning-600 text-warning-800'
        });

        // Info
        $('.form-check-input-styled-info').uniform({
            wrapperClass: 'border-info-600 text-info-800'
        });

        // Pink
        $('.form-check-input-styled-pink').uniform({
            wrapperClass: 'border-pink-600 text-pink-800'
        });

        // Violet
        $('.form-check-input-styled-violet').uniform({
            wrapperClass: 'border-violet-600 text-violet-800'
        });

        // Purple
        $('.form-check-input-styled-purple').uniform({
            wrapperClass: 'border-purple-600 text-purple-800'
        });

        // Indigo
        $('.form-check-input-styled-indigo').uniform({
            wrapperClass: 'border-indigo-600 text-indigo-800'
        });

        // Blue
        $('.form-check-input-styled-blue').uniform({
            wrapperClass: 'border-blue-600 text-blue-800'
        });

        // Teal
        $('.form-check-input-styled-teal').uniform({
            wrapperClass: 'border-teal-600 text-teal-800'
        });

        // Green
        $('.form-check-input-styled-green').uniform({
            wrapperClass: 'border-green-600 text-green-800'
        });

        // Orange
        $('.form-check-input-styled-orange').uniform({
            wrapperClass: 'border-orange-600 text-orange-800'
        });

        // Brown
        $('.form-check-input-styled-brown').uniform({
            wrapperClass: 'border-brown-600 text-brown-800'
        });

        // Grey
        $('.form-check-input-styled-grey').uniform({
            wrapperClass: 'border-grey-600 text-grey-800'
        });
    };


    //
    // Return objects assigned to module
    //

    return {
        initComponents: function() {
            _componentUniform();
        }
    }
}();


// Initialize module
// ------------------------------

document.addEventListener('DOMContentLoaded', function() {
    InputsCheckboxesRadios.initComponents();
});