<!-- Content area -->
<div class="content">

    <div class="card">
        <div class="card-header border-<?= $this->color;?> bg-transparent header-elements-inline">
        <h6 class="card-title font-weight-semibold"><i class="icon-list2 mr-3 icon-1x"></i> <?= $this->lang->line('Daftar'); ?> <?= $this->lang->line($this->title); ?>
            </h6>
            <input type="hidden" id="color" value="<?= $this->color;?>">
            <div class="header-elements">
                <div class="list-icons">
                    <a class="list-icons-item" data-action="collapse"></a>
                    <a class="list-icons-item" data-action="reload"></a>
                    <a class="list-icons-item" data-action="remove"></a>
                </div>
            </div>
        </div>
        
        <div class="card-body d-md-flex align-items-md-center justify-content-md-between flex-md-wrap">
            <div class="d-flex align-items-center mb-3 mb-md-0">
                <div class="col-md-6">
                    <div class="form-group">
                        <label>Toko :</label>
                        <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Nama Toko" data-fouc name="id_customer" id="id_customer">
                            <option value='null' selected>SEMUA</option> 
                        </select>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label>Brand :</label>
                        <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Nama Brand" data-fouc name="id_brand" id="id_brand">
                            <option value='null' selected>SEMUA</option> 
                        </select>
                    </div>
                </div>
                <div class="ml-2 mr-2">
                    <input type="hidden" id="url" value="<?php echo base_url().$this->folder.'/export_excel'; ?>">
                    <button class="btn btn-sm bg-<?= $this->color;?>" id="btn-export"><i class="icon-download"></i></button>
                </div>
            </div>
        </div>
        
        
<!--
        <div class="table-responsive">
            <div class="col-md-12">
                <?php if (check_role($this->id_menu, 1)) { 
                    $id_menu = $this->id_menu;
                }else{
                    $id_menu = "";
                } ?>
                <input type="hidden" id="id_menu" value="<?= $id_menu; ?>">
                <input type="hidden" id="path" value="<?= $this->folder;?>">
                <table class="table table-border-double table-columned table-xs" id="serverside" width="100%;">
                <table class="table table-columned table-xs" id="serverside">
                    <thead>
                        <tr class="bg-<?= $this->color;?> table-border-double">
                            <th>#</th>
                            <th><?= $this->lang->line('Toko'); ?></th>
                            <th><?= $this->lang->line('Perusahaan'); ?></th>
                            <th><?= $this->lang->line('Kode Barang'); ?></th>
                            <th>Tanggal Masuk</th>
                            <th>Tanggal Sekarang</th>
                            <th>Selisih</th>
                            <th>Kategori</th>
                            <th><?= $this->lang->line('Aksi');?></th>
                        </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </div>
        </div>
            -->
    </div>
</div>
<!-- /task manager table -->