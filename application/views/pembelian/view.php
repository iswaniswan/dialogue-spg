<style>
    .tabel td {
        padding: 7px 7px !important;
    }
</style>
<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-eye mr-2"></i> <?= $this->lang->line('View'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('No Dokumen');?> :</label>
                            <input type="text" class="form-control" readonly value="<?= $data->i_document; ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Tgl Dokumen');?> :</label>
                            <input type="text" class="form-control date" value="<?= $data->d_receive; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Toko');?> :</label>
                            <input type="text" class="form-control date" value="<?= $data->e_customer_name; ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Keterangan');?> :</label>
                            <textarea class="form-control".."><?= $data->e_remark; ?></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali');?></a>
                </div>
            </div>
        </div>

        <div class="card cover">
            <div class="card-body">
                <h6 class="card-title"><i class="icon-cart2 mr-2"></i> <?= $this->lang->line('Detail Barang');?></h6>
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th><?= $this->lang->line('Kode Barang');?></th>
                                        <th><?= $this->lang->line('Nama Barang');?></th>
                                        <th class="text-right">Qty</th>
                                        <th class="text-right"><?= $this->lang->line('Harga');?></th>
                                        <th ><?= $this->lang->line('Keterangan');?></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i = 0;
                                    if ($detail) {
                                        foreach ($detail->result() as $key) {
                                            $i++; ?>
                                            <tr>
                                                <td class="text-center">
                                                    <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                                </td>
                                                <td><?= $key->i_product;?></td>
                                                <td><?= ucwords(strtolower($key->e_product_name));?></td>
                                                <td class="text-right"><?= $key->n_qty;?></td>
                                                <td class="text-right"><?= number_format($key->v_price);?></td>
                                                <td><?= $key->e_remark;?></td>
                                            </tr>
                                    <?php }
                                    } ?>
                                </tbody>
                                <input type="hidden" id="jml" name="jml" value="<?= $i; ?>">
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->