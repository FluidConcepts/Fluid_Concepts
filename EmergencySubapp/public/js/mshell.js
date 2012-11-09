// Copyright 2010-2012 Ellucian. All Rights Reserved.

/* Login */
$(document).on('pageinit', '#mshell-login-page', function() {
    $page = $(this)
    $page.find('#login-login-failed').hide()
    $page.find('#login-password').val('')
    $form = $page.find('#list-login-form')
    $form.unbind('submit', loginSubmit)
    $form.bind('submit', loginSubmit)
    function loginSubmit(event) {
        // kill keyboard
        if( window.document.activeElement ){
            $( window.document.activeElement || "" ).add( "input:focus, textarea:focus, select:focus" ).blur();
        }

        // Show the loading message
        $.mobile.showPageLoadingMsg();

        //loginUrl = $(this).attr('ajax-action')
        var loginUrl = $('#login-url').val()
        var launchMappId = $('#launch-mapp-id').val()
        mappJqmEnabled = $('#mapp-jqm-enabled').val()
        $.getJSON( loginUrl, $(this).serialize(),
                   function(json) {
            $.mobile.hidePageLoadingMsg()

            if (json.result === "success") {
                // hide the error message
                mc.setLoggedIn(true);
                $('#login-login-failed').fadeOut()
                
                removeMshellShowPage();
                
                if ( json.authorized == undefined || json.authorized ) {
                    // Launch the mapp
                    var destination = $('#login-success-url').val()
                    if ( !destination || destination == "" ) {
                        history.back()
                    } else {
                        if ( launchMappId != "" && mappJqmEnabled != "true" ) {
                            window.open( destination , "_self", '', false )
                        } else {
                            $.mobile.changePage( destination, { transition: 'pop', reverse: true, reloadPage: true } )                    
                        }
                    }
                } else {
                    // Not Authorized to view mapp
                    var destination = $('#login-not-authorized-url').val()
                    if ( destination ) {
                        $.mobile.changePage( destination, { role: "dialog", transition: 'pop', reloadPage: true } )                        
                    } else {
                        alert( "login-not-authorized-url is not defined - please report")
                    }
                }
                
            } else {
                // show the error message
                $('#login-login-failed').fadeIn()
            }
        })

        // always stop the submit - login result will determine if the login page is dismissed
        event.preventDefault()    
        return false;
    }
})

$(document).on('pagebeforeshow', '#mshell-login-page', function(event, ui) {
    $(this).find('#login-login-failed').hide()
    $(this).find('#login-password').val('')
    
    // save off the previous page
    $.mobile.activePage.data('previousPage', ui.prevPage)
})

$(document).on('click', '#list-mshell-show-page #mode,#icon-mshell-show-page #mode', function() {
    var url = "/app/Mshell/set_mode?mode=" + $(this).attr("data-mode")
    $.mobile.showPageLoadingMsg()
    $.getJSON( url, function(json) {
        $.mobile.hidePageLoadingMsg()
        window.location = "/app/Mshell"
    })
})

function mshell_login() {
	$.mobile.changePage( "/app/Mshell/show_login", { reloadPage: true, transition: 'pop' } )
}

function mshell_logout(after_url) {
	var url = "/app/Mshell/async_logout"
    $.mobile.showPageLoadingMsg()
    $.getJSON( url, function(json) {
        $.mobile.hidePageLoadingMsg()
    	$.mobile.changePage( after_url, { reloadPage: true, transition: 'fade', allowSamePageTransition: true } )
    })
}

function open_about() {
	var about_url = "/app/About/show_about"
	$.mobile.changePage(about_url)	
}

$(document).on('pageshow', '#list-mshell-show-page,#icon-mshell-show-page', function() {
   $.get("/app/Mshell/set_mshell_controls", function() {})
})

function removeMshellShowPage() {
	var mShellShowPageSuffix = '-mshell-show-page';
	if ($.mobile.activePage.attr('id').match(mShellShowPageSuffix+'$') != mShellShowPageSuffix ) {
		$("div[id$='-mshell-show-page']").remove()
	}
}