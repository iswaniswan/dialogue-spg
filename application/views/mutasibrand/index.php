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
                <div class="d-flex align-items-center mb-3 mb-md-0">
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label><?= $this->lang->line('Dari Tanggal'); ?> :</label>
                            <div class="input-group">
                                <input type="text" readonly class="form-control form-control-sm date" name="dfrom" id="dfrom" placeholder="<?= $this->lang->line('Dari Tanggal'); ?>" value="<?= $dfrom; ?>" onchange=" getcustomer();">
                                <span class="input-group-append">
                                    <span class="input-group-text"><i class="icon-calendar22"></i></span>
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label><?= $this->lang->line('Sampai Tanggal'); ?> :</label>
                            <div class="input-group">
                                <input type="text" readonly class="form-control form-control-sm date" name="dto" id="dto" placeholder="<?= $this->lang->line('Sampai Tanggal'); ?>" value="<?= $dto; ?>" onchange=" getcustomer();">
                                <span class="input-group-append">
                                    <span class="input-group-text"><i class="icon-calendar22"></i></span>
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select-search" 
                                    data-container-css-class="select-sm" 
                                    data-placeholder="Select Customer" 
                                    data-fouc name="idcustomer" 
                                    id="idcustomer">
                                    <option value='null' selected>SEMUA</option> 
                                    <?php foreach ($listcustomer->result() as $customer) { ?>
                                        <?php $selected = ($customer->id_customer == $idcustomer) ? 'selected' : ''; ?>
                                        <option value="<?= $customer->id_customer ?>" <?= $selected ?>><?= $customer->e_customer_name ?></option>
                                    <?php } ?>    
                                <?php /*
                                <option></option>
                                <?php foreach($listcustomer as $row) { ?>
                                    <option value="<?= $row->id_customer;?>" <?php if ($idcustomer == $row->id_customer ) { echo 'selected="selected" ';}?>><?= strtoupper($row->e_customer_name);?></option>
                                <?php } ?>
                                */ ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label>Brand :</label>
                            <select class="form-control select-search" 
                                data-container-css-class="select-sm" 
                                data-placeholder="Select Brand" 
                                data-fouc name="idbrand" 
                                id="idbrand">
                                <option value='null' selected>SEMUA</option> 
                                <?php foreach($listbrand->result() as $brand) { ?>
                                    <?php $selected = ($brand->id == $idbrand) ? 'selected' : ''; ?>
                                    <option value="<?= $brand->id;?>" <?= $selected ?>><?= $brand->e_brand_name;?></option>
                                <?php } 
                                ?>
                            </select>
                        </div>
                    </div>                    
                    <div class="col-sm-3">
                        <button type="submit" class="btn btn-sm bg-<?= $this->color; ?>"><i class="icon-search4"></i></button>
                        <?php $idcustomer = ($idcustomer != null) ? $idcustomer : 'null'; ?>
                        <?php $idbrand = ($idbrand != null) ? $idbrand : 'null'; ?>
                        <?php $link = base_url() . $this->folder . "/export_excel/$idcustomer/$idbrand/$dfrom/$dto"; ?>
                        <a href="<?= $link ?>" id="export">
                            <button type="button" class="btn btn-sm bg-<?= $this->color;?>">
                                <i class="icon-download"></i>
                            </button>
                        </a>
                    </div>
                </div>
            </div>
            <!-- <div class="card-body d-md-flex align-items-md-center justify-content-md-between flex-md-wrap">
                <div class="d-flex offset-md-6 align-items-center mb-3 mb-md-0">
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
                    <div class="ml-2">
                        <div class="form-group">
                            <label><?= $this->lang->line('Perusahaan'); ?> :</label>
                            <div class="input-group">
                                <select class="form-control form-control-select2" data-container-css-class="select-sm" data-container-css-class="text-<?= $this->color; ?>" data-placeholder="<?= $this->lang->line('Perusahaan'); ?>" required data-fouc name="icompany">
                                    <option value="all" <?php if ($icompany == 'all') { ?> selected <?php } ?>>All Company</option>
                                    <?php if ($company->num_rows() > 0) {
                                        foreach ($company->result() as $key) { ?>
                                            <option value="<?= $key->i_company; ?>"  <?php if ($icompany == $key->i_company) { ?> selected <?php } ?>><?= $key->e_company_name; ?></option>
                                    <?php }
                                    } ?>
                                </select>
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
            </div> -->
        </form>
        
            <div class="col-md-12">
                <?php if (check_role($this->id_menu, 1)) {
                    $id_menu = $this->id_menu;
                } else {
                    $id_menu = "";
                } ?>
                <input type="hidden" id="id_menu" value="<?= $id_menu; ?>">
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <!-- <table class="table table-border-double table-columned table-xs" id="serverside" width="100%;"> -->
                <div class="table-responsive">
                    <table class="table table-columned table-xs" style="white-space: nowrap !important;" id="serverside">
                        <thead>
                            <tr class="bg-<?= $this->color; ?> table-border-double">
                                <th>#</th>
                                <th>Toko</th>
                                <th>Kode <br> Barang</th>
                                <th>Nama <br> Barang</th>
                                <th>Nama <br> Brand</th>
                                <th>Saldo <br> Awal</th>
                                <th>Penerimaan <br>Produk</th>
                                <th>Retur <br> Distributor</th>
                                <th>Pengeluaran <br> Produk</th>
                                <th>Adjustment</th>
                                <th>Saldo <br> Akhir</th>
                                <th>Stock <br> Opname</th>
                                <th>Selisih <br></th>
                                <th>Keterangan</th>
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