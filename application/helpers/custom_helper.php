<?php

use phpDocumentor\Reflection\DocBlock\Tags\Var_;

 if (!defined('BASEPATH')) exit('No direct script access allowed');

//-- check logged user
function cek_session()
{
	$ci = &get_instance();
	$username = $ci->session->userdata('id_user');
	if ($username == '') {
		$ci->session->sess_destroy();
		redirect(base_url() . 'auth');
	}

	$set_language = $ci->session->userdata('language');
    if ($set_language) {
        $ci->lang->load('app_lang', $set_language);
    } else {
        $ci->lang->load('app_lang', 'english');
    }
}

function cek_login()
{
	$ci = &get_instance();
	$username = $ci->session->userdata('id_user');
	if ($username != '') {
		redirect(base_url());
	}
}

function get_company()
{
	$ci = &get_instance();
	$id_user = $ci->session->userdata('id_user');
	if ($id_user != '') {
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_company($id_user);
	} else {
		$query = '';
	}
	return $query;
}

function get_menu()
{
	$ci = &get_instance();
	$id_user = $ci->session->userdata('id_user');
	if ($id_user != '') {
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_menu($id_user);
	} else {
		$query = '';
	}
	return $query;
}

function get_sub_menu($id_menu)
{
	$ci = &get_instance();
	$id_user = $ci->session->userdata('id_user');
	if ($id_user != '') {
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_sub_menu($id_user, $id_menu);
	} else {
		$query = '';
	}
	return $query;
}

if (!function_exists('check_role')) {
	function check_role($id_menu, $id)
	{
		$ci = get_instance();
		$id_user = $ci->session->userdata('id_user');
		$ci->load->model('Mcustom');
		$option = $ci->Mcustom->cek_role($id_user, $id_menu, $id)->row();

		return $option;
	}
}

function time_ago($timestamp)
{
	date_default_timezone_set('Asia/Jakarta');
	$time_ago 		 = strtotime($timestamp);
	$current_time 	 = time();
	$time_difference = $current_time - $time_ago;
	$seconds 		 = $time_difference;
	$minutes         = round($seconds / 60);        /* value 60 is seconds  */
	$hours           = round($seconds / 3600);       /*value 3600 is 60 minutes * 60 sec  */
	$days            = round($seconds / 86400);      /*86400 = 24 * 60 * 60;  */
	$weeks           = round($seconds / 604800);     /* 7*24*60*60;  */
	$months          = round($seconds / 2629440);    /*((365+365+365+365+366)/5/12)*24*60*60  */
	$years           = round($seconds / 31553280);   /*(365+365+365+365+366)/5 * 24 * 60 * 60  */
	if ($seconds <= 60) {
		return "Just Now";
	} else if ($minutes <= 60) {
		if ($minutes == 1) {
			return "one minute ago";
		} else {
			return "$minutes minutes ago";
		}
	} else if ($hours <= 24) {
		if ($hours == 1) {
			return "an hour ago";
		} else {
			return "$hours hrs ago";
		}
	} else if ($days <= 7) {
		if ($days == 1) {
			return "yesterday";
		} else {
			return "$days days ago";
		}
	} else if ($weeks <= 4.3) {  /*4.3 == 52/12*/
		if ($weeks == 1) {
			return "a week ago";
		} else {
			return "$weeks weeks ago";
		}
	} else if ($months <= 12) {
		if ($months == 1) {
			return "a month ago";
		} else {
			return "$months months ago";
		}
	} else {
		if ($years == 1) {
			return "one year ago";
		} else {
			return "$years years ago";
		}
	}
}

if (!function_exists('check_role')) {
	function check_role($id_menu, $id)
	{
		$ci = get_instance();
		$id_user = $ci->session->userdata('id_user');
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->cek_role($id_user, $id_menu, $id)->row();

		return $query;
	}
}

function formatSizeUnits($filename)
{
	if ($filename != '' || $filename != null) {
		$file_path = 'assets/upload/' . $filename;
		$bytes     = filesize($file_path);

		if ($bytes >= 1073741824) {
			$bytes = number_format($bytes / 1073741824, 2) . ' GB';
		} elseif ($bytes >= 1048576) {
			$bytes = number_format($bytes / 1048576, 2) . ' MB';
		} elseif ($bytes >= 1024) {
			$bytes = number_format($bytes / 1024, 2) . ' KB';
		} elseif ($bytes > 1) {
			$bytes = $bytes . ' bytes';
		} elseif ($bytes == 1) {
			$bytes = $bytes . ' byte';
		} else {
			$bytes = '0 bytes';
		}

		return $bytes;
	} else {
		return '0 KB';
	}
}

