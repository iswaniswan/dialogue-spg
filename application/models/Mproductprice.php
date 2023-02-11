<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mproductprice extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        // if ($this->i_company=='1') {
        //     $where = " a.i_company is not null 
        //         /* a.i_company IN (
        //         SELECT 
        //             i_company
        //         FROM 
        //             tm_user_company
        //         WHERE 
        //             id_user = '$this->id_user'
        //     ) */
        //     ";
        // }else{
        //     $where = "
        //         a.i_company = '$this->i_company'
        //     ";
        // }

        if ($this->fallcustomer=='t') {
            $and = "";
        }else{
            $and = "
            WHERE
                a.id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        $datatables->query("SELECT 
                a.i_company,
                a.id_customer,
                c.e_company_name,
                d.e_customer_name,
                a.i_product,
                initcap(b.e_product_name) AS e_product,
                e.e_brand_name,
                a.v_price,
                CASE
                    WHEN a.d_update ISNULL THEN to_char(a.d_entry, 'dd-mm-yyyy HH12:MI:SS')
                    ELSE to_char(a.d_update, 'dd-mm-yyyy HH12:MI:SS')
                END AS d_update
            FROM
                tr_customer_price a
            INNER JOIN tr_product b ON
                (
                    b.i_product = a.i_product AND b.i_company = a.i_company
                )
            INNER JOIN tr_company c ON
                (
                    c.i_company = a.i_company
                )
            INNER JOIN tr_customer d ON
                (
                    d.id_customer = a.id_customer
                )
            INNER JOIN tr_brand e ON
                (
                    b.id_brand = e.id_brand
                )
            $and 
            GROUP BY
            1,2,3,4,5,b.e_product_name,6,7,8
            ORDER BY
                d_update,
                c.e_company_name,
                d.e_customer_name,
                b.e_product_name
        ", FALSE);

         $datatables->edit('v_price', function ($data) {
            $v_price         = $data['v_price'];
            $data = "Rp. ". number_format($v_price,0);
            return $data;
        });

        
            $datatables->add('action', function ($data) {
                $id         = trim($data['i_product']);
                $i_company  = $data['i_company'];
                $id_customer= $data['id_customer'];
                $data       = '';
                /** Cek Hak Akses, Apakah User Bisa Edit */
                if (check_role($this->id_menu, 3)) {
                    $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id).'/'.encrypt_url($i_company).'/'.encrypt_url($id_customer)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                }
                return $data;
            });
               
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
                /*AND i_company IN (
                    SELECT 
                        i_company
                    FROM 
                        tm_user_company
                    WHERE 
                        id_user = '$this->id_user'
                )*/
            ORDER BY 2
        ", FALSE);
    }

    /** Get Data Company */
    public function get_company($id)
    {
        return $this->db->query("
            SELECT 
                i_company
            FROM 
                tr_product 
            WHERE 
                i_product = '$id'
        ", FALSE);
    }

    public function get_customer_id($name){
        return $this->db->query("
            SELECT 
                id_customer
            FROM 
                tr_customer 
            WHERE 
                e_customer_name = '$name'
        ", FALSE);
    }

    /** Get Data Customer */
    public function get_customer($cari)
    {
        if ($this->fallcustomer=='t') {
            $where = "";
        }else{
            $where = "
                AND id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        return $this->db->query("
            SELECT 
                id_customer AS id,
                e_customer_name AS e_name
            FROM 
                tr_customer 
            WHERE 
                (e_customer_name ILIKE '%$cari%')
                AND f_status = 't'
                $where
            ORDER BY 2
        ", FALSE);
    }

    /** Get Data Product */
    public function get_product($cari)
    {
        return $this->db->query("
            SELECT 
                i_product AS id,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand,
                a.i_company AS idcompany,
                c.e_company_name AS company
            FROM 
                tr_product a
            INNER JOIN tr_brand b ON
                (b.id_brand = a.id_brand)
            INNER JOIN tr_company c ON
                (c.i_company = a.i_company)
            WHERE 
                (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
                AND a.f_status = 't'
                AND a.id_brand IN (SELECT id_brand FROM tm_user_brand WHERE id_user = $this->id_user)
            ORDER BY 4,1
        ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {
        $icustomer  = $this->input->post('icustomer', TRUE);
        $iproduct   = $this->input->post('iproduct', TRUE);
        $icompany   = $this->input->post('icompany', TRUE);
        $icompany   = explode(' - ',$iproduct);
        $iproduct   = $icompany[0];
        $icompany   = $icompany[1];
        $vprice     = $this->input->post('vprice', TRUE);
        $dentry     = date('Y-m-d');
        $this->db->query("INSERT INTO tr_customer_price (id_customer, i_company, i_product, v_price, d_entry) 
        VALUES ($icustomer, $icompany, '$iproduct', $vprice, '$dentry')
        ON CONFLICT (i_product, i_company, id_customer) DO UPDATE 
          SET v_price = excluded.v_price, 
              d_update = now()", FALSE);
    }

    public function update()
    {
        $icustomer  = $this->input->post('icustomer', TRUE);
        $iproduct   = $this->input->post('iproduct', TRUE);
        $icompany   = $this->input->post('icompany', TRUE);
        $icompany   = explode(' - ',$iproduct);
        $iproduct   = $icompany[0];
        $icompany   = $icompany[1];
        $vprice     = $this->input->post('vprice', TRUE);
        $dupdate    = date('Y-m-d');
        $data       = array(
            'v_price'       => $vprice,
            'd_update'      => $dupdate,
        );
        $this->db->where('i_product',$iproduct);
        $this->db->update('tr_customer_price',$data);
    }

    /** Get Data Untuk Edit */
    public function getdata($id, $i_company, $id_customer)
    {
        return $this->db->query("
            SELECT 
                a.*,d.e_customer_name, initcap(b.e_product_name) AS e_product_name, b.id_brand
            FROM
                tr_customer_price a
            INNER JOIN tr_product b ON
                (
                    b.i_product = a.i_product AND
                    b.i_company = a.i_company
                )
            INNER JOIN tr_customer d ON
                (
                    d.id_customer = a.id_customer
                )
            WHERE
               a. i_product = '$id'
               AND a.i_company = '$i_company'
               AND a.id_customer = '$id_customer'
        ", FALSE);
    }

    /** Export Data */
    public function exportdata()
    {
        return $this->db->query("SELECT 
        i_product,
        e_product_name, 
        0 AS v_price 
        FROM 
            tr_product
        WHERE
        f_status = 't'
        GROUP BY i_company,1,2
        ORDER BY 1
        ", FALSE);
    }

    public function cek_produk($i_product, $i_company)
    {
        $this->db->where('i_product',$i_product);
        $this->db->where('i_company',$i_company);
        return $this->db->get('tr_product');
    }

    public function cek_produk_eksis($iproduct,$icompany)
    {
        return $this->db->query("SELECT * FROM tr_customer_price WHERE i_product = '$iproduct' AND i_company = '$icompany'");

    }

    public function transfer()
    {
        $icustomer = $this->input->post('icustomer', TRUE);
        $jml = $this->input->post('jml', TRUE);
        for ($i=1; $i <= $jml; $i++) { 
            $iproduct   = $this->input->post('iproduct'.$i, TRUE);
            $icompany   = $this->input->post('icompany'.$i, TRUE);
            $vprice     = $this->input->post('vprice'.$i, TRUE);
            if ($iproduct!='') {
                $this->db->query("INSERT INTO tr_customer_price (id_customer, i_company, i_product, v_price, d_entry) 
                VALUES ($icustomer, $icompany, '$iproduct', $vprice, now())
                ON CONFLICT (id_customer, i_company, i_product) DO UPDATE 
                SET v_price = excluded.v_price, 
                    d_update = now()
                WHERE excluded.v_price > 0", FALSE);
            }
        }
    }

    public function delete($id)
    {
        $this->db->where('id_customer', $id);
        $this->db->delete('tr_customer_price');
    }
}

/* End of file Mmaster.php */
