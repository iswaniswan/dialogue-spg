<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mizin extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT id, 
                    INITCAP(e_izin_name) e_izin_name, 
                    f_status 
                FROM tr_jenis_izin";

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $status = 'Not Active';
            $color  = 'danger';
            if ($data['f_status']=='t') {
                $status = 'Active';
                $color  = 'success';
            }

            $id = $data['id'];
            $cssClass = "class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'";
            $onchange = "onclick='changestatus(\"".$this->folder."\",\"".$id."\");'";
            $data = "<button $cssClass $onchange>".$status."</button>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        if (check_role($this->id_menu, 3)) {
            $datatables->add('action', function ($data) {
                $id = trim($data['id']);
                $data = '';

                $link = base_url().$this->folder. '/edit/' . encrypt_url($id);
                $data .= "<a href='$link' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                return $data;
            });
        }        
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
        $this->db->update('tr_jenis_izin', $table);
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
    public function save($e_izin_name)
    {
        $data = [
            'e_izin_name' => $e_izin_name
        ];
        $this->db->insert('tr_jenis_izin', $data);
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

    /** Update Data */
    public function update($e_izin_name, $id)
    {
        $data = array(
            'e_izin_name' => $e_izin_name, 
        );
        $this->db->where('id', $id);
        $this->db->update('tr_jenis_izin', $data);
    }

}

/* End of file Mmaster.php */
