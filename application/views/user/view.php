<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> Info Detail Pengguna </h6>
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
                            <input type="hidden" name="id_user" value="<?= $data->id_user; ?>">
                            <input type="hidden" name="usernameold" value="<?= $data->username; ?>">
                            <input type="text" class="form-control text-lowercase" autofocus placeholder="<?= $this->lang->line('Username'); ?>" name="username" maxlength="255" autocomplete="off" required value="<?= $data->username; ?>" disabled>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Password'); ?> :</label>
                            <input type="hidden" name="passwordold" value="<?= decrypt_password($data->password); ?>">
                            <input type="password" name="password" id="password" class="form-control" required placeholder="Minimum 5 characters allowed" value="<?= decrypt_password($data->password); ?>" disabled>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Nama Lengkap'); ?> :</label>
                            <input type="text" class="form-control text-capitalize" autofocus placeholder="<?= $this->lang->line('Nama Lengkap'); ?>" name="ename" maxlength="255" autocomplete="off" required value="<?= $data->e_nama; ?>" disabled>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Repeat Password'); ?> :</label>
                            <input type="password" name="repeat_password" class="form-control" required placeholder="<?= $this->lang->line('Repeat Password'); ?>" value="<?= decrypt_password($data->password); ?>" disabled>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-4">
                        <div class="form-group">
                            <label><?= $this->lang->line('Level'); ?> :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Level'); ?>" data-fouc name="ilevel" disabled>
                                <option value=""></option>
                                <?php if ($level->num_rows() > 0) {
                                    foreach ($level->result() as $key) { ?>
                                        <option value="<?= $key->i_level; ?>" <?php if ($key->i_level == $data->i_level) { ?> selected <?php } ?>><?= $key->e_level_name; ?></option>
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
                                    id="id_atasan" disabled>
                                <option value=""></option>
                                <?php foreach ($list_team_leader->result() as $key) { ?>
                                        <?php $selected = $key->id_user == $data->id_atasan ? 'selected' : ''; ?>
                                        <option value="<?= $key->id_user; ?>" <?= $selected ?>><?= $key->e_nama; ?></option>
                                <?php } ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label><?= $this->lang->line('Semua Customer'); ?> :</label>
                            <div class="form-check form-check-switch form-check-switch-left">
                                <input type="checkbox" name="fallcustomer" data-on-text="Yes" data-off-text="No" <?php if ($data->f_allcustomer == 't') { ?> checked <?php } ?> class="form-input-switch" disabled>
                            </div>
                        </div>
                    </div>
                    <!--
                    <div class="col-sm-6" hidden>
                        <div class="form-group">
                            <label><?= $this->lang->line('Perusahaan'); ?> :</label>
                            <select hidden class="form-control select-search" multiple data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Perusahaan'); ?>" required data-fouc name="icompany[]">
                                <?php if ($company->num_rows() > 0) {
                                    foreach ($company->result() as $key) { ?>
                                        <option value="<?= $key->i_company; ?>" <?= $key->selek; ?>><?= $key->e_company_name; ?></option>
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
                                <?php if ($brand->num_rows() > 0) {
                                    foreach ($brand->result() as $key) { ?>
                                        <option value="<?= $key->id_brand; ?>" <?= $key->selek; ?>><?= $key->e_brand_name; ?></option>
                                <?php }
                                } ?>
                            </select>
                        </div>
                    </div>
                </div>
                */ ?>
            </div>
        </div>

        <div class="card cover" <?php if ($data->f_allcustomer == 't') { ?> hidden="true" <?php } ?>>
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
                                    <?php $i = 0; foreach ($detail as $result) { 
                                            $i++; 
                                            $customer = $result['customer']; 
                                            $all_brand = $result['brand'];

                                            $selected_brand = [];
                                            foreach ($all_brand as $brand) {
                                                $selected_brand[] = $brand->id_brand;
                                            }
                                            ?>
                                            <tr>
                                                <td class="text-center">
                                                    <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                                </td>
                                                <td>
                                                    <select data-urut="<?= $i; ?>" 
                                                            required class="form-control form-control-sm form-control-select2" 
                                                            data-container-css-class="select-sm"
                                                            name="i_customer[<?= $i ?>][id]" 
                                                            id="i_customer<?= $i; ?>" 
                                                            required data-fouc>
                                                        <option value="<?= $customer->id_customer; ?>"><?= strtoupper($customer->e_customer_name); ?></option>
                                                    </select>
                                                </td>
                                                <td>
                                                    <select data-urut="<?= $i; ?>" 
                                                            class="form-control form-control-sm brand-select2" 
                                                            data-container-css-class="select-sm" 
                                                            name="i_customer[<?= $i ?>][i_brand][]" 
                                                            id="i_brand<?= $i ?>" 
                                                            multiple="true"
                                                            required data-fouc>
                                                            <?php foreach ($list_brand->result() as $_brand) { ?>
                                                                <?php $selected = (in_array($_brand->id, $selected_brand)) ? 'selected' : ''; ?>
                                                                <option value="<?= $_brand->id; ?>" <?= $selected ?>>
                                                                    <?= strtoupper($_brand->e_name); ?>
                                                                </option>
                                                            <?php } ?>                                                        
                                                    </select>
                                                </td>
                                                <td><span id="address<?= $i; ?>"><?= $customer->e_customer_address; ?></span></td>
                                                <td><span id="owner<?= $i; ?>"><?= $customer->e_customer_owner; ?></span></td>
                                                <td><span id="type<?= $i; ?>"><?= $customer->e_type; ?></span></td>
                                                <td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>
                                            </tr>
                                    <?php } ?>
                                </tbody>
                                <input type="hidden" id="jml" name="jml" value="<?= $i; ?>">
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->