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
                <h6 class="card-title"><i class="icon-stack-plus mr-2"></i> Add <?= $this->title; ?></h6>
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
                            <input type="text" class="form-control" readonly value="<?= $number; ?>" data-inputmask="'mask': 'BON-9999-999999'" autofocus placeholder="Entry No Document" id="idocument" name="idocument" maxlength="20" autocomplete="off" required>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" name="ddocument" id="ddocument" class="form-control date" required placeholder="Select Date" value="<?= date('Y-m-d'); ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Toko :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Nama Toko" required data-fouc name="idcustomer" id="idcustomer">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Pelanggan :</label>
                            <input type="text" class="form-control text-capitalize" autocomplete="off" id="nama" name="nama" placeholder="Nama Pelanggan .." value="-">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" id="eremark" placeholder="Isi keterangan jika ada .."></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Alamat Pelanggan :</label>
                            <textarea class="form-control" name="alamat" id="alamat" placeholder="Isi Alamat Pelanggan ..">-</textarea>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        Save</button>
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
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <th colspan="4" class="text-right">Bruto</th>
                                        <th class="text-right">
                                            <span id="sbruto"></span>
                                            <input type="hidden" name="bruto" id="bruto" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">Diskon (<span id="sdiskonpersen">0</span>%)</th>
                                        <th class="text-right">
                                            <span id="sdiskon"></span>
                                            <input type="hidden" name="diskon" id="diskon" value="0">
                                            <input type="hidden" name="diskonpersen" id="diskonpersen" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <?php /*
                                    <tr>
                                        <th colspan="4" class="text-right">DPP</th>
                                        <th class="text-right">
                                            <span id="sdpp"></span>
                                            <input type="hidden" name="dpp" id="dpp" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    <tr>
                                        <th colspan="4" class="text-right">PPN</th>
                                        <th class="text-right">
                                            <span id="sppn"></span>
                                            <input type="hidden" name="ppn" id="ppn" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                    */ ?>
                                    <tr>
                                        <th colspan="4" class="text-right">Netto</th>
                                        <th class="text-right">
                                            <span id="snetto"></span>
                                            <input type="hidden" name="netto" id="netto" value="0">
                                        </th>
                                        <th colspan="2"></th>
                                    </tr>
                                </tfoot>
                                <input type="hidden" id="jml" name="jml" value="0">
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->