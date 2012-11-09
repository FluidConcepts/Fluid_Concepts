/* JQM 1.1 PATCH */
// dialog sets the ui-overlay-<theme> but doesn't always clean it up! in JQM 1.1
$(document).on("pagebeforehide", ':jqmData(role="dialog")', function() {
    var theme = $(this).jqmData("overlay-theme") || "a"
    $.mobile.pageContainer.removeClass( "ui-overlay-" + theme)
})
// page sets the ui-overlay-<theme> but doesn't always clean it up! in JQM 1.1
$(document).on("pagebeforehide", ':jqmData(role="page"),:jqmData(role="dialog")', function() {
    var theme = $(this).jqmData("theme") || "c"
    $.mobile.pageContainer.removeClass( "ui-overlay-" + theme)
})
/* JQM 1.1 PATCH */

mc = {
    loggedIn: false,
    $homePage: null,
    isLoggedIn: function() {
        return loggedIn;
    },
    setLoggedIn: function(loggedIn) {
        this.loggedIn = loggedIn;
    },
    log_to_app: function(message) {
    	$.post("/app/Mshell/js_log", {message: message});
    }
};

$(document).on('pageinit', "#list-mshell-show-page, #icon-mshell-show-page", function(event) {
    // set logged in state from controller
    mc.loggedIn = $(this).hasClass('logged-in')
})

$(document).on('pagebeforeshow', "#list-mshell-show-page, #icon-mshell-show-page", function(event) {
    // keep $homePage up to date
    mc.$homePage = $(this)
    if ( mc.loggedIn ) {
        mc.$homePage.removeClass("logged-out").addClass("logged-in")
        // footer needs to know on it own because sometimes it lives outside of a page
        $('div.footer').removeClass("logged-out").addClass("logged-in")
    }
    else {
        mc.$homePage.removeClass("logged-in").addClass("logged-out")        
        // footer needs to know on it own because sometimes it lives outside of a page
        $('div.footer').removeClass("logged-in").addClass("logged-out")
    }
})

$(document).on('pageshow', function(event) {
    var loadedJS = []
    var javascriptsToLoad = 0;

    // build list of already loaded JS
    $('head script').each( function() { loadedJS.push($(this).attr('src'))})

	//mc.log_to_app('generic pagecreate, target: '+event.target.id);
    var needToLoad = [];
    // get the mApps being displayed
    $.getJSON("/app/Mshell/mapp_js_files", function(results) {
        var filelist = results["filelist"];
        $.each(filelist, function(index,path) {
            //   if not loaded, add to the missing list
            if (loadedJS.indexOf(path) == -1 ) {
                needToLoad.push(path)
            }
        });
        if (needToLoad.length > 0) {
        	//mc.log_to_app('mApp js NOT LOADED, load them now');
            javascriptsToLoad = needToLoad.length;
            $.each(needToLoad, function(index, path) {
                var scriptElement = document.createElement("script");
                scriptElement.setAttribute("type", "text/javascript");
                scriptElement.setAttribute("src", path);
                scriptElement.onload = function() {
                    // stamp that this js has been loaded, and decrement
                	// count of outstanding loads
                	loadedJS.push(path)
                    javascriptsToLoad--;
                    if (javascriptsToLoad == 0) {
                        var dataUrl = $.mobile.activePage.jqmData('url')
                        if (dataUrl.indexOf("/app/Mshell") != 0) { // no need to reload Mshell
                            //mc.log_to_app("!!! FORCED A PAGE REFRESH FOR (RE)LOADED JS FILES !!!");
                            $.mobile.changePage(dataUrl, {allowSamePageTransition: true, transition: "none", reloadPage: true, changeHash: false});
                        }
                    }
                }
                document.getElementsByTagName("head")[0].appendChild(scriptElement);
            });
        } else {
            javascriptsToLoad = 0;
        }  
    });
})

$(document).on('pageinit', ':jqmData(role="page"),:jqmData(role="dialog")', function(event) {
    // fix the data-url if JQM defaulted it to the page ID
    var $page = $(this),
        id = $page.attr('id'),
        dataUrl = $page.jqmData('url');
    if (dataUrl === id ) {
        // fix it
        dataUrl = location.href.substring(location.href.indexOf('/app/'))
        $page.jqmData('url', dataUrl)
        $page.attr('data-' + $.mobile.ns + 'url', dataUrl)
    }
})

$(document).on('pageremove', ':jqmData(role="page"),:jqmData(role="dialog")', function(event) {
    // manage pages that which to be cached while the m-App is active
    var $pageToRemove = $(event.target),
        cachingMApp = $pageToRemove.jqmData('cache-m-app');
        
    if (cachingMApp) {
        var $nextPage = $.mobile.activePage,
            nextPageUrl = $nextPage.jqmData('url').match(/^\/app\/[a-z,A-Z,0-9]+/)[0],
            pageToRemoveUrl = $pageToRemove.jqmData('url').match(/^\/app\/[a-z,A-Z,0-9]+/)[0];
        
        if ( nextPageUrl == pageToRemoveUrl) {
            event.preventDefault()
        } else {
            // remove all m-App pages, unless they have a data-dom-cache="true"
            $('[data-url^="' + pageToRemoveUrl + '"]').each( function() {
                var cache = $(this).jqmData('dom-cache');
                if (!(cache || $(this).is($pageToRemove))) {
                    $(this).remove()
                }
            })
        
            // let this one be removed
        }
    }
})

