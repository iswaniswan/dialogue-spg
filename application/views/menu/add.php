<!-- Content area -->
<div class="content">

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
            <form class="form-validation">
                <div class="form-group">
                    <label>Parent :</label>
                    <select class="form-control form-control-select2" data-container-css-class="text-<?= $this->color; ?>" required data-fouc id="iparent" name="iparent">
                    </select>
                </div>
                <div class="form-group">
                    <label>Id Menu :</label>
                    <input type="number" class="form-control text-capitalize" placeholder="Entry ID Menu" id="idmenu" name="idmenu" maxlength="10" autocomplete="off" required autofocus>
                </div>
                <div class="form-group">
                    <label>Nama Menu :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="Entry Menu Name" name="emenu" maxlength="30" autocomplete="off" required>
                </div>
                <div class="form-group">
                    <label>No Urut :</label>
                    <input type="number" class="form-control text-capitalize" placeholder="Entry No Urut" name="nurut" maxlength="10" autocomplete="off" required>
                </div>
                <div class="form-group">
                    <label>Nama Folder :</label>
                    <input type="text" class="form-control text-lowercase" placeholder="Entry Folder Name" name="efolder" maxlength="30" autocomplete="off">
                </div>
                <div class="form-group">
                    <label>Icon :</label>
                    <input type="text" class="form-control text-lowercase" placeholder="Entry Icon" name="icon" maxlength="30" autocomplete="off">
                </div>
                <div class="form-group">
                    <label>Power Menu (<code>Untuk Role Administrator</code>) :</label>
                    <select class="form-control form-control-select2" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="Select Power Menu" required data-fouc multiple name="ipower[]">
                        <option value=""></option>
                        <?php if ($power->num_rows() > 0) {
                            foreach ($power->result() as $key) { ?>
                                <option value="<?= $key->i_power;?>"><?= $key->e_power_name;?></option>
                        <?php }
                        } ?>
                    </select>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        Save</button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
                </div>
            </form>
        </div>
    </div>
</div>
<!-- /task manager table -->