<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Logger extends CI_Model {

    public function write($pesan)   
	{
		$ip_address = $_SERVER['REMOTE_ADDR'];
		$data = array(
			'id_user' 	 => $this->session->userdata('id_user'),
			'ip_address' => $ip_address,
			'waktu' 	 => current_datetime(),
			'activity' 	 => $pesan
		);
		$this->db->insert('dg_log', $data);
	}
}

/* End of file Logger.php */
