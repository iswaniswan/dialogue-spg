/* ------------------------------------------------------------------------------
 *
 *  # Echarts - Area charts
 *
 *  Demo JS code for echarts_areas.html page
 *
 * ---------------------------------------------------------------------------- */

// Setup module
// ------------------------------

var EchartsAreas = (function() {
    // Select2
    var _componentSelect2 = function() {
        if (!$().select2) {
            console.warn("Warning - select2.min.js is not loaded.");
            return;
        }

        $(".select").select2({
            minimumResultsForSearch: Infinity,
        });

        // Default initialization
        $(".form-control-select2").select2({
            minimumResultsForSearch: Infinity,
        });

        /* $("#divisi").select2({
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + link + "/getdivisi",
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
        }); */
    };

    //
    // Setup module components
    //

    // Area charts
    var _areaChartExamples = function() {
        if (typeof echarts == "undefined") {
            console.warn("Warning - echarts.min.js is not loaded.");
            return;
        }

        // Define elements
        var area_stacked_element = document.getElementById("area_stacked");

        //
        // Charts configuration
        //

        // Stacked area
        if (area_stacked_element) {
            // Initialize chart
            var area_stacked = echarts.init(area_stacked_element);

            //
            // Chart config
            //

            // Options
            area_stacked.setOption({
                // Define colors
                color: ["#2ec7c9", "#b6a2de", "#5ab1ef", "#ffb980", "#d87a80"],

                // Global text styles
                textStyle: {
                    fontFamily: "Roboto, Arial, Verdana, sans-serif",
                    fontSize: 13,
                },

                // Chart animation duration
                animationDuration: 750,

                // Setup grid
                grid: {
                    left: 0,
                    right: 40,
                    top: 35,
                    bottom: 0,
                    containLabel: true,
                },

                // Add legend
                legend: {
                    data: ["Internet Explorer", "Safari", "Firefox", "Chrome"],
                    itemHeight: 8,
                    itemGap: 20,
                },

                // Add tooltip
                tooltip: {
                    trigger: "axis",
                    backgroundColor: "rgba(0,0,0,0.75)",
                    padding: [10, 15],
                    textStyle: {
                        fontSize: 13,
                        fontFamily: "Roboto, sans-serif",
                    },
                },

                // Horizontal axis
                xAxis: [{
                    type: "category",
                    boundaryGap: false,
                    data: [
                        "Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec",
                    ],
                    axisLabel: {
                        color: "#333",
                    },
                    axisLine: {
                        lineStyle: {
                            color: "#999",
                        },
                    },
                    splitLine: {
                        show: true,
                        lineStyle: {
                            color: "#eee",
                            type: "dashed",
                        },
                    },
                }, ],

                // Vertical axis
                yAxis: [{
                    type: "value",
                    axisLabel: {
                        color: "#333",
                    },
                    axisLine: {
                        lineStyle: {
                            color: "#999",
                        },
                    },
                    splitLine: {
                        lineStyle: {
                            color: "#eee",
                        },
                    },
                    splitArea: {
                        show: true,
                        areaStyle: {
                            color: ["rgba(250,250,250,0.1)", "rgba(0,0,0,0.01)"],
                        },
                    },
                }, ],

                // Add series
                series: [{
                        name: "Internet Explorer",
                        type: "line",
                        stack: "Total",
                        areaStyle: {
                            normal: {
                                opacity: 0.25,
                            },
                        },
                        smooth: true,
                        symbolSize: 7,
                        itemStyle: {
                            normal: {
                                borderWidth: 2,
                            },
                        },
                        data: [120, 132, 101, 134, 490, 230, 210],
                    },
                    {
                        name: "Safari",
                        type: "line",
                        stack: "Total",
                        areaStyle: {
                            normal: {
                                opacity: 0.25,
                            },
                        },
                        smooth: true,
                        symbolSize: 7,
                        itemStyle: {
                            normal: {
                                borderWidth: 2,
                            },
                        },
                        data: [150, 1232, 901, 154, 190, 330, 810],
                    },
                    {
                        name: "Firefox",
                        type: "line",
                        stack: "Total",
                        areaStyle: {
                            normal: {
                                opacity: 0.25,
                            },
                        },
                        smooth: true,
                        symbolSize: 7,
                        itemStyle: {
                            normal: {
                                borderWidth: 2,
                            },
                        },
                        data: [320, 1332, 1801, 1334, 590, 830, 1220],
                    },
                    {
                        name: "Chrome",
                        type: "line",
                        stack: "Total",
                        areaStyle: {
                            normal: {
                                opacity: 0.25,
                            },
                        },
                        smooth: true,
                        symbolSize: 7,
                        itemStyle: {
                            normal: {
                                borderWidth: 2,
                            },
                        },
                        data: [820, 1632, 1901, 2234, 1290, 1330, 1320],
                    },
                ],
            });
        }

        // Resize function
        var triggerChartResize = function() {
            area_stacked_element && area_stacked.resize();
        };

        // On sidebar width change
        $(document).on("click", ".sidebar-control", function() {
            setTimeout(function() {
                triggerChartResize();
            }, 0);
        });

        // On window resize
        var resizeCharts;
        window.onresize = function() {
            clearTimeout(resizeCharts);
            resizeCharts = setTimeout(function() {
                triggerChartResize();
            }, 200);
        };
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _areaChartExamples();
            _componentSelect2();
        },
    };
})();

