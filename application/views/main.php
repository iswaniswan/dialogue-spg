<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>SPG - Web Application</title>

    <!-- Global stylesheets -->
    <link href="https://fonts.googleapis.com/css?family=Roboto:400,300,100,500,700,900" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>global_assets/css/icons/icomoon/styles.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/bootstrap.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/bootstrap_limitless.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/layout.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/components.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/colors.min.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>assets/css/global.css" rel="stylesheet" type="text/css">
    <link href="<?= base_url(); ?>global_assets/css/bootstrap4-editable/bootstrap-editable.css" rel="stylesheet" type="text/css">
    <!-- /global stylesheets -->

    <!-- assets css -->
    <?= put_headers(); ?>
    <style>
        .notification .badge {
        position: absolute;
        width: 20px;
        height: 20px;
        margin: 5px 5px;
        border-radius: 50%;
        background: red;
        color: white;
        }
    </style>
    <!-- /assets css -->
</head>

<body class="navbar-top">

    <!-- Loading Page -->
    <div class="loading"></div>
    <!-- End Loading Page -->

    <!-- Main navbar -->
    <div class="navbar navbar-expand-md navbar-dark bg-<?= $this->session->userdata('color'); ?> fixed-top" style="padding: 0px 1.1rem;">
        <div class="navbar-brand wmin-200" style="padding-top: 0.5rem;padding-bottom: 0.00002rem;min-width: 7.625rem;">
            <a href="<?= base_url(); ?>" class="d-inline-block">
                <img src="<?= base_url(); ?>global_assets/images/logo_light.png" title="Dashboard" style="height: 2.7rem;width: 6.5rem;margin-bottom: 0.0rem;margin-top: -0.5rem;">
            </a>
        </div>

        <div class="d-md-none">
            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar-mobile">
                <i class="icon-tree5"></i>
            </button>
            <button class="navbar-toggler sidebar-mobile-main-toggle" type="button">
                <i class="icon-paragraph-justify3"></i>
            </button>
        </div>

        <div class="collapse navbar-collapse" id="navbar-mobile">
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a href="#" class="navbar-nav-link sidebar-control sidebar-main-toggle d-none d-md-block">
                        <i class="icon-paragraph-justify3"></i>
                    </a>
                </li>

                <li class="nav-item dropdown">
                    <?php if ($this->session->userdata('language') == 'indonesia') { ?>
                        <a href="#" class="navbar-nav-link dropdown-toggle" data-toggle="dropdown">
                            <img src="<?= base_url(); ?>global_assets/images/lang/id.gif" class="img-flag mr-2" alt="">
                            Indonesia
                        </a>
                    <?php } else { ?>
                        <a href="#" class="navbar-nav-link dropdown-toggle" data-toggle="dropdown">
                            <img src="<?= base_url(); ?>global_assets/images/lang/gb.png" class="img-flag mr-2" alt="">
                            English
                        </a>
                    <?php } ?>
                    <div class="dropdown-menu dropdown-menu-right">
                        <?php if ($this->session->userdata('language') == 'indonesia') { ?>

                           <!--  <a href="<?= base_url('auth/switch_language/english'); ?>" class="dropdown-item"><img src="<?= base_url(); ?>global_assets/images/lang/gb.png" class="img-flag" alt=""> English</a> -->
                        <?php } else { ?>
                            <a href="<?= base_url('auth/switch_language/indonesia'); ?>" class="dropdown-item"><img src="<?= base_url(); ?>global_assets/images/lang/id.gif" class="img-flag" alt=""> Indonesia</a>
                        <?php } ?>
                    </div>
                </li>

                <!-- <li class="nav-item dropdown">
                    <a href="#" class="navbar-nav-link dropdown-toggle" data-toggle="dropdown">
                        <i class="icon-office mr-2"></i> <?= $this->session->userdata('e_company_name'); ?>
                    </a>

                    <div class="dropdown-menu">
                       <?php $all = ($this->session->userdata('i_company') == 'all') ? 'active' : ''; ?>
                        <a href="#" onclick="set_company('all','All Company'); return false;" class="dropdown-item <?= $all; ?>">All Company</a> 
                        <?php if (get_company()) {
                            foreach (get_company()->result() as $key) {
                                $status = ($this->session->userdata('i_company') == $key->i_company) ? 'active' : '';
                        ?>
                                <a href="#" onclick="set_company('<?= $key->i_company; ?>','<?= $key->e_company_name; ?>'); return false;" class="dropdown-item <?= $status; ?>"><?= $key->e_company_name; ?></a>
                        <?php }
                        } ?>
                    </div>
                </li> -->
            </ul>

            <span class="badge ml-md-auto mr-md-3">&nbsp;</span>

            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a href="#" class="navbar-nav-link dropdown-toggle caret-0 notification" data-toggle="dropdown">
                        <i class="icon-bell2"></i>
                        <span class="d-md-none ml-2">Activity</span>
                        <?php $badge = get_notification_saldo()->num_rows() 
                            + get_notification_retur()->num_rows() 
                            + get_notification_adjust()->num_rows()
                            + get_notification_pending_izin()->num_rows(); ?>

                        <?php if ($badge > 0) { ?>
                            <span class="badge"><?= $badge ?></span>
                        <?php } ?>
                    </a>

                    <div class="dropdown-menu dropdown-menu-right dropdown-content wmin-md-350">
                        <div class="dropdown-content-header">
                            <span class="font-weight-semibold">Latest activity</span>
                            <a href="#" class="text-default"><i class="icon-search4 font-size-base"></i></a>
                        </div>

                        <div class="dropdown-content-body dropdown-scrollable">
                            <ul class="media-list">
                                <?php if(get_notification_saldo()->num_rows() > 0){ 
                                        if($this->i_level == 4){
                                            foreach(get_notification_saldo()->result() as $row){?>
                                <li class="media">
                                    <div class="mr-3">
                                        <a href="<?=  base_url() . 'saldo/approvement/' . encrypt_url($row->id) .'/'.encrypt_url($row->i_periode).'/'.encrypt_url($row->id_customer) ?>" class="btn bg-warning-400 rounded-round btn-icon"><i class="icon-pencil"></i></a>
                                    </div>

                                    <div class="media-body">
                                        Mutasi Saldo Periode <a href="<?=  base_url() . 'saldo/approvement/' . encrypt_url($row->id) .'/'.encrypt_url($row->i_periode).'/'.encrypt_url($row->id_customer) ?>"><?= $row->i_periode ?></a> Meminta Approve
                                        <div class="font-size-sm text-muted mt-1"><?= $row->d_entry ?></div>
                                    </div>
                                </li>
                                <?php } } } ?>

                                <?php if(get_notification_retur()->num_rows() > 0){ 
                                        if($this->i_level == 4){
                                            foreach(get_notification_retur()->result() as $row){?>
                                <li class="media">
                                    <div class="mr-3">
                                        <a href="<?= base_url() . 'retur/approvement/' . encrypt_url($row->id) ?>" class="btn bg-warning-400 rounded-round btn-icon"><i class="icon-pencil"></i></a>
                                    </div>

                                    <div class="media-body">
                                        Retur Pembelian <a href="<?= base_url() . 'retur/approvement/' . encrypt_url($row->id) ?>"><?= $row->i_document ?></a> Meminta Approve
                                        <div class="font-size-sm text-muted mt-1"><?= $row->d_entry ?></div>
                                    </div>
                                </li>
                                <?php } } } ?>

                                <?php if(get_notification_adjust()->num_rows() > 0){ 
                                        if($this->i_level == 4){
                                            foreach(get_notification_adjust()->result() as $row){?>
                                <li class="media">
                                    <div class="mr-3">
                                        <a href="<?= base_url() . 'adjustment/approvement/' . encrypt_url(@$row->id) ?>" class="btn bg-warning-400 rounded-round btn-icon"><i class="icon-pencil"></i></a>
                                    </div>

                                    <div class="media-body">
                                        Adjustment <a href="<?= base_url() . 'adjustment/approvement/' . encrypt_url(@$row->id) ?>"><?= $row->i_document ?></a> Meminta Approve
                                        <div class="font-size-sm text-muted mt-1"><?= $row->d_entry ?></div>
                                    </div>
                                </li>
                                <?php } } } ?>

                                <?php foreach(get_notification_pending_izin()->result() as $row){ ?>
                                    <li class="media">
                                        <div class="mr-3">
                                            <a href="<?= base_url() . 'pengajuanizin/approvement/' . encrypt_url(@$row->id) ?>" class="btn bg-warning-400 rounded-round btn-icon"><i class="icon-pencil"></i></a>
                                        </div>

                                        <div class="media-body">
                                            <p><b><?= $row->e_nama ?></b>, 
                                            Pengajuan Izin <a href="<?= base_url() . 'pengajuanizin/approvement/' . encrypt_url(@$row->id) ?>"><?= $row->e_izin_name ?></a> Meminta Approve
                                            </p>
                                            <div class="font-size-sm text-muted mt-1"><?= date('Y-m-d H:i:s', strtotime($row->d_entry)) ?></div>
                                        </div>
                                    </li>
                                <?php } ?>

                                <!-- <li class="media">
                                    <div class="mr-3">
                                        <a href="#" class="btn bg-success-400 rounded-round btn-icon"><i class="icon-mention"></i></a>
                                    </div>

                                    <div class="media-body">
                                        <a href="#">Taylor Swift</a> mentioned you in a post "Angular JS. Tips and
                                        tricks"
                                        <div class="font-size-sm text-muted mt-1">4 minutes ago</div>
                                    </div>
                                </li> -->

                                
                            </ul>
                        </div>

                        <!-- <div class="dropdown-content-footer bg-light">
                            <a href="#" class="text-grey mr-auto">All activity</a>
                            <div>
                                <a href="#" class="text-grey" data-popup="tooltip" title="Clear list"><i class="icon-checkmark3"></i></a>
                                <a href="#" class="text-grey ml-2" data-popup="tooltip" title="Settings"><i class="icon-gear"></i></a>
                            </div>
                        </div> -->
                    </div>
                </li>

                <li class="nav-item dropdown dropdown-user">
                    <a href="#" class="navbar-nav-link d-flex align-items-center dropdown-toggle" data-toggle="dropdown">
                        <img src="<?= base_url(); ?>global_assets/images/placeholders/placeholder.jpg" class="rounded-circle mr-2" height="34" alt="">
                        <span><?= $this->session->userdata('e_name'); ?></span>
                    </a>

                    <?php                 
                    $id_user = $this->session->userdata('id_user');
                    $encrypt_id_user = encrypt_url($id_user);
                    $url_ganti_password = base_url() . 'user/edit_password/' . $encrypt_id_user;
                    ?>
                    <div class="dropdown-menu dropdown-menu-right">                        
                        <a href="<?= base_url() . 'user/view/' . $encrypt_id_user ?>" class="dropdown-item">
                            <i class="icon-user-plus"></i>Profil Saya
                        </a>
                        <a href="<?= $url_ganti_password ?>" class="dropdown-item">
                            <i class="icon-cog5"></i> Ganti Password
                        </a>
                        <a href="<?= base_url('auth/logout') ?>" class="dropdown-item">
                            <i class="icon-switch2"></i>
                            <?= $this->lang->line('Keluar');?>
                        </a>
                    </div>
                </li>
            </ul>
        </div>
    </div>
    <!-- /main navbar -->


    <!-- Page header -->
    <div class="page-header">
        <div class="breadcrumb-line breadcrumb-line-light header-elements-md-inline">
            <div class="d-flex">
                <div class="breadcrumb">
                    <a href="<?= base_url(); ?>" class="breadcrumb-item"><i class="icon-home2 mr-2"></i> Home</a>
                    <span class="breadcrumb-item active">Dashboard</span>
                </div>

                <a href="#" class="header-elements-toggle text-default d-md-none"><i class="icon-more"></i></a>
            </div>

            <!-- <div class="header-elements d-none">
                <div class="breadcrumb justify-content-center">
                    <div class="breadcrumb-elements-item dropdown p-0">
                        <a href="#" class="breadcrumb-elements-item dropdown-toggle" data-toggle="dropdown">
                            <i class="icon-gear mr-2"></i>
                            Settings
                        </a>

                        <div class="dropdown-menu dropdown-menu-right">
                            <a href="#" class="dropdown-item"><i class="icon-user-lock"></i> Account security</a>
                            <a href="#" class="dropdown-item"><i class="icon-statistics"></i> Analytics</a>
                            <a href="#" class="dropdown-item"><i class="icon-accessibility"></i> Accessibility</a>
                            <div class="dropdown-divider"></div>
                            <a href="#" class="dropdown-item"><i class="icon-gear"></i> All settings</a>
                        </div>
                    </div>
                </div>
            </div> -->
        </div>
    </div>
    <!-- /page header -->


    <!-- Page content -->
    <div class="page-content pt-0">

        <!-- Main sidebar -->
        <div class="sidebar sidebar-light sidebar-main sidebar-expand-md align-self-start">

            <!-- Sidebar mobile toggler -->
            <div class="sidebar-mobile-toggler text-center">
                <a href="#" class="sidebar-mobile-main-toggle">
                    <i class="icon-arrow-left8"></i>
                </a>
                <span class="font-weight-semibold">Main sidebar</span>
                <a href="#" class="sidebar-mobile-expand">
                    <i class="icon-screen-full"></i>
                    <i class="icon-screen-normal"></i>
                </a>
            </div>
            <!-- /sidebar mobile toggler -->


            <!-- Sidebar content -->
            <div class="sidebar-content">

                <!-- User menu -->
                <div class="sidebar-user-material">
                    <div class="sidebar-user-material-body card-img-top" style="background-image: url('<?= base_url(); ?>global_assets/images/backgrounds/user_bg4.jpg')">
                        <div class="card-body text-center">
                            <a href="#">
                                <img src="<?= base_url(); ?>global_assets/images/placeholders/user.jpg" class="img-fluid rounded-circle shadow-2 mb-3" width="80" height="80" alt="">
                            </a>
                            <h6 class="mb-0 text-white text-shadow-dark"><?= $this->session->userdata('e_name'); ?></h6>
                            <span class="font-size-sm text-white text-shadow-dark"><?= $this->session->userdata('e_company_name'); ?></span>
                        </div>

                        <div class="sidebar-user-material-footer">
                            <a href="#user-nav" class="d-flex justify-content-between align-items-center text-shadow-dark dropdown-toggle" data-toggle="collapse">
                                <span><?= $this->lang->line('Akun Saya');?></span>
                            </a>
                        </div>
                    </div>

                    <div class="collapse" id="user-nav">
                        <ul class="nav nav-sidebar">
                            <li class="nav-item">
                                <a href="<?= base_url() . 'user/view/' . $encrypt_id_user ?>" class="nav-link">
                                    <i class="icon-user-plus"></i>
                                    <span><?= $this->lang->line('Profil Saya');?></span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="<?= $url_ganti_password ?>" class="nav-link">
                                    <i class="icon-lock2"></i>
                                    <span>Ganti Password</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="<?= base_url('auth/logout'); ?>" class="nav-link">
                                    <i class="icon-switch2"></i>
                                    <span><?= $this->lang->line('Keluar');?></span>
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
                <!-- /user menu -->


                <!-- Navigation -->
                <div class="card card-sidebar-mobile bg-<?= $this->session->userdata('color'); ?>">
                    
                    <div class="card-body p-0">

                        <ul class="nav nav-sidebar" data-nav-type="">

                            <!-- active menu -->
                            <?php $is_current_menu_active = function($menu) {
                                if (get_current_active_menu() == $menu) {
                                    return 'active';
                                }
                                return '';
                            }; ?>
                            
                            <?php foreach (get_menu()->result() as $key) {

                                if ($key->e_folder == '#') { ?>
                                    <li class="nav-item nav-item-submenu">
                                        <a href="#" class="nav-link a-nav <?= $is_current_menu_active($key->e_menu) ?>">
                                            <i class="<?= $key->icon; ?>"></i>
                                            <span><?=$this->lang->line($key->e_menu);?></span>
                                        </a>

                                        <ul class="nav nav-group-sub" data-submenu-title="<?=$this->lang->line($key->e_menu);?>">
                                            <?php foreach (get_sub_menu($key->id_menu)->result() as $row) { ?>

                                                <!-- hide menu login pengguna jika tidak punya akses create -->
                                                <?php if (intval($row->id_menu) == 104) {
                                                    $is_granted = check_role($row->id_menu, 1);

                                                    if (!$is_granted) {
                                                        continue;
                                                    }
                                                } ?>
                                                

                                                <li class="nav-item">
                                                    <a href="<?= base_url($row->e_folder); ?>" class="nav-link a-nav <?= $is_current_menu_active($row->e_menu) ?>">
                                                        <i class="icon-circle-small"></i><?= $row->e_menu ?>
                                                    </a>
                                                </li>
                                            <?php } ?>
                                        </ul>
                                    </li>
                                <?php } else { ?>
                                    <li class="nav-item">
                                        <a href="<?= base_url($key->e_folder); ?>" class="nav-link a-nav <?= $is_current_menu_active($key->e_menu) ?>">
                                            <i class="<?= $key->icon; ?>"></i>
                                            <span>
                                                <?=$this->lang->line($key->e_menu);?>
                                                <!-- <?= $key->e_menu; ?> -->
                                            </span>
                                        </a>
                                    </li>
                            <?php }
                            } ?>
                        </ul>
                    </div>
                </div>
                <!-- /navigation -->

            </div>
            <!-- /sidebar content -->

        </div>
        <!-- /main sidebar -->


        <!-- Main content -->
        <div class="content-wrapper">

            <!-- Content area -->
            <?= $contents; ?>
            <!-- content area -->

        </div>
        <!-- /main content -->

    </div>
    <!-- /page content -->


    <!-- Footer -->
    <div class="navbar navbar-expand-lg navbar-light">
        <div class="text-center d-lg-none w-100">
            <button type="button" class="navbar-toggler dropdown-toggle" data-toggle="collapse" data-target="#navbar-footer">
                <i class="icon-unfold mr-2"></i>
                Footer
            </button>
        </div>

        <div class="navbar-collapse collapse" id="navbar-footer">
            <span class="navbar-text">
                &copy; 2021 - <?= date('Y'); ?>. <a href="#" onclick="return false;">Management Information System
                    (MIS)</a>
            </span>

            <!-- <ul class="navbar-nav ml-lg-auto">
				<li class="nav-item"><a href="https://kopyov.ticksy.com/" class="navbar-nav-link" target="_blank"><i class="icon-lifebuoy mr-2"></i> Support</a></li>
				<li class="nav-item"><a href="http://demo.interface.club/limitless/docs/" class="navbar-nav-link" target="_blank"><i class="icon-file-text2 mr-2"></i> Docs</a></li>
				<li class="nav-item"><a href="https://themeforest.net/item/limitless-responsive-web-application-kit/13080328?ref=kopyov" class="navbar-nav-link font-weight-semibold"><span class="text-pink-400"><i class="icon-cart2 mr-2"></i> Purchase</span></a></li>
			</ul> -->
        </div>
    </div>
    <!-- /footer -->

