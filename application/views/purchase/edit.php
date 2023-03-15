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
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> Edit <?= $this->title; ?></h6>
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
                            <input type="hidden" value="<?= $data->id; ?>" id="id" name="id">
                            <input type="text" class="form-control" readonly value="<?= $data->i_document; ?>" data-inputmask="'mask': 'BON-9999-999999'" autofocus placeholder="Entry No Document" id="idocument" name="idocument" maxlength="20" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" name="d_receive" id="d_receive" class="form-control date" required placeholder="Select Date" value="<?= $data->d_receive; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc name="id_customer" id="id_customer">
                                <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Distributor :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Distributor" 
                                    name="id_distributor" id="id_distributor" required data-fouc>
                                <option value="<?= $data->i_company; ?>"><?= $data->e_company_name; ?></option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>No. Surat Jalan :</label>
                            <input type="text" class="form-control" value="<?= $data->i_surat_jalan; ?>" name="i_surat_jalan">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Surat Jalan :</label>
                            <input type="text" class="form-control date" value="<?= $data->d_surat_jalan; ?>" name="d_surat_jalan">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark"><?= $data->e_remark; ?></textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        Update</button>
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
                                        <th width="40%;">Barang</th>
                                        <th width="15%;">Qty</th>
                                        <!-- <th width="15%;">Disc (%)</th> -->
                                        <th width="20%;">Harga</th>
                                        <th width="20%;">Total</th>
                                        <th width="3%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $grand_total = 0; ?>
                                    <?php $i = 0; foreach ($detail->result() as $key) { ?>
                                        <tr>
                                            <td class="text-center">
                                                <spanx id="snum<?= $i; ?>"><?= $i+1 ?></spanx>
                                            </td>
                                            <td>
                                                <select data-urut="${i}" class="form-control form-control-sm form-control-select2 form-input-product" 
                                                    data-container-css-class="select-sm" 
                                                    name="current_items[<?= $i ?>][id_product]" 
                                                    id="id_product<?= $i ?>" 
                                                    value="<?= $key->id_product ?>"
                                                    required data-fouc>
                                                    <option value="<?= $key->id_product ?>" selected>
                                                       <?= $key->i_product ?> - <?= $key->e_product_name ?>
                                                    </option>
                                                </select>
                                            </td>                                            
                                            <td>
                                                <input type="number" class="form-control form-control-sm form-input-current-items-qty" min="1" id="qty<?= $i; ?>" 
                                                        value="<?= $key->n_qty;?>" placeholder="Qty" name="current_items[<?= $i ?>][qty]">
                                            </td>                                            
                                            <td class="text-right">
                                                <div class="input-group">
                                                    <div class="input-group-prepend">
                                                        <span class="input-group-text">Rp.</span>
                                                    </div>
                                                    <input type="text" class="form-control"
                                                            name="current_items[<?= $i ?>][price]" id="price<?= $i ?>" autocomplete="off" 
                                                            value="<?= number_format($key->v_price, 0, ",", "."); ?>" 
                                                            required>
                                                </div>                                                
                                            </td>
                                            <td class="text-right">
                                                <?php $total = $key->n_qty * $key->v_price; ?>  
                                                <div class="input-group">
                                                    <div class="input-group-prepend">
                                                        <span class="input-group-text">Rp.</span>
                                                    </div>
                                                    <input type="text" class="form-control form-input-total"
                                                            name="current_items[<?= $i ?>][total]" id="total<?= $i ?>" autocomplete="off" 
                                                            value="<?= number_format($total, 0, ",", ".") ?>" 
                                                            readonly>
                                                </div>
                                                <?php $grand_total += $total; ?>
                                            </td>
                                            <td>
                                                <b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b>
                                            </td>
                                        </tr>
                                    <?php $i++; } ?>
                                </tbody>

                                <?php if ($i >= 1) { ?>
                                    <tfoot style="border-top: 1px solid #ddd;">
                                        <tr style="border-top: 1px solid #ddd" id="tr_grand_total_price">
                                            <td colspan="4">Grand Total Harga</td>
                                            <td>
                                                <div class="input-group">
                                                    <div class="input-group-prepend">
                                                        <span class="input-group-text">Rp.</span>
                                                    </div>
                                                    <input type="text" 
                                                            class="form-control"
                                                            id="grand_total_price" value="<?= number_format($grand_total, 0, ",", ".") ?>" 
                                                            readonly>
                                                </div>
                                            </td>
                                            <td></td>
                                        </tr>
                                    </tfoot>
                                <?php } ?>

                                <?php /*
                                <tfoot>
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
                                </tfoot>
                                */ ?>
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