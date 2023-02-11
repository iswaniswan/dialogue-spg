<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation" method="POST" enctype="multipart/form-data">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-upload7 mr-2"></i> <?= $this->lang->line('Unggah'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                <div class="form-group row">
                    <div class="col-md-2">
                        <label><?= $this->lang->line('Bulan'); ?> :</label>
                        <select class="form-control select" name="month" id="month" required data-fouc data-placeholder="<?= $this->lang->line('Bulan'); ?>">
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
                        <select class="form-control select" name="year" id="year" required data-fouc data-placeholder="<?= $this->lang->line('Tahun'); ?>">
                            <?php
                            for ($i = 2021; $i <= date('Y'); $i++) { ?>
                                <option value="<?= $i; ?>" <?php if (date('Y') == $i) { ?> selected <?php } ?>><?= $i; ?></option>
                            <?php } ?>
                        </select>
                    </div>
                    <div class="col-md-7">
                        <label><?= $this->lang->line('Pelanggan'); ?> :</label>
                        <select class="form-control select" name="id_customer" id="id_customer" required data-fouc data-placeholder="<?= $this->lang->line('Pelanggan'); ?>">
                            <option value=""></option>
                        </select>
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-lg-12">
                        <input type="file" data-show-upload="false" class="file-input-ajax" required id="fileuser" name="userfile">
                        <span class="form-text text-muted">Only the following extension files can be uploaded :<code>xls</code></span>
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-sm-4">
                        <button type="submit" id="cubmit" class="btn btn-block bg-<?= $this->color; ?> btn-sm"><i class="icon-upload"></i>&nbsp;<?= $this->lang->line('Unggah'); ?></button>
                    </div>
                    <div class="col-sm-4">
                        <a id="href" href="<?= base_url($this->folder); ?>" class="btn btn-block bg-teal btn-sm"><i class="icon-download"></i>&nbsp; Format <?= $this->lang->line('Unggah'); ?></a>
                    </div>
                    <div class="col-sm-4">
                        <a href="<?= base_url($this->folder); ?>" class="btn btn-block bg-danger btn-sm"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                    </div>
                </div>
            </div>
        </div>
        <!-- /bootstrap file input -->
    </form>
</div>
<!-- /task manager table -->