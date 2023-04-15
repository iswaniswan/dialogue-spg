<?php 


function getSelisih($price1, $price2) {
    return $price1 - $price2;
} 

function getStyle($v) {    
    if ($v < 0) {
        return 'success';
    }

    return 'danger';
}

function getBadgeSelisih($price1, $price2) {
    $value = getSelisih($price1, $price2);
    $style = getStyle($value);
    // $badge = "<span class='text-$style'>Rp. ". number_format($value, 0, ",", ".") . "</span>";
    $badge = "<span class='text-$style'>Rp. ". number_format(abs($value), 0, ",", ".") . "</span>";
    return $badge;
}        

$product_origin_price = $product->v_price;

/** status naik/turun harga terakhir */
function getStatusFluktuasi($db, $id_customer, $id_product, $e_brand_text) {
    $sql = "SELECT * 
            FROM tm_product_competitor p
            WHERE p.id_customer = '$id_customer' 
                AND p.id_product = '$id_product' 
                AND e_brand_text = '$e_brand_text'
            ORDER BY d_berlaku DESC LIMIT 2";

    $query = $db->query($sql)->result_array();
    
    $current_price = $query[0]['v_price'];
    $previous_price = @$query[1]['v_price'] ?? null;

    if ($previous_price == null) {
        return 0;
    }
    
    $status = 0;
    if ($current_price > $previous_price) {
        $status = 1;
    }

    if ($current_price < $previous_price) {
        $status = -1;
    }

    return $status;
}

function getBadgeStatusFluktuasi($status) {
    $_text = 'tetap';
    $_style = 'info'; 
    $_icon = "<i class='icon-minus3 text-$_style'></i>";
    if ($status == 1) {
        $_text = 'naik';
        $_style = 'success';
        $_icon = "<i class='icon-stats-growth2 text-$_style'></i>";
    }
    if ($status < 0) {
        $_text = 'turun';
        $_style = 'danger'; 
        $_icon = "<i class='icon-stats-decline2 text-$_style'></i>";
    }

    $badge = "<span class='text-$_style'>$_icon $_text</span>";
    
    return $badge;
}

function getBadgeProductStats($status)
{
    $_text = 'sama';
    $_style = 'info'; 
    $_icon = "<i class='icon-minus3 text-$_style'></i>";
    if ($status == 1) {
        $_text = 'mahal';
        $_style = 'danger';
        $_icon = "<i class='icon-stats-growth2 text-$_style'></i>";
    }
    if ($status < 0) {
        $_text = 'murah';
        $_style = 'success'; 
        $_icon = "<i class='icon-stats-decline2 text-$_style'></i>";
    }

    $badge = "<span class='text-$_style'>$_icon $_text</span>";
    
    return $badge;
}

?>