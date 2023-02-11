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
                            <input type="text" class="form-control" readonly value="<?= $data->d_receive; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select-search" disabled="true" data-container-css-class="select-sm">
                                <option value="<?= $data->id_item; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" readonly><?= $data->e_remark; ?></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start">
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
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
                                        <!-- <th class="text-right">Harga</th> -->
                                        <th>Keterangan</th>
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
                                                <td><?= $key->i_product; ?></td>
                                                <td><?= $key->e_product_name; ?></td>
                                                <td class="text-right"><?= $key->n_qty; ?></td>
                                                <!-- <td class="text-right"><?= number_format($key->v_price); ?></td> -->
                                                <td>
                                                    <?= $key->e_remark; ?>
                                                    <input type="hidden" id="i_product<?= $i; ?>" value="<?= $key->i_product; ?>" name="i_product[]">
                                                    <input type="hidden" id="qty<?= $i; ?>" value="<?= $key->n_qty; ?>" name="qty[]">
                                                    <!-- <input type="hidden" value="0" id="diskon<?= $i; ?>" name="vdiskon[]">
                                                    <input type="hidden" class="harga" id="harga<?= $i; ?>" value="<?= $key->v_price; ?>" name="harga[]"> -->
                                                </td>
                                            </tr>
                                    <?php }
                                    } ?>
                                </tbody>
                                <!-- <tfoot>
                                    <tr>
                                        <th colspan="4" class="text-right">Bruto</th>
                                        <th class="text-right">
                                            <span id="sbruto">0</span>
                                            <input type="hidden" name="bruto" id="bruto" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">Diskon (<span id="sdiskonpersen">0</span>%)</th>
                                        <th class="text-right">
                                            <span id="sdiskon">0</span>
                                            <input type="hidden" name="diskon" id="diskon" value="0">
                                            <input type="hidden" name="diskonpersen" id="diskonpersen" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">DPP</th>
                                        <th class="text-right">
                                            <span id="sdpp">0</span>
                                            <input type="hidden" name="dpp" id="dpp" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">PPN</th>
                                        <th class="text-right">
                                            <span id="sppn">0</span>
                                            <input type="hidden" name="ppn" id="ppn" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">Netto</th>
                                        <th class="text-right">
                                            <span id="snetto">0</span>
                                            <input type="hidden" name="netto" id="netto" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                </tfoot> -->
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