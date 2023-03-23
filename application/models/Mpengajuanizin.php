<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpengajuanizin extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT 	
                    ti.id, 
                    tji.e_izin_name,
                    tii.d_pengajuan_mulai, 
                    tii.d_pengajuan_selesai, 
                    tii.e_remark,
                    ti.f_status,
                    ti.d_approve,
                    ti.d_reject
                FROM tm_izin ti
                INNER JOIN tm_izin_item tii ON tii.id_izin = ti.id
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin 
                WHERE ti.f_status = 't'";

        // var_dump($sql);

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            /** status pending */
            $status = 'Wait';
            $color  = 'info';

            /** status reject */
            if ($data['d_reject'] != '') {
                $status = 'Not Active';
                $color  = 'danger';    
            }            

            /** status approve */
            if ($data['d_approve'] != '') {
                $status = 'Active';
                $color  = 'success';
            }

            $id = $data['id'];
            $cssClass = "class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'";
            // $onchange = "onclick='changestatus(\"".$this->folder."\",\"".$id."\");'";
            $button = "<button $cssClass>".$status."</button>";
            return $button;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $id = $data['id'];

            /** view */
            $link = base_url().$this->folder. '/view/' . encrypt_url($id);
            $button = "<a href='$link' title='View Data'><i class='icon-database-check text-success-800 ml-1'></i></a>";

            $link = base_url().$this->folder. '/Edit/' . encrypt_url($id);
            $button .= "<a href='$link' title='Edit Data'><i class='icon-database-edit2 text-warning-800 ml-1'></i></a>";

            $link = base_url().$this->folder. '/Approve/' . encrypt_url($id);
            $button .= "<a href='$link' title='Approval Data'><i class='icon-database-check text-info-800 ml-1'></i></a>";

            $link = base_url().$this->folder. '/Approve/' . encrypt_url($id);
            $button .= "<a href='$link' title='Reject Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
        
            return $button;        
        });

        /** hide some columns */
        $datatables->hide('d_approve');
        $datatables->hide('d_reject');

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
    public function save()
    {
        return;
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
        $data = [
            'id_user' => $id_user,
            'id_jenis_izin' => $id_jenis_izin
        ];
        $this->db->where('id', $id);
        $this->db->update('tm_izin', $data);
    }

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
                    tii.e_remark,
                    ti.f_status,
                    ti.d_approve,
                    ti.d_reject,
                    tu.e_nama,
                    ti.id_jenis_izin
                FROM tm_izin ti
                INNER JOIN tm_user tu ON tu.id_user = ti.id_user 
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin 
                INNER JOIN tm_izin_item tii ON tii.id_izin = ti.id                 
                WHERE ti.f_status = 't' AND ti.id = '$id'";

        // var_dump($sql); die();

        return $this->db->query($sql);
    }
    
}

/* End of file Mmaster.php */
