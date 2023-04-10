<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mlaporankehadiran extends CI_Model {

    const ROLE_ADMIN = 1;
    const ROLE_MARKETING = 4;

    public function get_user($id_user)
    {
        $sql = "SELECT * FROM tm_user WHERE id_user='$id_user'";

        return $this->db->query($sql);
    }

    public function get_customer($cari='', $id_customer=null)
    {
        $limit = " LIMIT 5";
        if ($cari != '') {
            $limit = '';
        }

        $user_cover = "SELECT id_customer FROM tm_user_customer
                        WHERE id_user = '$this->id_user'";

        if ($id_customer != null) {
            $user_cover = $id_customer;
        }

        $sql = "SELECT
                    id_customer,
                    e_customer_name 
                FROM tr_customer
                WHERE (e_customer_name ILIKE '%$cari%')
                    AND f_status = 't'
                    AND id_customer IN ($user_cover)
                ORDER BY e_customer_name ASC
                $limit ";

        return $this->db->query($sql, FALSE);
    }

    private function get_kehadiran_user($dfrom, $dto, $id_user=null) {
        $where_and = "";
        if ($id_user != null) {
            $where_and = " AND id_user='$id_user'";
        }

        $sql = "SELECT * FROM tm_kehadiran WHERE d_hadir BETWEEN '$dfrom' AND '$dto' $where_and";

        return $this->db->query($sql);
    }

    private function get_izin_user($dfrom, $dto, $id_user) {
        $where_and = "";
        if ($id_user != null) {
            $where_and = " AND id_user='$id_user'";
        }

        $sql = "SELECT * FROM tm_izin WHERE d_hadir BETWEEN '$dfrom' AND '$dto' $where_and";

        return $this->db->query($sql);
    }

    public function get_user_hadir($id_user, $date) 
    {
        $sql = "SELECT * FROM tm_kehadiran WHERE d_hadir = '$date' AND id_user='$id_user'";

        return $this->db->query($sql);
    }

    public function get_user_atasan($id_user)
    {
        $sql = "SELECT * FROM tm_user WHERE id_user = (
            SELECT id_atasan FROM tm_user WHERE id_user = $id_user
        )";

        return $this->db->query($sql);
    }

    public function get_user_customer_brand($cari='', $id_user, $id_customer=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND id_customer = '$id_customer'";
        }

        $sql = "SELECT tb.id_brand AS id, tb.e_brand_name 
                FROM tm_user_brand tub 
                INNER JOIN tm_user_customer tuc ON tuc.id = tub.id_user_customer
                INNER JOIN tr_brand tb ON tb.id_brand = tub.id_brand 
                WHERE id_user = '$id_user' 
                    $where_and 
                    AND tb.e_brand_name ILIKE '%$cari%'";

        return $this->db->query($sql);
    }

    public function get_all_user_kehadiran($id_user=null)
    {
        $id_user_session = $this->session->userdata('id_user');

        $where_and = "AND tu.id_user IN (
            SELECT b.id_user FROM tm_user b WHERE b.id_atasan='$id_user_session'
        )";

        if ($id_user != null) {
            $where_and = " AND tu.id_user = '$id_user'";
        }

        /** ROLE ADMIN & MARKETING */
        $level_session = $this->session->userdata('i_level');
        if ($level_session == static::ROLE_ADMIN or $level_session == static::ROLE_MARKETING) {
            $where_and = "";
        }

        $sql = "SELECT tk.id_user, tu.e_nama FROM tm_kehadiran tk 
                INNER JOIN tm_user tu ON tu.id_user = tk.id_user
                $where_and
                GROUP BY 1, 2";

        // var_dump($sql); die();
        return $this->db->query($sql);
    }

    public function is_hadir($id_user, $date)
    {
        $sql = "SELECT * FROM tm_kehadiran WHERE id_user='$id_user' AND d_hadir='$date'";

        return $this->db->query($sql)->row() ?? FALSE;
    }

    public function is_izin($id_user, $date, $is_approve=false)
    {
        $where_and = '';
        if ($is_approve) {
            $where_and = " AND d_approve IS NOT NULL";
        }

        $sql = "SELECT * FROM tm_izin ti WHERE id_user = '$id_user' 
                    AND	'$date' >= to_char(d_pengajuan_mulai, 'YYYY-MM-DD')
                    AND '$date' <= to_char(d_pengajuan_selesai, 'YYYY-MM-DD')
                    $where_and";

        return $this->db->query($sql)->row() ?? FALSE;
    }

    public function get_all_bawahan_id()
    {
        $id_user = $this->session->userdata('id_user');
        $i_level = $this->session->userdata('i_level');

        $all_spg = "SELECT id_user FROM tm_user tu WHERE i_level = 2 AND id_atasan = '$id_user'";
        $all_team_leader = "SELECT id_user FROM tm_user WHERE i_level = 5";
        $all_marketing = "SELECT id_user FROM tm_user WHERE i_level = 4";

        /** team leader */
        if ($i_level == 5) {
            return $all_spg;
        }

        return false;
    }

    public function get_all_user_bawahan($cari="")
    {
        $id_user = $this->session->userdata('id_user');

        $sql = "SELECT * FROM tm_user tu WHERE f_status = true AND id_atasan = '$id_user'
                AND e_nama ILIKE '%$cari%'";

        return $this->db->query($sql);
    }

    public function get_pengajuan_izin($dfrom, $dto, $id_user=null, $is_approve=false, $asSql=false)
    {
        $current_user = $this->session->userdata('id_user');
        $current_level = $this->session->userdata('i_level');

        $where_and = " AND ti.id_user = '$current_user'";        
        $all_bawahan = $this->get_all_bawahan_id();
        if ($all_bawahan != false) {
            $where_and = " AND (ti.id_user = '$current_user' OR ti.id_user IN ($all_bawahan)) ";
        }        

        if ($id_user != null) {
            $where_and = " AND ti.id_user = '$id_user'";
        }

        $level_session = $this->session->userdata('i_level');
        if ($level_session == static::ROLE_ADMIN or $level_session == static::ROLE_MARKETING) {
            $where_and = "";
        }

        if ($is_approve) {
            $where_and .= " AND ti.d_approve IS NOT NULL";
        }

        $sql = "SELECT 	
                    ti.id, 
                    ti.id_user,                    
                    tu.e_nama,
                    tu.id_atasan,
                    tji.e_izin_name,
                    ti.d_pengajuan_mulai AS d_mulai, 
                    ti.d_pengajuan_selesai AS d_selesai, 
                    ti.e_remark,
                    ti.e_remark_reject,
                    ti.f_status,
                    ti.d_approve::TEXT,
                    ti.d_reject::TEXT
                FROM tm_izin ti
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin 
                INNER JOIN tm_user tu ON tu.id_user = ti.id_user
                WHERE ti.f_status = 't'  
                    AND to_char(ti.d_pengajuan_mulai, 'YYYY-MM-DD') BETWEEN '$dfrom' AND '$dto'                  
                    $where_and
                ORDER BY ti.d_pengajuan_mulai ASC"; 
        
        if ($asSql) {
            return $sql;
        }
        
        return $this->db->query($sql);
    }

    public function get_kehadiran($dfrom, $dto, $id_user=null, $asSql=false)
    {
        $current_user = $this->session->userdata('id_user');
        $current_level = $this->session->userdata('i_level');

        $where_and = " AND tk.id_user='$current_user'";        
        $all_bawahan = $this->get_all_bawahan_id();
        if ($all_bawahan != false) {
            $where_and = " AND (tk.id_user='$current_user' OR tk.id_user IN ($all_bawahan)) ";
        }        

        if ($id_user != null) {
            $where_and = " AND ti.id_user = '$id_user'";
        }

        $level_session = $this->session->userdata('i_level');
        if ($level_session == static::ROLE_ADMIN or $level_session == static::ROLE_MARKETING) {
            $where_and = "";
        }

        $sql = "SELECT 	
                    tk.id, 
                    tk.id_user,                    
                    tu.e_nama,
                    tu.id_atasan,
                    NULL AS e_izin_name,
                    tk.d_datang AS d_mulai, 
                    tk.d_pulang AS d_selesai, 
                    NULL AS e_remark,
                    NULL AS e_remark_reject,
                    tk.f_status,
                    NULL AS d_approve,
                    NULL AS d_reject
                FROM tm_kehadiran tk  
                INNER JOIN tm_user tu ON tu.id_user = tk.id_user
                WHERE tk.f_status = 't'
                    AND to_char(tk.d_hadir, 'YYYY-MM-DD') BETWEEN '$dfrom' AND '$dto' 
                    $where_and
                ORDER BY tk.d_datang ASC"; 

            if ($asSql) {
                return $sql;
            }
        
        return $this->db->query($sql);
    }

    public function get_izin_dan_kehadiran($dfrom, $dto, $id_user=null)
    {
        $sql_izin = $this->get_pengajuan_izin($dfrom, $dto, $id_user, $is_approve=true, $asSql=true);
        $sql_kehadiran = $this->get_kehadiran($dfrom, $dto, $id_user, true);

        $sql = "SELECT * FROM ($sql_izin) AS a UNION ALL SELECT * FROM ($sql_kehadiran) AS b 
                ORDER BY d_mulai ASC, id_user ASC";

        // var_dump($sql); die();

        return $this->db->query($sql);
    }

    public function get_user_jenis_izin($id_user, $date)
    {
        $sql = "SELECT e_izin_name
                FROM tm_izin ti
                INNER JOIN tr_jenis_izin tji ON tji.id = ti.id_jenis_izin
                WHERE id_user = '$id_user' 
                    AND	'$date' >= to_char(d_pengajuan_mulai, 'YYYY-MM-DD')
                    AND '$date' <= to_char(d_pengajuan_selesai, 'YYYY-MM-DD')";

        return $this->db->query($sql);
    }

}
