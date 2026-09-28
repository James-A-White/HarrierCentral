jQuery(window).bind('load', function()
{ 
	mo2fa_has_elementor_class = jQuery('.htmega-login-form-wrapper');
	
	if(mo2fa_has_elementor_class.length){

		var mo2fa_input =  document.getElementsByTagName('input');
        var mo2fa_on_submit = mo2fa_input[3].getAttribute('id');
        mo2fa_on_submit = '#' +mo2fa_on_submit;

       	var mo2fa_form_id = jQuery('form').attr('id');
		mo2fa_form_id = '#'+mo2fa_form_id ;
       	jQuery(mo2fa_form_id).removeAttr('action');
	    var mo2fa_log_user =  document.getElementsByName('login_username');
        var mo2fa_log_pass =  document.getElementsByName('login_password');
        mo2fa_log_user[0].setAttribute("name","mo2fa_user_name");
        mo2fa_log_pass[0].setAttribute("name","mo2fa_user_password");

		var mo2fa_pwd = document.getElementsByName("mo2fa_user_password");
		mo2fa_pwd = mo2fa_pwd[0];
		var mo2fa_pwd = document.getElementById(mo2fa_pwd.id);
		mo2fa_pwd.setAttribute("id","mo2fa_user_password");

		var mo2fa_user = document.getElementsByName("mo2fa_user_name");
		mo2fa_user = mo2fa_user[0];
		var element = document.getElementById(mo2fa_user.id);
		element.setAttribute("id","mo2fa_user_name");

        if(my_ajax_object.mo2f_login_option == '0'){
        	
        	jQuery(mo2fa_form_id).after('<form name="f" id="mo2f_show_loginform" method="post" action="" hidden>'+
            '<input type="text" name="mo2fa_username" id="mo2fa_username" hidden/>'+
            '<input type="hidden" name="miniorange_login_nonce" value="'+my_ajax_object.nonce+'"/>'+'</form>'+
            '<form name="f" id="mo2f_loginform" method="post" action="" hidden>'+
            '<input type="text" name="mo2fa_elementor_user_name" id="mo2fa_elementor_user_name" hidden/>'+
            '<input type="text" name="mo2fa_elementor_user_password" id="mo2fa_elementor_user_password" hidden/>'+
            '<input type="hidden" name="miniorange_elementor_login_nonce" value="'+my_ajax_object.nonce+'"/>'+'</form>');

	        if(my_ajax_object.mo2f_enable_login_with_2nd_factor == '0'){      	
	        	jQuery(mo2fa_pwd).after('<h2 style="text-align: center;">or</h2><input type="text" name="mo2fa_usernamekey" id="mo2fa_usernamekey" autofocus="true" placeholder="Username"/>'+
	'<button style="padding:1px 4px 1px 4px; width:100%" name="miniorange_login_submit" id="miniorange_login_submit">Login with 2nd factor </button>');
	        }else{
		        jQuery("label[for='Password']").hide();
		        jQuery("#mo2fa_user_password").hide();
		         mo2fa_user = document.getElementsByName("mo2fa_user_name");
		       	mo2fa_user[0].setAttribute("name","mo2fa_usernamekey");
		       	mo2fa_log_user = document.getElementsByName("mo2fa_usernamekey");
		       	mo2fa_log_user[0].setAttribute("id","mo2fa_usernamekey");
			}
		}
		else{
			jQuery(mo2fa_form_id).after('<form name="f" id="mo2f_loginform" method="post" action="" hidden>'+
            '<input type="text" name="mo2fa_elementor_user_name" id="mo2fa_elementor_user_name" hidden/>'+
            '<input type="text" name="mo2fa_elementor_user_password" id="mo2fa_elementor_user_password" hidden/>'+
            '<input type="hidden" name="miniorange_elementor_login_nonce" value="'+my_ajax_object.nonce+'"/>'+'</form>');
		}

		jQuery('#mo2fa_user_password').keypress(function (e) {
			if (e.which == 13) {//Enter key pressed		
			   e.preventDefault();
			   mo2fa_elementor();
			}			
		});
		jQuery(mo2fa_on_submit).click(function(e){
  				if (e.which == 1) {//Enter key pressed
			   e.preventDefault();
			   mo2fa_elementor();
			}	
			});
		 jQuery('#mo2fa_user_name').keypress(function (e){
		 	if (e.which == 13) {//Enter key pressed	
		 	e.preventDefault();
		 	   mo2fa_elementor();
		 	}
		 });
		 jQuery('#mo2fa_usernamekey').keypress(function (e) {
            if (e.which == 13) {//Enter key pressed
                e.preventDefault();
                var username = jQuery('#mo2fa_usernamekey').val();
                document.getElementById("mo2f_show_loginform").elements[0].value = username;
                jQuery('#mo2f_show_loginform').submit();
            }

        });
		jQuery('.htmega-login-form-wrapper' ).on( 'submit', mo2fa_form_id, function(e) { 
				e.preventDefault();
                mo2f_login();
			
		 });
		function mo2fa_elementor(){
			if(my_ajax_object.mo2f_login_option == '1' || (my_ajax_object.mo2f_login_option == '0' && my_ajax_object.mo2f_enable_login_with_2nd_factor == '0' )){
				mo2f_login();
			}
			else{
                var username = jQuery('#mo2fa_usernamekey').val();
                document.getElementById("mo2f_show_loginform").elements[0].value = username;
                jQuery('#mo2f_show_loginform').submit();
			}
		 }

		 jQuery('#miniorange_login_submit').click(function(e){
		 	e.preventDefault();
		 	var username = jQuery('#mo2fa_usernamekey').val();
                 
            document.getElementById("mo2f_show_loginform").elements[0].value = username;
                
           jQuery('#mo2f_show_loginform').submit();		 	
       });

		 function mo2f_login(){
		 		var username = jQuery('#mo2fa_user_name').val();
		 		var password = jQuery('#mo2fa_user_password').val();
                 
            document.getElementById("mo2f_loginform").elements[0].value = username;
            document.getElementById("mo2f_loginform").elements[1].value = password;
                
           jQuery('#mo2f_loginform').submit();	
		 }

		}

});
