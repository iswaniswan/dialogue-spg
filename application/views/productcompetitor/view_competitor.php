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
                <div class="form-group row">
                    <div class="col-12">
                        <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                        <input class="form-control" value="<?= $customer->e_name ?>" readonly />
                    </div> 
                </div>
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
                        <label><?= $this->lang->line('Harga'); ?> :</label>
                        <input class="form-control" value="<?= 'Rp. ' . number_format($product->v_price, 0, ",", ".") ?>" readonly />
                    </div>                                        
                </div>       
                                 
                <div class="form-group row">
                    <div class="col-6" style="display: flex;">                        
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
                    <table class="table table-columned table-xs" id="table-competitor">
                        <thead>
                            <tr class="bg-<?= $this->color; ?> table-border-double">
                                <th style="width: 25px">#</th>
                                <th style="width: auto">Brand</th>
                                <th style="width: 250px">Harga</th>
                                <th style="width: 150px">Tanggal Berlaku</th>
                                <th style="width: auto">Keterangan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php $count = 1; ?>
                            <?php foreach ($all_competitor->result() as $competitor) { ?>
                                <tr>
                                    <td><?= $count++ ?></td>
                                    <td><?= $competitor->e_brand_text ?></td>
                                    <td><?= 'Rp. ' . number_format($competitor->v_price, 0, ",", ".") ?></td>
                                    <td><?= date('Y-m-d', strtotime($competitor->d_berlaku)) ?></td>
                                    <td><?= $competitor->e_remark ?></td>
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