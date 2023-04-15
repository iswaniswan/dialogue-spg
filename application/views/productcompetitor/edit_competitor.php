<style>

     .picker__weekday {
        padding: unset !important;
     }

</style>
<!-- Content area -->
<div class="content">
    <!-- Left and right buttons -->
    <form class="form-validation">

        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title">
                    <i class="icon-price-tags2 mr-2"></i>
                    Produk Origin
                </h6>
                <div class="header-elements">
                    <div class="list-icons">
                        <a class="list-icons-item" data-action="collapse"></a>
                        <a class="list-icons-item" data-action="reload"></a>
                        <a class="list-icons-item" data-action="remove"></a>
                    </div>
                </div>
            </div>
            <div class="card-body">                
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <input type="hidden" name="id_product" value="<?= $product->id ?>">
                <input type="hidden" name="id_customer" value="<?= $customer->id ?>">
                <div class="form-group row">
                    <div class="col-6">
                        <label>Kode :</label>
                        <input class="form-control" value="<?= $product->i_product ?>" readonly />
                    </div>
                    <div class="col-6">
                        <label>Brand :</label>
                        <input class="form-control" value="<?= $product->e_brand_name ?>" readonly />
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-6">
                        <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                        <input class="form-control" value="<?= $product->e_product_name ?>" readonly />
                    </div>
                    <div class="col-6">
                        <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                        <input class="form-control" value="<?= $customer->e_name ?>" readonly />
                    </div>                    
                </div>    
                <div class="form-group row">
                    <div class="col-6" style="display: flex;">
                        <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm" style="align-self:end">
                            <i class="icon-paperplane"></i>
                            <?= $this->lang->line('Ubah'); ?>
                        </button>
                        <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1" style="align-self:end">
                            <i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?>
                        </a>
                    </div>
                </div>                                    
                
            </div>
        </div>

        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title">
                    <i class="icon-price-tags2 mr-2"></i>
                    Daftar Produk Kompetitor
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
                    <table class="table table-columned table-bordered table-xs" id="table-competitor">
                        <thead>
                            <tr class="bg-<?= $this->color; ?> table-border-double">
                                <th style="width: 25px">#</th>
                                <th style="width: auto">Brand</th>
                                <th style="width: 250px">Harga</th>
                                <th style="width: 150px">Tanggal Berlaku</th>
                                <th style="width: auto">Keterangan</th>
                                <th width="55px"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php $i = 0; ?>
                            <?php foreach ($all_competitor->result() as $competitor) { $i++; ?>
                                <tr>
                                    <td><spanx><?= $i ?></spanx></td>
                                    <?php /*
                                    <td>
                                        <select data-urut="<?= $i ?>" class="form-control form-control-sm form-control-select2 form-input-customer" 
                                            data-container-css-class="select-sm" 
                                            name="items[<?= $i ?>][id_customer]" 
                                            id="id_customer<?= $i ?>" required data-fouc>
                                            <option value="<?= $competitor->id_customer ?>" selected>
                                                <?= $competitor->e_customer_name ?>
                                            </option>
                                        </select>
                                    </td>
                                    */?>
                                    <td>
                                        <input type="text" required class="form-control form-control-sm form-input-brand" 
                                            placeholder="Nama Brand" id="e_brand_text<?= $i ?>" name="items[<?= $i ?>][e_brand_text]"
                                            value="<?= $competitor->e_brand_text ?>">
                                    </td>
                                    <td>
                                        <div class="input-group">
                                            <div class="input-group-prepend">
                                                <span class="input-group-text">Rp.</span>
                                            </div>
                                            <input type="text" class="form-control form-input-price"
                                                    name="items[<?= $i ?>][vprice]" id="vprice<?= $i ?>" autocomplete="off" 
                                                    value="<?= number_format($competitor->v_price, 0, ",", ".") ?>" required>
                                        </div>
                                    </td>
                                    <td>
                                        <input type="text" class="form-control form-control-sm form-input-date date"
                                            name="items[<?= $i ?>][d_berlaku]" id="d_berlaku<?= $i ?>" 
                                            value="<?= $competitor->d_berlaku ?>" required>
                                    </td>
                                    <td>
                                        <input type="text" class="form-control form-control-sm"
                                            placeholder="Keterangan" id="e_remark<?= $i ?>" name="items[<?= $i ?>][e_remark]"
                                            value="<?= $competitor->e_remark ?>" >
                                    </td>
                                    <td class="text-center" width="3%;">
                                        <b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b>
                                    </td>                                                                                            
                                    <?php /*
                                    <td>
                                        <a href="#" class="x-editable" id="<?= $price->id ?>" 
                                            data-type="number" 
                                            data-pk="<?= $price->id ?>" 
                                            data-url="<?= base_url() ?>product/update_editable" 
                                            data-title="Enter price"><?= $price->v_price ?>
                                        </a>
                                    </td>
                                    <td>
                                        <?php 
                                        
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
                                    */?>
                                </tr>
                            <?php } ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </form>

</div>
<!-- /task manager table -->