</body>

</html>


<!-- Core JS files -->
<script src="<?= base_url(); ?>global_assets/js/main/jquery.min.js"></script>
<script src="<?= base_url(); ?>global_assets/js/main/bootstrap.bundle.min.js"></script>
<script src="<?= base_url(); ?>global_assets/js/plugins/loaders/blockui.min.js"></script>
<script src="<?= base_url(); ?>global_assets/js/plugins/ui/ripple.min.js"></script>
<!-- /core JS files -->

<!-- Theme JS files -->
<!-- <script src="<?= base_url(); ?>global_assets/js/plugins/ui/perfect_scrollbar.min.js"></script>
<script src="<?= base_url(); ?>global_assets/js/plugins/ui/fab.min.js"></script> -->
<!-- /theme JS files -->
<script>
    var base_url = "<?= base_url(); ?>";
    var lang     = "<?= $this->session->userdata('language'); ?>";
</script>
<script src="<?= base_url(); ?>assets/js/app.js"></script>
<script src="<?= base_url(); ?>assets/js/custom.js"></script>
<?= put_footer(); ?>
<!-- /theme JS files -->

<script type="text/javascript">
    const openUpNavigationBar = () => {
        $('.a-nav').each(function() {
            if ($(this).hasClass('active')) {
                const me = $(this);
                let parent = me.closest('ul');
                let grandParent = parent.closest('li');
                if (parent !== undefined) {
                    parent.css('display', 'block');
                }

                if (grandParent !== undefined) {
                    grandParent.addClass('nav-item-open');
                }
            }
        })        
    }

    $(document).ready(function() {
        openUpNavigationBar()
    })
</script>