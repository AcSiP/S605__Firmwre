var varShortTimeout	= 5000;
var varLongTimeout	= 8000;
var varUpdateFlag	= true;
var varViewPipe		= 0,
	varViewType		= "jpeg";
var varVideoWidth	= 320;
	varVideoHeight	= 240;
var eResol = { Width: 0, Height: 1 };
var eSetStat = { Resol: 0, FrameRate: 1, Quality: 2 },
	eViewStat = { FrameRate: 0, Bitrate: 1, Viewer: 2, Quality: 3 };
var eJpegQuality = { Auto: 0, High: 7, Middle: 11, Low: 15 },
	eH264Quality = { Auto: 0, High: 24, Middle: 30, Low: 36 };
var aWidthList = [ "320", "640", "1280", "1600", "1920" ];
var aHeightList = [ "240", "480", "720", "1200", "1072" ];

function updateResolution(varResolution)
{
	if(varResolution != null)
	{
		if(varResolution < aWidthList.length)
		{
			varVideoWidth = aWidthList[varResolution];
			varVideoHeight = aHeightList[varResolution];
			$("#sel_resolution").val(varResolution);
		}
		else
		{
			varVideoWidth = aWidthList[0];
			varVideoHeight = aHeightList[0];
			$("#sel_resolution").val(aWidthList.length);
		}
		
		$("#video").width(varVideoWidth * $("input:radio[name=Zoom]:checked").val());
		$("#video").height(varVideoHeight * $("input:radio[name=Zoom]:checked").val());
	}
}

function updateQuality(varQuality)
{
	if(varQuality != null)
	{
		$("#enc_quality").val(varQuality);
	}
}

function updateMaxFPS(varMaxFPS)
{
	if(varMaxFPS != null)
		$("#max_fps").val(varMaxFPS);
}

function refreshConfParam(bLoop, varSetStat)
{
	if(varUpdateFlag)
	{
		if((varSetStat & (1 << eSetStat.Resol)) > 0)
		{
			$.ajax({
				type: "GET",
				url: "/server.command?command=get_resol&type=" + varViewType + "&pipe=" + varViewPipe,
				async: false
			})
			.done(function(data){
				updateResolution(data.value);
			})
			.fail(function(){
				console.log("get_resol err");
				clearRefreshTimeout();
			});
		}
		
		if((varSetStat & (1 << eSetStat.Quality)) > 0)
		{
			$.get("/server.command?command=get_enc_bitrate&type=" + varViewType + "&pipe=" + varViewPipe)
			.done(function(data){
				if(data.value > 0 && varViewType == "jpeg")
					$("#enc_quality").val(0);
				else
				{
					$.get("/server.command?command=get_enc_quality&type=" + varViewType + "&pipe=" + varViewPipe)
					.done(function(data){
						updateQuality(data.value);
					})
					.fail(function(){
						console.log("get_enc_quality err");
						clearRefreshTimeout();
					});
				}
			})
			.fail(function(){
				console.log("get_set_bitrate err");
				clearRefreshTimeout();
			});
		}
		
		if((varSetStat & (1 << eSetStat.FrameRate)) > 0)
		{
			$.get("/server.command?command=get_max_fps&type=" + varViewType + "&pipe=" + varViewPipe)
			.done(function(data){
				updateMaxFPS(data.value);
			})
			.fail(function(){
				console.log("get_max_fps err");
				clearRefreshTimeout();
			});
		}
	}
	
	if(bLoop && varLongTimeout > 0)
		setTimeout(function() { refreshConfParam(true, varSetStat); }, varLongTimeout);
}	// refreshConfParam

function setResolution(event)
{
	varUpdateFlag = false;
	
	$("#sel_resolution").attr('disabled', true);
	//varNewResolution = $("input:radio[name=Resolution]:checked").val();
	varNewResolIdx = $("#sel_resolution").val();
	
	$.get("/server.command?command=set_resol&value=" + aWidthList[varNewResolIdx] + "&value1=" + aHeightList[varNewResolIdx] + "&type=" + varViewType + "&pipe=" + varViewPipe)
	.done(function(data){
		if(data.value < 0)
			alert("Specified resolution is not support!\n");
		else
		{
			$("#radio_zoom_1_0").prop("checked", true);
			$("#info_fps").html("");
			$("#info_kbps").html("");
			
			updateResolution(varNewResolIdx);
		}
		
		$("#sel_resolution").attr('disabled', false);
		varUpdateFlag = true;
		refreshConfParam(false, (1 << eSetStat.Resol));
	});
}	// setResolution

