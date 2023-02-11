<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mlaporankategoripenjualan extends CI_Model {

    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);

        $datatables->query("SELECT DISTINCT 
        row_number() OVER () as num,
        a.id_customer,
        (SELECT e_customer_name FROM tr_customer WHERE id_customer = a.id_customer) AS customer,
        c.i_company,
        (SELECT e_company_name FROM tr_company WHERE i_company = c.i_company) AS company,
        f.i_product,
        (SELECT e_product_name FROM tr_product WHERE i_product = f.i_product) AS product,
        g.v_price, 
        (a.d_entry::TIMESTAMP::DATE) AS tanggal_masuk, 
        current_date AS tanggal,
        (current_date - (a.d_entry::TIMESTAMP::DATE)) AS selisih,
        CASE
           WHEN (current_date - (a.d_entry::TIMESTAMP::DATE)) < 30 THEN 'Fast Moving'
           WHEN (current_date - (a.d_entry::TIMESTAMP::DATE)) > 30 AND (current_date - (a.d_entry::TIMESTAMP::DATE)) < 90 THEN 'Medium'
           WHEN (current_date - (a.d_entry::TIMESTAMP::DATE)) > 90 THEN 'Slow Moving'
        END kategori,
        a.f_status
        FROM 
        tm_mutasi_saldoawal a
        INNER JOIN
        tm_stockopname b ON
        (b.id_customer = a.id_customer)
        INNER JOIN
        tr_customer_item c ON
        (c.id_customer = a.id_customer AND c.id_customer = b.id_customer)
        INNER JOIN
        tm_pembelian d ON
        (d.id_item = c.id_item)
        INNER JOIN 
        tm_penjualan e ON
        (e.id_customer = a.id_customer AND e.id_customer = b.id_customer AND e.id_customer = c.id_customer)
        INNER JOIN 
        tm_penjualan_item f ON
        (f.id_document = e.id_document)
        INNER JOIN
        tr_customer_price g ON
        (g.id_customer = a.id_customer AND g.i_product = f.i_product)
        WHERE a.f_status = 't'
        GROUP BY 2,3,4,5,6,7,8,9,10,11,12,13
        ORDER BY a.id_customer 
        ", FALSE);
        /*
        $datatables->add('kategori', function ($data) {
            $selisih    = $data['selisih'];
            if ($selisih < 30){
                $kategori      = "Fast Moving";
            }

            if ($selisih > 30 && $selisih < 90){
                $kategori      = "Medium";
            }

            if ($selisih > 90){
                $kategori      = "Slow Moving";
            }
            return $kategori;
        });
        */

        // $datatables->edit('f_status', function ($data) {
        //     $id         = $data['id_customer'];
        //     if ($data['f_status']=='t') {
        //         $status = 'Aktif';
        //         $color  = 'success';
        //     }else{
        //         $status = 'Batal';
        //         $color  = 'danger';
        //     }
        //     $data = "<button class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'>".$status."</button>";
        //     return $data;
        // });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $id         = $data['id_customer'];
            $status     = $data['f_status'];
            $data       = '';
            /* if (check_role($this->id_menu, 3) && $status=='t') {
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
            }     */

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }
            
            if (check_role($this->id_menu, 4) && $status=='t') {
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-2'></i></a>";
            }
            return $data;
        });
        $datatables->hide('id_customer');
        $datatables->hide('i_company');
        $datatables->hide('i_product');
        $datatables->hide('f_status');
        return $datatables->generate();
    }

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

    public function export_excel($id){

        $today = date("Y-m-d");
        $month = date("m") + 1;
        $next = date("Y-".$month."-01");

        $id_user = $this->id_user;

        if ($id === "all") {

                $id = 'NULL';
                
        } else {
        $id = $id;
        }
        if ($id_user === '1') {

            $id_user = 'NULL';
        } 

        $d_from         = $today;
        $d_to           = $next;
        $d_jangka_from  = date('Y-m', strtotime($d_from)) . '-01';
        $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($d_from)));

        // if ($d_jangka_from == $d_from) {
        //     $d_jangka_from = '9999-01-01';
        //     $d_jangka_to   = '9999-01-31';
        // }
        $query = $this->db->query("select
            laporan.id_customer,
            laporan.e_customer_name as customer,
            laporan.i_product,
            laporan.e_product_name,
            laporan.e_brand_name,
            laporan.v_price,
            laporan.tanggal,
            laporan.saldo_akhir,
            laporan.jarak,
            case
                when laporan.jarak < 31 then 'Fast Moving'
                when laporan.jarak > 30
                and laporan.jarak < 91 then 'Medium'
                when laporan.jarak > 90 then 'Slow Moving'
                when laporan.jarak > 180 then 'STP'
            end kategori
        from
            (
            select
                id_customer,
                e_customer_name,
                i_product,
                e_product_name,
                e_brand_name,
                v_price,
                saldo_akhir,
                case
                    when (d_document is null
                    and d_receive is not null) then d_receive
                    when (d_document is null
                    and d_receive is null) then d_approve
                    else d_document
                end tanggal,
                (current_date -
                (case
                    when (d_document is null
                    and d_receive is not null) then d_receive
                    when (d_document is null
                    and d_receive is null) then d_approve
                    else d_document
                end)) as jarak
            from
                (
                select
                    distinct on
                    (a.i_product) a.id_customer,
                    c.e_customer_name,
                    a.i_product,
                    initcap(a.e_product_name) as e_product_name,
                    a.e_brand_name,
                    0 as v_price,
                    a.saldo_akhir,
                    f.d_document,
                    g.d_receive,
                    h.d_approve
                from
                    f_mutasi_brand_baru_new('$d_from',
                    '$d_to',
                    '$d_jangka_from',
                    '$d_jangka_to',
                    '$id',
                    $id_user) a
                inner join tr_customer c on (c.id_customer = a.id_customer)
                left join (
                    select
                            distinct aa.id_customer,
                            ab.i_product,
                            max(aa.d_document) as d_document
                    from
                            tm_penjualan aa
                    inner join tm_penjualan_item ab on
                            (aa.id_document = ab.id_document)
                    where
                            aa.f_status = 't'
                            and aa.id_customer = '$id'
                    group by
                            1,
                            2 ) as f on
                    (a.id_customer = f.id_customer
                    and a.i_product = f.i_product)
                left join (
                    select
                            distinct bc.id_customer,
                            bb.i_product,
                            max(ba.d_receive) as d_receive
                    from
                            tm_pembelian ba
                    inner join tm_pembelian_item bb on
                            (ba.id_document = bb.id_document)
                    inner join tr_customer_item bc on
                            (ba.id_item = bc.id_item)
                    where
                            ba.f_status = 't'
                            and bc.id_customer = '$id'
                    group by
                            1,
                            2 ) as g on
                    (g.id_customer = a.id_customer
                    and g.i_product = a.i_product)
                left join (
                    select
                            distinct ca.id_customer,
                            cb.i_product,
                            max(ca.d_approve) as d_approve
                    from
                            tm_mutasi_saldoawal ca
                    inner join tm_mutasi_saldoawal_item cb on
                            (ca.id = cb.id_header)
                    where
                            ca.f_status = 't'
                            and ca.id_customer = '$id'
                            and ca.d_approve is not null
                    group by
                            1,
                            2 ) as h on
                    (h.id_customer = c.id_customer
                    and h.i_product = a.i_product)
                group by
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                    7,
                    8,
                    9,
                    10 ) as datalaporan) as laporan
        where
            id_customer = '$id'");
        return $query;
    }

}