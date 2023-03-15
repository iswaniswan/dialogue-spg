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
                            <input type="text" name="ddocument" id="ddocument" readonly class="form-control date" required placeholder="Select Date" value="<?= $data->d_retur; ?>">
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
                            <label>Distributor :</label>
                            <select class="form-control select-search" data-container-css-class="select-sm" data-placeholder="Select Company" required data-fouc name="id_company" id="id_company">
                                <option value="<?= $data->id_company ?>"><?= $data->e_company_name ?></option>
                            </select>
                        </div>
                    </div>                       
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" placeholder="Isi keterangan jika ada .."><?= $data->e_remark; ?></textarea>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="d-flex justify-content-start align-items-center">
                            <button type="submit" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                                Update</button>
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
                                        <th width="10%;">Qty</th>
                                        <th width="20%;">Alasan</th>
                                        <th width="20%;">Foto</th>
                                        <th width="3%;">Action</th>
                                        <th width="3%;"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                                    </tr>
                                </thead>
                                <tbody>
                                <?php $i = 0; foreach ($detail->result() as $key) { $i++; ?>                                            
                                    <tr>
                                        <td class="text-center">
                                            <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                        </td>
                                        <td>
                                            <select data-urut="<?= $i; ?>" required class="form-control form-control-sm form-control-select2" data-container-css-class="select-sm" 
                                                name="items[<?= $i ?>][id_product]" id="i_product<?= $i; ?>" required data-fouc>
                                                <option value="<?= $key->id_product ?>">
                                                    <?= $key->i_product . ' - ' . $key->e_product_name . ' - ' . $key->e_brand_name; ?>
                                                </option>
                                            </select>
                                        </td>
                                        <td>
                                            <input type="number" 
                                                class="form-control form-control-sm" min="1" id="qty<?= $i; ?>" value="<?= $key->n_qty; ?>" placeholder="Qty" 
                                                name="items[<?= $i ?>][qty]" required>
                                        </td>
                                        <td>
                                            <select required class="form-control form-control-sm form-control-select2" 
                                                data-container-css-class="select-sm" name="items[<?= $i ?>][i_alasan]" id="i_alasan<?= $i ?>" required data-fouc>
                                                <option value="<?= $key->i_alasan; ?>"><?= $key->e_alasan; ?></option>
                                            </select>
                                            <input type="hidden" class="form-control form-control-sm" id="e_product<?= $i; ?>" name="items[<?= $i ?>][e_product]" 
                                                value="<?= $key->e_product_name; ?>">
                                        </td>
                                        <td>
                                            <input type="file" class="form-control" id="foto<?= $i; ?>" placeholder="Foto" name="foto<?= $i; ?>" value="<?= $key->foto ?>">
                                        </td>
                                        <td>
                                            <input type="hidden" class="form-control form-control-sm" id="fotolama<?= $i; ?>" name="fotolama<?= $i; ?>" value="<?= $key->foto; ?>">
                                            <input type="hidden" class="form-control form-control-sm" id="fotosrc<?= $i; ?>" value="<?= base_url().'./upload/images/'.$key->foto; ?>">
                                            <b><i title="Lihat Foto" class="icon-eye text-primary lihatfoto" data-toggle="modal" data-target="#imageModal" id="<?= $i; ?>"></i></b>
                                        </td>
                                        <td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel" id="<?= $key->id ?>"></i></b></td>
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