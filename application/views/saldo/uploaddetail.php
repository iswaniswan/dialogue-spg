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
                    <?php $tahun = substr($periode,0,4); $bulan = substr($periode,4,2);?>
                    <div class="col-md-2">
                        <label><?= $this->lang->line('Bulan'); ?> :</label>
                        <select disabled class="form-control select" name="month" id="month" required data-fouc data-placeholder="<?= $this->lang->line('Bulan'); ?>">
                            <option value="01" <?php if ($bulan == '01') { ?> selected <?php } ?>>Januari</option>
                            <option value="02" <?php if ($bulan == '02') { ?> selected <?php } ?>>Februari</option>
                            <option value="03" <?php if ($bulan == '03') { ?> selected <?php } ?>>Maret</option>
                            <option value="04" <?php if ($bulan == '04') { ?> selected <?php } ?>>April</option>
                            <option value="05" <?php if ($bulan == '05') { ?> selected <?php } ?>>Mei</option>
                            <option value="06" <?php if ($bulan == '06') { ?> selected <?php } ?>>Juni</option>
                            <option value="07" <?php if ($bulan == '07') { ?> selected <?php } ?>>Juli</option>
                            <option value="08" <?php if ($bulan == '08') { ?> selected <?php } ?>>Agustus</option>
                            <option value="09" <?php if ($bulan == '09') { ?> selected <?php } ?>>September</option>
                            <option value="10" <?php if ($bulan == '10') { ?> selected <?php } ?>>Oktober</option>
                            <option value="11" <?php if ($bulan == '11') { ?> selected <?php } ?>>November</option>
                            <option value="12" <?php if ($bulan == '12') { ?> selected <?php } ?>>Desember</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label><?= $this->lang->line('Tahun'); ?> :</label>
                        <select disabled class="form-control select" name="year" id="year" required data-fouc data-placeholder="<?= $this->lang->line('Tahun'); ?>">
                            <?php
                            for ($i = 2021; $i <= date('Y'); $i++) { ?>
                                <option value="<?= $i; ?>" <?php if ($tahun == $i) { ?> selected <?php } ?>><?= $i; ?></option>
                            <?php } ?>
                        </select>
                    </div>
                    <div class="col-md-7">
                        <label><?= $this->lang->line('Toko'); ?> :</label>
                        <!-- <select class="form-control select" name="icustomer" id="icustomer" required data-fouc data-placeholder="<?= $this->lang->line('Toko'); ?>">
                            <option value=""></option>
                        </select> -->
                        <input type="text" readonly class="form-control" name="e_customer_name" value="<?= $e_customer_name; ?>">
                        <input type="hidden" name="id_customer" value="<?= $id_customer; ?>">
                        <input type="hidden" name="i_periode" value="<?= $periode; ?>">
                    </div>
                </div>
                <div class="form-group row">
                    <div class="col-md-12">
                        <label><?= $this->lang->line('Keterangan'); ?> :</label>
                        <textarea name="e_remark" class="form-control" placeholder="Isi keterangan jika ada .."></textarea>
                    </div>
                </div>
                <div class="form-group row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned datatable-header-basic table-bordered table-xs demo2" id="tabledetail">
                                <thead>
                                    <tr class="bg-<?= $this->color; ?>">
                                        <th class="text-center">No</th>
                                        <th class="d-none"><?= $this->lang->line('ID mutasi saldo awal'); ?></th>
                                        <th><?= $this->lang->line('Kode Barang'); ?></th>
                                        <th><?= $this->lang->line('Nama Barang'); ?></th>
                                        <th><?= $this->lang->line('Brand'); ?></th>
                                        <th width="10%"><?= $this->lang->line('Qty'); ?></th>
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
                                            <td>
                                                <input type="hidden" name="id_product<?= $i ?>" value="<?= $key['id_product'] ?>">
                                                <input type="text" readonly class="form-control form-control-sm product" required name="iproduct<?= $i; ?>" id="iproduct<?= $i; ?>" value="<?= $key["i_product"]; ?>">
                                            </td>
                                            <td><?= $key["e_product"]; ?></td>
                                            <td><?= $key["brand"]; ?></td>
                                            <td><input type="number" class="form-control form-control-sm" required name="qty<?= $i; ?>" value="<?= $key["qty"]; ?>" autocomplete="off" onblur="if(this.value==''){this.value='0';}" onfocus="if(this.value=='0'){this.value='';}"></td>
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