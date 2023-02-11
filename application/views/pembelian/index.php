<!-- Content area -->
<div class="content">

    <div class="card">
        <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
            <h6 class="card-title font-weight-semibold"><i class="icon-list2 mr-3 icon-1x"></i> <?= $this->lang->line('Daftar'); ?> <?= $this->lang->line($this->title); ?>
            </h6>
            <input type="hidden" id="color" value="<?= $this->color; ?>">
            <div class="header-elements">
                <div class="list-icons">
                    <a class="list-icons-item" data-action="collapse"></a>
                    <a class="list-icons-item" data-action="reload"></a>
                    <a class="list-icons-item" data-action="remove"></a>
                </div>
            </div>
        </div>
        <form method="POST" action="<?= base_url($this->folder); ?>">
            <div class="card-body d-md-flex align-items-md-center justify-content-md-between flex-md-wrap">
                <div class="d-flex offset-md-4 align-items-center mb-3 mb-md-0">
                    <div class="ml-2">
                        <div class="form-group">
                            <label><?= $this->lang->line('Dari Tanggal'); ?> :</label>
                            <div class="input-group">
                                <input type="text" readonly class="form-control form-control-sm date" name="dfrom" id="dfrom" placeholder="<?= $this->lang->line('Dari Tanggal'); ?>" value="<?= $dfrom; ?>">
                                <span class="input-group-append">
                                    <span class="input-group-text"><i class="icon-calendar22"></i></span>
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="ml-2">
                        <div class="form-group">
                            <label><?= $this->lang->line('Sampai Tanggal'); ?> :</label>
                            <div class="input-group">
                                <input type="text" readonly class="form-control form-control-sm date" name="dto" id="dto" placeholder="<?= $this->lang->line('Sampai Tanggal'); ?>" value="<?= $dto; ?>">
                                <span class="input-group-append">
                                    <span class="input-group-text"><i class="icon-calendar22"></i></span>
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="ml-2 mr-2">
                        <button type="submit" class="btn btn-sm bg-<?= $this->color; ?>"><i class="icon-search4"></i></button>
                    </div>
                </div>
            </div>
        </form>
        <div class="table-responsive">
            <div class="col-md-12">
                <?php if (check_role($this->id_menu, 1)) {
                    $id_menu = $this->id_menu;
                } else {
                    $id_menu = "";
                } ?>
                <input type="hidden" id="id_menu" value="<?= $id_menu; ?>">
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <!-- <table class="table table-border-double table-columned table-xs" id="serverside" width="100%;"> -->
                <table class="table table-columned table-xs" id="serverside">
                    <thead>
                        <tr class="bg-<?= $this->color; ?> table-border-double">
                            <th>#</th>
                            <th><?= $this->lang->line('Perusahaan'); ?></th>
                            <th><?= $this->lang->line('No Dokumen'); ?></th>
                            <th><?= $this->lang->line('Tgl Dokumen'); ?></th>
                            <th><?= $this->lang->line('Toko'); ?></th>
                            <th><?= $this->lang->line('Keterangan'); ?></th>
                            <th>Status</th>
                            <th><?= $this->lang->line('Aksi'); ?></th>
                        </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<!-- /task manager table -->