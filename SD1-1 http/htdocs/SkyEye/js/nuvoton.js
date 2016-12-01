function readCookie(name)
{
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function verifyUser()
{
	if(readCookie("NuvotonAuthorized") == "" || readCookie("verified_url") != "true" || readCookie("skyeye_host") == null)
		return "";
	else
		return readCookie("NuvotonAuthorized");
}

function CreateControl(DivID, src, width, height)
{
	var tag = document.getElementById(DivID);
	
	tag.innerHTML = '';
	tag.innerHTML = '<object classid="clsid:9BE31822-FDAD-461B-AD51-BE1D1C159921" codebase="http://download.videolan.org/pub/videolan/vlc/last/win32/axvlc.cab" id="vlcPlayer" name="vlcPlayer" events="True"' +
	' width="' + width + '" height="' + height + '">' +
	'<param name="MRL" value="' + src + '" />' + 
	'<param name="AutoPlay" value="True" />';
}

String.prototype.toHHMMSS = function () {
	var seconds = parseInt(this, 10),	//Math.floor(this),
		hours = Math.floor(seconds / 3600);
	seconds -= hours*3600;
	var minutes = Math.floor(seconds / 60);
	seconds -= minutes*60;

	if (hours   < 10) {hours   = "0"+hours;}
	if (minutes < 10) {minutes = "0"+minutes;}
	if (seconds < 10) {seconds = "0"+seconds;}
	return hours+':'+minutes+':'+seconds;
}

function _setBrowser()
{
	var userAgent = navigator.userAgent.toLowerCase();

	// Figure out what browser is being used
	jQuery.browser = {
		version: (userAgent.match( /.+(?:rv|it|ra|ie|me|ve)[\/: ]([\d.]+)/ ) || [])[1],

		chrome: /chrome/.test( userAgent ),
		safari: /webkit/.test( userAgent ) && !/chrome/.test( userAgent ),
		opera: /opera/.test( userAgent ),
		firefox: /firefox/.test( userAgent ),
		msie: /msie/.test( userAgent ) && !/opera/.test( userAgent ),

		mozilla: /mozilla/.test( userAgent ) && !/(compatible|webkit)/.test( userAgent ),

		gecko: /[^like]{4} gecko/.test( userAgent ),
		presto: /presto/.test( userAgent ),

		xoom: /xoom/.test( userAgent ),

		android: /android/.test( userAgent ),
		androidVersion: (userAgent.match( /.+(?:android)[\/: ]([\d.]+)/ ) || [0,0])[1],

		iphone: /iphone|ipod/.test( userAgent ),
		iphoneVersion: (userAgent.match( /.+(?:iphone\ os)[\/: ]([\d_]+)/ ) || [0,0])[1].toString().split('_').join('.'),

		ipad: /ipad/.test( userAgent ),
		ipadVersion: (userAgent.match( /.+(?:cpu\ os)[\/: ]([\d_]+)/ ) || [0,0])[1].toString().split('_').join('.'),

		blackberry: /blackberry/.test( userAgent ),

		winMobile: /Windows\ Phone/.test( userAgent ),
		winMobileVersion: (userAgent.match( /.+(?:windows\ phone\ os)[\/: ]([\d_]+)/ ) || [0,0])[1]
	};

	jQuery.browser.mobile   =   ($.browser.iphone || $.browser.ipad || $.browser.android || $.browser.blackberry );
};
