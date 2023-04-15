<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Auth extends CI_Controller
{

    public function index()
    {
        cek_login();
        $this->form_validation->set_rules('username', 'Username', 'trim|required|min_length[0]');
        $this->form_validation->set_rules('password', 'Password', 'trim|required|min_length[0]');

        if ($this->form_validation->run() == false) {
            $this->load->view('auth');
        } else {

            $username = strtoupper(trim($this->input->post('username', true)));
            $color    = $this->input->post('color', true).'-800';
            $password = encrypt_password(trim($this->input->post('password', true)));

            $user = $this->db->get_where('tm_user', ['upper(username)' => $username, 'password' => $password, 'f_status' => 't'])->row_array();

          
            if ($user) {
                $id_user = $user['id_user'];
                $user_company = $this->db->query("
                    select x.i_company, y.e_company_name 
                    from tm_user_company x
                    inner join tr_company y on (x.i_company = y.i_company)
                    where x.id_user = '$id_user' order by x.i_company asc limit 1
                ")->row_array();
                $data = array(
                    'id_user'       => $user['id_user'],
                    'e_name'        => $user['e_nama'],
                    'username'      => $user['username'],
                    'i_level'       => $user['i_level'],
                    'F_status'      => $user['f_status'],
                    'F_allcustomer' => $user['f_allcustomer'],
                    'i_company'     => $user_company['i_company'],
                    'e_company_name' => $user_company['e_company_name'],
                    'color'         => $color,
                    'language'         => 'indonesia',
                );

                $this->session->set_userdata($data);
                $this->logger->write('Login');
                /* redirect('main', 'refresh'); */
                redirect(site_url());
            } else {
                $this->session->Set_flashdata('message', '<div class="alert text-slate-800 alpha-slate border-0 alert-dismissible">
                <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
                <span class="font-weight-semibold">Username</span> atau <span class="font-weight-semibold">Password</span> anda salah :(</div>');
                redirect('auth', 'refresh');
            }
        }
    }

    public function logout()
    {
        $this->logger->write('Logout');
        $this->session->sess_destroy();
        redirect('auth', 'refresh');
    }

    public function set_company()
    {
        $data = array(
            'i_company' => $this->input->post('id'),
            'e_company_name' => $this->input->post('name'),
        );
        $this->session->set_userdata($data);
    }

    public function switch_language($language = "indonesia")
    {

        $this->session->set_userdata('language', $language);

        redirect(base_url(), 'refresh');
    }

    public function cron()
    {
        /** trigger cronjob via URL endpoint */
        $data = [
            'id_user' => 1,
            'ip_address' => 'localhost',
            'activity' => 'cronjob test'
        ];
        $this->db->insert('dg_log', $data);

        echo 'success';
    }
}
