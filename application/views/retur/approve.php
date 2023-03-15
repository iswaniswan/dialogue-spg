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
                <h6 class="card-title"><i class="icon-eye mr-2"></i> Edit <?= $this->title; ?></h6>
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
                            <input type="hidden" class="form-control" readonly name="id" id="id" value="<?= $data->id; ?>">
                            <input type="text" class="form-control" readonly value="<?= $data->i_document; ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Tanggal Dokumen :</label>
                            <input type="text" readonly class="form-control" value="<?= $data->d_retur; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Toko :</label>
                            <input type="text" readonly class="form-control" value="<?= $data->e_customer_name; ?>">
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Distributor :</label>
                            <input type="text" readonly class="form-control" value="<?= $data->e_company_name; ?>">
                        </div>
                    </div>   
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" rows="1" readonly><?= $data->e_remark ?></textarea>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="d-flex justify-content-start align-items-center">
                            <a href="#" onclick="sweetapprove('retur',<?= $data->id; ?>);" class="btn btn bg-success btn-sm ml-1"><i class="icon-check"></i>&nbsp; <?= $this->lang->line('Approve'); ?></a> &nbsp;
                            <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm"><i class="icon-arrow-left16"></i>&nbsp; Back</a>
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
                                        <th>Kode Barang</th>
                                        <th>Nama Barang</th>
                                        <th>Brand</th>
                                        <th class="text-right">Qty</th>
                                        <th>Alasan</th>
                                        <th>Foto</th>
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
                                            <td><?= $key->e_brand_name; ?></td>
                                            <td class="text-right"><?= $key->n_qty; ?></td>
                                            <td><?= $key->e_alasan; ?></td>
                                            <td><input type="hidden" class="form-control form-control-sm" id="fotosrc<?= $i; ?>" name="fotosrc<?= $i; ?>" value="<?= base_url().'./upload/images/'.$key->foto; ?>">
                                                <b><i title="Lihat Foto" class="icon-eye text-primary lihatfoto" data-toggle="modal" data-target="#imageModal" id="<?= $i; ?>"></i></b></td></td>
                                        </tr>
                                    <?php } ?>
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

<!-- Modal -->
<div class="modal fade" id="imageModal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalLabel">Foto Barang Retur</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        <img class="img-responsive" id="myImage" src="" style="max-width:550px;">
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
<!-- /task manager table -->