<!-- Content area -->
<div class="content">

    <div class="card">
        <div class="card-header border-<?= $this->color;?> bg-transparent header-elements-inline">
            <h6 class="card-title font-weight-semibold"><i class="icon-list2 mr-3 icon-1x"></i> List <?= $this->title;?>
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

        <div class="table-responsive">
            <div class="col-md-12">
                <?php if (check_role($this->id_menu, 1)) { 
                    $id_menu = $this->id_menu;
                }else{
                    $id_menu = "";
                } ?>
                <input type="hidden" id="id_menu" value="<?= $id_menu; ?>">
                <input type="hidden" id="path" value="<?= $this->folder;?>">
                <!-- <table class="table table-border-double table-columned table-xs" id="serverside" width="100%;"> -->
                <table class="table table-columned table-xs" id="serverside">
                    <thead>
                        <tr class="bg-<?= $this->color;?> table-border-double">
                            <th>#</th>
                            <th>Id Menu</th>
                            <th>Nama Menu</th>
                            <th>Id Sub Menu</th>
                            <th>Folder</th>
                            <th>Icon</th>
                            <th>Action</th>
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