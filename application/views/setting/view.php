<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation">
        <div class="card">
            <div class="card-header border-<?= $this->color;?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> Update <?= $this->title.' '.$elevel->e_level_name;?></h6>
                <input type="hidden" id="path" value="<?= $this->folder;?>">
                <input type="hidden" id="color" value="<?= $this->color;?>">
                <input type="hidden" name="ilevel" value="<?= $level;?>" readonly>
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
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs">
                                <thead>
                                    <tr class="bg-<?= $this->color;?>-600">
                                        <th class="text-center">No</th>
                                        <th>Kode Menu</th>
                                        <th>Nama Menu</th>
                                        <th>Akses Menu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php 
                                    $i = 0;
                                    if ($cekdata) {
                                        foreach ($cekdata as $row) {
                                            $i++;?>
                                    <tr>
                                        <td class="text-center">
                                            <spanx id="snum<?=$i;?>"><?= $i;?></spanx>
                                        </td>
                                        <td>
                                            <?= $row->id_menu;?>
                                            <input type="hidden" id="idmenu<?=$i;?>" name="idmenu<?=$i;?>"
                                                value="<?= $row->id_menu;?>" readonly>
                                        </td>
                                        <td>
                                            <?= $row->e_menu;?>
                                        </td>
                                        <td>
                                            <div class="row">
                                                <?php foreach ($userpower as $key) {
                                                    if ($row->idadmin != null) {
                                                        if (strpos($row->idadmin,$key->id) !== false) {
                                                            $hidden   = '';
                                                        }else{
                                                            $hidden   = 'hidden';
                                                        }
                                                    }else{
                                                        $hidden = '';   
                                                    }
                                                    if ($key->id != null) {
                                                        if (strpos($row->id,$key->id) !== false) {
                                                            $checked = 'checked';
                                                        }else{
                                                            $checked = '';
                                                        }
                                                    }else{
                                                        $checked = '';   
                                                    }?>
                                                <div class="col-md-2">
                                                    <div class="form-check border-top-<?= $this->color;?> form-check-inline"><label
                                                            class="form-check-label" <?= $hidden;?>>
                                                            <input readonly="" type="checkbox"
                                                                name="<?= strtolower($key->e_name);?><?=$i;?>"
                                                                class="form-check-input-styled-<?= $this->color;?>" <?= $checked;?>
                                                                data-fouc disabled>
                                                            <span class="custom-control-indicator"></span>
                                                            <span
                                                                class="custom-control-description"><?= $key->e_name;?></span>
                                                    </div>
                                                </div>
                                                <?php } ?>
                                            </div>
                                        </td>
                                    </tr>
                                    <?php } 
                                    }?>
                                    <input type="hidden" name="jml" id="jml" value="<?= $i;?>">
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center mt-3">
                    <a href="<?= base_url($this->folder);?>" class="btn btn bg-danger btn-sm"><i
                            class="icon-arrow-left16"></i>&nbsp; Back</a>
                </div>
            </div>
        </div>
    </form>
</div>