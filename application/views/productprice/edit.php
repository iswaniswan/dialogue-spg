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
                <input type="hidden" name="id" value="<?= $data->id ?>" />
                <div class="form-group">
                    <label><?= $this->lang->line('Toko'); ?> :</label>
                    <select readonly class="form-control form-control-select2" data-container-css-class="select-sm" required data-fouc id="id_customer" name="id_customer">
                        <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                    </select>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                    <select readonly class="form-control form-control-select2" data-container-css-class="select-sm" required data-fouc id="id_product" name="id_product">
                        <option value="<?= $data->id_product ?>"><?= $data->i_product . ' - ' . $data->e_product_name; ?></option>
                    </select>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Harga Barang'); ?> :</label>
                    <input type="number" class="form-control" placeholder="<?= $this->lang->line('Harga Barang'); ?>" name="vprice" value="<?= $data->v_price; ?>" autocomplete="off" required>
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