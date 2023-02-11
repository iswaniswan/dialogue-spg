<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <div class="card">
        <div class="card-header border-<?= $this->color;?> bg-transparent header-elements-inline">
            <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> Edit <?= $this->title;?></h6>
            <input type="hidden" id="path" value="<?= $this->folder;?>">
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
                    <label>Level Name :</label>
                    <input type="hidden" class="form-control" id="ilevel" name="ilevel" value="<?= $data->i_level;?>">
                    <input type="hidden" class="form-control" id="elevelold" name="elevelold"
                        value="<?= $data->e_level_name;?>">
                    <input type="text" class="form-control text-capitalize" placeholder="Entry Level" id="elevel"
                        name="elevel" maxlength="30" autocomplete="off" required value="<?= $data->e_level_name;?>"
                        autofocus>
                </div>
                <div class="form-group">
                    <label>Deskripsi :</label>
                    <textarea class="form-control" placeholder="Deskripsi Level .."
                        name="deskripsi"><?= $data->e_deskripsi;?></textarea>
                </div>

                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color;?> btn-sm"><i
                            class="icon-paperplane"></i>&nbsp;
                        Edit</button>
                    <a href="<?= base_url($this->folder);?>" class="btn btn bg-danger btn-sm ml-1"><i
                            class="icon-arrow-left16"></i>&nbsp; Back</a>
                </div>
            </form>
        </div>
    </div>

</div>
<!-- /task manager table -->