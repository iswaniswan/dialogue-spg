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
                            <label><?= $this->lang->line('Tipe Toko'); ?> :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Tipe Toko'); ?>" required data-fouc name="itype">
                                <option value=""></option>
                                <?php if ($type->num_rows() > 0) {
                                    foreach ($type->result() as $key) { ?>
                                        <option value="<?= $key->i_type; ?>"><?= $key->e_type; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Status PKP'); ?> :</label>
                            <select class="form-control form-control-select2" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Status PKP'); ?>" required data-fouc name="fpkp" id="fpkp">
                                <option value=""></option>
                                <option value="t">PKP</option>
                                <option value="f">Non PKP</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                            <input type="text" class="form-control text-capitalize" autofocus placeholder="<?= $this->lang->line('Nama Toko'); ?>" name="ecustomer" maxlength="255" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama NPWP');?> ( <code><?= $this->lang->line('Disii Jika PKP');?></code> ) :</label>
                            <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama NPWP');?>" name="ecustomernpwp" id="ecustomernpwp" maxlength="255" autocomplete="off">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Alamat Toko');?> :</label>
                            <textarea type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Alamat Toko');?>" name="eaddress" required maxlength="255" autocomplete="off"></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Alamat NPWP');?> ( <code><?= $this->lang->line('Disii Jika PKP');?></code> ) :</label>
                            <textarea type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Alamat NPWP');?>" name="eaddressnpwp" id="eaddressnpwp" maxlength="255" autocomplete="off"></textarea>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Owner'); ?> :</label>
                            <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Owner'); ?>" name="eowner" maxlength="120" autocomplete="off">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Telepon'); ?> :</label>
                            <input type="number" class="form-control" placeholder="<?= $this->lang->line('Telepon'); ?>" name="ephone" maxlength="15" autocomplete="off">
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

        <div class="card">
            <div class="card-body">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="30%;"><?= $this->lang->line('Perusahaan');?></th>
                                        <th width="30%;"><?= $this->lang->line('Toko');?></th>
                                        <th class="text-right" width="11%;">Disc 1(%)</th>
                                        <th class="text-right" width="11%;">Disc 2(%)</th>
                                        <th class="text-right" width="11%;">Disc 3(%)</th>
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
        </div>
    </form>
</div>
<!-- /task manager table -->