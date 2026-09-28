/**
 *  Advanced iframe pro external workaround file v
 *  Created: 2022-07-29 14:39:12
*/
/* jslint devel: true, evil: false */
// I added this for IOS debugging as there it is hard to find out where the problem is
var extendedDebug = false;
var aiParent = window.parent;



if (typeof domain_advanced_iframe === 'undefined') {
    var domain_advanced_iframe = '/wp-content/plugins/advanced-iframe'; // Check if this is this is the path to the main directory of aip
}

// IE11 does not support includes
if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
  if (typeof start !== 'number') {
    start = 0;
  }
  if (start + search.length > this.length) {
    return false;
  } else {
    return this.indexOf(search, start) !== -1;
  }
  };
}

function aiTrimExtraChars(text) {
    return text == null ? '' : text.toString().replace(/^[\s:;]+|[\s:;]+$/g, '');
}

function aiDebugExtended(message) {
  if (extendedDebug) {
    if (console && console.log) {
      console.log("Advanced iframe: " + message);
    }
  }
}

/**
 * first we modify the iframe content
 * only once in case the script is included several times.
 */
function aiModifyIframe() {
    aiDebugExtended('calling aiModifyIframe');
    if (!ia_already_done) {
      // here we add unique keys if css should be modified
      if (add_css_class_iframe === 'true') {
         var iframeHref = window.location.toString();
         if (iframeHref.substr(-1) === '/') {
             iframeHref = iframeHref.substr(0, iframeHref.length - 1);
         }
         var lastIndex = iframeHref.lastIndexOf('/');
         var result = iframeHref.substring(lastIndex + 1);
         var newClass = result.replace(/[^A-Za-z0-9]/g, '-');
         var iframeBody = jQuery('body');
         iframeBody.addClass('ai-' + newClass);

         if (jQuery('#ai_wrapper_div').length) {
           jQuery('#ai_wrapper_div').children('div').each(function(i) {
               jQuery(this).addClass('ai-' + newClass + '-child-' + (i+1));
           });
         } else {
           iframeBody.children('div').each(function (i) {
               jQuery(this).addClass('ai-' + newClass + '-child-' + (i+1));
           });
         }
      }

      if (iframe_hide_elements !== '' && write_css_directly === 'false') {
          jQuery(iframe_hide_elements).css('display', 'none').css('width', '0').css('height','0');
      }
      if (onload_show_element_only !== '') {
          aiShowElementOnly(onload_show_element_only);
      }
      if (write_css_directly === 'false' && (iframe_content_id !== '' || iframe_content_styles !== '')) {
          var elementArray = iframe_content_id.split('|');
          var valuesArray = iframe_content_styles.split('|');
          if (elementArray.length !== valuesArray.length) {
              alert('Configuration error: The attributes iframe_content_id and iframe_content_styles have to have the amount of value sets separated by |.');
              return;
          } else {
              for (var x = 0; x < elementArray.length; ++x) {
                  var valuesArrayPairs = aiTrimExtraChars(valuesArray[x]).split(';');
                  for (var y = 0; y < valuesArrayPairs.length; ++y) {
                      var elements = valuesArrayPairs[y].split(':');
                      jQuery(elementArray[x]).css(elements[0],elements[1]);
                  }
              }
          }
      }
      // Change links targets and hrefs
      if (change_iframe_links !== '' && (change_iframe_links_target !== '' || change_iframe_links_href !== '')) {
          var linksArray = change_iframe_links.split('|');
          var targetArray = change_iframe_links_target.split('|');
          var hrefArray = change_iframe_links_href.split('|');

          if (linksArray.length < targetArray.length && linksArray.length < hrefArray.length) {
              alert('Configuration error: The attribute change_iframe_links has to have at least the same amount of value sets separated by | as  the and change_iframe_links_target and change_iframe_links_href. Please read the documentation for details.');
              return;
          } else {
              if (change_iframe_links.length > 0) {
				  for (var z = 0; z < linksArray.length; ++z) {
					   jQuery('body').on('mouseenter keydown', linksArray[z], targetArray[z], function(e) {
						  if (e.data === '_blank') {
							  var originalRel = (this.rel === undefined) ? '' : this.rel.toLowerCase();
								var newRel = originalRel.split(" ");
								if (originalRel.indexOf('noopener') === -1){
									newRel.push('noopener');
								}
								jQuery(this).attr('rel', newRel.join(" ").trim() );
						  } 
						  jQuery(this).attr('target', e.data);
						  
					  });
				  }
			  }
			  if (change_iframe_links_href.length > 0) {
				  for (var zz = 0; zz < hrefArray.length; ++zz) {
					  var hrefArrayelements = hrefArray[zz].split('~');
					  if (hrefArrayelements.length === 2) {
						  jQuery('body').on('mouseenter keydown', linksArray[zz], hrefArrayelements, function(e) {
								var hrefArrayelementsLocal = e.data;
								if ((typeof this.href !== 'undefined') && !this.href.includes(hrefArrayelementsLocal[1])) { 
									if (hrefArrayelementsLocal[0] === 'append') {
									   this.href = this.href.concat(hrefArrayelementsLocal[1]);
									} else {
									   this.href = this.href.replace(hrefArrayelementsLocal[0],hrefArrayelementsLocal[1]);
									}
								}
						  });
					  } else {
						  alert('Configuration error: The attribute change_iframe_links_href has not the required ~ seperator set. Please read the documentation for details');
						  return;
					  }
				  }
			  }
          }
      }
      // scroll to top
      if (scroll_to_top !== '') {
        jQuery(document).on( 'click', scroll_to_top, function() {
            aiSendScrollToTop();
        });
      }
      ia_already_done = true;

      // we check if we have to set the modify cookie
      if (modify_iframe_if_cookie) {
        aiSetCookie("aiIframeModifications", "true");
      }
    }
}

