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
                <h6 class="card-title"><i class="icon-eye mr-2"></i> View <?= $this->title; ?></h6>
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
                            <label>Nomor Dokumen :</label>
                            <input type="text" class="form-control" readonly value="<?= $data->i_document; ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" class="form-control" readonly value="<?= $data->d_document; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Toko :</label>
                            <select class="form-control select-search" disabled="true" data-container-css-class="select-sm">
                                <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Pelanggan :</label>
                            <input type="text" class="form-control text-capitalize" readonly value="<?= $data->e_customer_sell_name; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" readonly><?= $data->e_remark; ?></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Alamat Pelanggan :</label>
                            <textarea class="form-control" readonly><?= $data->e_customer_sell_address; ?></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
                </div>
            </div>
        </div>

        <div class="card cover">
            <div class="card-body">
                <h6 class="card-title"><i class="icon-cart-add mr-2"></i> Detail Barang</h6>
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned table-bordered table-xs" id="tablecover">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" width="3%;">#</th>
                                        <th>Kode Barang</th>
                                        <th>Nama Barang</th>
                                        <th class="text-right">Qty</th>
                                        <th class="text-right">Disc (%)</th>
                                        <th class="text-right">Harga</th>
                                        <th>Keterangan</th>
                                    </tr>
                                </thead>
                                <tbody>
                                <?php $i = 0; foreach ($detail->result() as $key) { $i++; ?>
                                    <tr>
                                        <td class="text-center">
                                            <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                        </td>
                                        <td><?= $key->i_product; ?></td>
                                        <td><?= $key->e_product_name; ?></td>
                                        <td class="text-right"><?= $key->n_qty; ?></td>
                                        <td class="text-right"><?= $key->v_diskon; ?></td>
                                        <td class="text-right"><?= number_format($key->v_price); ?></td>
                                        <td><?= $key->e_remark; ?></td>
                                    </tr>
                                <?php } ?>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <th colspan="4" class="text-right">Bruto</th>
                                        <th class="text-right">
                                            <span id="sbruto"><?= number_format($data->v_gross);?></span>
                                            <input type="hidden" name="bruto" id="bruto" value="<?= $data->v_gross;?>">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">Diskon (<span id="sdiskonpersen"><?= number_format($data->n_diskon);?></span>%)</th>
                                        <th class="text-right">
                                            <span id="sdiskon"><?= number_format($data->v_diskon);?></span>
                                            <input type="hidden" name="diskon" id="diskon" value="<?= $data->v_diskon;?>">
                                            <input type="hidden" name="diskonpersen" id="diskonpersen" value="<?= $data->n_diskon;?>">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <?php /*
                                    <tr>
                                        <th colspan="4" class="text-right">DPP</th>
                                        <th class="text-right">
                                            <span id="sdpp"><?= number_format($data->v_dpp);?></span>
                                            <input type="hidden" name="dpp" id="dpp" value="<?= $data->v_dpp;?>">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">PPN</th>
                                        <th class="text-right">
                                            <span id="sppn"><?= number_format($data->v_ppn);?></span>
                                            <input type="hidden" name="ppn" id="ppn" value="<?= $data->v_ppn;?>">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    */ ?>
                                    <tr>
                                        <th colspan="4" class="text-right">Netto</th>
                                        <th class="text-right">
                                            <span id="snetto"><?= number_format($data->v_netto);?></span>
                                            <input type="hidden" name="netto" id="netto" value="<?= $data->v_netto;?>">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                </tfoot>
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