<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation" method="POST" enctype="multipart/form-data">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-upload7 mr-2"></i> <?= $this->lang->line('Unggah'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                <div class="form-group row">
                    <div class="col-md-6">
                        <label><?= $this->lang->line('Nama Toko'); ?> :</label>
                        <select class="form-control select" name="id_customer" id="id_customer" required data-fouc data-placeholder="<?= $this->lang->line('Nama Toko'); ?>">
                            <option value=""></option>
                            <?php if ($customer->num_rows() > 0) {
                                foreach ($customer->result() as $key) { ?>
                                    <option value="<?= $key->id_customer; ?>"><?= $key->e_customer_name; ?></option>
                            <?php }
                            } ?>
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
                        <div class="input-group row">
                            <div class="col-4">
                                <select class="form-control" title="Select a year" name="e_periode_year" id="e_periode_year">
                                    <?php 
                                    $current_year = intval(date('Y'));
                                    $last3 = $current_year - 3;
                                    for ($i=$current_year; $i>$last3; $i--) {
                                        echo "<option value='$i'>$i</option>";
                                    }                                    
                                    ?>
                                </select>
                            </div>
                            <div class="col-2">
                                <select class="form-control" title="Select a month" name="e_periode_month" id="e_periode_month">
                                    <?php 
                                    $current_month = intval(date('m'));
                                    $months = getMonthShort();
                                    
                                    foreach ($months as $month => $value) {
                                        $selected = (intval($month) == $current_month) ? 'selected' : '';
                                        echo "<option value='$month' $selected>$value</option>";
                                    }   
                                    ?>
                                </select>
                            </div>
                        </div> 
                        */?>                       
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-lg-12">
                        <input type="file" data-show-upload="false" class="file-input-ajax" required id="fileuser" name="userfile">
                        <span class="form-text text-muted">Only the following extension files can be uploaded :<code>xls|xlsx|csv</code></span>
                    </div>
                </div>

                <div class="form-group row">
                    <div class="col-sm-4">
                        <button type="submit" id="cubmit" class="btn btn-block bg-<?= $this->color; ?> btn-sm"><i class="icon-upload"></i>&nbsp;<?= $this->lang->line('Unggah'); ?></button>
                    </div>
                    <div class="col-sm-4">
                        <a id="href" href="<?= base_url($this->folder); ?>" class="btn btn-block bg-teal btn-sm"><i class="icon-download"></i>&nbsp; Format <?= $this->lang->line('Unggah'); ?></a>
                    </div>
                    <div class="col-sm-4">
                        <a href="<?= base_url($this->folder); ?>" class="btn btn-block bg-danger btn-sm"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                    </div>
                </div>
            </div>
        </div>
        <!-- /bootstrap file input -->
    </form>
</div>
<!-- /task manager table -->