/**
 * Removes all elements from an iframe except the given one
 * script tags are also not removed!
 *
 * @param iframeId id of the iframe
 * @param showElement the id, class (jQuery syntax) of the element that should be displayed.
 */
function aiShowElementOnly(showElement) {
  aiDebugExtended('aiShowElementOnly');
  if (showElement.indexOf('|') === -1) {
    // this is the old way where the element is attaced directly to the body
    // this changes the dom tree and might breaks css rules
    var iframe = jQuery('body');
    var selectedBox = iframe.find(showElement).clone(true,true);
    iframe.find('*').not(jQuery('script')).remove();
    iframe.prepend(selectedBox);
  } else {
    // This is the new way where everything except the element and the elments
    // up to the root is hidden. This keeps the dom tree and therefore css will work like before.
    var showElementSplit = showElement.split('|')[0];
    var element = jQuery(showElementSplit);
    element.siblings().hide();
    var parents = element.parents();
    parents.siblings().hide();
    parents.css('padding', '0px').css('margin', '0px');
  }
}

/**
 * Init the resize element event.
 */
function aiInitElementResize_advanced_iframe() {
   aiDebugExtended('aiInitElementResize_advanced_iframe');
   if (resize_on_element_resize !== '') {
      if (ia_resize_init_done_advanced_iframe === false) {
        /*! jQuery resize event - v1.1 - 3/14/2010 http://benalman.com/projects/jquery-resize-plugin/ Copyright (c) 2010 "Cowboy" Ben Alman Dual licensed under the MIT and GPL licenses. http://benalman.com/about/license/ */
        /* jshint ignore:start */
        (function(e,t,n){"$:nomunge";function c(){s=t[o](function(){r.each(function(){var t=e(this),n=t.width(),r=t.height(),i=e.data(this,a);if(i&&n!==i.w||r!==i.h){t.trigger(u,[i.w=n,i.h=r])}});c()},i[f])}var r=e([]),i=e.resize=e.extend(e.resize,{}),s,o="setTimeout",u="resize",a=u+"-special-event",f="delay",l="throttleWindow";i[f]=250;i[l]=false;e.event.special[u]={setup:function(){if(!this.nodeName){return false}if(!i[l]&&this[o]){return false}var t=e(this);r=r.add(t);e.data(this,a,{w:t.width(),h:t.height()});if(r.length===1){c()}},teardown:function(){if(!i[l]&&this[o]){return false}var t=e(this);r=r.not(t);t.removeData(a);if(!r.length){clearTimeout(s)}},add:function(t){function s(t,i,s){var o=e(this),u=e.data(this,a);if(typeof u!=="undefined"){u.w=i!==n?i:o.width();u.h=s!==n?s:o.height()}r.apply(this,arguments)}if(!i[l]&&this[o]){return false}var r;if(e.isFunction(t)){r=t;return s}else{r=t.handler;t.handler=s}}};})(jQuery,this)
        /* jshint ignore:end */
        if (!jQuery().resize) {
            alert('jQuery.resize is not available. Most likely you have included jQuery AFTER the ai_external.js. Please include jQuery before the ai_external.js. If you cannot do this please disable "Resize on element resize"');
        }
        if (resize_on_element_resize_delay !== '' && parseInt(resize_on_element_resize_delay,10) >= 50 ) {
            jQuery.resize.delay=resize_on_element_resize_delay;
        }
        var res_element;
        if  (resize_on_element_resize === 'body') {
            res_element = jQuery('body');
        } else {
            res_element = jQuery('body').find(resize_on_element_resize);
        }
        if (res_element.length === 0) {
                // show an error if null
                if (console && console.error) {
                     console.error('Advanced iframe configuration error: The configuration of "resize_on_element_resize" is invalid. The specified element ' + encodeURI(resize_on_element_resize) + ' could not be found. Please check your configuration. If your content is loaded dynamically please specify onload_resize_delay with a time that is longer then your content needs to load!');
                }
        } else {
            res_element.resize(function(){
                ia_already_done = false;
                onload_resize_delay = 10;
                aiExecuteWorkaround_advanced_iframe(false);
            });
        }
        ia_resize_init_done_advanced_iframe = true;
      }
   }
}


/**
 * The function creates a hidden iframe and determines the height of the
 * current page. This is then set as height parameter for the iframe
 * which triggers the resize function in the parent.
 */
