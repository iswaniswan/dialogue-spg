<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpengajuanizin extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom, $dto){
        $current_user = $this->session->userdata('id_user');
        $current_level = $this->session->userdata('i_level');

        $where_and = " AND ti.id_user = '$current_user'";        
        $all_bawahan = $this->get_all_bawahan_id();
        if ($all_bawahan != false) {
            $where_and .= " OR ti.id_user IN ($all_bawahan) ";
        }

        if ($current_level == 1) {
            $where_and = '';
        }

        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT 	
                    ti.id, 
                    ti.id_user,                    
                    tu.e_nama,
                    tu.id_atasan,
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
                WHERE ti.f_status = 't'  
                    AND to_char(ti.d_pengajuan_mulai, 'YYYY-MM-DD HH24:MI') BETWEEN '$dfrom' AND '$dto'                  
                    $where_and
                ORDER BY ti.d_pengajuan_mulai ASC";   
                
        // var_dump($sql); die();

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $id_user = $data['id_user'];
            $atasan = $this->get_user_atasan($id_user);
            $nama_atasan = "";
            if ($atasan->row() != null) {
                $nama_atasan = $atasan->row()->e_nama;
            }

            /** status pending */
            $status = "Wait Approval $nama_atasan";
            $color  = 'info';

            /** status reject */
            if ($data['d_reject'] != '') {
                $status = 'Rejected, ' . $data['e_remark_reject'];
                $color  = 'danger';    
            }            

            /** status approve */
            if ($data['d_approve'] != '') {
                $status = 'Approve';
                $color  = 'success';
            }

            $id = $data['id'];
            $cssClass = "class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'";
            // $onchange = "onclick='changestatus(\"".$this->folder."\",\"".$id."\");'";
            $button = "<button $cssClass>".$status."</button>";
            return $button;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) use ($current_user) {
            $id = $data['id'];
            $id_atasan = $data['id_atasan'];

            /** view */
            $link = base_url().$this->folder. '/view/' . encrypt_url($id);
            $button = "<a href='$link' title='View Data'><i class='icon-database-check text-success-800 ml-1'></i></a>";

            if ($data['d_approve'] != null or $data['d_reject'] != null) {
                return $button;
            }

            if ($current_user == $id_atasan) {
                /* approve */
                $link = base_url().$this->folder. '/Approvement/' . encrypt_url($id);
                $button .= "<a href='$link' title='Approval Data'><i class='icon-database-check text-info-800 ml-1'></i></a>";
                
                return $button;
            }

            $link = base_url().$this->folder. '/Edit/' . encrypt_url($id);
            $button .= "<a href='$link' title='Edit Data'><i class='icon-database-edit2 text-warning-800 ml-1'></i></a>";                        

            $link = base_url().$this->folder. '/Cancel/' . encrypt_url($id);
            $onclick = "_sweetcancel(\"$link\", $id);";
            $button .= "<a href='#' title='Batal' onclick='$onclick'><i class='icon-database-remove text-danger-800 ml-1 confirm'></i></a>";

            return $button;        
        });

        /** hide some columns */
        $datatables->hide('d_approve');
        $datatables->hide('d_reject');
        $datatables->hide('id_user');
        $datatables->hide('id_atasan');
        $datatables->hide('e_remark_reject');

        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tr_jenis_izin');
        $this->db->where('id', $id);
        $query = $this->db->get();
        if ($query->num_rows()>0) {
            $status = $query->row()->f_status;
        }else{
            $status = 'f';
        }
        if ($status=='f') {
            $fstatus = 't';
        }else{
            $fstatus = 'f';
        }
        $table = array(
            'f_status' => $fstatus, 
        );
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($etype)
    {
        return $this->db->query("
            SELECT 
                e_izin_name
            FROM 
                tr_jenis_izin 
            WHERE 
                trim(upper(e_izin_name)) = trim(upper('$etype'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($id_user, $id_jenis_izin, $d_pengajuan_mulai, $d_pengajuan_selesai, $e_remark)
    {
        $data = [
            'id_user' => $id_user,
            'id_jenis_izin' => $id_jenis_izin,
            'd_pengajuan_mulai' => $d_pengajuan_mulai,
            'd_pengajuan_selesai' => $d_pengajuan_selesai,
            'e_remark' => $e_remark
        ];
        $this->db->insert('tm_izin', $data);
    }

    /** update data */
    public function update($id_user, $id_jenis_izin, $d_pengajuan_mulai, $d_pengajuan_selesai, $e_remark, $id)
    {
        $data = [
            'id_user' => $id_user,
            'id_jenis_izin' => $id_jenis_izin,
            'd_pengajuan_mulai' => $d_pengajuan_mulai,
            'd_pengajuan_selesai' => $d_pengajuan_selesai,
            'e_remark' => $e_remark
        ];
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);
    }

    public function insert_izin($id_user, $id_jenis_izin)
    {
        $data = [
            'id_user' => $id_user,
            'id_jenis_izin' => $id_jenis_izin
        ];
        $this->db->insert('tm_izin', $data);
    }

    public function update_izin($id_user, $id_jenis_izin, $id)
    {
        $d_update = date('Y-m-d H:i:s');

        $data = [
            'id_user' => $id_user,
            'id_jenis_izin' => $id_jenis_izin,
            'd_update' => $d_update
        ];
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);
    }

    /**
    public function insert_izin_item($id_izin, $d_pengajuan_mulai, $d_pengajuan_selesai, $e_remark)
    {
        $data = [
            'id_izin' => $id_izin,
            'd_pengajuan_mulai' => $d_pengajuan_mulai,
            'd_pengajuan_selesai' => $d_pengajuan_selesai,
            'e_remark' => $e_remark
        ];
        $this->db->insert('tm_izin_item', $data);        
    }

    public function delete_izin_item($id_izin)
    {
        $this->db->where('id_izin', $id_izin);
        $this->db->delete('tm_izin_item');
    }

    */

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_jenis_izin 
            WHERE
                id = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($etype,$etypeold)
    {
        return $this->db->query("
            SELECT 
                e_izin_name
            FROM 
                tr_jenis_izin 
            WHERE 
                trim(upper(e_izin_name)) <> trim(upper('$etypeold'))
                AND trim(upper(e_izin_name)) = trim(upper('$etype'))
        ", FALSE);
    }


    public function get_list_jenis_izin($cari='')
    {
        $sql = "SELECT id, e_izin_name
                FROM tr_jenis_izin
                WHERE (e_izin_name ILIKE '%$cari%')
                    AND f_status = 't'
                ORDER BY e_izin_name ASC";

        return $this->db->query($sql, FALSE);
    }

    public function get_data($id)
    {
        $sql = "SELECT 
                    ti.id, 
                    tji.e_izin_name, 
                    d_pengajuan_mulai, 
                    d_pengajuan_selesai, 
                    ti.e_remark,
                    ti.e_remark_reject,
                    ti.f_status,
                    ti.d_approve,
                    ti.d_reject,
                    tu.e_nama,
                    ti.id_jenis_izin
                FROM tm_izin ti
                INNER JOIN tm_user tu ON tu.id_user = ti.id_user 
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin 
                WHERE ti.f_status = 't' AND ti.id = '$id'";

        // var_dump($sql); die();

        return $this->db->query($sql);
    }

    /** Approve */
    public function approve($id)
    {
        $d_approve = date('Y-m-d H:i:s');
        $id_user_atasan = $this->session->userdata('id_user');

        $data = array(
            'd_approve' => $d_approve,
            'id_user_atasan' => $id_user_atasan 
        );
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);
   
    }

    /** Reject */
    public function reject($id, $text=null)
    {
        $d_reject = date('Y-m-d H:i:s');
        $id_user_atasan = $this->session->userdata('id_user');

        $data = array(
            'd_reject' => $d_reject, 
            'id_user_atasan' => $id_user_atasan,
            'e_remark_reject' => $text
        );
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);
    }

    /** Reject */
    public function cancel($id)
    {
        $data = array(
            'f_status' => 'f',
        );
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);   
    }

    public function get_all_bawahan_id()
    {
        $id_user = $this->session->userdata('id_user');
        $i_level = $this->session->userdata('i_level');

        $all_spg = "SELECT id_user FROM tm_user tu WHERE i_level = 2 AND id_atasan = '$id_user'";
        $all_team_leader = "SELECT id_user FROM tm_user WHERE i_level = 5";
        $all_marketing = "SELECT id_user FROM tm_user WHERE i_level = 4";

        /** team leader */
        if ($i_level == 5) {
            return $all_spg;
        }

        return false;
    }

    public function get_user_atasan($id_user)
    {
        $sql = "SELECT * FROM tm_user WHERE id_user = (
            SELECT id_atasan FROM tm_user WHERE id_user = $id_user
        )";

        return $this->db->query($sql);
    }

    public function get_all_waiting_izin($count=true)
    {
        $current_user = $this->session->userdata('id_user');

        $sql = "SELECT * FROM tm_izin ti
                WHERE d_approve IS NULL AND d_reject IS NULL 
                AND id_user IN (
                                SELECT id_user FROM tm_user WHERE id_atasan = '$current_user'
                                )";

        if ($count) {
            return $this->db->query($sql)->count();
        }

        return $this->db->query($sql);
    }

    public function export_excel($dfrom, $dto)
    {
        $current_user = $this->session->userdata('id_user');
        $current_level = $this->session->userdata('i_level');

        $where_and = " AND ti.id_user = '$current_user'";        
        $all_bawahan = $this->get_all_bawahan_id();
        if ($all_bawahan != false) {
            $where_and .= " OR ti.id_user IN ($all_bawahan) ";
        }

        if ($current_level == 1) {
            $where_and = '';
        }

        $sql = "SELECT 	
                    ti.id, 
                    ti.id_user,                    
                    tu.e_nama,
                    tu.id_atasan,
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
                WHERE ti.f_status = 't'  
                    AND to_char(ti.d_pengajuan_mulai, 'YYYY-MM-DD HH24:MI') BETWEEN '$dfrom' AND '$dto'                  
                    $where_and
                ORDER BY ti.d_pengajuan_mulai ASC"; 
        
        return $this->db->query($sql);
    }

}

/* End of file Mmaster.php */