function formatSize($path, $filename)
{
	if (($filename != '' && $path != '') || ($filename != null && $path != null)) {
		$file_path = $path . $filename;
		$bytes     = filesize($file_path);

		if ($bytes >= 1073741824) {
			$bytes = number_format($bytes / 1073741824, 2) . ' GB';
		} elseif ($bytes >= 1048576) {
			$bytes = number_format($bytes / 1048576, 2) . ' MB';
		} elseif ($bytes >= 1024) {
			$bytes = number_format($bytes / 1024, 2) . ' KB';
		} elseif ($bytes > 1) {
			$bytes = $bytes . ' bytes';
		} elseif ($bytes == 1) {
			$bytes = $bytes . ' byte';
		} else {
			$bytes = '0 bytes';
		}

		return $bytes;
	} else {
		return '0 KB';
	}
}

//-- current date time function
if (!function_exists('current_datetime')) {
	function current_datetime()
	{
		$ci = get_instance();
		$query   = $ci->db->query("SELECT current_timestamp as c");
		$row     = $query->row();
		$waktu   = $row->c;
		return $waktu;
	}
}

if (!function_exists('add_js')) {
	function add_js($file = '')
	{
		$str = '';
		$ci = &get_instance();
		$footer_js  = $ci->config->item('footer_js');

		if (empty($file)) {
			return;
		}

		if (is_array($file)) {
			if (!is_array($file) && count($file) <= 0) {
				return;
			}
			foreach ($file as $item) {
				$footer_js[] = $item;
			}
			$ci->config->set_item('footer_js', $footer_js);
		} else {
			$str = $file;
			$footer_js[] = $str;
			$ci->config->set_item('footer_js', $footer_js);
		}
	}
}


if (!function_exists('add_css')) {
	function add_css($file = '')
	{
		$str = '';
		$ci = &get_instance();
		$header_css = $ci->config->item('header_css');

		if (empty($file)) {
			return;
		}

		if (is_array($file)) {
			if (!is_array($file) && count($file) <= 0) {
				return;
			}
			foreach ($file as $item) {
				$header_css[] = $item;
			}
			$ci->config->set_item('header_css', $header_css);
		} else {
			$str = $file;
			$header_css[] = $str;
			$ci->config->set_item('header_css', $header_css);
		}
	}
}

if (!function_exists('add_key')) {
	function add_key($file = '')
	{
		$str = '';
		$ci = &get_instance();
		$key = $ci->config->item('key');

		if (empty($file)) {
			return;
		}

		if (is_array($file)) {
			if (!is_array($file) && count($file) <= 0) {
				return;
			}
			foreach ($file as $item) {
				$key[] = $item;
			}
			$ci->config->set_item('key', $key);
		} else {
			$str = $file;
			$key[] = $str;
			$ci->config->set_item('key', $key);
		}
	}
}

if (!function_exists('put_headers')) {
	function put_headers()
	{
		$str = '';
		$ci = &get_instance();
		$header_css  = $ci->config->item('header_css');

		foreach ($header_css as $item) {
			$str .= '<link href="' . base_url() . '' . $item . '" type="text/css" />' . "\n";
		}
		return $str;
	}
}
if (!function_exists('put_footer')) {
	function put_footer()
	{
		$str = '';
		$ci = &get_instance();
		$key  = $ci->config->item('key');
		$item_key = '<script>';
		foreach ($key as $item) {
			$item_key .= $item;
		}
		$item_key .= '</script>';
		$footer_js  = $ci->config->item('footer_js');
		foreach ($footer_js as $item) {
			$str .= '<script src="' . base_url() . '' . $item . '"></script>' . "\n";
		}
		return $item_key . "\n" . $str;
	}
}

function encrypt_password($string)
{
	$output = false;
	$secret_key     = 'merubahpassword';
	$secret_iv      = 'menjadilieur';
	$encrypt_method = 'aes-256-cbc';
	$key    = hash("sha256", $secret_key);
	$iv     = substr(hash("sha256", $secret_iv), 0, 16);
	$result = openssl_encrypt($string, $encrypt_method, $key, 0, $iv);
	$output = base64_encode($result);
	$output = str_replace('=', '', $output);
	return $output;
}