function aiExecuteWorkaround_advanced_iframe(init) {
    aiDebugExtended('aiExecuteWorkaround_advanced_iframe');

    init = (init === undefined) ? true : init;
    var modificationCookieSet = false;

    if (modify_iframe_if_cookie) {
       modificationCookieSet = aiGetCookie("aiIframeModifications") == "true";
    }

    if (window!==window.top) { /* I'm in a frame! */
      // first we modify the iframe content  - only once in case the script is included several times.
      if (onload_resize_delay === 0 && init) {
          aiModifyIframe();
          aiInitElementResize_advanced_iframe();
      }

      if (updateIframeHeight === 'true') {
        var showItNow = true;
        var url;
        // add the iframe dynamically
        if (!usePostMessage) {
          url = domain_advanced_iframe + '/js/iframe_height.html';
          var empty_url = 'about:blank';
          var newElementStr = '<iframe id="ai_hidden_iframe_advanced_iframe" style="display:none;clear:both" width="0" height="0" src="';
          newElementStr += empty_url +'">Iframes not supported.</iframe>';
          var newElement = aiCreate(newElementStr);
          document.body.appendChild(newElement);
        }
        if (init) {
        // add a wrapper div below the body to measure - if you remove this you have to measure the height of the body!
        // See below for this solution. The wrapper is only created if needed
        aiCreateAiWrapperDiv();

        // remove any margin,padding from the body because each browser handles this differently
        // Overflow hidden is used to avoid scrollbars that can be shown for a milisecond
        aiAddCss('body {margin:0px;padding:0px;overflow:hidden;}');
       }
       var newHeight = 0;
       if (onload_resize_delay === 0) {
          // get the height of the element right below the body or a custom element - Using this solution allows that the iframe shrinks also.
          var wrapperElement = aiGetWrapperElement(element_to_measure);
          var newHeightRaw =  Math.max(wrapperElement.scrollHeight, wrapperElement.offsetHeight);
          newHeight = parseInt(newHeightRaw,10) + element_to_measure_offset;

          //  Get the height from the body. The problem with this solution is that an iframe can not shrink anymore.
          //  remove everything from aiCreateAiWrapperDiv() until here for the alternative solution.
          //  var newHeight = Math.max(document.body.scrollHeight, document.body.offsetHeight,
          //    document.documentElement.scrollHeight, document.documentElement.offsetHeight);

          //  This is the width - need to detect a change of the iframe width at a browser resize!
          iframeWidth = aiGetIframeWidth();
        }

	// we only resize if we have a change of more than 5 pixel or we are in the init phase
        if (iframe_advanced_iframe_last_height === -1 || Math.abs(iframe_advanced_iframe_last_height - newHeight) >= 5) { 

            // if we have a height < 10 or > 10.000 the resize is done 500ms later because it seems like the
            // height could not be measured correctly. And if the page is really > 10.000 it does not matter because
            // no one does see that the resize is done later.
            if (onload_resize_delay === 0 && (newHeight < 10 || newHeight > 10000)) {
               onload_resize_delay = 500;
            }

            if (onload_resize_delay === 0) {
               // 4 pixels extra are needed because of IE! (2 for Chrome)
               // If you still have scrollbars add a little bit more offset.

               if (usePostMessage) {
                 var anchorPosition = aiGetAnchorPosition();
		 var data = { 'aitype' : 'height',
                      'height' :  (newHeight + 4),
                      'width' : iframeWidth,
                      'id' : iframe_id_advanced_iframe,
		      'anchor' : anchorPosition,
                      'data' : {}
                            };
                 if (add_iframe_url_as_param === 'remote') {
                     data.loc = encodeURIComponent(window.location);
                 }
                 aiExtractAdditionalContent(dataPostMessage, data);

                 var json_data = JSON.stringify(data);
                 if (debugPostMessage && console && console.log) {
                     console.log('Advanced iframe: postMessage sent: ' + json_data + ' - targetOrigin: ' + post_message_domain  );
                 }
                 aiParent.postMessage(json_data, post_message_domain);
               } else {
                 var iframe = document.getElementById('ai_hidden_iframe_advanced_iframe');
                 var send_data = 'height=' + (newHeight + 4) + '&width=' + iframeWidth + '&id=' + iframe_id_advanced_iframe;
                 if (add_iframe_url_as_param === 'remote') {
                     send_data += '&loc=' + encodeURIComponent(window.location);
                 }
                 iframe.src = url + '?' + send_data;
               }
               iframe_advanced_iframe_last_height = newHeight;
			} else {
               showItNow = false
               setTimeout(function () { aiResizeLater_advanced_iframe(); }, onload_resize_delay);
            }
            
        }

        // set overflow to visible again.
        if (keepOverflowHidden === 'false') {
            var timeoutRemove = onload_resize_delay + 500;
            window.setTimeout(aiRemoveOverflowHidden, timeoutRemove);
        }

        if (enable_responsive_iframe === 'true' && init) {
            // resize size after resize of window. setup is done 1 sec after first resize to avoid double resize.
            window.setTimeout(aiInitResize_advanced_iframe, onload_resize_delay + 1000);
        }
        if (showItNow) {
            document.documentElement.style.visibility = 'visible';
        }
      } else if (hide_page_until_loaded_external === 'true') {  // only one iframe is rendered - if auto height is disabled still the parent has to be informed to show the iframe ;).
        if (usePostMessage) {
           var dataShow = { 'aitype' : 'show',
                        'id' : iframe_id_advanced_iframe
                      };
           aiExtractAdditionalContent(dataPostMessage, dataShow);

           var jsonDataShow = JSON.stringify(dataShow);
           if (debugPostMessage && console && console.log) {
              console.log('Advanced iframe: postMessage sent: ' + jsonDataShow + ' - targetOrigin: ' + post_message_domain  );
           }
           aiParent.postMessage(jsonDataShow, post_message_domain);
        } else {
          // add the iframe dynamically
          var urlShow = domain_advanced_iframe + '/js/iframe_show.html?id='+ iframe_id_advanced_iframe;
          var newElementStrShow = '<iframe id="ai_hidden_iframe_show_advanced_iframe" style="display:none;" width="0" height="0" src="';
          newElementStrShow += urlShow+'">Iframes not supported.</iframe>';
          var newElementShow = aiCreate(newElementStrShow);
          document.body.appendChild(newElementShow);
        }
        document.documentElement.style.visibility = 'visible';
      } else {
        document.documentElement.style.visibility = 'visible';
      }
	  // disable right click
	  if (disable_right_click === 'true') {
	      document.oncontextmenu = function(){ return false; };
	  }

    } else if (modificationCookieSet) {
       if (onload_resize_delay === 0) {
          aiModifyIframe();
          document.documentElement.style.visibility = 'visible';
       } else {
           setTimeout(function () {
               aiModifyIframe();
               document.documentElement.style.visibility = 'visible';
           }, onload_resize_delay);
       }
    }
}

