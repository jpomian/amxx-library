#include <amxmodx>
#include <amxmisc>
#include <celltrie>

#define PLUGIN "Dynamic HUD"
#define VERSION "1.03"
#define AUTHOR "R3X"

#define TASKID_BASE 123435

#define FRAME_SIZE 3
#define MESSAGE_LEN 192
#define FILTERNAME_LEN 32
#define FILTERDESC_LEN 128
#define MAX_PARAMS 10

new Array:aDHUD;
new Array:gForwards;
new Array:gMessages;
new gszMessage[MESSAGE_LEN];

new Array:gArrays;

new Trie:gFilters;
new Array:gFiltersCB;

new Array:gFilterNames;
new Array:gFilterDesc;

new bool:gbDebug;

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	inner_register_filter(-1, "SetPosition", "filterSetPosition", "<Float:x> <Float:y> - Set given position", FP_FLOAT, FP_FLOAT);
	inner_register_filter(-1, "SetColor", "filterSetColor", "<r> <g> <b> - Set given color (3 ints)", FP_CELL, FP_CELL, FP_CELL);
	inner_register_filter(-1, "SetColorA", "filterSetColorA", "<iColor[3]> - Set given color (tab[3])", FP_ARRAY);
	inner_register_filter(-1, "MoveStraight", "filterMoveStraight", "<Float:a> <Float:b> - Move by straight line y = ax+b", FP_FLOAT, FP_FLOAT);
	inner_register_filter(-1, "TransColor", "filterTransColor", "<iStartColor[3]> <iTargetColor[3]> - Transform one color to other",  FP_ARRAY, FP_ARRAY);
	inner_register_filter(-1, "Flickering", "filterFlickering", "<freq> - Hide one per `freq` frames", FP_CELL);
	
	register_clcmd("dhud info", "cmdDHUD", ADMIN_CFG);
}
public cmdDHUD(id, level, cid){
	console_print(id, "%s v%s^n", PLUGIN, VERSION);
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	new iSize = ArraySize(gFilterDesc);
	
	console_print(id, "----Filters----");
	new szName[FILTERNAME_LEN], szDesc[FILTERDESC_LEN];
	for(new i=0;i<iSize;i++){
		ArrayGetString(gFilterNames, i, szName, FILTERNAME_LEN-1);
		ArrayGetString(gFilterDesc, i, szDesc, FILTERDESC_LEN-1);
		console_print(id, "^"%s^" - %s", szName, szDesc);
	}
	
	return PLUGIN_HANDLED;
}
GarbageCollector(tid = -1){
	new iArray[5];
	new iSize = ArraySize(gArrays);
	new task, dhud, id, iRet;
	for(new i=0;i<iSize;i++){
		ArrayGetArray(gArrays, i, iArray);
		task = iArray[0];
		if(!task_exists(task) || task==tid){
			ArrayDeleteItem(gArrays, i);
			i--, iSize--;
			
			gbDebug && log_amx("-Tid = %d, Array = %d, string = %d", iArray[0], iArray[1], iArray[2]);
			
			ArrayDestroy(Array:iArray[1]);
			ArraySetString(gMessages, iArray[2], "");
			
			id = iArray[3];
			dhud = iArray[4];
			
			ExecuteForward(ArrayGetCell(gForwards, dhud), iRet, id, dhud, (task == tid));
		}
	}
}
public plugin_precache(){
	gbDebug = ((plugin_flags () & AMX_FLAG_DEBUG) > 0);
}
public plugin_natives(){
	aDHUD = ArrayCreate();
	gForwards = ArrayCreate();
	gMessages = ArrayCreate(MESSAGE_LEN);
	
	gArrays = ArrayCreate(5);
	
	gFilters = TrieCreate();
	gFiltersCB = ArrayCreate(MAX_PARAMS+2);
	
	gFilterNames = ArrayCreate(FILTERNAME_LEN);
	gFilterDesc = ArrayCreate(FILTERDESC_LEN);
	
	register_library("DynamicHUD");
	
	//native CreateDHUD(dhud = -1);
	register_native("DHUD_create", "_CreateDHUD");
	
	//native DHUD_getFrames(dhud);
	register_native("DHUD_getFrames", "_getFramesDHUD");
	
	//native setFrameDHUD(dhud, frame, iColor[3], Float:x, Float:y, iLen = 1);
	register_native("DHUD_setFrame", "_setFrameDHUD");
	
	//native getFrameDHUD(dhud, frame, iColor[3], &Float:x, &Float:y, &iLen);
	register_native("DHUD_getFrame", "_getFrameDHUD");
	
	//native DisplayDHUD(id, dhud, Float:fInterval = 0.1, channel = 4, const szMessage[], any:...);
	register_native("DHUD_display", "_DisplayDHUD");
	
	//native DHUD_clear(id, dhud);
	register_native("DHUD_clear", "_clearDHUD");
	
	//native ApplyFilterDHUD(dhud, const szFilter[], startFrame, endFrame, Float:dx=0.1, Float:dy=0.0, any:...);
	register_native("DHUD_applyFilter", "_ApplyFilterDHUD");
	
	//native register_filter(const szName[], const szCallback[], ...);
	register_native("DHUD_registerFilter", "_register_filter");
}
stock allocString(szMessage[]){
	new iLen = strlen(szMessage);
	if(iLen >= MESSAGE_LEN)
		szMessage[MESSAGE_LEN] = '^0';
	
	new szTemp[2];
	new iSize = ArraySize(gMessages);
	for(new i=0;i<iSize;i++){
		szTemp[0] = '^0';
		
		ArrayGetString(gMessages, i, szTemp, 1);
		if(szTemp[0] == '^0'){
			ArraySetString(gMessages, i, szMessage);
			return i;
		}
	}
	ArrayPushString(gMessages, szMessage);
	return iSize;
}
stock isValidDHUD(dhud){
	return (dhud >=0 && dhud< ArraySize(aDHUD));
}
stock packColor(const iColor[3]){
	new col = 0;
	col |= (iColor[0]&0xFF)<<24;
	col |= (iColor[1]&0xFF)<<16;
	col |= (iColor[2]&0xFF)<<8;
	return col;
}
stock unpackColor(iColor[3], const color){
	iColor[0] = ((color&0xFF000000)>>24)&0xFF;
	iColor[1] = ((color&0xFF0000)>>16)&0xFF;
	iColor[2] = ((color&0xFF00)>>8)&0xFF;
}
stock Array:CopyOfArray(dhud){
	new Array:arr = ArrayCreate(FRAME_SIZE, 1);
	
	if(isValidDHUD(dhud)){
		new iFrame[FRAME_SIZE];
		new Array:arr2 = Array:ArrayGetCell(aDHUD, dhud);
		
		new iSize = ArraySize(arr2);
		
		for(new i=0;i<iSize;i++){
			ArrayGetArray(arr2, i, iFrame);
			ArrayPushArray(arr, iFrame);
		}
	}
	return arr;
}
stock setFrame(dhud, frame, iColor[3], Float:x, Float:y, iLen = 1){
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	if(frame < 0){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD Frame id %d", frame);
		return 0;
	}
	
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	new iArraySize = ArraySize(arr);
	if(iLen == 0){
		if(frame >=0 && frame < iArraySize){
			ArrayDeleteItem(arr, frame);
			return 1;
		}
		return 0;
	}
	
	new iSize = frame - iArraySize + 1;
	
	for(new i=0;i<iSize;i++)
		ArrayPushArray(arr, {0, 0, 0});
	
	new iFrame[FRAME_SIZE];
	iFrame = iColor;
	
	iFrame[0] = packColor(iFrame) | (iLen&0xFF);
	iFrame[1] = _:x;
	iFrame[2] = _:y;
	
	ArraySetArray(arr, frame, iFrame);
	return 1;
}
public _CreateDHUD(plugin, params){
	if(params < 1) 
		return -1;
	new dhud = get_param(1);
	
	new Array:arr;
	
	
	
	if(dhud >= 0)
		arr = CopyOfArray(dhud);
	else
		arr = ArrayCreate(FRAME_SIZE, 1);

	ArrayPushCell(aDHUD, arr);
	
	new fw = CreateOneForward(plugin, "fwStopAnimation", FP_CELL,  FP_CELL, FP_CELL);
	ArrayPushCell(gForwards, fw);
	return ArraySize(aDHUD)-1;
}
public _getFramesDHUD(plugin, params){
	new dhud = get_param(1);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	return ArraySize(arr);
}
public _setFrameDHUD(plugin, params){
	if(params < 6)
		return 0;
	
	new dhud = get_param(1);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	
	new frame = get_param(2);
	if(frame < 0){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD Frame id %d", frame);
		return 0;
	}
	
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	new iSize = frame - ArraySize(arr) + 1;
	
	for(new i=0;i<iSize;i++)
		ArrayPushArray(arr, {0x00000001, 0, 0});
	
	new iColor[3];
	get_array(3, iColor, 3);
	
	setFrame(dhud, frame, iColor, get_param_f(4), get_param_f(5), get_param(6));
	return 1;
}
public _getFrameDHUD(plugin, params){
	if(params < 6)
		return 0;
	
	new dhud = get_param(1);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	
	new frame = get_param(2);
	if(frame < 0 || frame >= ArraySize(arr)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD Frame id %d", frame);
		return 0;
	}
	
	new iFrame[3];
	ArrayGetArray(arr, frame, iFrame);
	
	set_float_byref(4, Float:iFrame[1]);
	set_float_byref(5, Float:iFrame[2]);
	set_param_byref(6, iFrame[0]&0xFF);
	
	unpackColor(iFrame, iFrame[0]);
	set_array(3, iFrame, 3);
	return 1;
}
public _DisplayDHUD(plugin, params){
	if(params < 5)
		return 0;
	
	new id = get_param(1);
	if(id && !is_user_connected(id)){
		log_error(AMX_ERR_NATIVE, "Player index %d out of bounds", id);
		return 0;
	}
	
	new dhud = get_param(2);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	
	new Float:fInterval = get_param_f(3);
	if(fInterval <= 0.0){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD interval value %.2f", fInterval);
		return 0;
	}
	
	new iChan = get_param(4);
	if(iChan < 0 || iChan > 4){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD channel %d", iChan);
		return 0;
	}
	
	new szMessage[MESSAGE_LEN];
	vdformat(szMessage, charsmax(szMessage), 5, 6);
	new string = allocString(szMessage);
	
	new Array:arr = CopyOfArray(dhud);
	
	new data[5];
	data[0] = id;
	data[1] = _:arr;
	data[2] = _:fInterval;
	data[3] = iChan;
	data[4] = string;
	
	new tid =  TASKID_BASE+33*dhud+id;
	
	if(task_exists(tid)){
		remove_task(tid);
		GarbageCollector();
	}
	
	new iArray[5];
	iArray[0] = tid;
	iArray[1] = _:arr;
	iArray[2] = string;
	iArray[3] = id;
	iArray[4] = dhud;
	ArrayPushArray(gArrays, iArray);
	
	gbDebug && log_amx("+Tid = %d Array = %d, string = %d", iArray[0], iArray[1], iArray[2]);
	
	taskDynamicHUD(data, tid);
	return 1;
}
public _clearDHUD(plugin, params){
	new id = get_param(1);
	if(id && !is_user_connected(id)){
		log_error(AMX_ERR_NATIVE, "Player index %d out of bounds", id);
		return 0;
	}
	
	new dhud = get_param(2);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	new tidBase = TASKID_BASE+33*dhud;
	
	if(id){
		if(task_exists(tidBase+id))
			remove_task(tidBase+id);
	}else{
		for(new i=0;i<33;i++){
			if(task_exists(tidBase+i))
				remove_task(tidBase+i);
		}
	}
	GarbageCollector();
	return 1;
}
public taskDynamicHUD(data[5], tid){
	new id = data[0];
	new Array:arr = Array:data[1];
	new Float:fInterval = Float:data[2];
	new iChan = data[3];
	new string = data[4];
	
	new iSize = ArraySize(arr);
	if(iSize == 0){
		GarbageCollector(tid);
		return;
	}
	
	new iFrame[FRAME_SIZE];
	ArrayGetArray(arr, 0, iFrame);
	ArrayDeleteItem(arr, 0);
	
	new iColor[3];
	unpackColor(iColor, iFrame[0]);
	
	new iLen = iFrame[0]&0xFF;
	fInterval *= iLen;
	
	ArrayGetString(gMessages, string, gszMessage, MESSAGE_LEN-1);
	
	set_hudmessage(iColor[0], iColor[1], iColor[2], Float:iFrame[1], Float:iFrame[2], 0, 0.0, fInterval+0.1, 0.0, 0.0, iChan);
	show_hudmessage(id, "%s", gszMessage)
	
	set_task(fInterval, "taskDynamicHUD", tid, data, sizeof data);
}
stock getParamsNum(const iParams[MAX_PARAMS+2]){
	new c=0;
	for(new i=2;i<MAX_PARAMS+2;i++){
		if(iParams[i] == -1) break;
		c++;
	}
	return c;
}
public _ApplyFilterDHUD(plugin, params){
	new dhud = get_param(1);
	if(!isValidDHUD(dhud)){
		log_error(AMX_ERR_PARAMS, "Invalid DHUD handle %d", dhud);
		return 0;
	}
	
	new szFilter[FILTERNAME_LEN];
	get_string(2, szFilter, FILTERNAME_LEN-1);
	
	new filter;
	if(!TrieGetCell(gFilters, szFilter, filter)){
		log_error(AMX_ERR_PARAMS, "Invalid filter name %s", szFilter);
		return 0;
	}
	
	new iNum = params - 6;
	if(iNum > MAX_PARAMS){
		log_error(AMX_ERR_PARAMS, "Max params count is %d, you send %d", MAX_PARAMS, iNum);
		return 0;
	}
	
	new iParams[MAX_PARAMS+2];
	ArrayGetArray(gFiltersCB, filter, iParams);
	
	new iMax = getParamsNum(iParams);
	if(iNum != iMax){
		log_error(AMX_ERR_PARAMS, "Expected %d params, got %d", iMax, iNum);
		return 0;
	}
	
	new startFrame = get_param(3);
	new endFrame = get_param(4);
	
	if(startFrame > endFrame){
		log_error(AMX_ERR_PARAMS, "Inverter start and end frames ( start > end)");
		return 0;
	}
	
	new Float:dx = get_param_f(5);
	new Float:dy = get_param_f(6);
	
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	new lastFrame = ArraySize(arr)-1;
	
	if(endFrame < 0 || endFrame > lastFrame)
		endFrame = lastFrame;
	
	if(startFrame < 0)
		startFrame = 0;
	else if(startFrame > lastFrame)
		startFrame = lastFrame;
	
	new iFrame[3];
	
	new const iParamOffset = 7;
	for(new i=startFrame;i<=endFrame;i++){
		ArrayGetArray(arr, (i>0)?i-1:i, iFrame);
		
		callfunc_begin_i(iParams[0], iParams[1]);
		callfunc_push_int(dhud);
		callfunc_push_int(i);
		callfunc_push_int(startFrame);
		callfunc_push_int(endFrame);
		callfunc_push_float(Float:iFrame[1] + dx);
		callfunc_push_float(Float:iFrame[2] + dy);
		
		new szTemp[MAX_PARAMS+7][128];
		new iTemp[MAX_PARAMS+7][3];
		for(new j=0;j<iNum;j++){
			switch(iParams[2+j]){
				case FP_CELL:{
					callfunc_push_int(get_param_byref(iParamOffset+j));
				}
				case FP_FLOAT:{
					callfunc_push_float(get_float_byref(iParamOffset+j));
				}
				case FP_ARRAY:{
					get_array(iParamOffset+j, iTemp[iParamOffset+j], 3);
					callfunc_push_array(iTemp[iParamOffset+j], 3, false);
				}
				case FP_STRING:{
					get_string(iParamOffset+j, szTemp[iParamOffset+j], charsmax(szTemp));
					callfunc_push_str(szTemp[iParamOffset+j], false);
				}
				default:{
					callfunc_push_int(0);
				}
			}
		}
		callfunc_end();
	}
	
	return 1;
}
public _register_filter(plugin, params){
	new szName[FILTERNAME_LEN], szFunc[32], szDescription[FILTERDESC_LEN];
	get_string(1, szName, FILTERNAME_LEN-1);
	get_string(2, szFunc, 31);
	get_string(3, szDescription, FILTERDESC_LEN-1);
	
	callfunc_begin("inner_register_filter");
	callfunc_push_int(plugin);
	callfunc_push_str(szName);
	callfunc_push_str(szFunc);
	callfunc_push_str(szDescription);
	
	new iParams[4+MAX_PARAMS];
	for(new i=4;i<=params;i++){
		iParams[i] = get_param_byref(i);
		callfunc_push_intrf( iParams[i] );
	}
	
	return callfunc_end();
}
//Filters
public inner_register_filter(plugin, const szName[], const szCallback[], const szDescription[], any:...){
	new iVal = 0;
	if(TrieGetCell(gFilters, szName, iVal)){
		log_error(AMX_ERR_NATIVE, "Filter %s already registered", szName);
		return 0;
	}
	
	iVal = get_func_id(szCallback, plugin);
	
	if(iVal == -1){
		log_error(AMX_ERR_PARAMS, "Function %s is not present", szCallback);
		return 0;
	}
	
	new iParams[MAX_PARAMS+2] = {-1, ...};
	iParams[0] = iVal;
	iParams[1] = plugin;
	
	
	new iNum = numargs() - 4;
	if(iNum > MAX_PARAMS){
		log_error(AMX_ERR_BOUNDS, "Max params count is %d, you send %d", MAX_PARAMS, iNum);
		return 0;
	}
	iNum++;
	for(new i=2;i<=iNum;i++){
		iParams[i] = getarg(i+2);
	}
	
	gbDebug && log_amx("Register Filter <%s>", szName);
	
	TrieSetCell(gFilters, szName, ArraySize(gFiltersCB));
	ArrayPushArray(gFiltersCB, iParams);
	ArrayPushString(gFilterNames, szName);
	ArrayPushString(gFilterDesc, szDescription);
	return 1;
}

