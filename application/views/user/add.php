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
                            <label><?= $this->lang->line('Username'); ?> :</label>
                            <input type="text" class="form-control text-lowercase" autofocus placeholder="<?= $this->lang->line('Username'); ?>" name="username" maxlength="255" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Password'); ?> :</label>
                            <input type="password" name="password" id="password" class="form-control" required placeholder="Minimum 5 characters allowed">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama Lengkap'); ?> :</label>
                            <input type="text" class="form-control text-capitalize" autofocus placeholder="<?= $this->lang->line('Nama Lengkap'); ?>" name="ename" maxlength="255" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Repeat Password'); ?> :</label>
                            <input type="password" name="repeat_password" class="form-control" required placeholder="<?= $this->lang->line('Repeat Password'); ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-4">
                        <div class="form-group">
                            <label><?= $this->lang->line('Level'); ?> :</label>
                            <select class="form-control select-search" 
                                data-container-css-class="select-sm" 
                                data-container-css-class="text-<?= $this->color; ?>"
                                data-placeholder="<?= $this->lang->line('Level'); ?>" 
                                required data-fouc name="ilevel" id="ilevel">
                                <option value=""></option>
                                <?php if ($level->num_rows() > 0) {
                                    foreach ($level->result() as $key) { ?>
                                        <option value="<?= $key->i_level; ?>"><?= $key->e_level_name; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-4">
                        <div class="form-group">
                            <label>Atasan :</label>
                            <select class="form-control select-search" 
                                    data-container-css-class="select-sm" 
                                    data-container-css-class="text-<?= $this->color; ?>" 
                                    data-placeholder="- Pilih Atasan -" 
                                    data-fouc 
                                    name="id_atasan" 
                                    id="id_atasan">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-2 ml-auto">
                        <div class="form-group">
                            <label><?= $this->lang->line('Semua Customer'); ?> :</label>
                            <div class="form-check form-check-switch form-check-switch-left">
                                <input type="checkbox" name="fallcustomer" data-on-text="Yes" data-off-text="No" checked class="form-input-switch">
                            </div>
                        </div>
                    </div>
                    <!--
                    <div class="col-sm-6" hidden>
                        <div class="form-group">
                            <label><?= $this->lang->line('Perusahaan'); ?> :</label>
                            <select class="form-control select-search" multiple data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Perusahaan'); ?>" name="icompany[]">
                                <option value="" selected></option>
                                <?php if ($company->num_rows() > 0) {
                                    foreach ($company->result() as $key) { ?>
                                        <option value="<?= $key->i_company; ?>"><?= $key->e_company_name; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                    -->
                </div>

                <?php /*
                <div class="row">
                    <div class="col-sm-12">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama Brand'); ?> :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Brand'); ?>" required data-fouc multiple name="i_brand[]" id="i_brand">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>
                </div>
                */ ?>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>

        <div class="card cover" hidden="true">
            <div class="card-body">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="25%;"><?= $this->lang->line('Nama Toko'); ?></th>
                                        <th width="30%;">Brand cover</th>
                                        <th width="35%;"><?= $this->lang->line('Alamat Toko'); ?></th>
                                        <th width="auto"><?= $this->lang->line('Owner'); ?></th>
                                        <th width="auto"><?= $this->lang->line('Tipe Toko'); ?></th>
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