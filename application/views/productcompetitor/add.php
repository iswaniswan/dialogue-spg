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
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                    <select class="form-control select-search" 
                            data-container-css-class="select-sm" 
                            data-container-css-class="text-<?= $this->color; ?>" 
                            data-placeholder="<?= $this->lang->line('Product'); ?>" 
                            data-fouc name="id_product" id="id_product" required>
                        <option value=""></option>
                    </select>                    
                </div>

                <div class="form-group">
                    <label><?= $this->lang->line('Nama Brand'); ?> :</label>
                    <select class="form-control select-search" 
                            data-container-css-class="select-sm" 
                            data-container-css-class="text-<?= $this->color; ?>" 
                            data-placeholder="<?= $this->lang->line('Brand'); ?>" 
                            data-fouc name="id_brand" id="id_brand" required>
                        <option value=""></option>
                    </select>
                </div>

                <div class="form-group">
                    <label><?= $this->lang->line('Harga Barang'); ?> :</label>
                    <div class="input-group mb-3">
                        <div class="input-group-prepend">
                            <span class="input-group-text">Rp.</span>
                        </div>
                        <input type="text" class="form-control" placeholder="<?= $this->lang->line('Harga Barang'); ?>" name="vprice" id="vprice" autocomplete="off" required>
                    </div>
                </div>

                <div class="form-group">
                    <label>Keterangan :</label>
                    <textarea class="form-control" name="e_remark"></textarea>
                </div>
                
                <div class="d-flex justify-content-start align-items-center mt-5">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </form>
        </div>
    </div>
</div>
<!-- /task manager table -->