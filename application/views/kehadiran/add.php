<!-- Content area -->
<div class="content">
    
    <!-- Left and right buttons -->
    <form class="form-validation">
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-stack-plus mr-2"></i> <?= $this->lang->line('Tambah'); ?> <?= $this->lang->line($this->title); ?></h6>
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
                    <div class="col-6">
                        <div class="form-group">
                            <label>Nama :</label>
                            <input type="text" class="form-control text-capitalize" 
                                id="id_user" 
                                name="id_user" 
                                value="<?= $_SESSION['username'] ?>"
                                readonly>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="form-group">
                            <label>Jenis Izin</label>
                            <select class="form-control form-control-select2" 
                                data-container-css-class="select-sm" 
                                data-container-css-class="text-<?= $this->color; ?>" 
                                required data-fouc name="id_jenis_izin" id="id_jenis_izin">                            
                            </select>
                        </div>
                    </div>
                </div>

                <div class="row mt-4">
                    <div class="col-6">
                        <div class="row">
                            <div class="col-8">
                                <div class="form-group">
                                    <label>Tanggal Mulai Izin</label>
                                    <input type="text" class="form-control date" 
                                        placeholder="yyyy-mm-dd"
                                        id="d_pengajuan_mulai_tanggal" 
                                        name="d_pengajuan_mulai_tanggal" 
                                        required>
                                </div>
                            </div>
                            <div class="col-4">
                                    <label for="">&nbsp;</label>
                                    <input type="text" class="form-control text-capitalize" 
                                        placeholder="00:00"
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
                                    <label>Tanggal Berakhir Izin</label>
                                    <input type="text" class="form-control date" 
                                        placeholder="yyyy-mm-dd"
                                        id="d_pengajuan_selesai_tanggal" 
                                        name="d_pengajuan_selesai_tanggal"
                                        required>
                                </div>
                            </div>
                            <div class="col-4">
                                    <label for="">&nbsp;</label>
                                    <input type="text" class="form-control text-capitalize" 
                                        placeholder="00:00"
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
                                name="e_remark">
                        </div>
                    </div>
                </div>

                <div class="d-flex justify-content-start align-items-center mt-4 mb-5">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm">
                        <i class="icon-paperplane"></i>&nbsp; <?= $this->lang->line('Simpan'); ?>
                    </button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>                   
            </div>
        </div>
    </form>
</div>
<!-- /task manager table -->