function setJpegQuality(event)
{
	varUpdateFlag = false;
	$("input[name=Quality]").attr('disabled', true);
	varNewQuality = $("input:radio[name=Quality]:checked").val();
	
	$.get("/server.command?command=set_quality&value=" + varNewQuality + "&pipe=" + varViewPipe, function(data){
		$(event.target).prop("checked", true);
	});
	
	$("input[name=Quality]").attr('disabled', false);
	varUpdateFlag = true;
}

function CreateVideoParam(tagResol, tagQuality, tagMaxFPS, varCurrViewType, varCurrViewPipe)
{
	var varSetStat		= 0,
		varIsCombined	= false;
	
	if(varCurrViewType == undefined || varCurrViewType == "")
		varViewType = "jpeg";
	else
		varViewType = varCurrViewType;
	
	if(varCurrViewPipe == undefined || varCurrViewPipe == "")
		varViewPipe	= 0;
	else
		varViewPipe = varCurrViewPipe;
	
	$.ajax({
		type: "GET",
		url: "/SkyEye/tmpCheckVideoComb.ncgi?type=" + varViewType,
		async: false
	})
	.done(function(data){
		varIsCombined = (data.value == 1);
		varVideo0Resol = data.Video0_Resol;
		varVideo1Resol = data.Video1_Resol;
	})
	.fail(function(){
		alert("Fail to get stream infomation!");
	});
	
	if(tagResol != null)
	{
		var tagElem = document.getElementById(tagResol);
		var tagHTML	= "";
		
		tagElem.innerHTML = "";
		
		if(varIsCombined)
			tagElem.innerHTML = '<a href="server_config.html#VideoComb" target="ServerConfig">[' + varVideo0Resol + '][' + varVideo1Resol + ']</a>';
		else
		{
			tagHTML = 
				'<select id="sel_resolution">';
					for(i = 0; i < aWidthList.length; i++)
						tagHTML += '<option value="' + i + '">' + aWidthList[i] + 'x' + aHeightList[i] + '</option>';
			tagHTML += 
				'<option value="' + aWidthList.length + '" selected>User-Defined</option>';
				'</select>';
			tagElem.innerHTML = tagHTML;
			$("#sel_resolution").change(setResolution);
			varSetStat = varSetStat | (1 << eSetStat.Resol);
		}
	}
	
	if(tagMaxFPS != null)
	{
		var tagElem	= document.getElementById(tagMaxFPS);
		var tagHTML	= "";
		
		tagElem.innerHTML = "";
		
		if(varIsCombined)
			tagElem.innerHTML = "N/A"
		else
		{
			tagHTML = 
				'<select id="max_fps">' +
					'<option value="0" selected></option>';
						for(i = 1; i <= 60; i++)
							tagHTML += '<option value="' + i + '">' + i + '</option>';
			tagHTML += 
				'</select>';
			tagElem.innerHTML = tagHTML;
		
			$("#max_fps").change(function(){
				varUpdateFlag = false;
				
				if($("#max_fps").val() > 0 && $("#max_fps").val() <= 30)
				{
					$.get("/server.command?command=set_max_fps&value=" + $("#max_fps").val() + "&type=" + varViewType + "&pipe=" + varViewPipe);
				}
				else
				{
					alert("Incorrect FPS!");
				}
				
				varUpdateFlag = true;
			});
			
			varSetStat = varSetStat | (1 << eSetStat.FrameRate);
		}
	}
	
	if(tagQuality != null)
	{
		var tagElem = document.getElementById(tagQuality);
		
		tagElem.innerHTML = '';

		var tagHTML	= "";
		var varBestQuality = 1, 
			varWorstQuality = 15
			varAutoQuality = 0;
		
		if(varViewType == "h264")
		{
			varBestQuality = 1;
			varWorstQuality = 52;
		}
		
		tagHTML = 
			'<select id="enc_quality">' +
				'<option value="" selected></option>' +
				'<option value="' + varAutoQuality + '">Auto</option>' + 
				'<option value="' + varBestQuality + '">' + varBestQuality + ' (Best)</option>';
					for(i = varBestQuality + 1; i <= varWorstQuality - 1; i++)
						tagHTML += '<option value="' + i + '">' + i + '</option>';
		tagHTML += 
			'<option value="' + varWorstQuality + '">' + varWorstQuality + ' (Worst)</option>' + 
			'</select>';
		tagElem.innerHTML = tagHTML;
		
		$("#enc_quality").change(function(){
			varUpdateFlag = false;
			
			if($("#enc_quality").val() == varAutoQuality || ($("#enc_quality").val() >= varBestQuality && $("#enc_quality").val() <= varWorstQuality))
			{
				$.get("/server.command?command=set_enc_quality&value=" + $("#enc_quality").val() + "&type=" + varViewType + "&pipe=" + varViewPipe);
			}
			else
			{
				alert("Failed to change video encoder quality!");
			}
			
			varUpdateFlag = true;
		});
		
		varSetStat = varSetStat | (1 << eSetStat.Quality);
	}
	
	refreshConfParam(true, varSetStat);
}	// CreateVideoParam

