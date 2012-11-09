// Fix issue with dialog adding ui-body-a regardless of the data-theme

// JQuery Mobile 1.0 doesn't set data-theme for dialogs
$(document).bind("mobileinit", function() {
    // Configure JQuery Mobile
    
    $.mobile.minScrollBack = "50"
    $.mobile.pushStateEnabled = false
    
    $.mobile.allowCrossDomainPages = true;
    $.mobile.zoom.enabled = false;
    $.mobile.buttonMarkup.hoverDelay = 0; //defaults 200
    
    // seems to be issues on double fades with default fade transitions on iOS
    // for now no transitions for all
    //var isiOS = navigator.userAgent.match(/iPhone|iPad|iPod/i)
    //if ( !isiOS ) {
        $.mobile.defaultDialogTransition = 'none';
        $.mobile.defaultPageTransition = 'none';
    //}
    
    // fetch language specific loading and error loading messages
    $.getJSON( "/app/Mshell/get_jquery_mobile_locale_strings", function(json) {
        $.mobile.loadingMessage = json.loadingMessage
        $.mobile.pageLoadErrorMessage = json.errorLoadingMessage
    })
})