<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Notification extends CI_Controller
{

    public function __construct()
    {
        parent::__construct();
		cek_session();

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('Mnotification', 'mymodel');
        $this->load->library('user_agent');
    }

    public function index()
    {

    }

    public function read()
    {
        $id_reff = $this->uri->segment(3);
        $id_user = $this->uri->segment(4);

        $query = $this->mymodel->get_data($id_reff, $id_user)->row();

        $this->mymodel->update_status($f_status=true, $query->id);

        $link_redirect = $query->link_redirect;
        
        redirect($link_redirect);
    }

    public function test()
    {
        $this->mymodel->test();
    }

}
