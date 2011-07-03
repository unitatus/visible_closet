jQuery.noConflict();
jQuery(function($) { 
	
	
	/* Drop Down Menu (superfish + hoverintent + supersubs)
	___________________________________________________________________ */
	// http://users.tpg.com.au/j_birch/plugins/superfish/#getting-started
	// http://users.tpg.com.au/j_birch/plugins/superfish/#options
	$(".sf-menu").supersubs({ 
			minWidth:    13,   // minimum width of sub-menus in em units 
			maxWidth:    27,   // maximum width of sub-menus in em units 
			extraWidth:  1     // extra width can ensure lines don't sometimes turn over 
							   // due to slight rounding differences and font-family 
		}).superfish({
			dropShadows:    false,
			delay:			400
			
							}); // call supersubs first, then superfish, so that subs are 
                         		// not display:none when measuring. Call before initialising 
                         		// containing tabs for same reason. 


	
	/* Menu Hover Indent
	___________________________________________________________________ */
	var sf_hover_sel = $(".sf-menu ul a");
	var sf_link_padding = parseInt(sf_hover_sel.css('padding-left'));
	var sf_hover_offset = 2 + sf_link_padding;
	$(sf_hover_sel).hover(
		function () {
			$(this).stop().animate({"padding-left": sf_hover_offset + "px"}, 75);
		  }, 
		  function () {
			$(this).stop().animate({"padding-left": sf_link_padding + "px"}, 250);
		  }
	);
	
	
	
	
	/* Social Icon Hover
	___________________________________________________________________ */	
	var social_icon_opacity = 0.5;
	var social_icon_img = $('.cudazi-social-icons').find('img');
	social_icon_img.fadeTo(0, social_icon_opacity);
	$(social_icon_img).hover(
		function () {
			$(this).stop().fadeTo(100, 1);
		  }, 
		  function () {
			$(this).stop().fadeTo(300, social_icon_opacity);
		  }
	);
	
		
	
	
	/* Lightbox (Fancybox)
	___________________________________________________________________ */
	// Ex: open any link <a href="large.jpg" />...
	$('a[href$="jpg"], a[href$="jpeg"], a[href$="png"], a[href$="gif"]').fancybox();

	// Vimeo Popup - Regula Size
	$(".vimeo-popup").click(function() {
		$.fancybox({
			'padding'		: 0,
			'autoScale'		: false,
			'transitionIn'	: 'none',
			'transitionOut'	: 'none',
			'title'			: this.title,
			'width'			: 680,
			'height'		: 495,
			'href'			: this.href.replace(new RegExp("([0-9])","i"),'moogaloop.swf?clip_id=$1'),
			'type'			: 'swf'
		});
		return false;
	});
	
	// Youtube Popup
	$(".youtube-popup").click(function() {
		$.fancybox({
				'padding'		: 0,
				'autoScale'		: false,
				'transitionIn'	: 'none',
				'transitionOut'	: 'none',
				'title'			: this.title,
				'width'			: 640,
				'height'		: 360,
				'href'			: this.href.replace(new RegExp("watch\\?v=", "i"), 'v/'),
				'type'			: 'swf',
				'swf'			: {
				   	 'wmode'		: 'transparent',
					'allowfullscreen'	: 'true'
				}
			});
	
		return false;
	});

	// Default Modal box
	$(".modal-box").fancybox({
		'modal' : true
	});
	
	// iFrame
	$(".iframe").fancybox({
		'width' : '95%',
	    'height' : '95%',
	    'autoScale' : false,
	    'transitionIn' : 'none',
	    'transitionOut' : 'none',
	    'type' : 'iframe'
	}); 
		
		
		
		
		
	/* Sign Up Form Validation
	___________________________________________________________________ */
	$(".standard #user_first_name, .standard #user_last_name, .standard #user_email, .standard #user_password, .standard #user_password_confirmation").live('change click', function(){
		return checkForm();
	});
	function checkForm() {
		var hasError = false;
		var emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
		if($(".standard #user_first_name").val() == '') {
			$("#user_first_name").addClass('error');
			hasError = true;
		}else{
			$("#user_first_name").removeClass('error');
		}
		if($(".standard #user_last_name").val() == '') {
			$("#user_last_name").addClass('error');
			hasError = true;
		}else{
			$("#user_last_name").removeClass('error');
		}
		if($("#user_email").val() == '') {
			$("#user_email").addClass('error');
			hasError = true;
		}else if(!emailReg.test( $("#user_email").val() )) {
			$("#user_email").addClass('error');
			hasError = true;
		}else{
			$("#user_email").removeClass('error');
		}
		if($("#user_password").val() == '') {
			$("#user_password").addClass('error');
			hasError = true;
		}else{
			$("#user_password").removeClass('error');
		}
		if($("#user_password_confirmation").val() == '') {
			$("#user_password_confirmation").addClass('error');
			hasError = true;
		}else{
			$("#user_password_confirmation").removeClass('error');
		}
		if($("#user_password_confirmation").val() != $("#user_password").val()) {
			$("#user_password_confirmation").addClass('error');
			hasError = true;
		}else{
			$("#user_password_confirmation").removeClass('error');
		}
		if(hasError == true){
			return false;
		}else{
			return true;
		}
	}
	// end contact form validation
		
}); // end jQuery

















