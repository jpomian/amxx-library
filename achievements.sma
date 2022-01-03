#include <amxmodx>
#include <hamsandwich>
#include <nvault>
#include <ColorChat>

#define PLUGIN "Achievements"
#define VERSION "1.1.2"
#define AUTHOR "Fili:P + Mixtaz"

#define MAX 32
#define PREFIX "Osiagniecia"

// achievement
new AchValue;
new Array:AchStance[ MAX+1 ];
new Array:AchStatus[ MAX+1 ];
new Array:AchTarget;
new Array:AchName;
new Array:AchDesc;

// forwardy
new g_Forward[ 5 ];

// cvary
new g_cvar_display;

new const AchsCommands[][] =
	{
		"say /achs",
		"say_team /achs",
		"say /achievements",
		"say_team /achievements",
		"say /osiagniecia",
		"say_team /osiagniecia"
	};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i=0; i < sizeof AchsCommands; i++)
    register_clcmd(AchsCommands[i], "AchMenu")
	
	RegisterHam(Ham_Killed, "player", "HamCheck", 0);
	RegisterHam(Ham_Spawn, "player", "HamSpawn", 1);

	g_cvar_display = get_pcvar_num( register_cvar("ach_display_gz", "1") ); // czy wyswietlac gratulacje zdobyles %s ?
		
	AchTarget = ArrayCreate(1, 1);
	AchName = ArrayCreate(32, 1);
	AchDesc = ArrayCreate(256, 1);
	
	g_Forward[ 0 ] = CreateMultiForward("ach_give_reward", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forward[ 1 ] = CreateMultiForward("ach_load_post", ET_CONTINUE, FP_CELL);
	g_Forward[ 2 ] = CreateMultiForward("ach_save_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forward[ 3 ] = CreateMultiForward("ach_save_post", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forward[ 4 ] = CreateMultiForward("ach_info_display", ET_CONTINUE, FP_CELL, FP_CELL, FP_ARRAY);
	AchValue = nvault_open("Achievements");
	
	if (AchValue == INVALID_HANDLE)
                set_fail_state( "Nie moge otworzyc pliku!");
}
public plugin_natives()
{
	register_library("achs");
	
	register_native("ach_get_index", "_ach_get_index");
	register_native("ach_get_stance", "_ach_get_stance"); // pobiera czy ach zaliczony czy nie
	register_native("ach_get_status", "_ach_get_status"); // pobiera postep w achu
	register_native("ach_get_desc", "_ach_get_desc"); // pobiera do talibyc opis acha o konkretnym id
	register_native("ach_get_name", "_ach_get_name"); // pobiera do tablicy nazwe acha o konkretnym id
	register_native("ach_get_target", "_ach_get_target"); // pobiera wymagana ilosc do zakonczenia acha
	register_native("ach_get_max", "_ach_get_max"); // pobiera ilosc achievementow (ACH_NUM)
	register_native("ach_set_stance", "_ach_set_stance"); // ustawia czy gracz ukonczyl acha
	register_native("ach_set_status", "_ach_set_status"); // ustawia postep w achu
	register_native("ach_add", "_ach_add"); // tworzy nowy ach
	register_native("ach_reset_status", "_ach_reset_status"); // ustawia AchStatus[id][aid] na 0
	register_native("ach_add_status", "_ach_add_status"); // dodaje postep w achu
	register_native("ach_get_playerachs", "_ach_get_playerachs")
}
public plugin_end() 
{
	nvault_close(AchValue);
}
public client_authorized(id)
{
	AchStance[id]=ArrayCreate(1,1);
	AchStatus[id]=ArrayCreate(1,1);
	
	for(new i=0; i<ArraySize(AchTarget); i++)
	{
		ArrayPushCell(AchStance[id], 0);
		ArrayPushCell(AchStatus[id], 0);
		load_nvault(id, i);
	}
	new iRet;
	ExecuteForward(g_Forward[ 1 ], iRet, id);
}
public client_disconnected(id)
{
	new iRet;
	ExecuteForward(g_Forward[ 2 ], iRet, id, 1);
	for(new i=0; i<ArraySize(AchTarget); i++)
		save_nvault(id, i)
	ArrayDestroy(AchStatus[id]);
	ArrayDestroy(AchStance[id]);
}
public AchMenu(id)
{
	new AchM = menu_create("Osiagniecia", "AchMenuHandle");
	
	for(new i=0; i<ArraySize(AchTarget); i++)
	{
		if(is_user_connected(id))
		{
			new message[128];
			new iAchName[64];
			new data[ 2 ];
			data[ 0 ] = ArrayGetCell(AchTarget, i);
			data[ 1 ] = ArrayGetCell(AchStatus[id], i);
			new iRet
			ExecuteForward(g_Forward[ 4 ], iRet, id, i, PrepareArray(data, 2, 1));
			new iAchStance = ArrayGetCell(AchStance[id], i);
			new iAchStatus = data[ 1 ];
			new iTarget = data[ 0 ];
			ArrayGetString(AchName, i, iAchName, 63);

			if(!iAchStance)
				format(message, 127, "\w%s \t\y%d/%d", iAchName, iAchStatus, iTarget)
			if(iAchStance)
				format(message, 127, "\w%s \t\yZaliczone!", iAchName)
			menu_additem(AchM, message);
		}
	}
	menu_display(id, AchM, 0);
	return PLUGIN_HANDLED;
}
public AchMenuHandle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED
	}
	else if(is_user_connected(id) && item > -1 && item < ArraySize(AchTarget))
	{
		new iAchDesc[256];
		new data[ 2 ];
		data[ 0 ] = ArrayGetCell(AchTarget, item);
		data[ 1 ] = ArrayGetCell(AchStatus[id], item);
		new iRet
		ExecuteForward(g_Forward[ 4 ], iRet, id, item, PrepareArray(data, 2, 1));
		new iAchStatus = data[ 1 ];
		new iTarget = data[ 0 ];
		ArrayGetString(AchDesc, item, iAchDesc, 255);	
		if(!ArrayGetCell(AchStance[id], item))
			ColorChat(id, GREEN, "[%s] ^x01%s ^x04%d/%d", PREFIX, iAchDesc, iAchStatus, iTarget)
		else
			ColorChat(id, GREEN, "[%s] ^x01%s ^x04Zaliczone!", PREFIX, iAchDesc)
				
		menu_display(id, menu, 0);
	}
        return PLUGIN_HANDLED;
}
// ham
public HamSpawn(id)
{
	if(is_user_connected(id))
	{
		for(new i=0; i<ArraySize(AchTarget); i++)
		{
			load_nvault(id, i);
		}
	}
}
public HamCheck(id)
{	
	if(is_user_connected(id))
	{
		check_all_ach(id);
		new iRet;
		ExecuteForward(g_Forward[ 2 ], iRet, id, 2);
		for(new i=0; i<ArraySize(AchTarget); i++)
			save_nvault(id, i);
		new iRet2;
		ExecuteForward(g_Forward[ 3 ], iRet2, id, 2);
	}
}
//natywy
public _ach_get_index(plugin, params)
{
	//if(params != 1)
		//return 0;
	new szAchName[32];
	new zwroc;
	get_string(1, szAchName, 31);
	for(new i=0; i<ArraySize(AchTarget); i++)
	{
		new szAchName2[31];
		ArrayGetString(AchName, i, szAchName2, 31);
		if(equal(szAchName2, szAchName))
			zwroc = i;
	}
	return zwroc;
}
public _ach_get_max(plugin, params)
	return ArraySize(AchTarget);
