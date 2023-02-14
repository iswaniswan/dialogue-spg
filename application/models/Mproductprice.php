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

        $where = "";
        if (!$this->fallcustomer=='t') {
            $where = "WHERE a.id_customer IN (
                                    SELECT id_customer
                                    FROM tm_user_customer
                                    WHERE id_user = '$this->id_user'
                )";
        }

        $sql = "SELECT a.id, 
                        a.id_customer,
                        d.e_customer_name,
                        b.i_product,
                        initcap(b.e_product_name) AS e_product,
                        e.e_brand_name,
                        a.v_price,
                    CASE
                        WHEN a.d_update ISNULL THEN to_char(a.d_entry, 'dd-mm-yyyy HH12:MI:SS')
                        ELSE to_char(a.d_update, 'dd-mm-yyyy HH12:MI:SS')
                    END AS d_update
                FROM tr_customer_price a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_customer d ON d.id_customer = a.id_customer
                INNER JOIN tr_brand e ON b.id_brand = e.id_brand
                $where 
                GROUP BY 1, 2, 3, 4, 5, b.e_product_name, 6, 7
                ORDER BY d_update, d.e_customer_name, b.e_product_name";

        // var_dump($sql); die();

        $datatables->query($sql, FALSE);         
        
        $datatables->add('action', function ($data) {
            $id = $data['id'];
            $action = '';

            /** Cek Hak Akses, Apakah User Bisa Edit */
            if (check_role($this->id_menu, 3)) {
                $link = base_url().$this->folder . '/edit/' . encrypt_url($id);
                $class = "icon-database-edit2 text-".$this->color."-800";
                $action = "<a href='$link' title='Edit Data'><i class='$class'></i></a>";
            }

            return $action;
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

    /** Get Data Customer by user cover */
    public function get_customer($cari='')
    {
        $id_user = $this->session->userdata('id_user');

        $limit = "LIMIT 5";
        if ($cari != '') {
            $limit = "";
        }

        $sql = "SELECT id_customer AS id, e_customer_name AS e_name
                FROM tr_customer 
                WHERE (e_customer_name ILIKE '%$cari%') AND f_status = 't' 
                    AND id_customer IN (
                                        SELECT  id_customer
                                        FROM tm_user_customer
                                        WHERE id_user = '$id_user'                
                                    )
                ORDER BY 2
                $limit";

        // var_dump($sql);

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Product sesuai user cover */
    public function get_product($cari='', $id_customer)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = 'LIMIT 5';
        if ($cari != '') {
            $limit = "";
        }

        $sql_brand_cover = "SELECT DISTINCT tub.id_brand 
                            FROM tm_user_brand tub 
                            INNER JOIN tm_user_customer tuc ON tuc.id = tub.id_user_customer
                            WHERE tuc.id_user = '$id_customer'";

        $sql = "SELECT a.id,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
                AND a.f_status = 't'
                AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4,1
            $limit";

        // var_dump($sql); die();

        return $this->db->query($sql, FALSE);
    }

    /** Simpan Data */
    public function save()
    {
        $id_customer  = $this->input->post('id_customer', TRUE);
        $id_product   = $this->input->post('id_product', TRUE);
        $vprice     = $this->input->post('vprice', TRUE);

        $product = array(
            'id_product' => $id_product,
            'id_customer' => $id_customer,
            'v_price' => $vprice,
            'd_entry' => current_datetime(),
        );
        
        $this->db->insert('tr_customer_price', $product);
    }

    public function update()
    {
        $id = $this->input->post('id');
        $id_customer  = $this->input->post('id_customer', TRUE);
        $id_product   = $this->input->post('id_product', TRUE);
        
        $vprice     = $this->input->post('vprice', TRUE);
        $dupdate    = date('Y-m-d');
        $data       = [
            'v_price'=> $vprice,
            'd_update' => $dupdate,
        ];

        if (@$id_customer != null) {
            $data['id_customer'] = $id_customer;
        }

        if (@$id_product != null) {
            $data['id_product'] = $id_product;
        }

        $this->db->where('id', $id);
        $this->db->update('tr_customer_price', $data);
    }

    /** Get Data Untuk Edit */
    public function getdata($id, $i_company, $id_customer)
    {
        $sql = "SELECT a.*,d.e_customer_name, initcap(b.e_product_name) AS e_product_name, b.id_brand, b.i_product
                FROM tr_customer_price a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_customer d ON d.id_customer = a.id_customer
                WHERE a.id = '$id'";

        return $this->db->query($sql, FALSE);
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

    public function is_customer_price_exist($id_product, $id_customer)
    {
        $sql = "SELECT * FROM tr_customer_price WHERE id_product = '$id_product' AND id_customer = '$id_customer'";
        $query = $this->db->query($sql);
        return $query->num_rows() > 0;
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