/**
*  Gets the position of a possible anchor
*/
function aiGetAnchorPosition() {
	if(window.location.hash) {
        try {
			var anchor = jQuery(window.location.hash);
			if (anchor.length !== 0) {
				return Math.round(anchor.offset().top); 
			}
		} catch(e) {
		    return -1;	
		}
	}
	return -1;
}

function aiResizeLater_advanced_iframe() {
    aiDebugExtended('aiResizeLater_advanced_iframe');

    // We also modify the iframe later as if the resize is delayed because of dynamic data
    // most of the time the elements that should be modified also are loaded dynamically
    if (onload_resize_delay !== 0) {
          aiModifyIframe();
          aiInitElementResize_advanced_iframe();
      }

   var url = domain_advanced_iframe + '/js/iframe_height.html';
   var wrapperElement = aiGetWrapperElement(element_to_measure);
   var newHeightRaw =  Math.max(wrapperElement.scrollHeight, wrapperElement.offsetHeight);
   var newHeight = parseInt(newHeightRaw,10) + element_to_measure_offset;
   var iframeWidth = aiGetIframeWidth();

  
   if (newHeight > 10) { // Only resize if the height is > 10
      if (Math.abs(iframe_advanced_iframe_last_height - newHeight) >= 5) { // we only resize if we have a change of more than 5 pixel

		  if (usePostMessage) {
			 var anchorPosition = aiGetAnchorPosition();
			 var data = { 'aitype' : 'height',
			  'height' :  (newHeight + 4),
			  'width' : iframeWidth,
			  'id' : iframe_id_advanced_iframe,
			  'anchor' : anchorPosition,
			  'data' : {}
					};
			 if (add_iframe_url_as_param === 'remote') {
				 data.loc = encodeURIComponent(window.location);
			 }
			 aiExtractAdditionalContent(dataPostMessage, data);

			 var json_data = JSON.stringify(data);
			 if (debugPostMessage && console && console.log) {
				 console.log('Advanced iframe: postMessage sent: ' + json_data + ' - targetOrigin: ' + post_message_domain);
			 }
             aiParent.postMessage(json_data, post_message_domain);
		   } else {
			 var iframe = document.getElementById('ai_hidden_iframe_advanced_iframe');
			 var send_data = 'height=' + (newHeight + 4) + '&width=' + iframeWidth + '&id=' + iframe_id_advanced_iframe;
			 if (add_iframe_url_as_param === 'remote') {
				 send_data += '&loc=' + encodeURIComponent(window.location);
			 }
			 iframe.src = url + '?' + send_data;
		 }

		 if (enable_responsive_iframe === 'true') {
			// this is the width - need to detect a change of the iframe width at a browser resize!
			iframeWidth = aiGetIframeWidth();
		 }
		 iframe_advanced_iframe_last_height = newHeight;
	 }
   } else {
       if (debugPostMessage && console && console.error) {
           console.error('Advanced iframe configuration error: The height of the page cannot be detected with the current settings. Please check the documentation of "element_to_measure" how to define an alternative element to detect the height. Also you can try to add the style overflow:hidden to this element in your html or with the plugin dynamically. Hidden iframes can also not be measured by default. Make sure to use one of the solutions described in the documentation.');
       }
   }
   document.documentElement.style.visibility = 'visible';
}

/**
 *  Remove the overflow:hidden from the body which
 *  what avoiding scrollbars during resize.
 */
function aiRemoveOverflowHidden() {
    document.body.style.overflow='auto';
}

/**
 *  Gets the text length from text nodes. For other nodes a dummy length is returned
 *  browser do add empty text nodes between elements which should return a length
 *  of 0 because they should not be counted.
 */
function aiGetTextLength( obj ) {
    var value = obj.textContent ? obj.textContent : 'NO_TEXT';
    return value.trim().length;
}

/**
 * Creates a wrapper div if needed.
 * It is not created if the body has only one single div below the body.
 * childNdes.length has to be > 2 because the iframe is already attached!
 */
function aiCreateAiWrapperDiv() {
    aiDebugExtended('aiCreateAiWrapperDiv');

    var countElements = 0;
    // Count tags which are not empty text nodes, no script and no iframe tags
    // because only if we have more than 1 of this tags a wrapper div is needed
    for (var i = 0; i < document.body.childNodes.length; ++i) {
       var nodeName = document.body.childNodes[i].nodeName.toLowerCase();
       var nodeLength = aiGetTextLength(document.body.childNodes[i]);
       if ( nodeLength !== 0 && nodeName !== 'script' && nodeName !== 'iframe') {
           countElements++;
       }
    }
    
	var skipWrapper = element_to_measure.indexOf('nowrapper') !== -1;
	
	if (countElements > 1 && !skipWrapper) {
      var div = document.createElement('div');
  	  div.id = 'ai_wrapper_div';
    	// Move the body's children into this wrapper
    	while (document.body.firstChild) {
    		div.appendChild(document.body.firstChild);
    	}
    	// Append the wrapper to the body
    	document.body.appendChild(div);

      // set the style
      div.style.cssText = 'margin:0px;padding:0px;border: none;overflow: hidden;' + additional_styles_wrapper_div;
      // If we have a wrapper we set this as default
      if (element_to_measure.lastIndexOf('default', 0) === 0) {
          element_to_measure = '#' + div.id;
      }
    }
}