public _ach_get_stance(plugin, params)
{
	new id = get_param(1);
	return ArrayGetCell(AchStance[ id ], get_param(2));
}
public _ach_get_status(plugin, params)
{
	new id = get_param(1);
	if( !is_user_connected( id ) )
		return 0;
	return ArrayGetCell(AchStatus[ id ], get_param(2));
}
public _ach_get_target(plugin, params)
	return ArrayGetCell(AchTarget, get_param(1));
public _ach_get_name(plugin, params)
{
	new iAchName[64];
	ArrayGetString(AchName, get_param(1), iAchName, 63);
	set_string(2, iAchName, get_param(3));
}
public _ach_get_desc(plugin, params)
{
	new iAchDesc[64];
	ArrayGetString(AchDesc, get_param(1), iAchDesc, 63);
	set_string(2, iAchDesc, get_param(3));
}
public _ach_set_stance(plugin, params)
	ArraySetCell(AchStatus[ get_param(1) ], get_param(2), get_param(3));	
public _ach_set_status(plugin, params)
	ArraySetCell(AchStatus[ get_param(1) ], get_param(2), get_param(3));
public _ach_add(plugin, params)
{
	new szAchName[64];
	new szAchDesc[256];
	get_string(1, szAchName, 63);
	get_string(2, szAchDesc, 255);
	ArrayPushString(AchName, szAchName);
	ArrayPushString(AchDesc, szAchDesc);
	ArrayPushCell(AchTarget, get_param(3));
	return ArraySize(AchTarget)-1;
}
public _ach_reset_status(plugin, params)
	ArraySetCell(AchStatus[get_param(1)], get_param(2), 0);
