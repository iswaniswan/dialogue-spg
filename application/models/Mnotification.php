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

    public function get_id_user_atasan($id_user)
    {
        $this->load->model('Muser');
        $user = $this->Muser->getdata($id_user);

        return $user->row()->id_atasan;
    }

    public function create_notification_saldo_awal($id_reff)
    {
        $id_user = $this->session->userdata('id_user');
        $id_atasan = $this->get_id_user_atasan($id_user);
        
        /** message ke SPG */
        $e_title = "Menunggu Approval";
        $e_message = "Data entry saldo awal berhasil disimpan.";
        $link = base_url() . "notification/read/$id_reff/$id_user";
        $link_redirect = base_url() . "saldo/view/" . encrypt_url($id_reff);
        $this->insert_notification($id_reff, $id_user, $e_title, $e_message, $link, $link_redirect);

        /** message ke Team Leader */
        $e_title = "Menunggu Approval";
        $e_message = "Permintaan persetujuan data Saldo awal.";
        $link = base_url() . "notification/read/$id_reff/$id_atasan";
        $link_redirect = base_url() . "saldo/approvement/" . encrypt_url($id_reff);
        $this->insert_notification($id_reff, $id_atasan, $e_title, $e_message, $link, $link_redirect);
    }

    public function insert_notification($id_reff, $id_user, $e_title, $e_message, $link, $link_redirect)
    {
        $data = [
            'id_user' => $id_user,
            'id_reff' => $id_reff,
            'e_type' => 'SALDO_AWAL',
            'e_title' => $e_title,
            'e_message' => $e_message,
            'link' => $link,
            'link_redirect' => $link_redirect
        ];

        $this->db->insert('tm_notification', $data);
    }

    public function test()
    {
        var_dump($this->session->userdata('i_level'));
    }

    public function get_data($id_reff, $id_user)
    {
        $sql = "SELECT * 
                FROM tm_notification
                WHERE id_reff='$id_reff' AND id_user='$id_user'";

        return $this->db->query($sql);
    }

    public function update_status($f_status=true, $id)
    {
        $data = [
            'f_status' => $f_status
        ];

        $this->db->where('id', $id);
        $this->db->update('tm_notification', $data);
    }

}

/* End of file Mmaster.php */
