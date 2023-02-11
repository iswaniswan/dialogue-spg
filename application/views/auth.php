<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>SPG - Login</title>

    <!-- Global stylesheets -->
    <link href="https://fonts.googleapis.com/css?family=Roboto:400,300,100,500,700,900" rel="stylesheet"
        type="text/css">
    <link href="<?php echo base_url();?>global_assets/css/icons/icomoon/styles.min.css" rel="stylesheet"
        type="text/css">
    <link href="<?php echo base_url();?>assets/css/bootstrap.min.css" rel="stylesheet" type="text/css">
    <link href="<?php echo base_url();?>assets/css/bootstrap_limitless.min.css" rel="stylesheet" type="text/css">
    <link href="<?php echo base_url();?>assets/css/layout.min.css" rel="stylesheet" type="text/css">
    <link href="<?php echo base_url();?>assets/css/components.min.css" rel="stylesheet" type="text/css">
    <link href="<?php echo base_url();?>assets/css/colors.min.css" rel="stylesheet" type="text/css">
    <!-- /global stylesheets -->

    <!-- Core JS files -->
    <script src="<?php echo base_url();?>global_assets/js/main/jquery.min.js"></script>
    <script src="<?php echo base_url();?>global_assets/js/main/bootstrap.bundle.min.js"></script>
    <script src="<?php echo base_url();?>global_assets/js/plugins/loaders/blockui.min.js"></script>
    <script src="<?php echo base_url();?>global_assets/js/plugins/ui/ripple.min.js"></script>
    <script src="<?php echo base_url();?>global_assets/js/plugins/forms/styling/uniform.min.js"></script>
    <script src="<?php echo base_url();?>assets/js/login/index.js"></script>

    <!-- /core JS files -->

    <!-- Theme JS files -->
    <script src="<?php echo base_url();?>assets/js/app.js"></script>
    <!-- /theme JS files -->

</head>

<body
    style="background-image: url('<?= base_url();?>global_assets/images/backgrounds/user_bg2.jpg'); height: 100%; background-position: center; background-repeat: no-repeat; background-size: cover;">

    <!-- Page content -->
    <div class="page-content">

        <!-- Main content -->
        <div class="content-wrapper">

            <!-- Content area -->
            <div class="content d-flex justify-content-center align-items-center">

                <!-- Login form -->
                <form class="login-form" action="<?php base_url().'/auth/'?>" method="post">
                    <div class="card mb-0">
                        <div class="card-body">
                            <div class="text-center mb-3">
                                <i
                                    class="icon-reading icon-2x text-slate-300 border-slate-300 border-3 rounded-round p-3 mb-3 mt-1"></i>
                                <h5 class="mb-0">Login to your account</h5>
                                <!-- <span class="d-block text-muted">Enter your credentials below</span> -->
                                <h6><?= $this->session->flashdata('message'); ?></h6>
                            </div>

                            <div class="form-group form-group-feedback form-group-feedback-left">
                                <input type="text" class="form-control" required placeholder="Username" name="username" autofocus>
                                <div class="form-control-feedback">
                                    <i class="icon-user ml-2 text-muted"></i>
                                </div>
                            </div>

                            <div class="form-group form-group-feedback form-group-feedback-left">
                                <input type="password" class="form-control" required placeholder="Password"
                                    name="password">
                                <div class="form-control-feedback">
                                    <i class="icon-lock2 ml-2 text-muted"></i>
                                </div>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn bg-slate btn-block">Sign in <i
                                        class="icon-circle-right2 ml-2"></i></button>
                            </div>
                        </div>
                    </div>
                    <div class="card card-body mt-1 border-top-slate">
                        <label class="font-weight-semibold text-center">Select Color Aplikasi</label>
                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-slate" value="slate" checked data-fouc>
                                        Slate
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-primary" value="primary" data-fouc>
                                        Primary
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-danger" value="danger" data-fouc>
                                        Danger
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-success" value="success" data-fouc>
                                        Success
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-warning" value="warning" data-fouc>
                                        Warning
                                    </label>
                                </div>
                            </div>
                            <div class="col-md-4">

								<div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-pink" value="pink" data-fouc>
                                        Pink
                                    </label>
                                </div>

								<div class="form-check">
									<label class="form-check-label">
										<input type="radio" name="color"
											class="form-check-input-styled-violet" value="violet" data-fouc>
										Violet
									</label>
								</div>

								<div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-purple" value="purple" data-fouc>
                                        Purple
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-indigo" value="indigo" data-fouc>
                                        Indigo
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-blue" value="blue" data-fouc>
                                        Blue
                                    </label>
                                </div>

                            </div>

                            <div class="col-md-4">

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-teal" value="teal" data-fouc>
                                        Teal
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-green" value="green" data-fouc>
                                        Green
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-orange" value="orange" data-fouc>
                                        Orange
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-brown" value="brown" data-fouc>
                                        Brown
                                    </label>
                                </div>

                                <div class="form-check">
                                    <label class="form-check-label">
                                        <input type="radio" name="color"
                                            class="form-check-input-styled-grey" value="grey" data-fouc>
                                        Grey
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>
            </div>
            </form>
            <!-- /login form -->

        </div>
        <!-- /content area -->

    </div>
    <!-- /main content -->

    </div>
    <!-- /page content -->

</body>

</html>
<script>

</script>