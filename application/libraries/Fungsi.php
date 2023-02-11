<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
class Fungsi {

	var $interval			= ''; 
	var $dateTime	  		= ''; 
	var $number	 		= ''; 

	function dateAdd($interval,$number,$dateTime) {
		$dateTime = (strtotime($dateTime) != -1) ? strtotime($dateTime) : $dateTime;
		$dateTimeArr=getdate($dateTime);
		$yr=$dateTimeArr['year'];
		$mon=$dateTimeArr['mon'];
		$day=$dateTimeArr['mday'];
		$hr=$dateTimeArr['hours'];
		$min=$dateTimeArr['minutes'];
		$sec=$dateTimeArr['seconds'];
		switch($interval) {
		    case "s"://seconds
		        $sec += $number;
		        break;
		    case "n"://minutes
		        $min += $number;
		        break;
		    case "h"://hours
		        $hr += $number;
		        break;
		    case "d"://days
		        $day += $number;
		        break;
		    case "ww"://Week
		        $day += ($number * 7);
		        break;
		    case "m": //similar result "m" dateDiff Microsoft
		        $mon += $number;
		        break;
		    case "yyyy": //similar result "yyyy" dateDiff Microsoft
		        $yr += $number;
		        break;
		    default:
		        $day += $number;
		     }      
		    $dateTime = mktime($hr,$min,$sec,$mon,$day,$yr);
		    $dateTimeArr=getdate($dateTime);
		    $nosecmin = 0;
		    $min=$dateTimeArr['minutes'];
		    $sec=$dateTimeArr['seconds'];
		    if ($hr==0){$nosecmin += 1;}
		    if ($min==0){$nosecmin += 1;}
		    if ($sec==0){$nosecmin += 1;}
		    if ($nosecmin>2){     
				return(date("Y-m-d",$dateTime));
			} else {     
				return(date("Y-m-d G:i:s",$dateTime));
			}
	}

	function mbulan($a){
		if($a=='') $b= '';
		if($a=='01') $b= 'Januari';
		if($a=='02') $b= 'Februari';
		if($a=='03') $b= 'Maret';
		if($a=='04') $b= 'April';
		if($a=='05') $b= 'Mei';
		if($a=='06') $b= 'Juni';
		if($a=='07') $b= 'Juli';
		if($a=='08') $b= 'Agustus';
		if($a=='09') $b= 'September';
		if($a=='10') $b= 'Oktober';
		if($a=='11') $b= 'November';
		if($a=='12') $b= 'Desember';
		return $b;
	}	

	function getbulan() {
		$res = "";
		$bulan=array("Januari","Februari","Maret","April","Mei","Juni","Juli","Agustus","September","Oktober","Nopember","Desember");
		$jlh_bln=count($bulan);
		for($c=0; $c<$jlh_bln; $c+=1){
			$i = $c+1;
			if ($i<=9){ $i = '0'.$i; }
			$res .= "<option value=$i> $bulan[$c] </option>";
		}
		return $res;
	}

}
?>
