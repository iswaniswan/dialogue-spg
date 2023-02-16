<style>
    .tabel td {
        padding: 7px 7px !important;
    }
</style>
<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-stack-plus mr-2"></i> Add <?= $this->title; ?></h6>
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <div class="header-elements">
                    <div class="list-icons">
                        <a class="list-icons-item" data-action="collapse"></a>
                        <a class="list-icons-item" data-action="reload"></a>
                        <a class="list-icons-item" data-action="remove"></a>
                    </div>
                </div>
            </div>

            <div class="card-body">
                <div class="row mb-4">
                    <div class="col-md-2">
                        <label><?= $this->lang->line('Bulan'); ?> :</label>
                        <select class="form-control form-control-select2" name="month" id="month" required data-fouc data-placeholder="<?= $this->lang->line('Bulan'); ?>">
                            <option value="01" <?php if (date('m') == '01') { ?> selected <?php } ?>>Januari</option>
                            <option value="02" <?php if (date('m') == '02') { ?> selected <?php } ?>>Februari</option>
                            <option value="03" <?php if (date('m') == '03') { ?> selected <?php } ?>>Maret</option>
                            <option value="04" <?php if (date('m') == '04') { ?> selected <?php } ?>>April</option>
                            <option value="05" <?php if (date('m') == '05') { ?> selected <?php } ?>>Mei</option>
                            <option value="06" <?php if (date('m') == '06') { ?> selected <?php } ?>>Juni</option>
                            <option value="07" <?php if (date('m') == '07') { ?> selected <?php } ?>>Juli</option>
                            <option value="08" <?php if (date('m') == '08') { ?> selected <?php } ?>>Agustus</option>
                            <option value="09" <?php if (date('m') == '09') { ?> selected <?php } ?>>September</option>
                            <option value="10" <?php if (date('m') == '10') { ?> selected <?php } ?>>Oktober</option>
                            <option value="11" <?php if (date('m') == '11') { ?> selected <?php } ?>>November</option>
                            <option value="12" <?php if (date('m') == '12') { ?> selected <?php } ?>>Desember</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label><?= $this->lang->line('Tahun'); ?> :</label>
                        <select class="form-control form-control-select2" name="year" id="year" required data-fouc data-placeholder="<?= $this->lang->line('Tahun'); ?>">
                            <?php
                            for ($i = 2021; $i <= date('Y'); $i++) { ?>
                                <option value="<?= $i; ?>" <?php if (date('Y') == $i) { ?> selected <?php } ?>><?= $i; ?></option>
                            <?php } ?>
                        </select>
                    </div>
                    <?php /*
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Periode :</label>
                            <input type="text" name="i_periode" id="i_periode" class="form-control" required placeholder="Select Date" value="<?= date('d-m-Y'); ?>">
                        </div>                    
                    </div>
                    */?>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select" data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc name="icustomer" id="icustomer">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" placeholder="Isi keterangan jika ada .."></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        Save</button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
                </div>
            </div>
        </div>

        <div class="card cover">
            <div class="card-body">
                <h6 class="card-title"><i class="icon-cart-add mr-2"></i> Detail Barang</h6>
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= str_replace("-800","",$this->color); ?> text-<?= str_replace("-800","-600",$this->color); ?>">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="30%;">Barang</th>
                                        <th width="20%;">Brand</th>
                                        <th width="15%;">Qty</th>
                                        <th width="3%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                                    </tr>
                                </thead>
                                <tbody>
                                </tbody>
                                <input type="hidden" id="jml" name="jml" value="0">
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->