<!-- Content area -->
<div class="content">

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
            <form class="form-validation">
                <?php /*
                <div class="form-group">
                    <label><?= $this->lang->line('Perusahaan'); ?> :</label>
                    <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Perusahaan'); ?>" required data-fouc name="icompany">
                        <option value=""></option>
                        <?php if ($company->num_rows() > 0) {
                            foreach ($company->result() as $key) { ?>
                                <option value="<?= $key->i_company; ?>"><?= $key->e_company_name; ?></option>
                        <?php }
                        } ?>
                    </select>
                </div>
                */ ?>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Brand'); ?> :</label>
                    <select class="form-control select-search" 
                            data-container-css-class="select-sm" 
                            data-container-css-class="text-<?= $this->color; ?>" 
                            data-placeholder="<?= $this->lang->line('Brand'); ?>" 
                            data-fouc name="ebrand" id="i_brand" required>
                        <option value=""></option>
                    </select>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Kode Barang'); ?> :</label>
                    <input type="text" class="form-control text-uppercase" placeholder="<?= $this->lang->line('Kode Barang'); ?>" name="iproduct" maxlength="15" autocomplete="off" required autofocus>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama Barang'); ?>" name="eproduct" maxlength="150" autocomplete="off" required>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Grup'); ?> :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama Grup'); ?>" name="egroup" maxlength="50" autocomplete="off" required>
                </div>                
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </form>
        </div>
    </div>
</div>
<!-- /task manager table -->