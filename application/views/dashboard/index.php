<!-- Content area -->
<div class="content">

    <!-- Stacked area -->
    <div class="card area_stacked">
        <div class="card-header header-elements-inline">
            <h5 class="card-title"><?= $this->lang->line('Laporan Perbulan');?></h5>
            <div class="header-elements">
                <div class="list-icons">
                    <select class="form-control form-control-sm select text-center" data-container-css-class="select-sm" id="history_year">
                        <?php for ($i = 2020; $i <= date('Y'); $i++) { ?>
                            <option value="<?= $i; ?>" <?php if ($i == date('Y')) { ?> selected <?php } ?>> <?= $i; ?>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</option>
                        <?php } ?>
                    </select>
                    <i onclick="loadhistory();" class="icon-search4 font-size-base text-muted ml-1 mt-1"></i>
                </div>
            </div>
        </div>

        <div class="card-body">
            <div class="chart-container">
                <div class="chart has-fixed-height" id="area_stacked"></div>
            </div>
        </div>
    </div>
    <!-- /stacked area -->

</div>
<!-- /content area -->