<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpembelian extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom,$dto){
        $datatables = new Datatables(new CodeigniterAdapter);
        if ($this->fallcustomer == 'f') {
            $where = "
                AND b.id_customer IN (
                    SELECT 
                        id_customer
                    FROM 
                        tm_user_customer
                    WHERE 
                        id_user = '$this->id_user'
                )
            ";
        }else{
            $where = "";
        }

        /*
        if ($this->i_company=='all') {
            $and = "
                AND a.i_company IN (
                SELECT 
                    i_company
                FROM 
                    tm_user_company
                WHERE 
                    id_user = '$this->id_user'
            )
            ";
        }else{
            $and = "
                AND a.i_company = '$this->i_company'
            ";
        }
        */
        $datatables->query("SELECT
                DISTINCT id_document,
                e_company_name,
                i_document,
                d_receive,
                c.e_customer_name,
                a.e_remark, 
                a.f_status
            FROM
                tm_pembelian a
            INNER JOIN tr_customer_item b ON
                (
                    b.id_item = a.id_item
                )
            INNER JOIN tr_customer c ON
                (
                    c.id_customer = b.id_customer
                ) 
            INNER JOIN tr_company d ON
                (
                    d.i_company = a.i_company
                ) 
            WHERE 
                d_receive BETWEEn '$dfrom' 
                AND '$dto' 
                $where
            ORDER BY d_receive, i_document ASC
            ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_document'];
            if ($data['f_status']=='t') {
                $status = 'Aktif';
                $color  = 'success';
            }else{
                $status = 'Batal';
                $color  = 'danger';
            }
            $data = "<button class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'>".$status."</button>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $id         = trim($data['id_document']);
            $ddocument  = $data['d_receive'];
            $month      = date('m', strtotime($ddocument));
            $bulan      = date('m');
            $batas      = date('Y-m-06');
            $tgl        = date('Y-m-d');
            $cek        = $bulan-$month;
            $status     = $data['f_status'];
            $data       = '';
            /* if (check_role($this->id_menu, 3) && $status=='t') {
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
            }     */

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }
            
            if (check_role($this->id_menu, 4) && $status=='t') {
                if($month == $bulan && $ddocument <= $batas && $tgl <= $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
                else if($ddocument > $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
                else if($cek == 1 && $tgl <= $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
            }
            return $data;
        });
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

    /** Simpan Data */
    public function save()
    {
        $icompany   = $this->input->post('icompany', TRUE);
        $dfrom      = $this->input->post('dfrom', TRUE);
        $dto        = $this->input->post('dto', TRUE);
        $eremark    = $this->input->post('eremark', TRUE);
        $this->db->where('i_company',$icompany);
        $query      = $this->db->get('tr_company')->row();
        $Url        = $query->db_address;
        $User       = $query->db_user;
        $Password   = $query->db_password;
        $DbName     = $query->db_name;
        $Port       = $query->db_port;
        $Jenis      = $query->jenis_company;
        if ($Jenis=='produksi') {
            $dbexternalna = "
                SELECT
                    i_customer,
                    i_do AS i_sj,
                    trim(i_do_code) AS i_sj_code,
                    d_accept AS d_sj_receive
                FROM
                    tm_do
                WHERE
                    d_accept BETWEEN '$dfrom' AND '$dto'
                    AND f_do_cancel = 'f'
                ORDER BY
                    i_do_code
            ";
        }else{
            $dbexternalna = "
                SELECT
                    i_customer,
                    i_sj,
                    i_sj AS i_sj_code,
                    d_sj_receive
                FROM
                    tm_nota
                WHERE
                    d_sj_receive BETWEEN '$dfrom' AND '$dto'
                    AND f_nota_cancel = 'f'
                ORDER BY
                    i_sj
            ";
        }

        $header = $this->db->query("
            SELECT
                x.*,
                y.id_item
            FROM
                (
                SELECT
                    *
                FROM
                    dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                    $$ $dbexternalna $$) AS get_product ( i_customer CHARACTER VARYING(6),
                    i_sj CHARACTER VARYING(20),
                    i_sj_code CHARACTER VARYING(20),
                    d_receive date ) ) x
            INNER JOIN tr_customer_item y ON
                (
                    y.i_customer = x.i_customer
                )
            ORDER BY
                2,
                3 ASC
        ", FALSE);
        if ($header->num_rows()>0) {
            foreach ($header->result() as $key) {
                $this->db->query("INSERT INTO tm_pembelian (id_item, i_document, d_receive, e_remark, d_entry, id_user, i_company) 
                VALUES ($key->id_item, '$key->i_sj_code', '$key->d_receive', '$eremark', now(), $this->id_user, $icompany)
                ON CONFLICT (id_item, i_company, i_document) DO UPDATE 
                SET d_receive = excluded.d_receive,
                    e_remark = excluded.e_remark, 
                    id_user = excluded.id_user, 
                    d_update = now()", FALSE);
                if ($Jenis=='produksi') {
                    $eksternal = "
                        SELECT
                            i_product,
                            e_product_name,
                            n_deliver AS n_qty,
                            v_unitprice AS v_price
                        FROM
                            tm_do_item
                        WHERE
                            i_do = '$key->i_sj'
                        ORDER BY
                            i_do
                    ";
                }else{
                    $eksternal = "
                        SELECT
                            i_product,
                            e_product_name,
                            n_deliver AS n_qty,
                            v_unit_price AS v_price
                        FROM
                            tm_nota_item
                        WHERE
                            i_sj = '$key->i_sj'
                        ORDER BY
                            i_sj
                    ";
                }
                $query = $this->db->query("SELECT id_document AS id FROM tm_pembelian WHERE i_document = '$key->i_sj_code' AND i_company = '$icompany' ", TRUE);
                if ($query->num_rows() > 0) {
                    $id = $query->row()->id;
                    if ($id == null) {
                        die;
                    } else {
                        $id = $id;
                    }
                } else {
                    die;
                }
                $this->db->query("
                    INSERT INTO tm_pembelian_item (id_document, i_company, i_product, e_product_name, n_qty, v_price)
                    SELECT
                        $id AS id_document,
                        $icompany AS i_company,
                        i_product,
                        e_product_name,
                        n_qty,
                        v_price
                    FROM
                        (
                        SELECT
                            *
                        FROM
                            dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                            $$ $eksternal $$) AS get_product ( 
                                i_product CHARACTER VARYING(11),
                                e_product_name CHARACTER VARYING(150),
                                n_qty NUMERIC,
                                v_price NUMERIC ) 
                        ) x
                    ORDER BY
                        2,
                        1 ASC
                    ON CONFLICT (id_document, i_company, i_product) DO UPDATE 
                        SET e_product_name = excluded.e_product_name, 
                            n_qty = excluded.n_qty, 
                            v_price = excluded.v_price
                ", FALSE);
            }
        }
    }

    public function get_data($id)
    {
        return $this->db->query("
            SELECT
                DISTINCT a.*,
                c.e_customer_name
            FROM
                tm_pembelian a
            JOIN tr_customer_item b ON
                (b.id_item = a.id_item)
            JOIN tr_customer c ON
                (c.id_customer = b.id_customer)
            WHERE
                a.id_document = '$id'
        ", FALSE);
    }

    public function cancel($id)
    {
        $data = array(
            'f_status' => false, 
        );
        $this->db->where('id_document', $id);
        $this->db->update('tm_pembelian', $data);
    }

    /** Transfer Data */
    public function trasferdata()
    {
        $dfrom      = date('Y-m-01');
        $dto        = date('Y-m-d');
        $eremark    = null;

        $this->db->where('db_name is NOT NULL', NULL, FALSE);
        $this->db->where('f_status', 't');
        $query      = $this->db->get('tr_company');
        if ($query->num_rows() > 0) {
            foreach ($query->result() as $kuy) {
                $icompany   = $kuy->i_company;
                $Url        = $kuy->db_address;
                $User       = $kuy->db_user;
                $Password   = $kuy->db_password;
                $DbName     = $kuy->db_name;
                $Port       = $kuy->db_port;
                $Jenis      = $kuy->jenis_company;
                if ($Jenis == 'produksi') {
                    $dbexternalna = "
                        SELECT
                            i_customer,
                            i_do AS i_sj,
                            trim(i_do_code) AS i_sj_code,
                            d_accept AS d_sj_receive
                        FROM
                            tm_do
                        WHERE
                            d_accept BETWEEN '$dfrom' AND '$dto'
                            AND f_do_cancel = 'f'
                        ORDER BY
                            i_do_code
                    ";
                } else {
                    $dbexternalna = "
                        SELECT
                            i_customer,
                            i_sj,
                            i_sj AS i_sj_code,
                            d_sj_receive
                        FROM
                            tm_nota
                        WHERE
                            d_sj_receive BETWEEN '$dfrom' AND '$dto'
                            AND f_nota_cancel = 'f'
                        ORDER BY
                            i_sj
                    ";
                }

                $header = $this->db->query("
                    SELECT
                        x.*,
                        y.id_item
                    FROM
                    (
                        SELECT
                            *
                        FROM
                        dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                        $$ $dbexternalna $$) AS get_product ( i_customer CHARACTER VARYING(6),
                        i_sj CHARACTER VARYING(20),
                        i_sj_code CHARACTER VARYING(20),
                        d_receive date ) ) x
                        INNER JOIN tr_customer_item y ON
                        (
                            y.i_customer = x.i_customer
                        )
                        ORDER BY
                            2,
                            3 ASC
                        ", FALSE);
                if ($header->num_rows() > 0) {
                    foreach ($header->result() as $key) {
                        $this->db->query("INSERT INTO tm_pembelian (id_item, i_document, d_receive, e_remark, d_entry, id_user, i_company) 
                        VALUES ($key->id_item, '$key->i_sj_code', '$key->d_receive', '$eremark', now(), $this->id_user, $icompany)
                        ON CONFLICT (id_item, i_company, i_document) DO UPDATE 
                        SET d_receive = excluded.d_receive,
                            e_remark = excluded.e_remark, 
                            id_user = excluded.id_user, 
                            d_update = now()", FALSE);
                        if ($Jenis == 'produksi') {
                            $eksternal = "
                                SELECT
                                    i_product,
                                    e_product_name,
                                    n_deliver AS n_qty,
                                    v_unitprice AS v_price
                                FROM
                                    tm_do_item
                                WHERE
                                    i_do = '$key->i_sj'
                                ORDER BY
                                    i_do
                            ";
                        } else {
                            $eksternal = "
                                SELECT
                                    i_product,
                                    e_product_name,
                                    n_deliver AS n_qty,
                                    v_unit_price AS v_price
                                FROM
                                    tm_nota_item
                                WHERE
                                    i_sj = '$key->i_sj'
                                ORDER BY
                                    i_sj
                            ";
                        }
                        $query = $this->db->query("SELECT id_document AS id FROM tm_pembelian WHERE i_document = '$key->i_sj_code' AND i_company = '$icompany' ", TRUE);
                        if ($query->num_rows() > 0) {
                            $id = $query->row()->id;
                            if ($id == null) {
                                die;
                            } else {
                                $id = $id;
                            }
                        } else {
                            die;
                        }
                        $this->db->query("
                            INSERT INTO tm_pembelian_item (id_document, i_company, i_product, e_product_name, n_qty, v_price)
                            SELECT
                                $id AS id_document,
                                $icompany AS i_company,
                                i_product,
                                e_product_name,
                                n_qty,
                                v_price
                            FROM
                            (
                                SELECT
                                    *
                                FROM
                                dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                                $$ $eksternal $$) AS get_product ( 
                                    i_product CHARACTER VARYING(11),
                                    e_product_name CHARACTER VARYING(150),
                                    n_qty NUMERIC,
                                    v_price NUMERIC ) 
                                    ) x
                                ORDER BY
                                    2,
                                    1 ASC
                            ON CONFLICT (id_document, i_company, i_product) DO UPDATE 
                            SET e_product_name = excluded.e_product_name, 
                            n_qty = excluded.n_qty, 
                            v_price = excluded.v_price
                            ", FALSE);
                    }
                }
            }
        }
    }
}

/* End of file Mmaster.php */
