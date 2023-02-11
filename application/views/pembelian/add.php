<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-stack-plus mr-2"></i> <?= $this->lang->line('Tambah'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Perusahaan'); ?> :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="<?= $this->lang->line('Perusahaan'); ?>" required data-fouc name="icompany" id="icompany">
                                <option value=""></option>
                                <?php if ($company->num_rows() > 0) {
                                    foreach ($company->result() as $key) { ?>
                                        <option value="<?= $key->i_company; ?>"><?= $key->e_company_name; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label><?= $this->lang->line('Dari Tanggal'); ?> :</label>
                            <input type="text" name="dfrom" value="<?= date('Y-m-d', strtotime('-1 days', strtotime(date('Y-m-d')))); ?>" class="form-control date" required placeholder="<?= $this->lang->line('Dari Tanggal'); ?>">
                        </div>
                    </div>
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label><?= $this->lang->line('Sampai Tanggal'); ?> :</label>
                            <input type="text" name="dto" value="<?= date('Y-m-d'); ?>" class="form-control date" required placeholder="<?= $this->lang->line('Sampai Tanggal'); ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-12">
                        <div class="form-group">
                            <label><?= $this->lang->line('Keterangan'); ?> :</label>
                            <textarea class="form-control" name="eremark" placeholder="<?= $this->lang->line('Keterangan'); ?> .."></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>

        <!-- <div class="card cover">
            <div class="card-body">
                <h6 class="card-title"><i class="icon-cart-add mr-2"></i> Detail Barang</h6>
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="25%;">Nama Toko</th>
                                        <th width="35%;">Alamat Toko</th>
                                        <th width="18%;">Owner)</th>
                                        <th width="15%;">Tipe Toko</th>
                                        <th width="4%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
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
        </div> -->
    </form>
</div>
<!-- /task manager table -->