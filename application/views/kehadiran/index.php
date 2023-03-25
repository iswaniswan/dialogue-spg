<style>
    .fc-icon-chevron-left::after, .fc-icon-chevron-right::after {
        content:  none !important;
    }
</style>

<!-- Content area -->
<div class="content">
    <div class="card">
        <div class="card-body">
            <div class="row">
                <div class="col-lg-4">
                    <table border="0" width="100%" style="border-collapse: separate;border-spacing: 0 15px !important">
                        <tbody>
                            <tr>
                                <td width="15%" bgcolor="#2baf2b"></td>
                                <td width="5%"></td>
                                <td width="80%">Hadir</td>
                            </tr>                            
                            <tr>
                                <td width="15%" bgcolor="#6a737b"></td>
                                <td width="5%"></td>
                                <td width="80%">Izin Tidak masuk</td>
                            </tr>
                            <tr>
                                <td width="15%" bgcolor="#ff6908"></td>
                                <td width="5%"></td>
                                <td width="80%">Izin Sakit</td>
                            </tr>
                            <tr>
                                <td width="15%" bgcolor="#6b0f24"></td>
                                <td width="5%"></td>
                                <td width="80%">Izin Terlambat</td>
                            </tr>
                            <tr>
                                <td width="15%" bgcolor="#97824b"></td>
                                <td width="5%"></td>
                                <td width="80%">Izin Pulang Sebelum Waktunya</td>
                            </tr>
                            <tr>
                                <td width="15%" bgcolor="#ff0000"></td>
                                <td width="5%"></td>
                                <td width="80%">Libur Nasional</td>
                            </tr>                                        
                        </tbody>
                    </table>  
                </div>

                <div class="col-lg-8">
                    <input type="hidden" id="id_menu" value="<?= $this->id_menu; ?>">
                    <input type="hidden" id="path" value="<?= $this->folder; ?>">
                    <div id="calendar"></div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- /modal -->
<div class="modal fade" id="modal-event" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-dark">
                <h5 class="modal-title" id="modal-title"></h5>
            </div>
            <div class="modal-body">
                <h6 class="font-weight-semibold">Jenis</h6>
                <span id="modal-jenis"></span>
                <hr>
                <h6 class="font-weight-semibold">Keterangan</h6>      
                <p><span id="modal-time_start_end"></span><br/><span id="modal-e_remark"></span></p>
                <hr>
                <h6 class="font-weight-semibold">Status</h6>  
                <p><span id="modal-status"></span><br/><span id="modal-e_remark_reject"></span></p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