function decrypt_password($string)
{
	$output = false;
	$secret_key     = 'merubahpassword';
	$secret_iv      = 'menjadilieur';
	$encrypt_method = 'aes-256-cbc';
	$key    = hash("sha256", $secret_key);
	$iv = substr(hash("sha256", $secret_iv), 0, 16);
	$output = openssl_decrypt(base64_decode($string), $encrypt_method, $key, 0, $iv);
	return $output;
}

function encrypt_url($string)
{
	$output = false;
	$secret_key     = 'dukanaonteuapal';
	$secret_iv      = 'nanaonan';
	$encrypt_method = 'aes-256-cbc';
	$key    = hash("sha256", $secret_key);
	$iv     = substr(hash("sha256", $secret_iv), 0, 16);
	$result = openssl_encrypt($string, $encrypt_method, $key, 0, $iv);
	$output = base64_encode($result);
	$output = str_replace('=', '', $output);
	return $output;
}
function decrypt_url($string)
{
	$output = false;
	$secret_key     = 'dukanaonteuapal';
	$secret_iv      = 'nanaonan';
	$encrypt_method = 'aes-256-cbc';
	$key    = hash("sha256", $secret_key);
	$iv = substr(hash("sha256", $secret_iv), 0, 16);
	$output = openssl_decrypt(base64_decode($string), $encrypt_method, $key, 0, $iv);
	return $output;
}

function replace($str = '', $sp = '')
{
	$replace_string = '';

	if (!empty($str)) {
		$q_separator = preg_quote($sp, '#');

		$trans = array(
			'_' => $sp,
			'&.+?;' => '',
			'[^\w\d -]' => '',
			'\s+' => $sp,
			'(' . $q_separator . ')+' => $sp
		);

		$str = strip_tags($str);

		foreach ($trans as $key => $val) {
			$str = preg_replace('#' . $key . '#i' . (UTF8_ENABLED ? 'u' : ''), $val, $str);
		}

		$str = strtolower($str);
		$replace_string = trim(trim($str, $sp));
	}

	return $replace_string;
}


function get_setting($config_name)
{
	$ci = &get_instance();
	return $ci->db->query("select config_value from tbl_config where config_name = '$config_name'")->row()->config_value;
}

if (!function_exists('check_db')) {
	function check_db($ename)
	{

		$ci = get_instance();
		$cek = $ci->db->query("
	        SELECT
	            e_db
	        FROM
	            public.db_link
	        WHERE
	            trim(e_name) = trim('$ename') ");
		if ($cek->num_rows() > 0) {
			return $cek->row()->e_db;
		} else {
			return '';
		}
	}
}

function get_notification_saldo()
{

	$ci = &get_instance();
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_notif_saldo();
	return $query;
}

function get_notification_retur()
{

	$ci = &get_instance();
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_notif_retur();
	return $query;
}

function get_notification_adjust()
{

	$ci = &get_instance();
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_notif_adjust();
	return $query;
}

function get_notification_pending_izin()
{
	$ci = &get_instance();
		$ci->load->model('Mcustom');
		$query = $ci->Mcustom->get_notification_pending_izin();
	return $query;
}

function set_current_active_menu($menu)
{
	$_SESSION['active_menu'] = $menu;
}

function get_current_active_menu()
{
	return $_SESSION['active_menu'] ?? '';
}

function getBulan()
{
	$data = array(
		"01" => "Januari",
		"02" => "Februari",
		"03" => "Maret",
		"04" => "April",
		"05" => "Mei",
		"06" => "Juni",
		"07" => "Juli",
		"08" => "Agustus",
		"09" => "September",
		"10" => "Oktober",
		"11" => "November",
		"12" => "Desember",
	);
	return $data;
}

function getMonthShort()
{
	$data = array(
		"01" => "Jan",
		"02" => "Feb",
		"03" => "Mar",
		"04" => "Apr",
		"05" => "May",
		"06" => "Jun",
		"07" => "Jul",
		"08" => "Aug",
		"09" => "Sept",
		"10" => "Oct",
		"11" => "Nov",
		"12" => "Dec",
	);
	return $data;
}

function notification_saldo_awal($count=false)
{
	$ci = &get_instance();
	$ci->load->model('Mnotification');
	$query = $ci->Mnotification->get_saldo_awal();

	if ($count) {
		return $query['count'];
	}

	return $query['data'];
}