// enable menus
$(document).on('pageinit', ':jqmData(role="page")', function() {

    $(':jqmData(role="header")').fixedtoolbar({ tapToggle: false });

    var page = $(this)

    // Menu
    var menuButton = page.find(".menuLink")
    if ( menuButton.length > 0 ) {
        var menu = page.find("ul.menu")
        hideMenu(page, menuButton)
        enableMenu( page, menuButton, menu, showMenu, hideMenu)
    }

    // More Menu
    var moreMenuButton = page.find("#more-link")
    if ( moreMenuButton.length > 0 ) {
        var moreMenu = page.find("#more-menu")
        hideMoreMenu(page, moreMenu)
        enableMenu( page, moreMenuButton, moreMenu, showMoreMenu, hideMoreMenu)
    }
});

function showMenu(page, menu) {
    var numberOfOptions = menu.find('li').length
    var liWidth = numberOfOptions <= 3 ? (Math.round( 100 / numberOfOptions ) - 1) + '%' : "33%"
    menu.css('top', $(window).scrollTop() + 43 + 'px')
    menu.find('li').css('width', liWidth)
    menu.fadeIn()
    //menu.slideDown()
}

function hideMenu(page, menu) {
    menu.fadeOut()
    //menu.slideUp()
}

function showMoreMenu(page, menu) {
    var bottomScroll = page.outerHeight() - window.innerHeight - $(window).scrollTop()
    menu.css('bottom', bottomScroll + 50)
    page.find('#more-link').addClass("selected")
    menu.fadeIn()
}

function hideMoreMenu(page, menu) {
    page.find('#more-link').removeClass("selected")
    menu.fadeOut()
}

function enableMenu(page, button, menu, showMenu, hideMenu) {
    // ensure hidden to start with
    hideMenu(page, menu)
    
    // bind for the click on the menu button
    button.one('click', function(event) {
        
        // show the menu
        showMenu(page, menu)
        
        // dimiss on a click to anywhere on the page, but disable all link except in the menu
        page.bind('click', function(event) {
            var followLinkFlag = false
            var hideMenuFlag = true
            
            if ( menu.has(event.target).length > 0 && $(event.target).is('a') ) {
                // clicked a menu link
                followLinkFlag = true
                hideMenuFlag = true
            } else if ( $(event.target).get(0) === menu.get(0) ||
                        menu.has(event.target).length > 0 ) {
                        
                // click on a non-link part of menu, just ignore it
                followLinkFlag = false
                hideMenuFlag = false
            }
            
            if ( hideMenuFlag )
            {
                // unbind the page click
                page.unbind(event)
                
                // hide the menu
                hideMenu(page, menu)
                
                // re-enable menu button click
                enableMenu(page, button, menu, showMenu, hideMenu)
            }
            
            if ( !followLinkFlag ) event.preventDefault()
            return followLinkFlag
        });
        
        // stop click propigation
        event.preventDefault()
        return false
    });
}

// Ensure current m-Aapp is set - controller is not invoked if the page is cached
$(document).on('pagebeforeshow', ':jqmData(role="page"):jqmData(url*="launch_mapp")', function(event) {
    var url = "/app/Mshell/set_mapp?id=" + $(this).jqmData("url").match(/(\?id=)(.*)/)[2]
    $.getJSON( url, function(json) {
        // success
    });
});

// bind clicks to sign in and out links
$(document).on('pageinit', ':jqmData(role="page")', function() {
    var $page = $(this)

    // Bind on Sign In click
    $page.find('a.sign-in-link').bind('click', function(event) {
        var success_url = $page.jqmData('url'),
            transition = $(this).jqmData('transition') || "fade",
            url = $(this).jqmData('login-url'),
            data = { success_url: success_url }
            
        // hide menu if showing
        $(document).trigger("menuhide")
        
        $.mobile.changePage( url, {
            transition: transition,
            changeHash: true,
            data: data,
            role: "dialog" } )
            
        event.preventDefault()
        return false
    });
    
    // Bind on Sign Out click
    $(this).find('a.sign-out-link').bind('click', function(event) {
        var success_url = $page.jqmData('url'),
            transition = $(this).jqmData('transition') || "fade",
            direction =  $(this).jqmData('direction'),
            url = $(this).jqmData('logout-url')

        // hide menu if showing
        $(document).trigger("menuhide")

        reverse = false
        if ( direction && direction === "reverse" ) reverse = true

        $.getJSON( url, function(json) {
            $.mobile.changePage( success_url, {
                transition: transition,
                reverse: reverse,
                reloadPage: true } )
                mc.setLoggedIn(false);
        });
            
        event.preventDefault()
        return false
    });
});


