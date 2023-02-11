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
                            <input type="hidden" value="<?= $data->id_stockopname; ?>" id="id" name="id">
                            <input type="text" class="form-control" readonly value="<?= $data->i_stockopname; ?>" data-inputmask="'mask': 'BON-9999-999999'" autofocus placeholder="Entry No Document" id="idocument" name="idocument" maxlength="20" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" name="ddocument" id="ddocument" readonly class="form-control date" required placeholder="Select Date" value="<?= $data->d_stockopname; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc name="idcustomer" id="idcustomer">
                                <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" placeholder="Isi keterangan jika ada .."><?= $data->e_remark; ?></textarea>
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
                                    <tr class="alpha-<?= str_replace("-800","",$this->color); ?> text-<?= str_replace("-800","-600",$this->color); ?>">
                                        <th class="text-center" width="3%;">#</th>
                                        <th width="25%;">Perusahaan</th>
                                        <th width="35%;">Barang</th>
                                        <th width="15%;">Qty</th>
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
                                                        <option value="<?= $key->i_product; ?>"><?= $key->i_product . ' - ' . $key->e_product_name; ?></option>
                                                    </select>
                                                </td>
                                                <td><input type="text" readonly class="form-control form-control-sm" id="e_company_name<?= $i; ?>" placeholder="Perusahaan" name="e_company_name[]" value="<?= $key->e_company_name; ?>"></td>
                                                <td>
                                                    <input type="number" required class="form-control form-control-sm" min="1" id="qty<?= $i; ?>" value="<?= $key->n_stockopname; ?>" placeholder="Qty" name="qty[]">
                                                    <input type="hidden" class="form-control form-control-sm" id="e_product<?= $i; ?>" name="e_product[]" value="<?= $key->e_product_name; ?>">
                                                    <input type="hidden" class="form-control form-control-sm" id="i_company<?= $i; ?>" name="i_company[]" value="<?= $key->i_company; ?>">
                                                </td>
                                                <td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>
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