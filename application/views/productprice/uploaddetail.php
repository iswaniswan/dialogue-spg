<!-- <style>
    .table-responsive{
  height:400px;  
  overflow:scroll;
}
 thead tr:nth-child(1) th{
    background: white;
    position: sticky;
    top: 0;
    z-index: 10;
  }
</style> -->
<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-transmission mr-2"></i> <?= 'Tranfer'; ?> <?= $this->lang->line($this->title); ?></h6>
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <input type="hidden" id="color" value="<?= $this->color; ?>">
                <div class="header-elements">
                    <div class="list-icons">
                        <a class="list-icons-item" data-action="collapse"></a>
                        <a class="list-icons-item" data-action="reload"></a>
                        <a class="list-icons-item" data-action="remove"></a>
                    </div>
                </div>
            </div>

            <div class="card-body">
                <div class="form-group row mb-5">
                    <div class="col-md-6">
                        <label><?= $this->lang->line('Toko'); ?> :</label>
                        <select class="form-control select" name="id_customer" id="id_customer" required data-fouc data-placeholder="<?= $this->lang->line('Toko'); ?>" readonly>
                            <option value="<?= $id_customer; ?>"><?= $e_customer_name; ?></option>
                        </select>
                    </div>
                    <div class="col-6">
                        <div class="form-group">
                            <label>Periode :</label>
                            <div class="input-group">
                                <input type="text" readonly class="form-control form-control-sm month-picker" name="e_periode"
                                            id="e_periode" placeholder="Periode" value="<?= @$e_periode ?>">                                
                            </div>
                        </div>
                        <?php /*
                        <label>Periode:</label>
                        <div class="input-group row">
                            <div class="col-4">
                                <select class="form-control" title="Select a year" name="e_periode_year" id="e_periode_year">
                                    <?php
                                    $current_year = intval(date('Y'));
                                    $last3 = $current_year - 3;
                                    for ($i=$current_year; $i>$last3; $i--) {
                                        $selected = ($e_periode_year == $i) ? 'selected' : '';
                                        echo "<option value='$i' $selected>$i</option>";
                                    }                                    
                                    ?>
                                </select>
                            </div>
                            <div class="col-2">
                                <select class="form-control" title="Select a month" name="e_periode_month" id="e_periode_month">
                                    <?php     
                                    $months = getMonthShort();                                
                                    foreach ($months as $month => $value) {
                                        $selected = ($month == $e_periode_month) ? 'selected' : '';
                                        echo "<option value='$month' $selected>$value</option>";
                                    }   
                                    ?>
                                </select>
                            </div>
                        </div> 
                        */ ?>                       
                    </div>
                </div>
                <div class="form-group row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-columned datatable-header-basic table-bordered table-xs demo2" id="tabledetail">
                                <thead>
                                    <tr class="">
                                        <th style="width: 50px" class="text-center">No</th>
                                        <th class="d-none" style="width: 100px;">ID Barang</th>
                                        <th style="width: 100px;">Kode</th>
                                        <th style="width: auto;">Nama</th>
                                        <th style="width: 200px;">Brand</th>
                                        <th style="width: 200px">Harga</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i = 0; foreach ($datadetail as $key) { 
                                        $i++;
                                        // $warna = ($key['i_product'] == '') ? 'class="table-danger"' : '';
                                    ?>
                                        <tr>
                                            <td class="text-center">
                                                <spanx id="snum<?= $i; ?>"><?= $i; ?></spanx>
                                            </td>
                                            <td class="d-none">
                                                <input type="text" readonly required 
                                                        class="form-control form-control-sm product"                                                         
                                                        name="id_product<?= $i; ?>" 
                                                        id="id_product<?= $i; ?>" 
                                                        value="<?= $key["id_product"]; ?>">
                                            </td>
                                            <td><?= $key["i_product"]; ?></td>
                                            <td><?= $key["e_product"]; ?></td>
                                            <td><?= $key["brand"]; ?></td>
                                            <td>
                                                <input type="hidden" name="v_price<?= $i; ?>" value="<?= $key["v_price"]; ?>" readonly>
                                                <span>Rp. <?= number_format($key['v_price'], 2, ",", ".") ?></span>
                                            </td>                                            
                                        </tr>
                                    <?php } ?>
                                    <input type="hidden" name="jml" id="jml" value="<?= $i; ?>">
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-start align-items-center mt-3">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Simpan'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>
    </form>
</div>
<!-- Latest compiled and minified JavaScript -->