//SetPosition
public filterSetPosition(dhud, frame, startFrame, endFrame, Float:x, Float:y, Float:setX, Float:setY){
	if(frame == 0) return;
	
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	
	new iFrame[FRAME_SIZE];
	ArrayGetArray(arr, frame, iFrame);
	
	iFrame[1] = _:setX;
	iFrame[2] = _:setY;
	ArraySetArray(arr, frame, iFrame);
}
//SetColor
public filterSetColor(dhud, frame, startFrame, endFrame, Float:x, Float:y, r, g, b){	
	new iFrame[FRAME_SIZE];
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	ArrayGetArray(arr, frame, iFrame);
	
	new iColor[3];
	iColor[0] = r;
	iColor[1] = g;
	iColor[2] = b;
	
	new iLen  = (iFrame[0]&0xFF);
	if(!iLen) 
		iLen = 1;
	
	iFrame[0] =  iLen | packColor(iColor);
	ArraySetArray(arr, frame, iFrame);
}
public filterSetColorA(dhud, frame, startFrame, endFrame, Float:x, Float:y, iColor[3]){
	filterSetColor(dhud, frame,startFrame, endFrame, x, y, iColor[0], iColor[1], iColor[2]);
}
//FilterStraight
public filterMoveStraight(dhud, frame, startFrame, endFrame, Float:x, Float:y, Float:a,  Float:b){
	new iFrame[FRAME_SIZE];
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	ArrayGetArray(arr, frame, iFrame);
	
	iFrame[1] = _:x;
	iFrame[2] = _:floatmax((a*x+b), 0.0);
	ArraySetArray(arr, frame, iFrame);
}
//TransColor
public filterTransColor(dhud, frame, startFrame, endFrame, Float:x, Float:y, const iColor[3], const iColor2[3]){
	new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
	
	new iFrame[FRAME_SIZE];
	ArrayGetArray(arr, frame, iFrame);
	
	new iLen = iFrame[0]&0xFF;
	
	new Float:fFrames = float(endFrame - startFrame);
	
	new iColorDis[3];
	iColorDis[0] = iColor2[0] - iColor[0];
	iColorDis[1] = iColor2[1] - iColor[1];
	iColorDis[2] = iColor2[2] - iColor[2];
	
	iColorDis[0] = iColor[0] + floatround(iColorDis[0]/fFrames * (frame-startFrame));
	iColorDis[1] = iColor[1] + floatround(iColorDis[1]/fFrames * (frame-startFrame));
	iColorDis[2] = iColor[2] + floatround(iColorDis[2]/fFrames * (frame-startFrame));
	
	iFrame[0] = iLen | packColor(iColorDis);
	ArraySetArray(arr, frame, iFrame);
}
//Flickering
public filterFlickering(dhud, frame, startFrame, endFrame, Float:x, Float:y, a){
	if(((frame - startFrame) % a) == 0){
		new Array:arr = Array:ArrayGetCell(aDHUD, dhud);
		
		new iFrame[FRAME_SIZE];
		ArrayGetArray(arr, frame, iFrame);
		
		new iLen = iFrame[0]&0xFF;
		
		iFrame[0] = iLen | packColor({0, 0, 0});
		ArraySetArray(arr, frame, iFrame);
	}
}
