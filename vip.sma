#include <amxmodx>
#include <colorchat>


new Array:g_Array, bool:g_Vip[33];

new const g_Langcmd[][]={"say /vips","say_team /vips","say /vipy","say_team /vipy"};
new const g_Prefix[] = "Vip Chat";

public plugin_init(){
	register_plugin("VIP Ultimate", "12.3.0.2", "benio101 & speedkill");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	g_Array=ArrayCreate(64,32);
	for(new i;i<sizeof g_Langcmd;i++){
		register_clcmd(g_Langcmd[i], "ShowVips");
	}
	register_clcmd("say /vip", "ShowMotd");
	register_clcmd("say_team", "VipChat");
	register_message(get_user_msgid("SayText"),"handleSayText");
}
public client_authorized(id){
	if(get_user_flags(id) & 524288 == 524288){
		client_authorized_vip(id);
	}
}
public client_authorized_vip(id){
	g_Vip[id]=true;
	new g_Name[64];
	get_user_name(id,g_Name,charsmax(g_Name));
	
	new g_Size = ArraySize(g_Array);
	new szName[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, szName, charsmax(szName));
		
		if(equal(g_Name, szName)){
			return 0;
		}
	}
	ArrayPushString(g_Array,g_Name);
	
	return PLUGIN_CONTINUE;
}
public client_disconnected(id){
	if(g_Vip[id]){
		client_disconnect_vip(id);
	}
}
public client_disconnect_vip(id){
	g_Vip[id]=false;
	new Name[64];
	get_user_name(id,Name,charsmax(Name));
	
	new g_Size = ArraySize(g_Array);
	new g_Name[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		if(equal(g_Name,Name)){
			ArrayDeleteItem(g_Array,i);
			break;
		}
	}
}
public VipStatus(){
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && g_Vip[id]){
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
	}
}
public ShowVips(id){
	new g_Name[64],g_Message[192];
	
	new g_Size=ArraySize(g_Array);
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		add(g_Message, charsmax(g_Message), g_Name);
		
		if(i == g_Size - 1){
			add(g_Message, charsmax(g_Message), ".");
		}
		else{
			add(g_Message, charsmax(g_Message), ", ");
		}
	}
	ColorChat(id,GREEN,"^x03Vipy ^x04na ^x03serwerze: ^x04%s", g_Message);
	return PLUGIN_CONTINUE;
}
public client_infochanged(id){
	if(g_Vip[id]){
		new szName[64];
		get_user_info(id,"name",szName,charsmax(szName));
		
		new Name[64];
		get_user_name(id,Name,charsmax(Name));
		
		if(!equal(szName,Name)){
			ArrayPushString(g_Array,szName);
			
			new g_Size=ArraySize(g_Array);
			new g_Name[64];
			for(new i = 0; i < g_Size; i++){
				ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
				
				if(equal(g_Name,Name)){
					ArrayDeleteItem(g_Array,i);
					break;
				}
			}
		}
	}
}
public plugin_end(){
	ArrayDestroy(g_Array);
}
public ShowMotd(id){
	show_motd(id, "vip.txt", "Informacje o vipie");
}
public VipChat(id){
	if(g_Vip[id]){
		new g_Msg[256],
		g_Text[256];
		
		read_args(g_Msg,charsmax(g_Msg));
		remove_quotes(g_Msg);
		
		if(g_Msg[0] == '*' && g_Msg[1]){
			new g_Name[64];
			get_user_name(id,g_Name,charsmax(g_Name));
			
			formatex(g_Text,charsmax(g_Text),"^x01(%s) ^x03%s : ^x04%s",g_Prefix, g_Name, g_Msg[1]);
			
			for(new i=1;i<33;i++){
				if(is_user_connected(i) && g_Vip[i])
				ColorChat(i, GREEN, "%s", g_Text);
			}
			return PLUGIN_HANDLED_MAIN;
		}
	}
	return PLUGIN_CONTINUE;
}
public handleSayText(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id))
	{
		if(g_Vip[id])
		{
			new szTmp[256],szTmp2[256];
			get_msg_arg_string(2,szTmp, charsmax(szTmp))
		
			new szPrefix[64] = "^x01[^x04VIP^x01]";

			if(!equal(szTmp,"#Cstrike_Chat_All")){
				add(szTmp2,charsmax(szTmp2),szPrefix);
				add(szTmp2,charsmax(szTmp2)," ");
				add(szTmp2,charsmax(szTmp2),szTmp);
			}
			else{
				add(szTmp2,charsmax(szTmp2),szPrefix);
				add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
			}
			set_msg_arg_string(2,szTmp2);
		}
	}
	
	return PLUGIN_CONTINUE;
}