public _ach_add_status(plugin, params)
	ArraySetCell(AchStatus[get_param(1)], get_param(2), ArrayGetCell(AchStatus[get_param(1)] , get_param(2)) + get_param(3));
public _ach_get_playerachs(plugin, params)
	get_player_achs(get_param(0))


// stocki
stock check_ach(pid, aid)
{
	if(ArrayGetCell(AchStatus[pid], aid) >= ArrayGetCell(AchTarget, aid) && !ArrayGetCell(AchStance[pid], aid) && is_user_connected(pid))
	{
		new name[33];
		get_user_name(pid, name, 32);
		ArraySetCell(AchStance[pid], aid, 1);
		new iAchName[64];
		ArrayGetString(AchName, aid, iAchName, 63);
		if(g_cvar_display)
			ColorChat(pid, GREEN, "[%s] ^x01Gracz ^x04%s^x01 zdobyl osiagniecie ^x04^"%s^"^x01!", PREFIX, name, iAchName)
		new iRet;
		ExecuteForward(g_Forward[ 0 ], iRet, pid, aid);
	}
}
stock check_all_ach(pid)
	for(new i=0; i<ArraySize(AchTarget); i++)
		check_ach(pid, i);

stock get_player_achs(id)
{
	new a[33];
	for(new i=0; i<ArraySize(AchTarget); i++)
	{
		if(ArrayGetCell(AchStance[ id ], i))
			a[id]++
	}

	return a[id];
}

stock load_nvault(index, ach_id)
{
	if(is_user_connected(index))
	{
		new name[35]
		get_user_name(index,name,34)
		new vaultkey[64],vaultdata[256]
		format(vaultkey,63,"%s-%d-ach",name, ach_id)
		format(vaultdata,255,"%d#%d#",ArrayGetCell(AchStatus[index], ach_id) , ArrayGetCell(AchStance[index], ach_id))
		nvault_get(AchValue,vaultkey,vaultdata,255) 
 
		replace_all(vaultdata, 255, "#", " ") 
        
		new ach_status[33], ach_stance[33];
		parse(vaultdata,ach_status,32,ach_stance,32) 
    
		ArraySetCell(AchStatus[index], ach_id, str_to_num(ach_status));
		ArraySetCell(AchStance[index], ach_id, str_to_num(ach_stance));
	}
}  
stock save_nvault(index, ach_id)
{
	if(is_user_connected(index))
	{
		new name[35]
		get_user_name(index,name,34)
		new vaultkey[64],vaultdata[256] 
		format(vaultkey,63,"%s-%d-ach",name, ach_id) 
		format(vaultdata,255,"%d#%d#", ArrayGetCell(AchStatus[index], ach_id), ArrayGetCell(AchStance[index], ach_id)) 

		nvault_set(AchValue,vaultkey,vaultdata)   
	}
}
