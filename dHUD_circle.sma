#include <amxmodx>
#include <amxmisc>
#include <dHUD>

#define PLUGIN "dHUD Circle"
#define VERSION "1.2"
#define AUTHOR "R3X"

new circle, inf1, inf2, inf3;

enum{
	dir_left = -1,
	dir_right = 1
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	DHUD_registerFilter("Circle", "filterCircle", 
		"<Float:x> <Float:y> <Float:r> <Float:angle> <Float:offset> <dir> - Draw circle, dx,dx set to 0.0", 
		FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_CELL);
	
	DHUD_registerFilter("InfinityChar", "filterInfinityChar", 
		"<Float:x> <Float:y> <Float:r> <Float:angle> <Float:offset> <dir> - Draw infinity char, dx,dx set to 0.0", 
		FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_FLOAT, FP_CELL);
	
	
	
	circle = DHUD_create();
	DHUD_setFrame(circle, 20);
	DHUD_applyFilter(circle, "SetColor", 0, 20, _, _, 255, 255, 255);
	DHUD_applyFilter(circle, "Circle", 0, 20, D_ZERO, D_ZERO, 0.5, 0.5, 0.2, 360.0, 0.0, dir_left);
	
	
	//InfinityChar
	
	//Second trail
	inf3 = DHUD_create();
	DHUD_setFrame(inf3, 42);
	DHUD_applyFilter(inf3, "SetColor", 2, 42, _, _, 50, 50, 50);
	DHUD_applyFilter(inf3, "InfinityChar", 2, 42, D_ZERO, D_ZERO, 0.7, 0.5, 0.2, 720.0, 90.0, dir_left);
	
	//First trail
	inf2 = DHUD_create(inf3);
	DHUD_removeFrames(inf2, 0, 1);
	DHUD_applyFilter(inf2, "SetColor", 1, 41, _, _, 100, 100, 100);
	
	//Main message
	inf1 = DHUD_create(inf2);
	DHUD_removeFrames(inf1, 0, 1);
	DHUD_applyFilter(inf1, "SetColor", 0, 40, _, _, 255, 255, 255);

	
	new iColor[3], Float:oldx, Float:oldy, iLen;
	DHUD_getFrame(inf1, 40, iColor, oldx, oldy, iLen);
	DHUD_setFrame(inf1, 40, iColor, oldx, oldy, 30);//stay on screen
	
	register_clcmd("circle", "cmdCircle");
	register_clcmd("inf", "cmdInf");
}
public filterInfinityChar(dhud, frame, startFrame, endFrame, Float:x, Float:y, Float:rx, Float:ry, Float:r, Float:angle, Float:offset, dir){
	new iColor[3], Float:oldx, Float:oldy, iLen;
	DHUD_getFrame(dhud, frame, iColor, oldx, oldy, iLen);

	new Float:beta = angle / (endFrame-startFrame);
	beta *= dir;
	beta *= (frame-startFrame);
	beta += offset;
	
	x = r;
	y = 0.0;
			
	x = x*floatcos(beta, degrees);
	y = x*floatsin(beta, degrees);
			
	DHUD_setFrame(dhud, frame, iColor, rx+x, ry+y, iLen);
}
public filterCircle(dhud, frame, startFrame, endFrame, Float:x, Float:y, Float:rx, Float:ry, Float:r, Float:angle, Float:offset, dir){
	new iColor[3], Float:oldx, Float:oldy, iLen;
	DHUD_getFrame(dhud, frame, iColor, oldx, oldy, iLen);

	new Float:beta = angle / (endFrame-startFrame);
	beta *= dir;
	beta *= (frame-startFrame);
	beta += offset;
	
			
	x = rx + r*floatcos(beta, degrees);
	y = ry + r*floatsin(beta, degrees);
			
	DHUD_setFrame(dhud, frame, iColor, x, y, iLen);
}


public cmdCircle(id){
	DHUD_display(id, circle, 0.1, 3, "XYZ");
	client_print(id, print_chat, "Dziala")
	return PLUGIN_HANDLED;
}
public cmdInf(id){
	DHUD_display(id, inf1, 0.1, 4, "Loading");
	DHUD_display(id, inf2, 0.1, 3, "Loading");
	DHUD_display(id, inf3, 0.1, 2, "Loading");
	return PLUGIN_HANDLED;
}