// Initialize module
// ------------------------------

function loadhistory() {
    return;
    var yearnow = $("#history_year").val();
    var area_stacked_element = document.getElementById("area_stacked");
    area_stacked_element.height = 10000;
    if (area_stacked_element) {
        // Initialize chart
        var area_stacked = echarts.init(area_stacked_element);

        $.ajax({
            url: base_url + "dashboard/history_chart",
            type: "GET",
            dataType: "json",
            contentType: "application/json;charset=utf-8",
            data: {
                year: yearnow,
            },
            cache: false,
            beforeSend: function() {
                $(".area_stacked").block({
                    /* message: '<img src="' +
                        base_url +
                        'assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                    message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
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
                var bulan = $.parseJSON(data['bulan'][0]['month']);
                var company = $.parseJSON(data['company'][0]['e_company_name']);
                var series = [];
                for (let index = 0; index < company.length; index++) {
                    series.push({
                        name: data['query'][index]['e_company_name'],
                        type: "line",
                        stack: "Total",
                        areaStyle: {
                            normal: {
                                opacity: 0.25,
                            },
                        },
                        smooth: true,
                        symbolSize: 7,
                        itemStyle: {
                            normal: {
                                borderWidth: 2,
                            },
                        },
                        data: $.parseJSON(data['query'][index]['qty']),
                    });
                }

                // Options
                area_stacked.setOption({
                    // Define colors
                    color: ["#2ec7c9", "#b6a2de", "#5ab1ef", "#ffb980", "#d87a80"],

                    // Global text styles
                    textStyle: {
                        fontFamily: "Roboto, Arial, Verdana, sans-serif",
                        fontSize: 13,
                    },

                    // Chart animation duration
                    animationDuration: 750,

                    // Setup grid
                    grid: {
                        left: 0,
                        right: 40,
                        top: 35,
                        bottom: 0,
                        containLabel: true,
                    },

                    // Add legend
                    legend: {
                        data: company,
                        itemHeight: 8,
                        itemGap: 20,
                    },

                    // Add tooltip
                    tooltip: {
                        trigger: "axis",
                        backgroundColor: "rgba(0,0,0,0.75)",
                        padding: [10, 15],
                        textStyle: {
                            fontSize: 13,
                            fontFamily: "Roboto, sans-serif",
                        },
                    },

                    // Horizontal axis
                    xAxis: [{
                        type: "category",
                        boundaryGap: false,
                        data: bulan,
                        axisLabel: {
                            color: "#333",
                        },
                        axisLine: {
                            lineStyle: {
                                color: "#999",
                            },
                        },
                        splitLine: {
                            show: true,
                            lineStyle: {
                                color: "#eee",
                                type: "dashed",
                            },
                        },
                    }, ],

                    // Vertical axis
                    yAxis: [{
                        type: "value",
                        axisLabel: {
                            color: "#333",
                        },
                        axisLine: {
                            lineStyle: {
                                color: "#999",
                            },
                        },
                        splitLine: {
                            lineStyle: {
                                color: "#eee",
                            },
                        },
                        splitArea: {
                            show: true,
                            areaStyle: {
                                color: ["rgba(250,250,250,0.1)", "rgba(0,0,0,0.01)"],
                            },
                        },
                    }, ],

                    // Add series
                    series: series
                });
                $(".area_stacked").unblock();
            },
            error: function() {
                $(".area_stacked").unblock();
            },
        });
    }
}

document.addEventListener("DOMContentLoaded", function() {
    /* EchartsAreas.init(); */
    loadhistory();
});