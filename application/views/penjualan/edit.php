<style>
    .tabel td {
        padding: 7px 7px !important;
    }
    .input-group-prepend {
        margin-right: unset;
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
                            <input type="text" name="ddocument" id="ddocument" class="form-control date" required placeholder="Select Date" value="<?= $data->d_document; ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Toko :</label>
                            <select class="form-control select-search" 
                                data-container-css-class="select-sm" data-placeholder="Select Customer" required data-fouc 
                                name="idcustomer" id="idcustomer">
                                <option value="<?= $data->id_customer; ?>"><?= $data->e_customer_name; ?></option>
                            </select>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Nama Pelanggan :</label>
                            <input type="text" class="form-control text-capitalize" placeholder="Nama Pelanggan .." id="nama"
                                name="nama" value="<?= $data->e_customer_sell_name ?>">
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Keterangan :</label>
                            <textarea class="form-control" name="eremark" placeholder="Isi keterangan jika ada .."><?= $data->e_remark ?></textarea>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label>Alamat Pelanggan :</label>
                            <textarea class="form-control" name="alamat" placeholder="Isi Alamat Pelanggan .."><?= $data->e_customer_sell_address ?></textarea>
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
                        <div class="table-responsive" style="display: block; overflow-x: auto; white-space: nowrap;">
                            <table class="table table-columned table-bordered table-xs" id="tablecover" style="width: 1200px;">
                                <thead>
                                    <tr class="alpha-<?= $this->color; ?> text-<?= $this->color; ?>-600">
                                        <th class="text-center" style="width:15px;" rowspan="2">#</th>
                                        <th style="width:350px;" rowspan="2">Barang</th>
                                        <th style="width:75px;" rowspan="2">Qty</th>
                                        <th style="width:75px;" rowspan="2">Disc (%)</th>
                                        <th style="width:auto;" class="text-center" colspan="4">Harga</th>
                                        <th style="width:100px;" rowspan="2">Keterangan</th>
                                        <th style="width:15px;" rowspan="2"><i id="addrow" title="Tambah Baris" class="icon-plus-circle2"></i></th>
                                    </tr>
                                    <tr>
                                        <th class="text-center">Satuan</th>
                                        <th class="text-center">Total</th>
                                        <th class="text-center">Diskon</th>
                                        <th class="text-center">Akhir</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $grand_total = 0; $grand_discount = 0; $grand_akhir = 0; ?>
                                    <?php $i = 0; foreach ($detail->result() as $key) { $i++; ?>
                                    <tr>
                                        <td class="text-center">
                                            <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                        </td>
                                        <td>
                                            <select data-urut="<?= $i; ?>" class="form-control form-control-sm form-control-select2" 
                                                data-container-css-class="select-sm" 
                                                name="items[<?= $i ?>][id_product]" id="i_product<?= $i ?>" required data-fouc>
                                                <option value="<?= $key->id_product ?>"><?= $key->i_product . ' - ' . $key->e_product_name . ' - ' . $key->e_brand_name; ?>
                                                </option>
                                            </select>
                                        </td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm input-qty" value="<?= $key->n_qty ?>"
                                                min="1" id="qty<?= $i ?>" onkeyup="getTotal(this); getAkhir(this)" placeholder="Qty" name="items[<?= $i ?>][qty]">
                                        </td>
                                        <td>
                                            <input type="number" required 
                                                class="form-control form-control-sm input-discount" 
                                                onblur="if(this.value==''){this.value='0';}" 
                                                onfocus="if(this.value=='0'){this.value='';}"  
                                                onkeyup="getAkhir(this);"
                                                onchange="getAkhir(this)";
                                                value="<?= $key->v_diskon;?>" 
                                                id="diskon<?= $i ?>" 
                                                placeholder="Diskon" 
                                                name="items[<?= $i ?>][vdiskon]">
                                        </td>
                                        <td>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>                        
                                                <input type="text" value="<?= number_format($key->v_price); ?>" 
                                                    class="form-control form-control-sm text-right input-harga"
                                                    onblur='if(this.value==""){this.value="0";}' 
                                                    onfocus='if(this.value=="0"){this.value="";}'
                                                    onkeyup="getTotal(this); getAkhir(this); reformat(this)"
                                                    name="items[<?=$i?>][harga]">
                                            </div>  
                                        </td>
                                        <td class="text-right">
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>   
                                                <?php $total = $key->v_price * $key->n_qty; $grand_total += $total; ?>                     
                                                <input type="text" value="<?= number_format($total); ?>" 
                                                    class="form-control form-control-sm text-right input-total" readonly>
                                            </div>                                              
                                        </td>
                                        <td class="text-right">
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>   
                                                <?php $discount = ($total * $key->v_diskon) / 100; 
                                                    $grand_discount += $discount; ?>                     
                                                <input type="text" value="<?= number_format($discount); ?>" 
                                                    class="form-control form-control-sm text-right input-harga-discount" readonly>
                                            </div>                                              
                                        </td>
                                        <td class="text-right">
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>                      
                                                <?php $akhir =  $total - $discount; 
                                                    $grand_akhir += $akhir; ?>  
                                                <input type="text" value="<?= number_format($akhir); ?>" 
                                                    class="form-control form-control-sm text-right input-akhir" readonly>
                                            </div>                                              
                                        </td>
                                        <td>
                                            <input type="text" class="form-control form-control-sm" placeholder="Keterangan" name="items[<?= $i ?>][enote]"  value="<?= $key->e_remark;?>">
                                            <input type="hidden" class="form-control form-control-sm" id="e_product<?= $i; ?>" name="items[<?= $i ?>][e_product]"  value="<?= $key->e_product_name;?>">
                                            <input type="hidden" class="form-control form-control-sm" id="i_company<?= $i; ?>" name="items[<?= $i ?>][i_company]"  value="<?= $key->i_company;?>">
                                        </td>
                                        <td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>
                                    </tr>
                                <?php } ?>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <th colspan="5" class="text-right">Grand Total</th>
                                        <th class="text-right">
                                            <span class="d-none" id="sbruto"></span>
                                            <input type="hidden" name="bruto" id="bruto" value="0">
                                            
                                            <div class="input-group mb-3">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>                        
                                                <input type="text" name="grand_total" id="grand_total" value="<?= number_format($grand_total, 2, ".", ",") ?>" 
                                                    class="form-control form-control-sm text-right" readonly>
                                            </div>   
                                        </th>
                                        <th class="text-right">
                                            <span class="d-none" id="sbruto"></span>                                            
                                            <div class="input-group mb-3">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>                        
                                                <input type="text" name="grand_discount" id="grand_discount" value="<?= number_format($grand_discount, 0, ".", ",") ?>" 
                                                    class="form-control form-control-sm text-right" readonly>
                                            </div>   
                                        </th>
                                        <th>
                                            <div class="input-group mb-3">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">Rp.</span>
                                                </div>                        
                                                <input type="text" name="grand_akhir" id="grand_akhir" value="<?= number_format($grand_akhir, 2, ".", ",") ?>" 
                                                    class="form-control form-control-sm text-right" readonly>
                                            </div>                                             
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