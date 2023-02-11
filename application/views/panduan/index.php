<!-- Content area -->
<div class="content">

    <div class="card">
        <div class="card-header border-<?= $this->color;?> bg-transparent header-elements-inline">
            <h6 class="card-title font-weight-semibold"><i class="icon-list2 mr-3 icon-1x"></i> List <?= $this->title; ?>
            </h6>
            <input type="hidden" value="<?= $this->folder; ?>" id="path">
            <div class="header-elements">
                <div class="list-icons">
                    <a class="list-icons-item" data-action="collapse"></a>
                    <a class="list-icons-item" data-action="reload"></a>
                    <a class="list-icons-item" data-action="remove"></a>
                </div>
            </div>
        </div>

        <div class="table-responsive">
            <div class="card-body">
                <table class="table table-sm table-borderless border">
                    <thead>
                        <tr>
                            <th>File Name</th>
                            <th class="text-right">Size</th>
                            <th class="text-center"><i class="icon-menu"></i></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php $i = 0;
                        foreach ($datafile->result() as $file) {
                            $i++;
                        ?>
                            <tr>
                                <td class="font-weight-bold"><i class="icon-file-pdf text-danger"></i> <?= $file->e_file_name; ?></td>
                                <td class="text-right"><? 
                                if (file_exists($file->file_path . $file->e_file_name)) {
                                    echo formatSize($file->file_path, $file->e_file_name); 
                                } else {
                                    echo "File Not Found";
                                }

                                if (file_exists($file->file_path . $file->e_file_name)) {
                                ?></td>

                                    <td class="text-center">
                                        <a title="View" href="<?= base_url() . $file->file_path . $file->e_file_name; ?>" target="_blank"><i class="icon-file-eye2 mr-1 text-primary-800"></i></a>
                                        <a title="Download" href="<?= base_url() . $file->file_path . $file->e_file_name; ?>" target="_blank" download><i class="icon-file-download2 text-success-800 mr-1"></i></a>
                                        <?php if (check_role($this->id_menu, 4)) { ?>
                                            <a title="Delete" href="#" onclick="hapusfile(<?= $file->id;?>,'<?= $file->e_file_name;?>','<?= $file->file_path; ?>'); return false;"><i class="icon-file-minus2 text-danger-800"></i></a>
                                        <?php } ?>
                                    </td>
                                <?php } ?>
                            </tr>
                        <?php } ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<!-- /task manager table -->