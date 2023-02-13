<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> <?= $this->lang->line('Ubah'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                            <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Tipe Toko'); ?>" required data-fouc name="itype" disabled>
                                <option value=""></option>
                                <?php if ($type->num_rows() > 0) {
                                    foreach ($type->result() as $key) { ?>
                                        <option value="<?= $key->i_type; ?>" <?php if ($data->i_type == $key->i_type) { ?> selected <?php } ?>><?= $key->e_type; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Status PKP'); ?> :</label>
                            <select class="form-control form-control-select2" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Status PKP'); ?>" required data-fouc name="fpkp" id="fpkp" disabled>
                                <option value=""></option>
                                <option value="t" <?php if ($data->f_pkp == 't') { ?> selected <?php } ?>>PKP</option>
                                <option value="f" <?php if ($data->f_pkp == 'f') { ?> selected <?php } ?>>Non PKP
                                </option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                            <input type="hidden" name="idcustomer" value="<?= $data->id_customer ?>">
                            <input type="text" class="form-control text-capitalize" autofocus placeholder="<?= $this->lang->line('Nama Toko'); ?>" name="ecustomer" maxlength="255" autocomplete="off" value="<?= $data->e_customer_name ?>" required readonly>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama NPWP'); ?> ( <code><?= $this->lang->line('Disii Jika PKP'); ?></code> ) :</label>
                            <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama NPWP'); ?>" name="ecustomernpwp" id="ecustomernpwp" maxlength="255" autocomplete="off" value="<?= $data->e_npwp_name ?>" readonly>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Alamat Toko'); ?> :</label>
                            <textarea type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Alamat Toko'); ?>" name="eaddress" required maxlength="255" autocomplete="off" readonly><?= $data->e_customer_address ?></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Alamat NPWP'); ?> ( <code><?= $this->lang->line('Disii Jika PKP'); ?></code> ) :</label>
                            <textarea type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Alamat NPWP'); ?>" name="eaddressnpwp" id="eaddressnpwp" maxlength="255" autocomplete="off" readonly><?= $data->e_npwp_address ?></textarea>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Owner'); ?> :</label>
                            <input type="text" class="form-control text-capitalize" readonly placeholder="<?= $this->lang->line('Owner'); ?>" name="eowner" maxlength="120" autocomplete="off" value="<?= $data->e_customer_owner ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Telepon'); ?> :</label>
                            <input type="number" class="form-control" readonly placeholder="<?= $this->lang->line('Telepon'); ?>" name="ephone" maxlength="15" autocomplete="off" value="<?= $data->e_customer_phone ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Latitude :</label>
                            <input type="text" class="form-control" placeholder="Latitude" name="latitude" value="<?= $data->latitude ?>" readonly>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Longitude :</label>
                            <input type="text" class="form-control" placeholder="Longitude" name="longitude" value="<?= $data->longitude ?>" readonly>
                        </div>
                    </div>
                </div>
                <?php /*
                <div class="row">
                    <div class="col-sm-12">
                        <div class="form-group">
                            <label><?= $this->lang->line('Brand'); ?> :</label>
                            <div class="ml-2">
                                <select class="form-control select-search" 
                                        data-container-css-class="select-sm" 
                                        data-container-css-class="text-<?= $this->color; ?>"
                                        required data-fouc 
                                        multiple="true"
                                        name="i_brand[]" 
                                        id="i_brand"
                                        disabled>
                                    <?php foreach ($brand->result() as $key) { ?>
                                            <option value="<?= $key->id ?>" selected><?= $key->e_brand_name ?></option>
                                    <?php } ?>                                
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
                */ ?>

                <div class="d-flex justify-content-start align-items-center">
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>

        <?php /*
        <div class="card">
            <div class="card-body">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="30%;"><?= $this->lang->line('Perusahaan'); ?></th>
                                        <th width="30%;"><?= $this->lang->line('Toko'); ?></th>
                                        <th class="text-right" width="11%;">Disc 1(%)</th>
                                        <th class="text-right" width="11%;">Disc 2(%)</th>
                                        <th class="text-right" width="11%;">Disc 3(%)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i = 0;
                                    if ($detail->num_rows() > 0) {
                                        foreach ($detail->result() as $key) {
                                            $i++; ?>
                                            <tr>
                                                <td class="text-center">
                                                    <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                                </td>
                                                <td>
                                                    <select data-nourut="<?= $i; ?>" class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_company[]" id="i_company<?= $i; ?>" required data-fouc disabled>
                                                        <option value="<?= $key->i_company; ?>"><?= $key->e_company_name; ?></option>
                                                    </select>
                                                </td>
                                                <td>
                                                    <select data-urut="<?= $i; ?>" class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_customer[]" id="i_customer<?= $i; ?>" required data-fouc disabled>
                                                        <option value="<?= $key->i_customer; ?>"><?= $key->e_customer_name; ?></option>
                                                    </select>
                                                </td>
                                                <td><input type="text" class="form-control form-control-sm text-right" name="v_discount1[]" id="v_discount1<?= $i; ?>" required value="<?= $key->n_diskon1; ?>" readonly>
                                                </td>
                                                <td><input type="text" class="form-control form-control-sm text-right" name="v_discount2[]" id="v_discount2<?= $i; ?>" required value="<?= $key->n_diskon2; ?>" readonly>
                                                </td>
                                                <td>
                                                    <input type="text" class="form-control form-control-sm text-right" name="v_discount3[]" id="v_discount3<?= $i; ?>" required value="<?= $key->n_diskon3; ?>" readonly>
                                                    <input type="hidden" name="i_area[]" id="i_area<?= $i; ?>" value="<?= $key->i_area; ?>">
                                                    <input type="hidden" name="e_customer[]" id="e_customer<?= $i; ?>" value="<?= $key->e_customer_name; ?>">
                                                </td>
                                            </tr>
                                    <?php }
                                    } ?>
                                </tbody>
                                <input type="hidden" id="jml" name="jml" value="<?= $i; ?>">
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        */ ?>
    </form>
</div>
<!-- /task manager table -->