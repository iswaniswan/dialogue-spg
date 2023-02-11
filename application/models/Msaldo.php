<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Msaldo extends CI_Model
{

    /** List Datatable */
    public function serverside()
    {
        $datatables = new Datatables(new CodeigniterAdapter);
        if ($this->fallcustomer == 't') {
            $and = "";
        } else {
            $and = "
                WHERE a.id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        $datatables->query("SELECT
                a.id,
                a.id_customer,
                b.e_customer_name,
                i_periode,
                d_approve,
                e_remark,
                a.f_status
            FROM
                tm_mutasi_saldoawal a
            INNER JOIN tr_customer b ON
                (a.id_customer = b.id_customer)
            $and
        ", FALSE);

        $datatables->edit('f_status', function ($data) {
            if ($data['f_status'] == 't') {
                $status = 'Active';
                $color  = 'success';
            } else {
                $status = 'Not Active';
                $color  = 'danger';
            }
            $data = "<span class='btn btn-sm badge rounded-round alpha-" . $color . " text-" . $color . "-800 border-" . $color . "-600 legitRipple'>" . $status . "</span>";
            return $data;
        });

        $datatables->edit('d_approve', function ($data) {
            $status = $data['f_status'];
            if ($status == 't') {
                if ($data['d_approve'] == '' || $data['d_approve'] == null) {
                    $status = 'Menunggu Approve';
                    $color  = 'warning';
                } else {
                    $status = 'Sudah di Approve';
                    $color  = 'info';
                }
            } else {
                $status = 'Dibatalkan';
                $color  = 'orange';
            }
            $data = "<span class='btn btn-sm badge rounded-round alpha-" . $color . " text-" . $color . "-800 border-" . $color . "-600 legitRipple'>" . $status . "</span>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        // if (check_role($this->id_menu, 3)) {
            $datatables->add('action', function ($data) {
                $id        = trim($data['id']);
                $d_approve = trim($data['d_approve']);
                $i_periode = trim($data['i_periode']);
                $id_customer = trim($data['id_customer']);
                $status    = $data['f_status'];
                /* $i_company  = $data['i_company'];
                $id_customer= $data['id_customer']; */
                $data       = '';
                if (check_role($this->id_menu, 3) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                    $data      .= "<a href='" . base_url() . $this->folder . '/edit/' . encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "' title='Edit Data'><i class='icon-database-edit2 mr-1 text-" . $this->color . "-800'></i></a>";
                }
                if (check_role($this->id_menu, 5) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                    $data      .= "<a href='" . base_url() . $this->folder . '/approvement/'. encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "'  title='Approve Data'><i class='icon-database-check text-teal-800 mr-1'></i></a>";
                }
                if (check_role($this->id_menu, 4) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                    $data      .= "<a href='#' onclick='sweetcancel(\"" . $this->folder . "\",\"" . $id . "\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 mr-1'></i></a>";
                }
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "' title='View Data'><i class='icon-eye text-light-800 mr-1'></i></a>";
                return $data;
            });
        // }
        $datatables->hide('id_customer');
        return $datatables->generate();
    }

    /** Get Data Company */
    public function get_company_data()
    {
        return $this->db->query("
            SELECT 
                i_company,
                e_company_name
            FROM 
                tr_company 
            WHERE 
                f_status = 't'
                AND db_name IS NOT NULL
                AND i_company IN (
                    SELECT 
                        i_company
                    FROM 
                        tm_user_company
                    WHERE 
                        id_user = '$this->id_user'
                )
            ORDER BY 2
        ", FALSE);
    }

    /** Ambil Data Customer */
    public function get_customer($cari)
    {
        if ($this->fallcustomer == 't') {
            $where = "";
        } else {
            $where = "AND id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        return $this->db->query("SELECT
                id_customer as id,
                e_customer_name as e_name
            FROM
                tr_customer
            WHERE
                (e_customer_name ILIKE '%$cari%')
                AND f_status = 't'
                $where
            ORDER BY
                e_customer_name ASC
        ", FALSE);
    }

    /** Get Data Product */
    public function get_product($cari)
    {
        return $this->db->query("
            SELECT 
                a.i_product AS id,
                a.e_product_name AS e_name,
                c.e_brand_name,
                a.id_brand
            FROM 
                tr_product a
            INNER JOIN tr_brand c ON
                (c.id_brand = a.id_brand)
            WHERE 
                (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
                AND a.f_status = 't'
                AND a.id_brand IN (SELECT id_brand FROM tm_user_brand WHERE id_user = $this->id_user)
            ORDER BY 3,1
        ", FALSE);
    }

    /** Ambil Data Detail Product */
    public function get_detail_product($i_product,$i_brand/* , $i_company */)
    {
        return $this->db->query("SELECT
        initcap(a.e_product_name) AS e_product_name,
        a.id_brand,
        c.e_brand_name, 
        a.i_company,
        b.e_company_name
    FROM
        tr_product a
    INNER JOIN
        tr_company b ON (b.i_company = a.i_company)
    INNER JOIN
        tr_brand c ON (c.id_brand = a.id_brand)
    WHERE
        b.i_company = a.i_company
        AND a.i_product = '$i_product'
        AND a.id_brand = '$i_brand'
        ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {

        $query = $this->db->query("SELECT max(id) AS id FROM tm_mutasi_saldoawal", TRUE);
		if ($query->num_rows() > 0) {
			$id = $query->row()->id;
			if ($id == null) {
				$id = 1;
			} else {
				$id = $id + 1;
			}
		} else {
			$id = 1;
		}

        $table = array(
            'id'                        => $id,
            'id_customer'               => $this->input->post('icustomer', TRUE),
            'i_periode'                 => $this->input->post('periode', TRUE),
            'e_remark'                  => $this->input->post('eremark', TRUE),
        );
        $this->db->insert('tm_mutasi_saldoawal', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $i_product = $product[0];
                $tabledetail = array(
                    'id_header'         => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $i_product,
                    'n_saldo'           => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                );
                $this->db->insert('tm_mutasi_saldoawal_item', $tabledetail);
                $i++;
            };
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
               *
            FROM
                tm_mutasi_saldoawal
            WHERE
               id = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("SELECT
                a.*,
                b.e_product_name AS e_product,
                c.id_brand,
                c.e_brand_name AS brand,
                d.e_company_name AS e_company,
                a.n_saldo AS qty
            FROM
                tm_mutasi_saldoawal_item a
            INNER JOIN tr_product b ON
                (b.i_product = a.i_product
                    AND b.i_company = a.i_company)
            INNER JOIN tr_brand c ON
                (c.id_brand = b.id_brand)
            INNER JOIN tr_company d ON
                (d.i_company = a.i_company)
            WHERE a.id_header = '$id'
            ORDER BY a.i_product
        ", FALSE);
    }

    /** Export Data */
    public function exportdata()
    {
        /* if ($this->i_company == '1') {
            $where = "AND i_company IN (SELECT i_company FROM tm_user_company WHERE id_user = '$this->id_user' )";
        }else{
            $where = "AND i_company = '$this->i_company'";
        } */
        return $this->db->query("
            SELECT
                a.i_company,
                e_company_name,
                i_product,
                e_product_name,
                e_brand_name,
                0 AS n_saldo
            FROM
                tr_product a
            INNER JOIN tr_brand b on (a.id_brand = b.id_brand)
            INNER JOIN tr_company c ON (c.i_company = a.i_company)
            where a.f_status = 't' and b.id_brand in (select id_brand from tm_user_brand where id_user = '$this->id_user')
            ORDER BY 1,3
        ", FALSE);
    }

    public function cek_produk($i_product, $i_company)
    {
        $this->db->where('i_product', $i_product);
        $this->db->where('i_company', $i_company);
        return $this->db->get('tr_product');
    }

    public function transfer()
    {
        $query = $this->db->query("SELECT max(id)+1 AS id FROM tm_mutasi_saldoawal", TRUE);
        if ($query->num_rows() > 0) {
            $id = $query->row()->id;
            if ($id == null) {
                $id = 1;
            } else {
                $id = $id;
            }
        } else {
            $id = 1;
        }
        $id_customer = $this->input->post('id_customer', TRUE);
        $i_periode = $this->input->post('i_periode', TRUE);
        $e_remark = $this->input->post('e_remark', TRUE);

        $this->db->query("INSERT INTO tm_mutasi_saldoawal (id, id_customer, i_periode, e_remark, d_entry) 
                VALUES ($id, $id_customer, '$i_periode', '$e_remark', now())
                ON CONFLICT (id_customer, i_periode) DO UPDATE 
                SET e_remark = excluded.e_remark,
                    d_update = now()", FALSE);

        $jml = $this->input->post('jml', TRUE);
        for ($i = 1; $i <= $jml; $i++) {
            $i_company   = $this->input->post('i_company' . $i, TRUE);
            $iproduct   = $this->input->post('iproduct' . $i, TRUE);
            $qty     = $this->input->post('qty' . $i, TRUE);
            if ($iproduct != '') {
                $this->db->query("INSERT INTO tm_mutasi_saldoawal_item (id_header, i_company, i_product, n_saldo) 
                VALUES ($id, $i_company, '$iproduct', $qty)
                ON CONFLICT (id_header, i_company, i_product) DO UPDATE 
                SET n_saldo = excluded.n_saldo
                WHERE excluded.n_saldo > 0", FALSE);
            }
        }
    }

    public function update_detail()
    {
        $id = $this->input->post('id', TRUE);
        $id_customer = $this->input->post('id_customer', TRUE);
        $i_periode = $this->input->post('i_periode', TRUE);
        $e_remark = $this->input->post('e_remark', TRUE);

        $this->db->query("INSERT INTO tm_mutasi_saldoawal (id, id_customer, i_periode, e_remark, d_entry) 
                VALUES ($id, $id_customer, '$i_periode', '$e_remark', now())
                ON CONFLICT (id_customer, i_periode) DO UPDATE 
                SET e_remark = excluded.e_remark,
                    d_update = now()", FALSE);

        $jml = $this->input->post('jml', TRUE);
        $this->db->where('id_header', $id);
        $this->db->delete('tm_mutasi_saldoawal_item');

        if ($jml > 0) {
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $iproduk = $product[0];
                $tabledetail = array(
                    'id_header'         => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $iproduk,
                    'n_saldo'           => $this->input->post('qty', TRUE)[$i],
                );
                $this->db->insert('tm_mutasi_saldoawal_item', $tabledetail);
                $i++;
            };
        };
    }

    public function update_header($id){
        $this->db->set('d_approve', '');
        $this->db->where('id', $id);
        $this->db->update('tm_mutasi_saldoawal');
    }

    public function cancel($id)
    {

        $this->db->query("DELETE FROM tm_mutasi_saldoawal_item where id_header = '$id'");
        $this->db->query("DELETE FROM tm_mutasi_saldoawal where id = '$id'");

    }

    public function approve($id)
    {
        $data = array(
            'i_approve' => $this->id_user,
            'd_approve' => date('Y-m-d'),
        );
        $this->db->where('id', $id);
        $this->db->update('tm_mutasi_saldoawal', $data);
    }
}

/* End of file Mmaster.php */
