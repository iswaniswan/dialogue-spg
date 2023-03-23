<!-- Content area -->
<div class="content">

    <!-- Left and right buttons -->
    <form class="form-validation">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> <?= $this->lang->line('Ubah'); ?> <?= $this->lang->line($this->title); ?></h6>
                <input type="hidden" id="path" value="<?= $this->folder; ?>">
                <input type="hidden" id="id" name="id" value="<?= $data->id; ?>">
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
                    <div class="col-6">
                        <div class="form-group">
                            <label>Nama :</label>
                            <input type="hidden" class="form-control text-capitalize" 
                                id="id_user" 
                                name="id_user" 
                                value="<?= $_SESSION['id_user'] ?>"
                                readonly>

                            <input type="text" class="form-control text-capitalize" 
                                value="<?= $data->e_nama ?>"
                                disabled>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="form-group">
                            <label>Jenis Izin</label>
                            <select class="form-control form-control-select2" 
                                data-container-css-class="select-sm" 
                                data-container-css-class="text-<?= $this->color; ?>" 
                                required data-fouc name="id_jenis_izin" id="id_jenis_izin">
                                <option value="<?= $data->id_jenis_izin ?>" selected><?= $data->e_izin_name ?></option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="row mt-4">
                    <div class="col-6">
                        <div class="row">
                            <div class="col-8">
                                <div class="form-group">
                                    <?php $d_pengajuan_mulai = $data->d_pengajuan_mulai;                                
                                    $d_pengajuan_mulai_tanggal = date('Y-m-d', strtotime($d_pengajuan_mulai));
                                    $d_pengajuan_mulai_pukul = date('H:i', strtotime($d_pengajuan_mulai));
                                    ?>
                                    <label>Tanggal Mulai Izin</label>
                                    <input type="text"class="form-control date" 
                                            id="d_pengajuan_mulai_tanggal" 
                                            name="d_pengajuan_mulai_tanggal" 
                                            value="<?= $d_pengajuan_mulai_tanggal ?>"
                                            required>
                                </div>
                            </div>
                            <div class="col-4">
                                    <label for="">&nbsp;</label>
                                    <input type="text" class="form-control text-capitalize" 
                                        value="<?= $d_pengajuan_mulai_pukul ?>"
                                        id="d_pengajuan_mulai_pukul" 
                                        name="d_pengajuan_mulai_pukul"
                                        required>
                            </div>
                        </div>                        
                    </div>
                    <div class="col-6">
                        <div class="row">
                            <div class="col-8">
                                <div class="form-group">
                                    <?php 
                                    $d_pengajuan_selesai = $data->d_pengajuan_selesai;
                                    $d_pengajuan_selesai_tanggal = date('Y-m-d', strtotime($d_pengajuan_selesai));
                                    $d_pengajuan_selesai_pukul = date('H:i', strtotime($d_pengajuan_selesai));
                                    ?>
                                    <label>Tanggal Berakhir Izin</label>
                                    <input type="text" class="form-control date" 
                                        value="<?= $d_pengajuan_selesai_tanggal ?>"
                                        id="d_pengajuan_selesai_tanggal" 
                                        name="d_pengajuan_selesai_tanggal"
                                        required>
                                </div>
                            </div>
                            <div class="col-4">
                                    <label for="">&nbsp;</label>
                                    <input type="text" class="form-control text-capitalize" 
                                        value="<?= $d_pengajuan_selesai_pukul ?>" 
                                        id="d_pengajuan_selesai_pukul" 
                                        name="d_pengajuan_selesai_pukul"
                                        required>
                            </div>
                        </div>                        
                    </div>
                    <div class="col-12">
                        <div class="form-group">
                            <label>Keterangan</label>
                            <input type="text" class="form-control text-capitalize" 
                                id="e_remark" 
                                name="e_remark"
                                value="<?= $data->e_remark ?>" required>
                        </div>
                    </div>
                </div>

                <div class="d-flex justify-content-start align-items-center mt-4 mb-5">                
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Ubah'); ?></button>                
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>                   
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->