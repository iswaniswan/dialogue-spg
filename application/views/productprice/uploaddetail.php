<!-- <style>
    .table-responsive{
  height:400px;  
  overflow:scroll;
}
 thead tr:nth-child(1) th{
    background: white;
    position: sticky;
    top: 0;
    z-index: 10;
  }
</style> -->
<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-transmission mr-2"></i> <?= 'Tranfer'; ?> <?= $this->lang->line($this->title); ?></h6>
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <input type="hidden" id="color" value="<?= $this->color; ?>">
                <div class="header-elements">
                    <div class="list-icons">
                        <a class="list-icons-item" data-action="collapse"></a>
                        <a class="list-icons-item" data-action="reload"></a>
                        <a class="list-icons-item" data-action="remove"></a>
                    </div>
                </div>
            </div>

            <div class="card-body">
                <div class="form-group row">
                    <div class="col-md-12">
                        <label><?= $this->lang->line('Toko'); ?> :</label>
                        <select class="form-control select" name="icustomer" id="icustomer" required data-fouc data-placeholder="<?= $this->lang->line('Toko'); ?>">
                            <option value="<?= $icustomer; ?>"><?= $ecustomer; ?></option>
                        </select>
                    </div>
                </div>
                <div class="form-group row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned datatable-header-basic table-bordered table-xs demo2" id="tabledetail">
                                <thead>
                                    <tr class="bg-<?= $this->color; ?>-600">
                                        <th class="text-center">No</th>
                                        <th><?= $this->lang->line('Toko'); ?></th>
                                        <th><?= $this->lang->line('Kode Barang'); ?></th>
                                        <th><?= $this->lang->line('Nama Barang'); ?></th>
                                        <th><?= $this->lang->line('Harga Barang'); ?></th>
                                        <th class="text-center"><?= $this->lang->line('Aksi'); ?></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i = 0;
                                    foreach ($datadetail as $key) {
                                        $i++;
                                        $warna = ($key['i_product'] == '') ? 'class="table-danger"' : '';
                                    ?>
                                        <tr <?= $warna; ?>>
                                            <td class="text-center">
                                                <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                            </td>
                                            <td><?= $key["e_customer"]; ?></td>
                                            <td><input type="text" readonly class="form-control form-control-sm product" required name="iproduct<?= $i; ?>" id="iproduct<?= $i; ?>" value="<?= $key["i_product"]; ?>">
                                            <input type="hidden" name="icompany<?= $i; ?>" value="<?= $key["i_company"]; ?>"></td>
                                            <td><?= $key["e_product"]; ?></td>
                                            <td><input type="number" class="form-control form-control-sm" required name="vprice<?= $i; ?>" value="<?= $key["v_harga"]; ?>" autocomplete="off" onblur="if(this.value==''){this.value='0';}" onfocus="if(this.value=='0'){this.value='';}"></td>
                                            <td class="text-center"><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></td>
                                        </tr>
                                    <?php } ?>
                                    <input type="hidden" name="jml" id="jml" value="<?= $i; ?>">
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center mt-3">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- Latest compiled and minified JavaScript -->