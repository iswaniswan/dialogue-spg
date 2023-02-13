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
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Perusahaan'); ?> :</label>
                    <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Nama Perusahaan'); ?>" required data-fouc name="icompany">
                        <option value=""></option>
                        <?php if ($company->num_rows() > 0) {
                            foreach ($company->result() as $key) { ?>
                                <option value="<?= $key->i_company; ?>" <?php if ($key->i_company == $data->i_company) { ?> selected <?php } ?>><?= $key->e_company_name; ?></option>
                        <?php }
                        } ?>
                    </select>
                    <input type="hidden" name="icompanyold" value="<?= $data->i_company; ?>">
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Brand'); ?> :</label>
                    <select class="form-control select-search" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Brand'); ?>" required data-fouc name="ebrand" id="i_brand">
                        <option value="<?= $data->id_brand; ?>"><?= $data->e_brand_name;?></option>
                    </select>
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Kode Barang'); ?> :</label>
                    <input type="hidden" name="iproductold" value="<?= $data->i_product; ?>">
                    <input type="text" class="form-control text-uppercase" placeholder="<?= $this->lang->line('Kode Barang'); ?>" name="iproduct" maxlength="15" autocomplete="off" required autofocus value="<?= $data->i_product; ?>">
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama Barang'); ?>" name="eproduct" maxlength="150" autocomplete="off" required value="<?= $data->e_product_name; ?>">
                </div>
                <div class="form-group">
                    <label><?= $this->lang->line('Nama Grup'); ?> :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama Grup'); ?>" name="egroup" maxlength="50" autocomplete="off" required value="<?= $data->e_product_group_name; ?>">
                </div>
                <!-- <div class="form-group">
                    <label><?= $this->lang->line('Nama Brand'); ?> :</label>
                    <input type="text" class="form-control text-capitalize" placeholder="<?= $this->lang->line('Nama Brand'); ?>" name="ebrand" maxlength="50" autocomplete="off" required value="<?= $data->e_brand; ?>">
                </div> -->
                <div class="form-group" hidden>
                    <label><?= $this->lang->line('Harga Beli'); ?> :</label>
                    <input type="number" class="form-control" placeholder="<?= $this->lang->line('Harga Beli'); ?>" name="vpricebeli" autocomplete="off" required value="<?= $data->v_price_beli; ?>">
                </div>
                <div class="form-group" hidden="">
                    <label><?= $this->lang->line('Harga Jual'); ?> :</label>
                    <input type="number" class="form-control" placeholder="Entry Price" name="vpricejual" autocomplete="off" required value="<?= $data->v_price_jual; ?>">
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Ubah'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </form>
        </div>
    </div>

    <div class="card">
        <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
            <h6 class="card-title">
                <i class="icon-price-tags2 mr-2"></i>
                Harga Per Toko (Under development)
            </h6>
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
            <div class="table-responsive">
                <table class="table table-columned table-xs" id="serverside">
                    <thead>
                        <tr class="bg-<?= $this->color; ?> table-border-double">
                            <th style="width: 25px">#</th>
                            <th style="width: auto">Toko</th>
                            <th style="width: 250px">Harga</th>
                            <th style="width: 150px">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php $count = 1; ?>
                        <?php foreach ($all_customer_price as $price) { ?>
                            <tr>
                                <td><?= $count++ ?></td>
                                <td><?= $price->e_customer_name ?></td>
                                <td>
                                    <a href="#" class="x-editable" id="<?= $price->id ?>" 
                                        data-type="number" 
                                        data-pk="<?= $price->id ?>" 
                                        data-url="<?= base_url() ?>product/update_editable" 
                                        data-title="Enter price"><?= $price->v_price ?>
                                    </a>
                                </td>
                                <td>
                                    <?php /** button status */
                                    
                                    $status = 'Not Active';
                                    $color  = 'danger';
                                    
                                    if ($price->f_status == 't') {
                                        $status = 'Active';
                                        $color  = 'success';
                                    }
                                    
                                    $class ="btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple";
                                    $onclick = "onclick='product/update_editable'";
                                    $button = "<button class='$class'>".$status."</button>";
                                    
                                    echo $button;
                                    ?>
                                </td>
                            </tr>
                        <?php } ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</div>
<!-- /task manager table -->