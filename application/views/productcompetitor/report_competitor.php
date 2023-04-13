<style>

     .picker__weekday {
        padding: unset !important;
     }

/*!
// CSS only Responsive Tables
// http://dbushell.com/2016/03/04/css-only-responsive-tables/
// by David Bushell
*/

.rtable {
  /*!
  // IE needs inline-block to position scrolling shadows otherwise use:
  // display: block;
  // max-width: min-content;
  */
  display: inline-block;
  vertical-align: top;
  max-width: 100%;
  
  overflow-x: auto;
  
  // optional - looks better for small cell values
  white-space: nowrap;

  border-collapse: collapse;
  border-spacing: 0;
}

.rtable,
.rtable--flip tbody {
  // optional - enable iOS momentum scrolling
  -webkit-overflow-scrolling: touch;
  
  // scrolling shadows
  background: radial-gradient(left, ellipse, rgba(0,0,0, .2) 0%, rgba(0,0,0, 0) 75%) 0 center,
              radial-gradient(right, ellipse, rgba(0,0,0, .2) 0%, rgba(0,0,0, 0) 75%) 100% center;
  background-size: 10px 100%, 10px 100%;
  background-attachment: scroll, scroll;
  background-repeat: no-repeat;
}

// change these gradients from white to your background colour if it differs
// gradient on the first cells to hide the left shadow
.rtable td:first-child,
.rtable--flip tbody tr:first-child {
  background-image: linear-gradient(to right, rgba(255,255,255, 1) 50%, rgba(255,255,255, 0) 100%);
  background-repeat: no-repeat;
  background-size: 20px 100%;
}

// gradient on the last cells to hide the right shadow
.rtable td:last-child,
.rtable--flip tbody tr:last-child {
  background-image: linear-gradient(to left, rgba(255,255,255, 1) 50%, rgba(255,255,255, 0) 100%);
  background-repeat: no-repeat;
  background-position: 100% 0;
  background-size: 20px 100%;
}

.rtable th {
  font-size: 11px;
  text-align: left;
  text-transform: uppercase;
  background: #f2f0e6;
}

.rtable th,
.rtable td {
  padding: 6px 12px;
  border: 1px solid #d9d7ce;
}

.rtable--flip {
  display: flex;
  overflow: hidden;
  background: none;
}

.rtable--flip thead {
  display: flex;
  flex-shrink: 0;
  min-width: min-content;
}

.rtable--flip tbody {
  display: flex;
  position: relative;
  overflow-x: auto;
  overflow-y: hidden;
}

.rtable--flip tr {
  display: flex;
  flex-direction: column;
  min-width: min-content;
  flex-shrink: 0;
}

.rtable--flip td,
.rtable--flip th {
  display: block;
}

.rtable--flip td {
  background-image: none !important;
  // border-collapse is no longer active
  border-left: 0;
}

// border-collapse is no longer active
.rtable--flip th:not(:last-child),
.rtable--flip td:not(:last-child) {
  border-bottom: 0;
}

/*!
// CodePen house keeping
*/

body {
  margin: 0;
  padding: 25px;
  color: #494b4d;
  font-size: 14px;
  line-height: 20px;
}

h1, h2, h3 {
  margin: 0 0 10px 0;
  color: #1d97bf;
}

h1 {
  font-size: 25px;
  line-height: 30px;
}

h2 {
  font-size: 20px;
  line-height: 25px;
}

h3 {
  font-size: 16px;
  line-height: 20px;
}

table {
  margin-bottom: 30px;
}

a {
  color: #ff6680;
}

code {
  background: #fffbcc;
  font-size: 12px;
}

</style>
<!-- Content area -->
<div class="content">
    <!-- Left and right buttons -->
    <form class="form-validation">

        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title">
                    <i class="icon-price-tags2 mr-2"></i>
                    Produk Origin
                </h6>
                <div class="header-elements">
                    <div class="list-icons">
                        <a class="list-icons-item" data-action="collapse"></a>
                        <a class="list-icons-item" data-action="reload"></a>
                        <a class="list-icons-item" data-action="remove"></a>
                    </div>
                </div>
            </div>
            <div class="card-body">                
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <input type="hidden" name="id_product" value="<?= $product->id ?>">
                <div class="form-group row">
                    <div class="col-12">
                        <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                        <input class="form-control" value="<?= $customer->e_name ?>" readonly />
                    </div> 
                </div>
                <div class="form-group row">
                    <div class="col-6">
                        <label>Kode :</label>
                        <input class="form-control" value="<?= $product->i_product ?>" readonly />
                    </div>
                    <div class="col-6">
                        <label>Brand :</label>
                        <input class="form-control" value="<?= $product->e_brand_name ?>" readonly />
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-6">
                        <label><?= $this->lang->line('Nama Barang'); ?> :</label>
                        <input class="form-control" value="<?= $product->e_product_name ?>" readonly />
                    </div>
                    <div class="col-6">
                        <label><?= $this->lang->line('Harga'); ?> :</label>
                        <input class="form-control" value="<?= 'Rp. ' . number_format($product->v_price, 0, ",", ".") ?>" readonly />
                    </div>                  
                </div>       
                                 
                <div class="form-group row">
                    <div class="col-6" style="display: flex;">                        
                        <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1" style="align-self:end">
                            <i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?>
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title">
                    <i class="icon-price-tags2 mr-2"></i>
                    Perbandingan Produk Kompetitor
                </h6>
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
                <div class="table-responsive">
                    <table class="rtable rtable--flip" id="table-competitor">
                        <thead>
                            <tr>
                                <th class="text-dark" style="width: 200px">Brand</th>
                                <th class="text-dark" style="width: 200px">Harga</th>
                                <th class="text-dark" style="width: 200px">Tanggal Berlaku</th>
                                <th class="text-dark" style="width: 200px">Stats</th>
                                <th class="text-dark" style="width: 200px">Selisih Origin</th>
                                <th class="text-dark" style="width: 200px">Keterangan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php require_once ('_report_helper.php'); ?>

                            <?php $count = 1; ?>
                            <?php foreach ($all_competitor->result() as $competitor) { ?>
                                <tr>
                                    <?php $count++ ?>
                                    <td><?= $competitor->e_brand_text ?></td>
                                    <td><?= 'Rp. ' . number_format($competitor->v_price, 0, ",", ".") ?></td>
                                    <td><?= date('Y-m-d', strtotime($competitor->d_berlaku)) ?></td>
                                    
                                    <td>
                                        <?php 
                                        $_status = getStatusFluktuasi($db, $customer->id, $product->id, $competitor->e_brand_text);                                         
                                        ?>
                                        <?= getBadgeStatusFluktuasi($_status) ?>
                                    </td>

                                    <td><?= getBadgeSelisih($product_origin_price, $competitor->v_price) ?></td>
                                    <td style="max-width: 300px;"><?= $competitor->e_remark ?></td>                                    
                                </tr>
                            <?php } ?>                        
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </form>

</div>
<!-- /task manager table -->