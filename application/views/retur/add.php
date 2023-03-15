<style>
    .tabel td {
        padding: 7px 7px !important;
    }
</style>
<!-- Content area -->
<div class="content">

    <!-- <form class="form-validation" enctype="multipart/form-data" method="POST" > -->
    <?php echo form_open_multipart('retur/prosesupload',array('class'=>'form-validation', 'id'=>'addretur'));?>
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
                            <input type="text" name="ddocument" readonly id="ddocument" class="form-control date" required placeholder="Select Date" value="<?= date('Y-m-d'); ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc name="idcustomer" id="idcustomer">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Distributor :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Company" required data-fouc name="id_company" id="id_company">
                                <option value=""></option>
                            </select>
                        </div>
                    </div>                    
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" rows="1" placeholder="Isi keterangan jika ada .."></textarea>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="d-flex justify-content-start align-items-center">
                            <button type="submit" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                                Save</button>
                            <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
                        </div>
                    </div>
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
                                        <!-- <th width="25%;">Perusahaan</th> -->
                                        <th width="10%;">Qty</th>
                                        <th width="20%;">Alasan</th>
                                        <th width="20%;">Foto</th>
                                        <th width="3%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                                    </tr>
                                </thead>
                                <tbody>
                                </tbody>
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