// ThemeRoller Support for Calendar/DateBox plugin
// Add Theme classes to DateBox after it has rendered it's enhancements: this allows 
// the theme to drive the colors making it work with the ThemeRoller Tool
$(document).on('pageshow', ':jqmData(role="page")', function(){
    // add 'ui-bar-f' class to div container of the header
    $(".ui-datebox-gridheader").addClass("ui-bar-f");
    // add 'ui-body-a' class to items in the Day Name row of the grid   
   // $(".ui-datebox-griddate.ui-datebox-griddate-empty.ui-datebox-griddate-label").addClass("ui-body-a");
    //$('.ui-datebox-gridrow:first-child').addClass('ui-body-a');
});


/***************************
MC Menu Widget
****************************/

(function($, undefined) {
    $.widget("mobile.menu", $.mobile.widget, {
        options: {
            location: "header",
            icon: "menu",
            theme: null,
            disabled: false,
            initSelector: "ul:jqmData(role='menu')"
        },
        _create: function() {
            $(document).trigger("menucreate");
            var $menu = this.element,
                $parentPage = $($menu.closest('.ui-page')),
                o = $.extend(this.options, $menu.data("options")),
                dns = "data-" + $.mobile.ns,
                icon, content;

            function showMenu() {
                var numberOfOptions = 0
                $menu.find('li').each( function() {
                    if ( $(this).css("display") != "none" ) {
                        numberOfOptions++
                    }
                })
                var liWidth = numberOfOptions <= 3 ? (Math.round( 100 / numberOfOptions ) - 1) + '%' : "33%"
                var $header = $($parentPage.find(':jqmData(role="header")'))
                var top = $(window).scrollTop() + $header.outerHeight()
                $menu.css('top', top + 'px')
                $menu.find('li').css('width', liWidth)
                $menu.fadeIn()
                $pageCover.show()
            }

            function hideMenu(page, menu) {
                $menu.fadeOut()
                $pageCover.hide()
            }

            function menuShowHandler(event) {
                showMenu()
                $(this).unbind("click", menuShowHandler);
                $(this).unbind("menushow", menuShowHandler);
                $(document).bind("click menuhide", menuHideHandler );
                
                // prevent scrolling
                $(document).bind("touchmove", touchMovePrevent);
                
                // prevent header from tap disappearing
                $parentPage.find("[data-role=header]").fixedtoolbar({ tapToggle: false });
                
                event.preventDefault();
                return false;
            }

            function menuHideHandler(event) {
                // hide menu and enable menu icon again
                hideMenu()
                $(this).unbind("click", menuHideHandler);
                $(this).unbind("menuhide", menuHideHandler);
                icon.bind("click menushow", menuShowHandler );
                
                // allow scrolling again
                $(document).unbind("touchmove", touchMovePrevent);
                
                var $target = $(event.target);
                if ($menu.has($target).length > 0 && $target.is('a')) {
                    return true;
                }
                else {
                    event.preventDefault();
                    return false;
                }
            }
            
            function touchMovePrevent(event) {
                return menuHideHandler(event)
            }

            o.location = $menu.jqmData( "location" ) || o.location;
            o.icon = $menu.jqmData( "icon" ) || o.icon;
            o.theme = $menu.jqmData( "theme" ) || o.theme;
            o.disabled = $menu.jqmData( "disabled" ) || o.disabled;

            if ( !o.theme ) {
                o.theme = $.mobile.getInheritedTheme( this.element, "a" );
            }

            $content = $($parentPage.find(':jqmData(role="content")'));
            $header = $($parentPage.find(':jqmData(role="header")'));

            // add the icon right before the initial menu UL
            var icon = $('<a href="#" ' + dns + 'icon="' + o.icon + '" class="ui-btn-right" data-iconpos="notext" data-corners="false", data-iconshadow="false" data-shadow="false">Menu</a>')
            icon.bind("click menushow", menuShowHandler);
            $menu.before(icon);
            
            // create the page cover (to intercept clicks and gestures)
            var $pageCover = $($("<div class=\"ui-menu-page-cover\">"));
            $content.append($pageCover)

            // Create a new menu UL, append old menu UL children and enhance
            var $newMenu = $($('<ul data-role="listview" ' + dns + 'theme="' + o.theme + '" class="ui-menu ui-body-' + o.theme + '">'))
            $newMenu.append($menu.children())
            $menu.remove()
            $menu = $newMenu
            $content.append($menu)
            $parentPage.one("pagebeforeshow", function(event) {
                // enhance the injected elements for menu
                $header.trigger("create");
                $content.trigger('create');
            });
        },
        hide: function() {
            $(document).trigger("menuhide");
        },
        show: function() {
            $(document).trigger("menushow");
        }
    });
    $(document).bind("pagecreate create", function(event) {
        $(document).trigger("menubeforecreate");
        $.mobile.menu.prototype.enhanceWithin( event.target );
    });
})(jQuery);

