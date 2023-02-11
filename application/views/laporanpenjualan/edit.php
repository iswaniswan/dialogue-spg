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
                            <input type="hidden" value="<?= $data->id_document; ?>" id="id" name="id">
                            <input type="text" class="form-control" readonly value="<?= $data->i_document; ?>" data-inputmask="'mask': 'BON-9999-999999'" autofocus placeholder="Entry No Document" id="idocument" name="idocument" maxlength="20" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" name="ddocument" id="ddocument" class="form-control date" required placeholder="Select Date" value="<?= $data->d_document; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Toko :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc name="idcustomer" id="idcustomer">
                                <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Pelanggan :</label>
                            <input type="text" class="form-control text-capitalize" placeholder="Nama Pelanggan .." id="nama" name="nama" value="<?php if($data->e_customer_sell_name =='-'){ echo '';} ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" placeholder="Isi keterangan jika ada .."><?php if($data->e_remark =='-'){ echo '';} ?></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Alamat Pelanggan :</label>
                            <textarea class="form-control" name="alamat" placeholder="Isi Alamat Pelanggan .."><?php if($data->e_customer_sell_address =='-'){ echo '';} ?></textarea>
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
                                        <th width="35%;">Barang</th>
                                        <th width="15%;">Qty</th>
                                        <th width="15%;">Disc (%)</th>
                                        <th width="15%;" class="text-right">Harga</th>
                                        <th width="20%;">Keterangan</th>
                                        <th width="3%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
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
                                                <td>
                                                    <select data-urut="<?= $i; ?>" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" name="i_product[]" id="i_product<?= $i; ?>" required data-fouc>
                                                        <option value="<?= $key->i_product . ' - ' . $key->id_brand; ?>"><?= $key->i_product . ' - ' . $key->e_product_name . ' - ' . $key->e_brand_name; ?></option>
                                                    </select>
                                                </td>
                                                <td><input type="number" required class="form-control form-control-sm" min="1" id="qty<?= $i; ?>" onkeyup="hetang();" value="<?= $key->n_qty;?>" placeholder="Qty" name="qty[]"></td>
                                                <td><input type="number" required class="form-control form-control-sm" onblur="if(this.value==''){this.value='0';}" onfocus="if(this.value=='0'){this.value='';}"  value="<?= $key->v_diskon;?>" id="diskon<?= $i; ?>" onkeyup="hetang();" placeholder="Diskon" name="vdiskon[]"></td>
                                                <td><input type="text" required class="form-control form-control-sm text-right harga" id="harga<?= $i; ?>" placeholder="Harga"  value="<?= number_format($key->v_price);?>" name="harga[]" onkeyup="hetang();"></td>
                                                <td>
                                                    <input type="text" class="form-control form-control-sm" placeholder="Keterangan" name="enote[]"  value="<?= $key->e_remark;?>">
                                                    <input type="hidden" class="form-control form-control-sm" id="e_product<?= $i; ?>" name="e_product[]"  value="<?= $key->e_product_name;?>">
                                                    <input type="hidden" class="form-control form-control-sm" id="i_company<?= $i; ?>" name="i_company[]"  value="<?= $key->i_company;?>">
                                                </td>
                                                <td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>
                                            </tr>
                                    <?php }
                                    } ?>
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