<!-- Content area -->
<div class="content">

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
            <form class="form-validation">
                <input type="hidden" class="form-control" id="id" name="id" value="<?= $data->id; ?>">
                <div class="form-group">
                    <label>Pilih Kategori :</label>
                    <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Kategori" required data-fouc name="id_category" id="id_category">
                        <option value="<?= $data->id_category ?>" selected><?= $data->e_category_name ?></option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Nama Sub Kategori :</label>
                    <input type="text" class="form-control text-capitalize" id="e_sub_category_name" name="e_sub_category_name"
                        value="<?= $data->e_sub_category_name ?>"
                        maxlength="30" autocomplete="off" required autofocus>
                </div>

                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Ubah'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </form>
        </div>
    </div>

</div>
<!-- /task manager table -->