function clearRefreshTimeout()
{
	varShortTimeout = 0;
	varLongTimeout = 0;
}

function RefreshStatus(strIdentifyKey, bInfoFPS, bInfoConn, bInfoKbps, bInfoQuality)
{
	if(bInfoFPS)
	{
		$.get("/server.command?identify_key=" + strIdentifyKey + "&command=get_fps")
		.done(function(data){
			$("#info_fps").html(data.value);
		})
		.fail(function(){
			clearRefreshTimeout();
		});
	}	// if(bInfoFPS)
	
	if(bInfoConn)
	{
		$.get("/server.command?command=get_conn")
		.done(function(data){
			$("#info_conn").html(data.value);
		})
		.fail(function(){
			clearRefreshTimeout();
		});
	}	// bInfoConn
	
	if(bInfoKbps)
	{
		$.get("/server.command?identify_key=" + strIdentifyKey + "&command=get_trans_bitrate")
		.done(function(data){
			$("#info_kbps").html(data.value);
		})
		.fail(function(){
			clearRefreshTimeout();
		});
	}	// if(bInfoKbps)
	
	if(bInfoQuality)
	{
		$.get("/server.command?command=get_view_quality&type=jpeg&&pipe=" + varViewPipe)
		.done(function(data){
			if(data.value > 0)
				$("#info_quality").html(data.value);
		})
		.fail(function(){
			clearRefreshTimeout();
		});
	}	// if(bInfoQuality)
	
	if(varShortTimeout > 0)
	{
		setTimeout(
			function(){
				RefreshStatus(strIdentifyKey, bInfoFPS, bInfoConn, bInfoKbps, bInfoQuality)
			}, 
			varShortTimeout
		);
	}
}	// RefreshStatus

function CreateVideoStatus(tagStatus, bInfoFPS, bInfoConn, bInfoKbps, bInfoQuality)
{
	var tagHTML	= "";
	
	if(tagStatus != null && (bInfoFPS || bInfoConn || bInfoKbps || bInfoQuality))
	{
		var tagElem = document.getElementById(tagStatus);
	
		tagElem.innerHTML = tagHTML;
		tagHTML = 
			'<table cellspacing="0" border="1" align="center">' +
				'<tr>';
		if(bInfoFPS)
			tagHTML += '<td>FPS</td>';
		if(bInfoConn)
			tagHTML += '<td>Kbps</td>';
		if(bInfoKbps)
			tagHTML += '<td>Viewer</td>';
		if(bInfoQuality)
			tagHTML += '<td>Quality</td>';
		
		tagHTML += 
				'</tr>' +
				'<tr align="right">';
		
		if(bInfoFPS)
			tagHTML += '<td><div id="info_fps" style="font-weight: bold; color: blue;">N/A</div></td>';
		if(bInfoConn)
			tagHTML += '<td><div id="info_kbps" style="font-weight: bold; color: blue;">N/A</div></td>';
		if(bInfoKbps)
			tagHTML += '<td><div id="info_conn" style="font-weight: bold; color: blue;">N/A</div></td>';
		if(bInfoQuality)
			tagHTML += '<td><div id="info_quality" style="font-weight: bold; color: blue;">N/A</div></td>';
		
		tagHTML += 
				'</tr>' +
			'</table>';
		tagElem.innerHTML = tagHTML;
	}
}	// CreateVideoStatus

