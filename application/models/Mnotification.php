<?php
defined('BASEPATH') OR exit('No direct script access allowed');
/* use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter; */

class Mnotification extends CI_Model {

    public $SALDO_AWAL = 'SALDO_AWAL';
    public $RETUR = 'RETUR';
    public $IZIN = 'IZIN';
    public $ADJUSMENT = 'ADJUSTMENT';

    /** saldo awal */
    protected function _sql($id_user, $e_type)
    {        
        $sql = "SELECT * 
                FROM tm_notification 
                WHERE e_type='$e_type'
                    AND f_status='f'
                    AND id_user='$id_user'";

        return $sql;
    }

    public function get_saldo_awal($id_user=null)
    {
        if ($id_user == null) {
            $id_user = $this->session->userdata('id_user');
        }

        $sql = $this->_sql($id_user, $this->SALDO_AWAL);
        
        $count = $this->db->query($sql)->num_rows();
        $result = $this->db->query($sql)->result();

        return [
            'count' => $count,
            'data' => $result
        ];
    }


}

/* End of file Mmaster.php */