/**
 *  Creates a new dom fragment from a string
 */
function aiCreate(htmlStr) {
    var frag = document.createDocumentFragment(),
    temp = document.createElement('div');
    temp.innerHTML = htmlStr;
    while (temp.firstChild) {
        frag.appendChild(temp.firstChild);
    }
    return frag;
}

function aiGetIframeWidth() {
  aiDebugExtended('aiGetIframeWidth');

  var wrapperElement = aiGetWrapperElement(element_to_measure);
  var newWidthRaw = Math.max(wrapperElement.scrollWidth, wrapperElement.offsetWidth);

  // we have a width set and no max-width!
  var directWidth = jQuery(wrapperElement).css('width');

  if (typeof directWidth !== typeof undefined && directWidth !== false) {
      var maxWidth = jQuery(wrapperElement).css('max-width');
      if (!(typeof maxWidth !== typeof undefined && maxWidth !== 'none')) {
         newWidthRaw = directWidth;
      }
  }
  return parseInt(newWidthRaw,10);
}

function aiInitResize_advanced_iframe() {
  aiDebugExtended('aiInitResize_advanced_iframe');

// resize the iframe only when the width changes!
jQuery(window).resize(function() {
    if (enable_responsive_iframe === 'true') {
      if (iframeWidth !== aiGetIframeWidth()) {
          iframeWidth = aiGetIframeWidth();
          // hide the overflow if not keept
          if (keepOverflowHidden === 'false') {
               document.body.style.overflow='hidden';
          }
          ia_already_done = false;
          onload_resize_delay = 10;
          aiExecuteWorkaround_advanced_iframe(false);
          // set overflow to visible again.
          if (keepOverflowHidden === 'false') {
              window.setTimeout(aiResizeLater_advanced_iframe,500);
          }
      }
    }
});
}

function aiSetCookie(name,value) {
	document.cookie = name + "=" + (value || "") + "; path=/;" + ('https:' === document.location.protocol ? " Secure; SameSite=None": "");
}
function aiGetCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return '';
}

/**
 *  Adds a css style to the head
 */
function aiAddCss(cssCode) {
    var styleElement = document.createElement('style');
    styleElement.type = 'text/css';
    if (styleElement.styleSheet) {
      styleElement.styleSheet.cssText = cssCode;
    } else {
      styleElement.appendChild(document.createTextNode(cssCode));
    }
    document.getElementsByTagName('head')[0].appendChild(styleElement);
}

if(typeof String.prototype.trim !== 'function') {
  String.prototype.trim = function() {
    return this.replace(/^\s+|\s+$/g, '');
  };
}

/**
 * Helper function without jQuery to add a onload event
 * even if there is already one attached.
 */
function aiAddOnloadEvent(fnc){
  aiDebugExtended('aiAddOnloadEvent');

  if ( typeof window.addEventListener !== 'undefined' ) {
    window.addEventListener( 'load', fnc, false );
  } else if ( typeof window.attachEvent !== 'undefined' ) {
    window.attachEvent( 'onload', fnc );
  }
  else {
    if ( window.onload !== null ) {
      var oldOnload = window.onload;
      window.onload = function ( e ) {
        oldOnload( e );
        window[fnc]();
      };
    }
    else {
      window.onload = fnc;
    }
  }
  
  window.addEventListener("orientationchange", function() {
	   onload_resize_delay = 100;
	   aiExecuteWorkaround_advanced_iframe(false);     
  }, false);
}

function aiGetUrlParameter( name )
{
  name = name.replace(/[\[]/,'\\\[').replace(/[\]]/,'\\\]');
  var regexS = '[\\?&]'+name+'=([^&#]*)';
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );

  if( results == null ) {
    return '';
  } else {
    var allowedChars = new RegExp('^[a-zA-Z0-9_\-]+$');
    if (!allowedChars.test(results[1])) {
        return '';
    }
    return results[1];
  }
}

/**
 *  Gets the first element or the element you define at element_to_measure
 *  Either by id if no # and . is found or by jquery otherwise.
 */
function aiGetWrapperElement(elementToMeasureLocal) {
  elementToMeasureLocal = elementToMeasureLocal.split('|')[0];
  var element;
  if (elementToMeasureLocal === 'default' || elementToMeasureLocal === '' ) {
     element = document.body.children[0];
  } else {
     if (elementToMeasureLocal.indexOf('#') > -1 || elementToMeasureLocal.indexOf('.') > -1) {
         element = jQuery(elementToMeasureLocal)[0];
     } else {
         element = document.getElementById(elementToMeasureLocal);
     }
  }
  // show an error if null and set the default again.
  if (element == null || element.length === 0) {
         if (console && console.error) {
               console.error('Advanced iframe configuration error: The configuration of "element_to_measure" is invalid. The specified element ' + encodeURI(elementToMeasureLocal) + ' could not be found. Please check your configuration. As fallback "default" is used which measures the first child of the body.');
          }
          element = document.body.children[0];
  }
  //  margins top and bottom are set to 0 because the ai wrapper is not always used.
  element.style.marginTop = element.style.marginBottom = 0;
  return element;
}

