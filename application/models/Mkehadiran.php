<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mkehadiran extends CI_Model {

    public function get_all_izin($id_user)
    {        
        $sql = "SELECT 	
                    ti.id, 
                    ti.id_user,                    
                    tu.e_nama,
                    tu.id_atasan,
                    ti.id_jenis_izin,
                    tji.e_izin_name,
                    ti.d_pengajuan_mulai, 
                    ti.d_pengajuan_selesai, 
                    ti.e_remark,
                    ti.e_remark_reject,
                    ti.f_status,
                    ti.d_approve,
                    ti.d_reject
                FROM tm_izin ti
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin 
                INNER JOIN tm_user tu ON tu.id_user = ti.id_user
                WHERE ti.f_status = 't' and ti.id_user = '$id_user'
                    AND (ti.d_approve IS NOT NULL OR ti.d_reject IS NOT NULL)";

        return $this->db->query($sql);
    }

}

/* End of file Mmaster.php */
