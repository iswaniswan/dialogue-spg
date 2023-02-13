<!-- Content area -->
<div class="content">

    <form class="form-validation">
        <!-- Left and right buttons -->
        <div class="card">
            <div class="card-header border-<?= $this->color; ?> bg-transparent header-elements-inline">
                <h6 class="card-title"><i class="icon-pencil6 mr-2"></i> Ganti Password</h6>
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
                    <input type="hidden" name="id_user" value="<?= $this->session->id_user ?>" />
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Password'); ?> Baru :</label>
                            <input type="hidden" name="passwordold" value="<?= decrypt_password($data->password); ?>">                                                        
                            <div class="input-group" id="show_hide_password">
                            <input type="password" name="password" id="password" class="form-control" required placeholder="Minimum 5 characters allowed" value="<?= decrypt_password($data->password); ?>">
                                <div class="input-group-addon">
                                    <a href="#"><i class="icon-eye-blocked" aria-hidden="true"></i></a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">                       
                    <div class="col-sm-6">
                        <div class="form-group">
                            <label><?= $this->lang->line('Repeat Password'); ?> Baru :</label>                            
                            <div class="input-group" id="show_hide_password_repeat">
                            <input type="password" name="repeat_password" class="form-control" required placeholder="<?= $this->lang->line('Repeat Password'); ?>" value="<?= decrypt_password($data->password); ?>">
                                <div class="input-group-addon">
                                    <a href="#"><i class="icon-eye-blocked" aria-hidden="true"></i></a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>      
                <div class="d-flex justify-content-start align-items-center">
                    <button type="button" id="submit" class="btn btn bg-<?= $this->color; ?> btn-sm"><i class="icon-paperplane"></i>&nbsp;
                        <?= $this->lang->line('Ubah'); ?></button>
                    <a href="<?= base_url($this->folder); ?>" class="btn btn bg-danger btn-sm ml-1"><i class="icon-arrow-left16"></i>&nbsp; <?= $this->lang->line('Kembali'); ?></a>
                </div>
            </div>
        </div>
       
    </form>
</div>
<!-- /task manager table -->