function aiWriteCssDirectly() {
    aiDebugExtended('aiWriteCssDirectly');

    var css_output = '';

    if (iframe_hide_elements !== '') {
        css_output += iframe_hide_elements + '{ display: none !important; width:0px; height:0px }';
    }

    if (iframe_content_id !== '' || iframe_content_styles !== '') {
        var elementArray = iframe_content_id.split('|');
        var valuesArray = iframe_content_styles.split('|');
        if (elementArray.length !== valuesArray.length) {
            alert('Configuration error: The attributes iframe_content_id and iframe_content_styles have to have the amount of value sets separated by |.');
            return;
        } else {
            for (var x = 0; x < elementArray.length; ++x) {
                css_output += elementArray[x] + '{';
                css_output += aiTrimExtraChars(valuesArray[x]);
                css_output += '}';
            }
        }
    }

    if (css_output !== '') {
        var aiStyle = document.createElement('style');
        aiStyle.innerHTML = css_output;
        document.head.appendChild(aiStyle);
    }
}

function aiLoadExternalConfig(path) {
  aiDebugExtended('aiLoadExternalConfig');

  var scripts = document.getElementsByTagName('script');
  var myScript = scripts[ scripts.length - 1 ];
  var queryString = myScript.src.replace(/^[^\?]+\??/,'');
  if ( queryString ) { // try to load a config
     var param = queryString.substr(0,9);
     if (param === "config_id") {
       if (console && console.log) {
         console.log("Advanced iframe: Deprecated feature. Please use for the loading of a config which depends on an url parameter the config switcher template (ai_config_switcher_template.js) and include it directly into ai_external.js. This saves 2 additional requests where the config and ai_external.js is loaded again!");
       }
     var id = queryString.substr(10);
     if (id != '') {
       var letters = /^[\w\d_\-/$/]*$/;
       if(!id.match(letters)) {
         alert('The value of config_id can only have alphanumeric characters, - and _.');
       }
       // load the config.
       if (loadedConfig[id] === undefined) {
         document.write("<script src='"+path+"/../advanced-iframe-custom/ai_external_config_"+id+".js'></script>");
         document.write("<script src='"+path+"/js/ai_external.js'></script>");
         document.write('\n');
         loadedConfig[id] = 'true';
		 return false;
       } else {
         return true;
         }
       }
     }
  }
  return true;
}

/**
 * Extract elements from the page and adds this to the json data.
 */
function aiExtractAdditionalContent(config, data) {
     if (config !== '') {
        try {
            var elementArray = config.split(',');
            for (var x = 0; x < elementArray.length; ++x) {
                var valuesArrayPairs = aiTrimExtraChars(elementArray[x]).split('|');
                data.data[valuesArrayPairs[0]] = jQuery(valuesArrayPairs[1]).html();
            }
        }  catch(e) {
            if (console && console.error) {
              console.error('Advanced iframe configuration error: dataPostMessage is set to an invalid value. Please check your configuration.');
              console.log(e);
            }
        }
    }
}

function aiSendScrollToTop() {
    var data = { 'aitype' : 'scrollToTop',
                 'id' : iframe_id_advanced_iframe
    };
    var json_data = JSON.stringify(data);
    aiParent.postMessage(json_data, post_message_domain);
}

/* main */
/* safari cookie fix */
var safari_cookie_fix_value = aiGetUrlParameter('safari_cookie_fix')
if (safari_cookie_fix_value  !== '') {
  if (safari_cookie_fix_value == 'true') {
      document.documentElement.style.visibility = 'hidden';
      document.cookie = 'safari_cookie_fix=fixed; path=/; Secure; SameSite=None';
      if (aiGetCookie("safari_cookie_fix") !== "fixed") {
        if (typeof safari_cookie_fix_no_cookie_message === 'undefined') {
           safari_cookie_fix_message = 'This website requires that cookies are accepted. Please change your browser settings to continue.';
        }
        alert(safari_cookie_fix_message);
      }
      window.location.replace(document.referrer);
  } else if (safari_cookie_fix_value == 'message') {
    if (aiGetCookie("safari_cookie_fix") !== "fixed") {
       if (typeof safari_cookie_fix_message === 'undefined') {
           safari_cookie_fix_message = 'This website requires that third-party cookies are accepted. Please change your browser settings that at least "from visited" cookies are allowed.';
       }
       alert(safari_cookie_fix_message);
    }
  }
}

if (typeof loadedConfigs === 'undefined') {
   var loadedConfig = {};
}

// load an external config from the inital site. Param config_id is checked from the url.
var doIt = aiLoadExternalConfig(domain_advanced_iframe);