function CreateVideoExt(tagZoom, tagVideoCtrl, tagRecFileList, varViewTypeParam, varViewPipeParam)
{
	if(tagZoom != null)
	{
		var tagElem = document.getElementById(tagZoom);
		
		tagElem.innerHTML = 
			'<input type="radio" id="radio_zoom_0_25" name="Zoom" value="0.25">1/4</input>' +
			'<input type="radio" id="radio_zoom_0_5" name="Zoom" value="0.5">1/2</input>' +
			'<input type="radio" id="radio_zoom_1_0" name="Zoom" value="1" checked>1</input>' +
			'<input type="radio" id="radio_zoom_2_0" name="Zoom" value="2">2</input>' +
			'<input type="radio" id="radio_zoom_4_0" name="Zoom" value="4">4</input>';
		
		$("#radio_zoom_0_25, #radio_zoom_0_5, #radio_zoom_1_0, #radio_zoom_2_0, #radio_zoom_4_0").click(
			function(evt){
				$("#video").width(varVideoWidth * $(evt.target).val());
				$("#video").height(varVideoHeight * $(evt.target).val());
			}
		);
	}
	
	if(tagVideoCtrl != null)
	{
		var tagElem = document.getElementById(tagVideoCtrl);
		
		tagElem.innerHTML = 
			'<button id="btnVideoCtrl">Video Control</button>';
		
		$("#btnVideoCtrl").click(function(){
			if($("#video_ctrl").width() == 0 || $("#video_ctrl").height() == 0 || $("#video_ctrl").prop("src").indexOf("server_video_ctrl.html") < 0)
			{
				$("#video_ctrl").prop("src", "server_video_ctrl.html?type=" + varViewTypeParam + "&pipe=" + varViewPipeParam);
				$("#video_ctrl").width(260);
				$("#video_ctrl").height(450);
			}
			else
			{
				$("#video_ctrl").prop("src", "");
				$("#video_ctrl").width(0);
				$("#video_ctrl").height(0);
			}
		});
	}
	
	if(tagRecFileList != null)
	{
		var tagElem = document.getElementById(tagRecFileList);
		
		tagElem.innerHTML = 
			'<button id="btnRecFileList">Recorded Files</button>';
		
		$("#btnRecFileList").click(function()
		{
			$.get("server.command?command=check_storage")
			.done(function(data){
				if(data.value == "0")
					alert("No external storage! Please insert SD card or USB disk fist.");
				else
				{
					if($("#video_ctrl").width() == 0 || $("#video_ctrl").height() == 0 || $("#video_ctrl").prop("src").indexOf("param.cgi?action=list&group=file&fmt=link") < 0)
					{
						$("#video_ctrl").prop("src", "param.cgi?action=list&group=file&fmt=link");
						$("#video_ctrl").width(260);
						$("#video_ctrl").height(450);
					}
					else
					{
						$("#video_ctrl").prop("src", "");
						$("#video_ctrl").width(0);
						$("#video_ctrl").height(0);
					}
				}
			})
			.fail(function(){
				alert("Failed to communicate with server! Please check network status or retry again later");
			});
		});
	}
}

function getVideoResol(varSel)
{
	if(varSel == eResol.Width)
		return varVideoWidth;
	else if(varSel == eResol.Height)
		return varVideoHeight;
	else
		return 0;
}

function queryPipeCnt(tagPipeCnt, varPipeType)
{
	var varRet = 0;
	
	$.ajax({
		type: "GET",
		url: "/server.command?command=get_pipe_cnt&type=" + varPipeType,
		async: false
	})
	.done(function(data){
		var tagElem = document.getElementById(tagPipeCnt);
		var tagHTML	= "";
		
		if(data.value > 0 && tagPipeCnt != null)
		{
			tagElem.innerHTML = tagHTML;
			tagHTML = '<select id="pipe_id">';
			
			for(i = 0; i < data.value; i++)
				tagHTML += '<option value="' + i + '">Pipe_' + i + '</option>';
			
			tagHTML += '</select>';
			tagElem.innerHTML = tagHTML;
		}
		
		varRet = data.value;
	})
	.fail(function(){
		varRet = -1;
	});
	
	return varRet;
}