if (doIt) {
  // Variables are checked with typeof before because this enables that the user can
  // define this values before and after including this file and they don't have to set
  // them at all if not needed.
  var iframe_id_advanced_iframe;
  if (typeof iframe_id === 'undefined') {
      iframe_id_advanced_iframe = 'advanced_iframe';
  }  else {
      /* jshint ignore:start */
      iframe_id_advanced_iframe = iframe_id;
      /* jshint ignore:end */
  }

  var iframe_advanced_iframe_last_height = -1;

  if (typeof iframe_url_id === 'undefined') {
      var iframe_url_id = '';
  }
  // multisite support
  if (typeof domainMultisite === 'undefined') {
      if (typeof aiExternalSettings !== 'undefined' &&  aiExternalSettings.hasOwnProperty('domainMultisite')) {
          var domainMultisite = aiExternalSettings.domainMultisite;
      } else { 
          var domainMultisite = 'false';
      }
  }
  if (typeof post_message_domain === 'undefined') {
      var post_message_domain = '';
      // remove the protocol and add dynamically the real one to support http and https at the same time
      var domainOrig = post_message_domain.split('/')[2];
      post_message_domain = document.location.protocol + domainOrig; 	  
  }
  if (domainMultisite === 'true') {
      // Check the referer
      var ref = document.referrer;
      // If found we exchange the domain.
      if (ref !== '') {
        var domainOrig = domain_advanced_iframe.split('/')[2];
        var multiDomain = ref.split('/')[2];
        domain_advanced_iframe = domain_advanced_iframe.replace(domainOrig, multiDomain);
      }
      post_message_domain = '*';
  }

  if (typeof usePostMessage === 'undefined') {
       if (typeof aiExternalSettings !== 'undefined' &&  aiExternalSettings.hasOwnProperty('usePostMessage')) {
          var usePostMessage = aiExternalSettings.usePostMessage === '1';
      } else { 
          var usePostMessage = true;
      }   
  }
  if (typeof debugPostMessage === 'undefined') {
      var debugPostMessage = false;
  }
  if (typeof dataPostMessage === 'undefined') {
      var dataPostMessage = '';
  }

  if (iframe_url_id !== '') {
     var value_id = aiGetUrlParameter(iframe_url_id);
     if (value_id !== '') {
        iframe_id_advanced_iframe = value_id;
     } else {
        var errorText = 'Configuration error: The id cannot be found in the url at the configured parameter.';
        alert(errorText);
        throw errorText;
     }
  }
  if (typeof updateIframeHeight === 'undefined') {
      var updateIframeHeight = 'true';
  }
  if (typeof onload_resize_delay === 'undefined') {
      var onload_resize_delay = 0;
  }
  if (typeof keepOverflowHidden === 'undefined') {
      var keepOverflowHidden = 'false';
  }
  if (typeof hide_page_until_loaded_external === 'undefined') {
      var hide_page_until_loaded_external = 'false';
  }
  if (typeof iframe_hide_elements === 'undefined') {
    var iframe_hide_elements = '';
  }
  if (typeof onload_show_element_only === 'undefined') {
      var onload_show_element_only = '';
  }
  if (typeof iframe_content_id === 'undefined') {
      var iframe_content_id = '';
  }
  if (typeof iframe_content_styles === 'undefined') {
      var iframe_content_styles = '';
  }
  if (typeof change_iframe_links === 'undefined') {
      var change_iframe_links = '';
  }
  if (typeof change_iframe_links_target === 'undefined') {
      var change_iframe_links_target = '';
  }
  if (typeof change_iframe_links_href === 'undefined') {
      var change_iframe_links_href = '';
  }
  if (typeof additional_js_file_iframe === 'undefined') {
      var additional_js_file_iframe = '';
  }
  if (typeof additional_js_iframe === 'undefined') {
      var additional_js_iframe = '';
  }
  if (typeof additional_css_file_iframe === 'undefined') {
      var additional_css_file_iframe = '';
  }
  if (typeof iframe_redirect_url === 'undefined') {
      var iframe_redirect_url = '';
  }
  if (typeof enable_responsive_iframe === 'undefined') {
      var enable_responsive_iframe = 'false';
  }
  if (typeof write_css_directly === 'undefined') {
      var write_css_directly = 'false';
  }
  if (typeof resize_on_element_resize === 'undefined') {
      var resize_on_element_resize = '';
  }
  if (typeof resize_on_element_resize_delay === 'undefined') {
      var resize_on_element_resize_delay = '250';
  }
  if (typeof add_iframe_url_as_param === 'undefined') {
      var add_iframe_url_as_param = 'false';
  }
  if (typeof element_to_measure === 'undefined') {
      var element_to_measure = 'default';
  }
  if (typeof element_to_measure_offset === 'undefined') {
      var element_to_measure_offset = 0;
  }
  var modify_iframe_cookie_found = false;
  if (typeof modify_iframe_if_cookie === 'undefined') {
      var modify_iframe_if_cookie = false;
  }
  // This is a feature only mentioned in the readme.txt as it was only needed for a custom solution.
  if (typeof additional_styles_wrapper_div === 'undefined') {
      var additional_styles_wrapper_div = '';
  }
  if (typeof add_css_class_iframe === 'undefined') {
      var add_css_class_iframe = 'false';
  }

  if (typeof scroll_to_top === 'undefined') {
      var scroll_to_top = '';
  }

  if (typeof send_console_log === 'undefined') {
      var send_console_log = false;
	  if (aiGetUrlParameter("send_console_log") === 'true' || aiGetCookie("debugAiExternal") === "true") {
	      send_console_log = true;  	  
	  }
	  if (aiGetUrlParameter("send_console_log") === 'false') {
	      send_console_log = false;
	      document.cookie = 'debugAiExternal=; path=/; Secure; SameSite=None;expires=Thu, 01 Jan 1970 00:00:01 GMT';
	  }		  
	  if (send_console_log) {
		  extendedDebug = true;
		  debugPostMessage = true;  
		  document.cookie = 'debugAiExternal=true; path=/; Secure; SameSite=None';
	  }
  }
  if (typeof disable_right_click === 'undefined') {
      var disable_right_click = '' === '' ? 'false' : 'true';
  }

  // read optional jquery and resize on element resize paths!
  if (typeof jquery_path === 'undefined') {
      var jquery_path = '/wp-includes/js/jquery/jquery.js';
  }

  var iframeWidth = 0;
  var ia_resize_init_done_advanced_iframe = false;

  // redirect to a given url if the page is NOT in an iframe, You can provide a list of allowed referer seperated by |
  if (iframe_redirect_url !== '') {
       /* Add existing parameters */
      var iframe_redirect_url_all =  iframe_redirect_url.split('|');
      var iframe_redirect_url_first = iframe_redirect_url_all[0]       
      if ('' !== window.location.search && iframe_redirect_url.indexOf('?') ===-1) {
          iframe_redirect_url_first += window.location.search;
      }
      if (window===window.top) { /* I'm not in a frame! */
          location.replace(iframe_redirect_url_first);
      } else {
          /* we check if the referrer is the parent  */
          var ref = document.referrer;
          if (ref !== '') {
            var currentDomain = window.location.hostname;
            var invalid = true;
            // loop
            for (var i = 0; i < iframe_redirect_url_all.length; i++) {
			  var el = iframe_redirect_url_all[i];
              var domainRedirect = el.split('/')[2];
            var domainRef = ref.split('/')[2];
            // we allow if the referrer is the parent OR if the referrer is the current domain because a user clicked inside already.
              if (domainRedirect === domainRef || domainRef === currentDomain) {
                  invalid = false;
                  break;
              }
            }
            if (invalid) {
              top.location.replace(iframe_redirect_url_first);  
            }
          } else {
            /*  If no referer is found we redirect to the defined parent as this seems to be a fake include */
            top.location.replace(iframe_redirect_url_first);
          }
      }
  }

  // load jQuery if not available
  window.jQuery || document.write('<script src="' + jquery_path + '"></script>');

  // if responsive is enabled auto height has to be enabled as well.
  if (enable_responsive_iframe === 'true') {
      updateIframeHeight = 'true';
  }

  var modificationCookieSet = false;
  if (modify_iframe_if_cookie) {
    modificationCookieSet = aiGetCookie("aiIframeModifications") == "true";
  }

  if (typeof ia_already_done === 'undefined') {
      if (window!==window.top || modificationCookieSet) { /* I'm in a frame! */
          // dom is not fully loaded therefore jQuery is not used to hide the body!
          if (iframe_hide_elements !== '' || onload_show_element_only !== '' ||
              iframe_content_id !== '' || iframe_content_styles !== '') {
              if (document.documentElement && write_css_directly === 'false') {
                  document.documentElement.style.visibility = 'hidden';
              }
              // Solution if you want to remove the background but you see it for a very short time.
              // because hiding the iframe content does not help!
              //if (window != window.top) {
              //    document.write("<style>body { background-image: none; }</style>");
              //}
          }
      }
      var ia_already_done = false;
  }

  // add the aiUpdateIframeHeight to the onload of the site.
  aiAddOnloadEvent(aiExecuteWorkaround_advanced_iframe);

  if (write_css_directly === 'true' && (window!==window.top || modificationCookieSet)) {
      aiWriteCssDirectly();
  }
  if (additional_css_file_iframe !== '' && (window!==window.top || modificationCookieSet)) {
      var link = document.createElement('link');  
      link.rel = 'stylesheet';  
      link.type = 'text/css'; 
      link.href = additional_css_file_iframe;
      document.getElementsByTagName('HEAD')[0].appendChild(link);  
  }
  if (additional_js_file_iframe !== '' && (window!==window.top || modificationCookieSet)) { 
	  var script = document.createElement('script');
	  script.type ='text/javascript';
	  script.src = additional_js_file_iframe;
	  document.getElementsByTagName('head')[0].appendChild(script);	  
  }
  if (additional_js_iframe !== '' && (window!==window.top || modificationCookieSet)) {
      var aiScript = document.createElement('script');
      aiScript.innerHTML = additional_js_iframe;
      document.head.appendChild(aiScript);
  }

  // we overwrite console.log/warn/debug/error if it exists
  if (usePostMessage && send_console_log && console && console.log) {
	 
     console.defaultLog = console.log.bind(console);
     console.logs = [];
     console.log = function(){
		 console.defaultLog.apply(console, arguments);
		 console.logs.push(Array.from(arguments));
		 var data = { 'aitype' : 'debug',
				 'id' : iframe_id_advanced_iframe,
				 'data' : 'LOG: ' + [].map.call(arguments, JSON.stringify)
	     };
		 var json_data = JSON.stringify(data);
         aiParent.postMessage(json_data, post_message_domain);
	 }
	 
	console.defaultWarn = console.warn.bind(console);
	console.warns = [];
	console.warn = function(){
		console.defaultWarn.apply(console, arguments);
		console.warns.push(Array.from(arguments));
		var data = { 'aitype' : 'debug',
				 'id' : iframe_id_advanced_iframe,
				 'data' : 'WARN: ' + [].map.call(arguments, JSON.stringify)
	     };
		 var json_data = JSON.stringify(data);
		 aiParent.postMessage(json_data, post_message_domain);
	}
	
	console.defaultError = console.error.bind(console);
	console.errors = [];
	console.error = function(){
		console.defaultError.apply(console, arguments);
		console.errors.push(Array.from(arguments));
		var data = { 'aitype' : 'debug',
				 'id' : iframe_id_advanced_iframe,
				 'data' :  'ERROR: ' + [].map.call(arguments, JSON.stringify)
	     };
		 var json_data = JSON.stringify(data);
		 aiParent.postMessage(json_data, post_message_domain);
	}	
	
    window.onerror = function (msg, url, lineNo, columnNo, error) {
        var data = { 'aitype' : 'debug',
                     'id' : iframe_id_advanced_iframe,
                     'data' :  'ERROR: ' + msg + ' - ' + lineNo + ':' + columnNo
                   };
        var json_data = JSON.stringify(data);
        aiParent.postMessage(json_data, post_message_domain);
	return false;
    };
  }
}