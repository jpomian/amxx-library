#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <colorchat>
#include <engine>
#include <xs>
#include <sqlx>
#tryinclude "biohazard.cfg"

#define EQUIP_PRI (1<<0)
#define EQUIP_SEC (1<<1)
#define EQUIP_GREN (1<<2)
#define EQUIP_ALL (1<<0 | 1<<1 | 1<<2)

#define HAS_NVG (1<<0)
#define ATTRIB_BOMB (1<<1)
#define DMG_HEGRENADE (1<<24)

#define ANNOUNCEMENT_DURATION 4.0
#define MAX_BOTS 6

#define MODEL_CLASSNAME "player_model"
#define WEAPONMODEL_CLASSNAME "ent_weaponmodel"
#define IMPULSE_FLASHLIGHT 100

#define FADE_IN_TIME 0.3
#define FADE_HOLD_TIME 0.5
#define FADE_OUT_TIME 0.5
#define FADE_TIME (FADE_IN_TIME + FADE_HOLD_TIME + FADE_OUT_TIME)
#define FADE_ALPHA 80
#define MESSAGE_SCREEN_FADE 98
#define FFADE_OUT 0x0001
#define FFADE_IN 0x0000

#define fm_get_user_team(%1) get_pdata_int(%1, 114)
#define fm_get_user_deaths(%1) get_pdata_int(%1, 444)
#define fm_set_user_deaths(%1,%2) set_pdata_int(%1, 444, %2)
#define fm_get_user_money(%1) get_pdata_int(%1, 115)
#define fm_get_user_armortype(%1) get_pdata_int(%1, 112)
#define fm_set_user_armortype(%1,%2) set_pdata_int(%1, 112, %2)
#define fm_get_weapon_id(%1) get_pdata_int(%1, 43, 4)
#define fm_reset_user_primary(%1) set_pdata_int(%1, 116, 0)
#define fm_lastprimary(%1) get_pdata_cbase(id, 368)
#define fm_lastsecondry(%1) get_pdata_cbase(id, 369)
#define fm_lastknife(%1) get_pdata_cbase(id, 370)
#define fm_get_user_model(%1,%2) engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, %1), "model", %2, charsmax(%2)) 
#define is_vip(%1) get_user_flags(%1) & ADMIN_LEVEL_H
#define isGametype(%1) get_pcvar_num(cvar_gametype) == %1
#define isDucking(%1) (pev(%1, pev_flags) & FL_DUCKING) 
#define _random(%1) random_num(0, %1 - 1)
#define AMMOWP_NULL (1<<0 | 1<<CSW_KNIFE | 1<<CSW_FLASHBANG | 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)

enum(+= 100)
{
	TASKID_STRIPNGIVE,
	TASKID_NEWROUND,
	TASKID_INITROUND,
	TASKID_STARTROUND,
	TASKID_ANNOUNCEMENT,
	TASKID_BALANCETEAM,
	TASKID_UPDATESCR,
	TASKID_SPAWNDELAY,
	TASKID_RESPAWN,
	TASKID_CHECKSPAWN
}

enum
{
	MENU_PRIMARY = 1,
	MENU_SECONDARY
}

enum
{
	_:CS_TEAM_UNASSIGNED = 0,
	_:CS_TEAM_T,
	_:CS_TEAM_CT,
	CS_TEAM_SPECTATOR
}

enum _:DATA_SCREENFADE_SIZE
{
    Float:DSS_OutTime,
    DSS_Red,
    DSS_Green,
    DSS_Blue,
    DSS_Alpha
}

enum
{
	KBPOWER_357SIG = 0,
	KBPOWER_762NATO,
	KBPOWER_BUCKSHOT,
	KBPOWER_45ACP,
	KBPOWER_556NATO,
	KBPOWER_9MM,
	KBPOWER_57MM,
	KBPOWER_338MAGNUM,
	KBPOWER_556NATOBOX,
	KBPOWER_50AE
}

enum DataTypes
{
	SAVE,
	LOAD,
	RESET,
	UPDATE
}

enum _:SaveTypes
{
	NICKNAME,
	IP,
	STEAMID
}

enum PlayerData
{ 
	AuthInfo[ MAX_AUTHID_LENGTH ],
	NickInfo[ MAX_NAME_LENGTH ],
	IpInfo[ MAX_IP_LENGTH ],
	Infects
}

new const SQL_HOST[ ] = "sql.pukawka.pl"
new const SQL_USER[ ] = "898035"
new const SQL_PASS[ ] = "zmKOLOSEUM"
new const SQL_DATABASE[ ] = "898035_infekcje"
new const SQL_TABLE[ ] = "Infections"


new const g_weapon_knockback[] =
{
	-1, 
	KBPOWER_357SIG, 
	-1, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_BUCKSHOT, 
	-1, 
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	-1, 
	KBPOWER_9MM, 
	KBPOWER_57MM,
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_45ACP,
	KBPOWER_9MM, 
	KBPOWER_338MAGNUM,
	KBPOWER_9MM, 
	KBPOWER_556NATOBOX,
	KBPOWER_BUCKSHOT, 
	KBPOWER_556NATO, 
	KBPOWER_9MM, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_50AE, 
	KBPOWER_556NATO, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_57MM
}

new const g_weapon_ammo[] = 
{ 
	-1, 52, -1, 90, 1, 32, 
	1, 100, 90, 1, 120, 100,
	100, 90, 90, 90, 100, 120,
	30, 120, 200, 32, 90, 120, 
	90, 2, 35, 90, 90, -1, 100 
}

new const g_remove_entities[][] = 
{ 
	"func_bomb_target",    
	"info_bomb_target", 
	"hostage_entity",      
	"monster_scientist", 
	"func_hostage_rescue", 
	"info_hostage_rescue",
	"info_vip_start",      
	"func_vip_safetyzone", 
	"func_escapezone",     
	"func_buyzone"
}

new const g_teaminfo[][] = 
{ 
	"UNASSIGNED", 
	"TERRORIST",
	"CT",
	"SPECTATOR" 
}

new const g_skies[][] =
{
	"space",
	"night",
	"black",
	"hav",
	"xen8"
}

new const Float: g_zmspeed_array[] =
{
	280.0,
	265.0,
	250.0
}

new g_maxplayers,
    g_buyzone,
    g_sync_dmgdisplay,
    g_msg_money,
    g_fwd_spawn,
    g_fwd_result,
    g_fwd_infect,
    g_fwd_gamestart,
    g_msg_flashlight,
    g_msg_teaminfo,
    g_msg_scoreinfo,
    g_rounds_elapsed,
    g_newzombies,
    Float:g_vecvel[3],
    bool:g_brestorevel,
    bool:g_gamestarted,
    bool:g_roundstarted,
    bool:g_roundended;

new cvar_autoteambalance[4],
    cvar_starttime,
    cvar_weaponsmenu,
    cvar_enabled,
    cvar_moneybonus,
    cvar_zombiehp,
	cvar_zombiehpmultiplied,
	cvar_viphp,
    cvar_spawnlimit,
    cvar_gametype,
    cvar_multiinfection,
	cvar_respmoney,
	cvar_resptime,
	cvar_infecthp,
    cvar_knockback,
    cvar_knockback_duck,
    cvar_knockback_dist;

new bool:g_zombie[33],
    bool:g_waszombie[33],
    bool:g_falling[33],
    bool:g_disconnected[33],
    bool:g_blockmodel[33],
    bool:g_showmenu[33],
    bool:g_menufailsafe[33],
    bool:g_suicide[33],
    bool:g_preinfect[33],
    g_victim[33],
    g_modelent[33],
    g_weaponent[33],
    g_player_weapons[33][2],
    g_msg_screenfade,
    g_msg_deathmsg,
    g_msg_scoreattrib,
    weapons[33],
    Float:g_regendelay[33],
    Float:g_regendelaymodifier[33],
	Float: g_kbReduction[33],
    g_healthmodifier[33],
    g_moneymodifier[33],
    g_map[32],
	g_tag[18],
    g_damagecount[33],
    g_Bestdmg,
    g_Bestdmgid,
    g_infectcount[33],
    g_Bestinfect,
    g_Bestinfectid,
    g_winnerid,
    bool:g_zombieswon,
    bool:g_humanswon,
    g_lives[33],
	Float: g_respcount[33];
	
new g_iPlayer[ 33 ][ PlayerData ],
	Handle:g_SQLTuple,
	g_szSQLError[ MAX_QUERY_LENGTH ];

const MAX_QUERY_LENGTH = 256;
const MAX_AUTHID_LENGTH = 64
const MAX_NAME_LENGTH = 32
const MAX_IP_LENGTH = 16

public plugin_precache()
{
	register_plugin("Biohazard", "1", "cheap_suit")

	cvar_enabled = register_cvar("bh_enabled", "1")

	if(!get_pcvar_num(cvar_enabled)) 
		return

	cvar_gametype = register_cvar("bh_gametype","1")
	cvar_spawnlimit = register_cvar("bh_spawnlimit", "2")
	cvar_starttime = register_cvar("bh_starttime", "8.0")
	cvar_multiinfection = register_cvar("bh_multi","1")
	cvar_weaponsmenu = register_cvar("bh_weaponsmenu", "1")

	cvar_moneybonus = register_cvar("vip_bonusmoney", "500")
	cvar_viphp = register_cvar("vip_zombiehp", "250")
	cvar_zombiehp = register_cvar("bh_zombiehp", "2500")
	cvar_zombiehpmultiplied = register_cvar("bh_zombiemotherhp", "2.0")
	cvar_respmoney = register_cvar("bh_respmoney", "500")
	cvar_resptime = register_cvar("bh_resptime", "10.0")
	cvar_infecthp = register_cvar("bh_infecthp", "300")

	cvar_knockback = register_cvar("bh_knockback", "1")
	cvar_knockback_duck = register_cvar("bh_knockback_duck", "0")
	cvar_knockback_dist = register_cvar("bh_knockback_dist", "290.0")
			
	precache_model(DEFAULT_PMODEL)
	precache_model(FIRSTZOMBIE_PMODEL) 

	precache_model(DEFAULT_WMODEL)

	new i

	//models
	for(i = 0; i < sizeof g_human_vip_models; i++)
		precache_model(fmt("models/player/%s/%s.mdl", g_human_vip_models[i], g_human_vip_models[i]))
	
	//hardcoded dual precache method

	precache_model("models/player/bhz_gign/bhz_gignT.mdl")
	precache_model("models/player/bhz_sas/bhz_sasT.mdl")

    //sounds
	for(i = 0; i < sizeof g_zombie_miss_sounds; i++)
    	precache_sound(g_zombie_miss_sounds[i])

	for(i = 0; i < sizeof g_zombie_hit_sounds; i++) 
		precache_sound(g_zombie_hit_sounds[i])
	
	for(i = 0; i < sizeof g_scream_sounds; i++) 
    	precache_sound(g_scream_sounds[i])

	for(i = 0; i < sizeof g_zombie_die_sounds; i++)
    	precache_sound(g_zombie_die_sounds[i])
		
	g_fwd_spawn = register_forward(FM_Spawn, "fwd_spawn")
	
	g_buyzone = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
	if(g_buyzone) 
    {
    	dllfunc(DLLFunc_Spawn, g_buyzone)
    	set_pev(g_buyzone, pev_solid, SOLID_NOT)
    }

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_bomb_target"))
	if(ent) 
    {
    	dllfunc(DLLFunc_Spawn, ent)
    	set_pev(ent, pev_solid, SOLID_NOT)
    }

    /* ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))

    if(ent)
    {
    	fm_set_kvd(ent, "density", FOG_DENSITY, "env_fog")
    	fm_set_kvd(ent, "rendercolor", FOG_COLOR, "env_fog")
    } */
}

public plugin_init()
{
	if(!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_autoteambalance[0] = get_cvar_pointer("mp_autoteambalance")
	cvar_autoteambalance[1] = get_pcvar_num(cvar_autoteambalance[0])
	set_pcvar_num(cvar_autoteambalance[0], 0)

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("say /guns", "cmd_enablemenu")
		
	unregister_forward(FM_Spawn, g_fwd_spawn)
	register_forward(FM_CmdStart, "fwd_cmdstart")
	register_forward(FM_EmitSound, "fwd_emitsound")
	register_forward(FM_CreateNamedEntity, "fwd_createnamedentity")
	register_forward(FM_ClientKill, "fwd_clientkill")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink_post", 1)
	register_forward(FM_PlayerPostThink, "fwd_player_postthink")
	register_forward(FM_SetClientKeyValue, "fwd_setclientkeyvalue")

	RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player")
	RegisterHam(Ham_Killed, "player", "bacon_killed_player")
	RegisterHam(Ham_Spawn, "player", "bacon_spawn_player_post", 1)
	RegisterHam(Ham_TraceAttack, "player", "bacon_traceattack_player")
	RegisterHam(Ham_Use, "func_tank", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankmortar", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankrocket", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tanklaser", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_pushable", "bacon_use_pushable")
	RegisterHam(Ham_Touch, "func_pushable", "bacon_touch_pushable")
	RegisterHam(Ham_Touch, "weaponbox", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "bacon_touch_weapon")
	RegisterHam(get_player_resetmaxspeed_func(), "player", "bacon_changespeed_player", 1);
	
	register_message(get_user_msgid("Health"), "msg_health")
	register_message(get_user_msgid("TextMsg"), "msg_textmsg")
	register_message(get_user_msgid("StatusIcon"), "msg_statusicon")
	register_message(get_user_msgid("ScoreAttrib"), "msg_scoreattrib")
	register_message(get_user_msgid("DeathMsg"), "msg_deathmsg")
	register_message(get_user_msgid("TeamInfo"), "msg_teaminfo")
	register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")
	register_message(get_user_msgid("WeapPickup"), "msg_weaponpickup")
	register_message(get_user_msgid("AmmoPickup"), "msg_ammopickup")
	
	register_event("Damage", "event_damage", "be")
	register_event("TextMsg", "event_textmsg", "a", "2=#Game_will_restart_in")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_event("ArmorType", "event_armortype", "be")
	
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_msg_flashlight = get_user_msgid("Flashlight")
	g_msg_teaminfo = get_user_msgid("TeamInfo")
	g_msg_scoreinfo = get_user_msgid("ScoreInfo")
	g_msg_money = get_user_msgid("Money")
	g_msg_screenfade = get_user_msgid("ScreenFade")
	g_msg_deathmsg = get_user_msgid("DeathMsg")
	g_msg_scoreattrib = get_user_msgid("ScoreAttrib")
	
	g_fwd_infect = CreateMultiForward("event_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwd_gamestart = CreateMultiForward("event_gamestart", ET_IGNORE)

	g_sync_dmgdisplay = CreateHudSyncObj()
	
	g_maxplayers = get_maxplayers()
	
	get_mapname(g_map, 31)
	

	if(equali(g_map, "zm", 2))
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Biohazard")
	}
	else if(equali(g_map, "ze", 2))
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Escape")
	}
	else
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Deathmatch")
	}

	set_cvar_string("sv_skyname", g_skies[random_num(0, charsmax(g_skies))])
	
	set_task(3.0, "task_lights", _, _, _, "b")

	set_task(3.0, "move_bots");

	// SQL init

	g_SQLTuple = SQL_MakeDbTuple( SQL_HOST, SQL_USER, SQL_PASS, SQL_DATABASE );
			    
	new szQuery[ MAX_QUERY_LENGTH ], Handle:SQLConnection, iErrorCode;
	SQLConnection = SQL_Connect( g_SQLTuple, iErrorCode, g_szSQLError, charsmax( g_szSQLError ) );
			    
	if( SQLConnection == Empty_Handle )
		set_fail_state( g_szSQLError );
	
	formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` (\
	`Auth` VARCHAR(%i) NOT NULL,\
	`Nick` VARCHAR(%i) NOT NULL,\
	`IP` VARCHAR(%i) NOT NULL,\
	`Infections` INT(%i) NOT NULL,\
	PRIMARY KEY (Auth));",\
	SQL_TABLE, MAX_AUTHID_LENGTH, MAX_NAME_LENGTH, MAX_IP_LENGTH, MAX_IP_LENGTH );
			
	RunQuery( SQLConnection, szQuery, g_szSQLError, charsmax( g_szSQLError ) );
}

public plugin_end()
{
	if(get_pcvar_num(cvar_enabled))
		set_pcvar_num(cvar_autoteambalance[0], cvar_autoteambalance[1])
}

public plugin_natives()
{
	register_library("biohazardf")
	register_native("infect_user", "native_infect_user", 1)
	register_native("cure_user", "native_cure_user", 1)
	register_native("game_started", "native_game_started", 1)
	register_native("is_user_zombie", "native_is_user_zombie", 1)	
	register_native("add_bonus_money", "native_add_money", 1)
	register_native("get_zombie_regendelay", "native_get_regendelay", 1)
	register_native("set_zombie_regendelay", "native_set_regendelay", 1)
	register_native("respawn_zombie", "native_respawn_zombie", 1)
	register_native("is_user_firstzombie", "native_is_user_firstzombie", 1)
	register_native("get_player_modelent", "native_get_player_modelent", 1)
	register_native("set_user_kbimmunity", "native_set_user_kbimmunity", 1)
}

public client_authorized(id)
{
	g_healthmodifier[id] = (is_vip(id) ? get_pcvar_num(cvar_zombiehp)+get_pcvar_num(cvar_viphp) : get_pcvar_num(cvar_zombiehp));
}

public client_connect(id)
{
	g_showmenu[id] = true
	g_blockmodel[id] = true
	g_zombie[id] = false
	g_waszombie[id] = false
	g_disconnected[id] = false
	g_falling[id] = false
	g_menufailsafe[id] = false
	g_preinfect[id] = false
	g_victim[id] = 0
	g_lives[id] = 0
	g_player_weapons[id][0] = -1
	g_player_weapons[id][1] = -1
	new Float:delay = DATA_REGENDELAY
	g_regendelaymodifier[id] = delay;
	g_moneymodifier[id] = 0;

	if(fm_has_custom_model(id))
		fm_remove_model_ents(id)

	
	ReadData( id, RESET );
		
	get_user_name( id, g_iPlayer[ id ][ NickInfo ], charsmax( g_iPlayer[ ][ NickInfo ] ) )
	get_user_ip( id, g_iPlayer[ id ][ IpInfo ], charsmax( g_iPlayer[ ][ IpInfo ] ), 1 )
	get_user_authid( id, g_iPlayer[ id ][ AuthInfo ], charsmax( g_iPlayer[ ][ AuthInfo ] ) )
		
	ReadData( id, LOAD );
	ReadData( id, UPDATE );
}

public client_disconnected(id)
{
	remove_task(TASKID_STRIPNGIVE + id)
	remove_task(TASKID_UPDATESCR + id)
	remove_task(TASKID_SPAWNDELAY + id)
	remove_task(TASKID_CHECKSPAWN + id)
	remove_task(TASKID_RESPAWN + id)

	g_disconnected[id] = true
	if(fm_has_custom_model(id))
		fm_remove_model_ents(id)

	g_iPlayer[ id ][ Last_Seen ] = get_systime( );
		ReadData( id, SAVE );
}

public cmd_jointeam(id)
{
	if(is_user_alive(id) && g_zombie[id])
	{
		client_print(id, print_center, "Nie jest dozwolona zmiana druzyny.")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
	
public cmd_enablemenu(id)
{	
	if(get_pcvar_num(cvar_weaponsmenu))
	{
		ColorChat(id, GREEN, "[%s]^x01 %s", g_tag, !g_showmenu[id] ?  "Twoj ekwipunek zostal przywrocony." : "Twoje menu ekwipunku jest aktualnie wlaczone.")
		g_showmenu[id] = true
	}
}

public msg_teaminfo(msgid, dest, id)
{
	if(!g_gamestarted)
		return PLUGIN_CONTINUE

	static team[2]
	get_msg_arg_string(2, team, 1)
	
	if(team[0] != 'U')
		return PLUGIN_CONTINUE

	id = get_msg_arg_int(1)
	if(is_user_alive(id) || !g_disconnected[id])
		return PLUGIN_CONTINUE

	g_disconnected[id] = false
	if(id)
	{
		fm_set_user_team(id, _:CS_TEAM_CT, 0)
		set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	}
	return PLUGIN_CONTINUE
}

public msg_scoreattrib(msgid, dest, id)
{
	static attrib 
	attrib = get_msg_arg_int(2)
	
	if(attrib == ATTRIB_BOMB)
		set_msg_arg_int(2, ARG_BYTE, 0)
}

public msg_statusicon(msgid, dest, id)
{
	static icon[3]
	get_msg_arg_string(2, icon, 2)
	
	return (icon[0] == 'c' && icon[1] == '4') ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public msg_weaponpickup(msgid, dest, id)
	return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE

public msg_ammopickup(msgid, dest, id)
	return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE

public msg_deathmsg(msgid, dest, id) 
{
	static killer, victim
	killer = get_msg_arg_int(1)
	victim = get_msg_arg_int(2)

	if(is_user_connected(killer) && g_zombie[killer])
		set_msg_arg_string(4, g_zombie_weapname)

	CheckRespawnAbility(victim)
}

public msg_health(msgid, dest, id)
{	
	static health
	health = get_msg_arg_int(1)
		
	if(health > 255) 
		set_msg_arg_int(1, ARG_BYTE, 255)
	
	return PLUGIN_CONTINUE
}

public msg_textmsg(msgid, dest, id)
{
	if(get_msg_arg_int(1) != 4)
		return PLUGIN_CONTINUE
	
	static txtmsg[25];
	get_msg_arg_string(2, txtmsg, 24)
	
	if(equal(txtmsg[1], "Game_bomb_drop") || equal(txtmsg[1], "Terrorists_Win") || equal(txtmsg[1], "Target_Saved") || equal(txtmsg[1], "CTs_Win"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public zabij(id)
{
	user_kill(id)
	fm_set_user_money(id, -2000);
}

public msg_clcorpse(msgid, dest, id)
{
	id = get_msg_arg_int(12)
	if(!g_zombie[id])
		return PLUGIN_CONTINUE
	
	static ent
	ent = fm_find_ent_by_owner(-1, MODEL_CLASSNAME, id)
	
	if(ent)
	{
		static model[64]
		pev(ent, pev_model, model, 63)
		
		set_msg_arg_string(1, model)
	}
	return PLUGIN_CONTINUE
}

public logevent_round_start()
{
	g_roundended = false
	g_roundstarted = true

	set_task(get_pcvar_float(cvar_starttime), "task_initround", TASKID_INITROUND)
	
	if(get_pcvar_num(cvar_weaponsmenu))
	{
		static id, team
		for(id = 1; id <= g_maxplayers; id++) if(is_user_alive(id))
		{
			team = fm_get_user_team(id)
			if(team == _:CS_TEAM_T || team == _:CS_TEAM_CT)
			{
				if(g_showmenu[id])
				{
					add_delay(id, "display_equipmenu")
						
					g_menufailsafe[id] = true
				}
				else {
					if(sprawdz_bronie(id, (1<<CSW_SG550)|(1<<CSW_M249)|(1<<CSW_G3SG1)) && !g_waszombie[id]) { equipweapon(id, EQUIP_SEC); equipweapon(id, EQUIP_GREN); g_waszombie[id] = false; }
					else equipweapon(id, EQUIP_ALL);
				}
					
				if(is_vip(id))
				{
					fm_give_item(id, "weapon_smokegrenade")
					fm_set_user_money(id, get_pcvar_num(cvar_moneybonus))
					fm_set_user_nvg(id)
				}
				if(isGametype(2))
					fm_set_user_nvg(id)

				if(g_moneymodifier[id]) fm_set_user_money(id, g_moneymodifier[id]);
			}
		}
	}
}

public logevent_round_end()
{
	g_gamestarted = false 
	g_roundstarted = false
	g_roundended = true

	g_zombieswon = false;
	g_humanswon = false;

	for(new i = 1; i <= g_maxplayers; i++) { 
		if(!is_user_alive(i))
			remove_task(TASKID_RESPAWN + i)
	}

	g_Bestdmg = 0, g_Bestdmgid = 0, g_Bestinfect = 0, g_Bestinfectid = 0;
	
	if(get_playersnum() < 2)
		return;

	if(!sprawdz()) {
		for(new i = 1; i <= g_maxplayers; i++)
		{
			if(g_zombie[i]) g_waszombie[i] = true;
			MessageScreenFade(i, FADE_IN_TIME*2, FADE_HOLD_TIME*3, FADE_OUT_TIME, 0, 0, 0, 200);
		}

		
		set_dhudmessage(225, 0, 0, -1.0, 0.3, 2, 0.01, 3.0, 0.05, 0.05)
		show_dhudmessage(0, "Zombie przejelo kontrole nad swiatem.")
		g_zombieswon = true;
	}

	else if(!sprawdz(true)) {
		set_dhudmessage(0, 100, 200, -1.0, 0.3, 2, 0.01, 3.0, 0.05, 0.05)
		show_dhudmessage(0, "Ludzie przezyli apokalipse.")
		g_humanswon = true;
		for(new i = 1; i <= g_maxplayers; i++)
			MessageScreenFade(i, FADE_IN_TIME*2, FADE_HOLD_TIME*3, FADE_OUT_TIME, 0, 0, 0, 200);
	}

	else
	{
		for(new i = 1; i <= g_maxplayers; i++) { 

			if(!is_user_alive(i))
				continue;

			if(g_zombie[i]) {
				add_delay(i, "zabij");
				g_waszombie[i] = true;

				MessageScreenFade(i, FADE_IN_TIME, FADE_HOLD_TIME*3, FADE_OUT_TIME, 0, 0, 0, 200);
			}
		}

		set_dhudmessage(100, 100, 100, -1.0, 0.3, 2, 0.01, 3.0, 0.05, 0.05)
		show_dhudmessage(0, "Zombie zginelo z glodu.")
	}
	
	remove_task(TASKID_BALANCETEAM) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	set_task(0.1, "task_balanceteam", TASKID_BALANCETEAM)

	for(new i=1; i<= g_maxplayers; i++)
	{
		if(is_user_connected(i))
		{
			if(!g_zombie[i] && g_damagecount[i] > g_Bestdmg)
			{
				g_Bestdmg = g_damagecount[i];
				g_Bestdmgid = i;
			}

			if(g_zombie[i] && g_infectcount[i] > g_Bestinfect)
			{
				g_Bestinfect = g_infectcount[i];
				g_Bestinfectid = i;
			}
		}
	}

	reward_distribution()
}

public reward_distribution()
{
	if(get_playersnum() < 4)
		return;

	if(!g_Bestdmgid && !g_Bestinfectid)
		return;


	static name[32];

	if(g_Bestdmg > 0 && !g_zombieswon) {
		g_winnerid = g_Bestdmgid;
		get_user_name(g_winnerid, name, 31);
		ColorChat(0, GREEN, "[Biohazard] ^x01Najwiecej obrazen zadal ^x04%s ^x01(^x04%d^x01 obrazen).", name, g_Bestdmg);
	} else if(g_Bestinfect > 0 && !g_humanswon) {
		g_winnerid = g_Bestinfectid;
		get_user_name(g_winnerid, name, 31);
		ColorChat(0, GREEN, "[Biohazard] ^x01Najwiecej graczy zarazil ^x04%s ^x01(^x04%d^x01 %s).", name, g_Bestinfect, g_Bestinfect == 1 ? "czlowiek" : "ludzi");
	} else
		return;
}

public event_textmsg()
{
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true
	g_rounds_elapsed = 0
	
	static seconds[5] 
	read_data(3, seconds, 4)
	
	static Float:tasktime 
	tasktime = float(str_to_num(seconds)) - 0.5
	
	remove_task(TASKID_BALANCETEAM)
	
	set_task(tasktime, "task_balanceteam", TASKID_BALANCETEAM)
}

public event_newround()
{
	g_gamestarted = false
	
	
			
	static id
	for(id = 0; id <= g_maxplayers; id++)
	{
		if(is_user_connected(id))
			g_blockmodel[id] = true
					
		g_zombie[id] = false;
		g_damagecount[id] = 0;
		g_infectcount[id] = 0;
		g_lives[id] = 0;
	}
	
	remove_task(TASKID_NEWROUND)
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	set_task(0.1, "task_newround", TASKID_NEWROUND)
	set_task(0.5, "show_announcement", TASKID_ANNOUNCEMENT)
	set_task(1.0, "show_dhud_info", _, _, _, "a", floatround(ANNOUNCEMENT_DURATION))

}
public task_newround()
{
	static players[32], num, id
	get_players(players, num, "a")

	if(num > 1)
	{
		for(new i = 0; i < num; i++)
		{
			g_preinfect[players[i]] = false
		}
		
		new zombies;

		if(get_pcvar_num(cvar_multiinfection) == 1)
		{
			switch(get_pcvar_num(cvar_gametype))
			{
				case 1 : zombies = clamp(floatround(num * 0.25), 1, 31)
				case 2 : zombies = clamp(floatround(num * 0.25), 1, 31)
				case 3 : zombies = clamp(floatround(num * 0.50), 1, 31)
			}
		} else
			zombies = 1;
			
		g_newzombies = zombies;
		
		new i = 0
		while(i < zombies)
		{
			id = players[_random(num)]
			if(!g_preinfect[id])
			{
				g_preinfect[id] = true
				g_lives[id] = get_pcvar_num(cvar_spawnlimit)
				i++
			}
		}
	}
}
public show_announcement()
{
	g_rounds_elapsed++;

	ColorChat(0, GREEN, "[ZM]^x01 Wylosowano ^x04%i^x01 zombie.", g_newzombies);

	new rndctstr[21]
	num_to_word(g_rounds_elapsed, rndctstr, 20);
	client_cmd(0, "spk ^"vox/round %s^"",rndctstr)

	return PLUGIN_CONTINUE;
}
public show_dhud_info()
{
	new p_playernum = get_playersnum(1);
	new tl = get_timeleft(),
        m = tl / 60,
        s = tl % 60
	new szIP[ 64 ];
	get_user_ip( !is_dedicated_server( ), szIP, 63 );

	if( tl > 0)
	{
		set_dhudmessage(random_num(160, 255), random_num(0, 50), random_num(0, 50), -1.0, 0.08, 0, 1.0, 1.0)
		show_dhudmessage(0, "-%s-^n%s^n%s (%i/%i)^n[%d:%02d]", g_tag, szIP, g_map, p_playernum, g_maxplayers, m, s)
	}
}
public event_curweapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	static weapon
	weapon = read_data(2)
	
	weapons[id] = weapon;
	
	if(g_zombie[id])
	{
		if(weapon == CSW_KNIFE) set_pev(id, pev_viewmodel2, DEFAULT_WMODEL)
		
		else if(weapon == CSW_SMOKEGRENADE) set_pev(id, pev_weaponmodel2, DEFAULT_WMODEL);
			
		if(weapon != CSW_KNIFE  && weapon != CSW_SMOKEGRENADE && !task_exists(TASKID_STRIPNGIVE + id))
			set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + id)
								
		return PLUGIN_CONTINUE
	} else
	{
		if(fm_has_custom_model(id))
		{
			//workaround with entities
			fm_update_weapon_ent(id)
			fm_set_weaponmodel_ent(id)
		}
	}
	


	if((AMMOWP_NULL & (1<<weapon)))
		return PLUGIN_CONTINUE
	
	static ammo, maxammo
	ammo = fm_get_user_bpammo(id, weapon)
	maxammo = g_weapon_ammo[weapon]
	
	if(ammo < maxammo) 
		fm_set_user_bpammo(id, weapon, maxammo)

	return PLUGIN_CONTINUE
}

public event_armortype(id)
{
	if(!is_user_alive(id) || !g_zombie[id])
		return PLUGIN_CONTINUE
	
	if(fm_get_user_armortype(id) != 0)
		fm_set_user_armortype(id, 0)
	
	return PLUGIN_CONTINUE
}

public fwd_player_prethink(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	static flags
	flags = pev(id, pev_flags)
	
	if(flags & FL_ONGROUND)
	{
		pev(id, pev_velocity, g_vecvel)
		g_brestorevel = true
	}
	else
	{
		if(g_zombie[id])
		{
			static Float:fallvelocity
			pev(id, pev_flFallVelocity, fallvelocity)
			
			g_falling[id] = fallvelocity >= 350.0 ? true : false
		}
	}

	if(g_gamestarted && g_zombie[id])
	{	
		static Float:gametime
		gametime = get_gametime()

		static Float:health
		pev(id, pev_health, health)
		
		if(health < g_healthmodifier[id] && g_regendelay[id] < gametime) {
			set_pev(id, pev_health, health + DATA_HPREGEN)
			g_regendelay[id] = (gametime + g_regendelaymodifier[id])
		}
	}
	
	return FMRES_IGNORED
}

public fwd_player_prethink_post(id)
{
	if(!g_brestorevel)
		return FMRES_IGNORED

	g_brestorevel = false
		
	static flag
	flag = pev(id, pev_flags)
	
	if(!(flag & FL_ONTRAIN))
	{
		static ent
		ent = pev(id, pev_groundentity)
		
		if(pev_valid(ent) && (flag & FL_CONVEYOR))
		{
			static Float:vectemp[3]
			pev(id, pev_basevelocity, vectemp)
			
			xs_vec_add(g_vecvel, vectemp, g_vecvel)
		}

		set_pev(id, pev_velocity, g_vecvel)
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fwd_player_postthink(id)
{ 
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if(g_zombie[id] && g_falling[id] && (pev(id, pev_flags) & FL_ONGROUND))
	{	
		set_pev(id, pev_watertype, CONTENTS_WATER)
		g_falling[id] = false
	}
	
	return FMRES_IGNORED
}

public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{	
	if(channel == CHAN_ITEM && sample[6] == 'n' && sample[7] == 'v' && sample[8] == 'g')
		return FMRES_SUPERCEDE	
	
	if(!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED	

	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
			return FMRES_SUPERCEDE
		}
		else if(sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't' || sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
		{
			if(sample[17] == 'w' && sample[18] == 'a' && sample[19] == 'l')
				emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
			else
				emit_sound(id, channel, g_zombie_hit_sounds[_random(sizeof g_zombie_hit_sounds)], volume, attn, flag, pitch)
			
			return FMRES_SUPERCEDE
		}
	}			
	else if(sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
	{
		emit_sound(id, channel, g_zombie_die_sounds[_random(sizeof g_zombie_die_sounds)], volume, attn, flag, pitch)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_cmdstart(id, handle, seed)
{
	if(!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	
	static impulse
	impulse = get_uc(handle, UC_Impulse)
	
	if(impulse == IMPULSE_FLASHLIGHT)
	{
		set_uc(handle, UC_Impulse, 0)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_spawn(ent)
{
	if(!pev_valid(ent)) 
		return FMRES_IGNORED
	
	static classname[32]
	pev(ent, pev_classname, classname, 31)

	static i
	for(i = 0; i < sizeof g_remove_entities; ++i)
	{
		if(equal(classname, g_remove_entities[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fwd_createnamedentity(entclassname)
{
	static classname[10]
	engfunc(EngFunc_SzFromIndex, entclassname, classname, 9)
	
	return (classname[7] == 'c' && classname[8] == '4') ? FMRES_SUPERCEDE : FMRES_IGNORED
}

public fwd_clientkill(id)
{
	if(is_user_alive(id))
		g_suicide[id] = true
}

public fwd_setclientkeyvalue(id, infobuffer, const key[])
{
	if(!equal(key, "model") || !g_blockmodel[id])
		return FMRES_IGNORED
	
	static model[32]
	fm_get_user_model(id, model)
	
	if(equal(model, "gordon"))
		return FMRES_IGNORED
	
	g_blockmodel[id] = false
	
	return FMRES_SUPERCEDE
}

public bacon_changespeed_player(id)
{
	if(is_user_alive(id) && g_zombie[id])
	{
		switch(get_pcvar_num(cvar_gametype))
		{
			case 1: fm_set_user_maxspeed(id, g_zmspeed_array[0])
			case 2: fm_set_user_maxspeed(id, g_zmspeed_array[1])
			case 3: fm_set_user_maxspeed(id, g_zmspeed_array[2])
		}
	}
}

public bacon_touch_weapon(ent, id)
	return (is_user_alive(id) && g_zombie[id]) ? HAM_SUPERCEDE : HAM_IGNORED

public bacon_use_tank(ent, caller, activator, use_type, Float:value)
	return (is_user_alive(caller) && g_zombie[caller]) ? HAM_SUPERCEDE : HAM_IGNORED

public bacon_use_pushable(ent, caller, activator, use_type, Float:value)
	return HAM_SUPERCEDE


public bacon_traceattack_player(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
	if(!g_gamestarted) 
		return HAM_SUPERCEDE
	
	if(!get_pcvar_num(cvar_knockback) || !(damagetype & DMG_BULLET))
		return HAM_IGNORED
	
	if(!is_user_connected(attacker) || !g_zombie[victim])
		return HAM_IGNORED

	if(g_kbReduction[victim] == 1.0)
		return HAM_IGNORED
	
	static kbpower
	kbpower = g_weapon_knockback[get_user_weapon(attacker)]
	
	if(kbpower != -1) 
	{
		static flags
		flags = pev(victim, pev_flags)
		
		if(get_pcvar_num(cvar_knockback_duck) && (isDucking(victim) && (flags & FL_ONGROUND)))
			return HAM_IGNORED
		
		static Float:origins[2][3]
		pev(victim, pev_origin, origins[0])
		pev(attacker, pev_origin, origins[1])
		
		if(get_distance_f(origins[0], origins[1]) <= get_pcvar_float(cvar_knockback_dist))
		{
			static Float:velocity[3]
			pev(victim, pev_velocity, velocity)
			
			static Float:tempvec
			tempvec = velocity[2]
			
			xs_vec_mul_scalar(direction, damage, direction)

			if(g_kbReduction[victim] == 0.0)
				xs_vec_mul_scalar(direction, g_knockbackpower[kbpower], direction)
			else
				xs_vec_mul_scalar(direction, g_kbReduction[victim]*g_knockbackpower[kbpower], direction)
			
			xs_vec_add(direction, velocity, velocity)
			velocity[2] = tempvec
			
			set_pev(victim, pev_velocity, velocity)
			
			return HAM_HANDLED
		}
	}

	return HAM_IGNORED
}

public bacon_takedamage_player(victim, inflictor, attacker, Float:damage, damagetype)
{
	if(damagetype & DMG_GENERIC || victim == attacker || !is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(!g_gamestarted || (!g_zombie[victim] && !g_zombie[attacker]) || ((damagetype & DMG_HEGRENADE) && g_zombie[attacker]))
		return HAM_SUPERCEDE

	if(g_zombie[attacker])
	{
		if(get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_SUPERCEDE

		static Float:armor
		pev(victim, pev_armorvalue, armor)

		if(armor > 0.0)
		{
			armor -= 100
			
			if(armor < 0.0) 
				armor = 0.0
			
			set_pev(victim, pev_armorvalue, armor)
			SetHamParamFloat(4, 0.0)
		}
		else
		{
			switch(get_pcvar_num(cvar_gametype))	
				{
					case 1,2:
					{
						static bool:infect
						infect = allow_infection()
			
						g_victim[attacker] = infect ? victim : 0
			
						if(infect && !g_zombie[victim])
							SetHamParamFloat(4, 0.0);
					}
				}
			}
		}
	
	else
	{
		if((damagetype & DMG_HEGRENADE))
		{
			damage *= isGametype(1) ? 8.0 : 3.0
			SetHamParamFloat(4, damage)
		}

		if(get_user_weapon(attacker) == CSW_KNIFE && pev(attacker,pev_button) & IN_ATTACK2)
		{
			damage = isGametype(1) ? 400.0 : 333.0;
			SetHamParamFloat(4, damage);
		}
	}

	if(is_user_connected(attacker) && !g_zombie[attacker] && g_zombie[victim]) 
	{
		g_damagecount[attacker] += floatround(damage)
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		if(is_vip(attacker) || isGametype(2))
		{
			ShowSyncHudMsg(attacker, g_sync_dmgdisplay, "[-%i HP]^n%d", floatround(damage), pev(victim, pev_health))
		} else
			ShowSyncHudMsg(attacker, g_sync_dmgdisplay, "[-%i HP]", floatround(damage), pev(victim, pev_health))
			
	}

	return HAM_HANDLED

}

public bacon_killed_player(victim, killer, shouldgib)
{	
	if(!is_user_alive(killer) || g_zombie[killer] || !g_zombie[victim])
		return HAM_IGNORED
	
	static killbonus
	switch(get_pcvar_num(cvar_gametype))
	{
		case 1: killbonus = 2;
		case 2: killbonus = 1;
		case 3: killbonus = 0;
	}
	
	if(killbonus)
	{
		set_pev(killer, pev_frags, pev(killer, pev_frags) + float(killbonus))
	}
	
	if(isGametype(1))
	{
		if(!user_has_weapon(killer, CSW_SMOKEGRENADE))
			fm_give_item(killer, "weapon_smokegrenade")
	} else if(isGametype(2)) {
		if(!user_has_weapon(killer, CSW_HEGRENADE))
			fm_give_item(killer, "weapon_hegrenade")
	}
	fm_set_user_money(killer, 300);
	

	// CheckRespawnAbility(victim)

	return HAM_IGNORED
}

public resp_countdown(id)
{
	g_respcount[id]-= 0.1;
	if(g_respcount[id] >= 0 && g_gamestarted)
	{
		if(isGametype(13))
    		client_print(id, print_center, "Respawn [%i/%i].^n Zostaniesz odrodzony za %.1f.", g_lives[id], get_pcvar_num(cvar_spawnlimit), g_respcount[id])
		else
    		client_print(id, print_center, "Respawn: %.1f", g_respcount[id])
	}
}

public respawn_player(taskid)
{
	static id
	id = taskid - TASKID_RESPAWN


	ExecuteHamB(Ham_CS_RoundRespawn, id)
	infect_user(id, -1)
	set_zombie_attibutes(id)

	set_task(0.3, "change_usermodel", id)

	g_lives[id]--

			
}

public change_usermodel(id)
{
	fm_remove_model_ents(id)
	fm_set_playermodel_ent(id, "slum")
}

public bacon_spawn_player_post(id)
{	
	if(!is_user_alive(id))
		return HAM_IGNORED

	static team
	team = fm_get_user_team(id)
	
	if(team != _:CS_TEAM_T && team != _:CS_TEAM_CT)
		return HAM_IGNORED
	
	g_healthmodifier[id] = (is_vip(id) ? get_pcvar_num(cvar_zombiehp)+get_pcvar_num(cvar_viphp) : get_pcvar_num(cvar_zombiehp));

	fm_set_user_nvg(id, 0)

	
	if(pev(id, pev_rendermode) == kRenderTransTexture)
		reset_user_model(id)
	
	set_task(0.3, "task_spawned", TASKID_SPAWNDELAY + id)
	set_task(1.0, "task_checkspawn", TASKID_CHECKSPAWN + id)
	

	return HAM_IGNORED
}

public bacon_touch_pushable(ent, id)
{
	static movetype
	pev(id, pev_movetype)
	
	if(movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_NONE)
		return HAM_IGNORED	
	
	if(is_user_alive(id))
	{
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		
		if(!(pev(id, pev_flags) & FL_ONGROUND))
			return HAM_SUPERCEDE
	}
	
	
	return HAM_SUPERCEDE
}

public task_spawned(taskid)
{
	static id
	id = taskid - TASKID_SPAWNDELAY
	
	// = 0;

	if(is_user_alive(id))
	{		
		if(g_suicide[id])
		{
			g_suicide[id] = false
			
			user_silentkill(id)
			remove_task(TASKID_CHECKSPAWN + id)

			ColorChat(id, GREEN, "[System]^x01 Zostales ukarany za popelnienie samobojstwa (komenda: ^x03kill^x01).")
			
			return
		}
		
		if(fm_has_custom_model(id))
			fm_remove_model_ents(id)

		if(sprawdz_bronie(id, (1<<CSW_SMOKEGRENADE)))
		{
			fm_strip_user_weapons(id)
			fm_reset_user_primary(id)
			fm_give_item(id, "weapon_knife")
			fm_give_item(id, "weapon_smokegrenade")
		} else
		{
			fm_strip_user_weapons(id)
			fm_reset_user_primary(id)
			fm_give_item(id, "weapon_knife")
		}

		if(!g_zombie[id])
		{
			if(is_vip(id))
				fm_set_playermodel_ent(id, g_human_vip_models[random_num(0, charsmax(g_human_vip_models))])
		}

		if(get_pcvar_num(cvar_weaponsmenu) && g_roundstarted && g_showmenu[id] && !g_zombie[id])
			display_equipmenu(id)

		if(is_user_bot(id))
			equip_randomweapon(id)

		if(g_gamestarted)
		{			
			static team
			team = fm_get_user_team(id)
			
			if(team == _:CS_TEAM_T && !g_zombie[id])
				fm_set_user_team(id, _:CS_TEAM_CT)
		} else 
		{
			if(is_vip(id))
			{
				ColorChat(id, GREEN, "[VIP]^x01 Jestes %s.", g_preinfect[id] ? "zainfekowany" : "zdrowy")
				if(get_timeleft() > 0)
					MessageScreenFade(id, FADE_IN_TIME, FADE_HOLD_TIME, FADE_OUT_TIME, g_preinfect[id] ? 200 : 0, 0, g_preinfect[id] ? 0 : 200, FADE_ALPHA);
			}
		}
	}
}

public task_checkspawn(taskid)
{
	static id
	id = taskid - TASKID_CHECKSPAWN
	
	if(!is_user_connected(id) || is_user_alive(id) || g_roundended)
		return
	
	static team
	team = fm_get_user_team(id)
	
	if(team == _:CS_TEAM_T || team == _:CS_TEAM_CT)
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}
public task_lights()
{
	new szHours[2]
	new iHours
	new szLights[2] = "d"

	get_time("%H", szHours, 2)
	iHours = str_to_num(szHours)

	switch(iHours)
	{
		case 0..8: szLights = "e"
		case 9..11: szLights = "f"
		case 12..15: szLights = "f"
		case 16..18: szLights = "f"
		case 19..21: szLights = "e"
		case 22..23: szLights = "d"
		default: szLights = "d"
	}

	set_lights(szLights)
}

public move_bots()
{
	static szCmd[32];
	formatex(szCmd, charsmax(szCmd), "amx_cvar yb_quota %i", (equali(g_map, "zm", 2) || equali(g_map, "ze", 2) ? 0 : MAX_BOTS))
	server_cmd(szCmd)
}

public event_damage(victim)
{
	if(!is_user_alive(victim) || !g_gamestarted)
		return PLUGIN_CONTINUE
	
	if(g_zombie[victim])
	{
		static Float:gametime
		gametime = get_gametime()
		g_regendelay[victim] = (gametime + DATA_HITREGENDELAY)
	}
	else
	{
		static attacker
		attacker = get_user_attacker(victim)
		
		if(!is_user_alive(attacker) || !g_zombie[attacker])
			return PLUGIN_CONTINUE
	
		if(g_zombie[attacker] && get_user_weapon(attacker) != CSW_KNIFE)
			return PLUGIN_CONTINUE
		
		if(g_victim[attacker] == victim)
		{
			g_victim[attacker] = 0
			
			message_begin(MSG_ALL, g_msg_deathmsg)
			write_byte(attacker)
			write_byte(victim)
			write_byte(0)
			write_string(g_infection_name)
			message_end()
			
			message_begin(MSG_ALL, g_msg_scoreattrib)
			write_byte(victim)
			write_byte(0)
			message_end()
			
			infect_user(victim, attacker)
			
			static Float:frags, deaths
			pev(attacker, pev_frags, frags)
			deaths = fm_get_user_deaths(victim)
			set_pev(attacker, pev_frags, frags  + 1.0)

			fm_set_user_deaths(victim, deaths + 1)
			fm_set_user_money(attacker, 300 + is_vip(attacker) ? 200 : 0)
			g_lives[victim] = get_pcvar_num(cvar_spawnlimit)

			static params[2]
			params[0] = attacker
			params[1] = victim
			set_task(0.3, "task_updatescore", TASKID_UPDATESCR, params, 2)
		}
	}

	return PLUGIN_CONTINUE
}

public task_updatescore(params[])
{
	if(!g_gamestarted) 
		return
	
	static attacker
	attacker = params[0]
	
	static victim
	victim = params[1]
	
	if(!is_user_connected(attacker))
		return

	static frags, deaths, team
	frags  = get_user_frags(attacker)
	deaths = fm_get_user_deaths(attacker)
	team   = get_user_team(attacker)
	
	message_begin(MSG_BROADCAST, g_msg_scoreinfo)
	write_byte(attacker)
	write_short(frags)
	write_short(deaths)
	write_short(0)
	write_short(team)
	message_end()
	
	if(!is_user_connected(victim))
		return
	
	frags  = get_user_frags(victim)
	deaths = fm_get_user_deaths(victim)
	team   = get_user_team(victim)
	
	message_begin(MSG_BROADCAST, g_msg_scoreinfo)
	write_byte(victim)
	write_short(frags)
	write_short(deaths)
	write_short(0)
	write_short(team)
	message_end()
}

public task_stripngive(taskid)
{
	static id
	id = taskid - TASKID_STRIPNGIVE
	
	if(is_user_alive(id))
	{
		fm_strip_user_weapons(id)
		fm_reset_user_primary(id)
		fm_give_item(id, "weapon_knife")

		set_pev(id, pev_viewmodel2, DEFAULT_WMODEL)
	}
}

public task_initround()
{
	static zombiecount, newzombie
	zombiecount = 0
	newzombie = 0

	static players[32], num, id
	get_players(players, num, "a")
		
	for(new i = 0; i < num; i++) if(g_preinfect[players[i]])
		{
			newzombie = players[i]
			zombiecount++
		}

	if(zombiecount > 1) 
		newzombie = 0
	else if(zombiecount < 1) 
		newzombie = players[_random(num)]
		
	for(new i = 0; i < num; i++)
	{
		id = players[i]
		if(id == newzombie || g_preinfect[id])
		{
			infect_user(id, 0)
			multiply_hp(id, get_pcvar_float(cvar_zombiehpmultiplied))
			
			new name[33];
			get_user_name(id, name, charsmax(name))

			set_dhudmessage(250, 50, 0, -1.0, 0.16, 1, 0.01, 6.0, 1.0, 1.0)
			
			if(newzombie)
			{
				show_dhudmessage(0, fmt("%s jest pierwszym zombie!", name))
			}
			else
				show_dhudmessage(0, "Wielokrotna infekcja!")
		}
		else
		{
			fm_set_user_team(id, _:CS_TEAM_CT, 0)
			add_delay(id, "update_team")
		}
	}
			
	set_task(0.51, "task_startround", TASKID_STARTROUND)
}

public task_startround()
{
	g_gamestarted = true

	ExecuteForward(g_fwd_gamestart, g_fwd_result)
}


public task_balanceteam()
{
	static players[3][32], count[3]
	get_players(players[_:CS_TEAM_UNASSIGNED], count[_:CS_TEAM_UNASSIGNED])
	
	count[_:CS_TEAM_T] = 0
	count[_:CS_TEAM_CT] = 0
	
	static i, id, team
	for(i = 0; i < count[_:CS_TEAM_UNASSIGNED]; i++)
	{
		id = players[_:CS_TEAM_UNASSIGNED][i] 
		team = fm_get_user_team(id)
		
		if(team == _:CS_TEAM_T || team == _:CS_TEAM_CT)
			players[team][count[team]++] = id
	}

	if(abs(count[_:CS_TEAM_T] - count[_:CS_TEAM_CT]) <= 1) 
		return

	static maxplayers
	maxplayers = (count[_:CS_TEAM_T] + count[_:CS_TEAM_CT]) / 2
	
	if(count[_:CS_TEAM_T] > maxplayers)
	{
		for(i = 0; i < (count[_:CS_TEAM_T] - maxplayers); i++)
			fm_set_user_team(players[_:CS_TEAM_T][i], _:CS_TEAM_CT, 0)
	}
	else
	{
		for(i = 0; i < (count[_:CS_TEAM_CT] - maxplayers); i++)
			fm_set_user_team(players[_:CS_TEAM_CT][i], _:CS_TEAM_T, 0)
	}
}

public update_team(id)
{
	if(!is_user_connected(id))
		return
	
	static team
	team = fm_get_user_team(id)
	
	if(team == _:CS_TEAM_T || team == _:CS_TEAM_CT)
	{
		emessage_begin(MSG_ALL, g_msg_teaminfo)
		ewrite_byte(id)
		ewrite_string(g_teaminfo[team])
		emessage_end()
	}
}

public infect_user(victim, attacker)
{
	if(!is_user_alive(victim))
		return

	new Float:Random_Float[2]
	for(new i = 0; i < 2; i++) Random_Float[i] = random_float(-100.0, 100.0)
	set_pev(victim, pev_punchangle, Random_Float);
	
	message_begin(MSG_ONE, g_msg_screenfade, _, victim)
	write_short(1<<12) // duration
	write_short(1<<12) // hold time    
	
	write_short(0x0000)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(150)
	message_end()

	new origin[3]
	get_user_origin(victim, origin)

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_IMPLOSION) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(128) // radius
	write_byte(20) // count
	write_byte(3) // duration
	message_end()

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_PARTICLEBURST) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(0) // r
	write_byte(150) // g
	write_byte(0) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
	
	fm_set_user_team(victim, _:CS_TEAM_T)
	set_zombie_attibutes(victim)

	if(attacker != 0 && is_user_alive(attacker)) {
		new Float:health, extrahp
		extrahp = get_pcvar_num(cvar_infecthp)
		pev(attacker, pev_health, health)

		if(health < (g_healthmodifier[attacker] - extrahp)) {
			set_pev(attacker, pev_health, health+float(extrahp))
			set_hudmessage(107, 142, 35, 0.03, 0.88, 0, 0.0, 2.5, 0.1, 0.4, -1)
			show_hudmessage(attacker, "(+%i HP)", extrahp)
		}

		g_infectcount[attacker]++
	}

	if(attacker != -1) emit_sound(victim, CHAN_STATIC, g_scream_sounds[_random(sizeof g_scream_sounds)], VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
	ExecuteForward(g_fwd_infect, g_fwd_result, victim, attacker)
}

public cure_user(id)
{
	if(!is_user_alive(id)) 
		return

	g_zombie[id] = false
	g_falling[id] = false

	if(fm_has_custom_model(id))
		fm_remove_model_ents(id)

	if(is_vip(id))
	{
		fm_set_playermodel_ent(id, g_human_vip_models[random_num(0, charsmax(g_human_vip_models))])
		fm_give_item(id, "weapon_smokegrenade")
		fm_set_user_nvg(id, 1)
	}
	set_pev(id, pev_gravity, 1.0)
	
	display_equipmenu(id)

	static viewmodel[64]
	pev(id, pev_viewmodel2, viewmodel, 63)
	
	if(equal(viewmodel, DEFAULT_WMODEL))
	{
		static weapon 
		weapon = fm_lastknife(id)

		if(pev_valid(weapon))
			ExecuteHam(Ham_Item_Deploy, weapon)
	}
}

public display_equipmenu(id)
{
	new menu = menu_create("\yEkwipunek", "action_equip")

	new bool:hasweap = g_player_weapons[id][0] != -1 && g_player_weapons[id][1] != -1
	
	menu_additem(menu, "Nowa bron")
	menu_additem(menu, "Poprzedni krok", "", !hasweap ? ADMIN_IMMUNITY : 0)
	menu_additem(menu, "Nie pokazuj menu ponownie^n^n", "", !hasweap ? ADMIN_IMMUNITY : 0)

	id == g_winnerid ? menu_additem(menu, "Przyjmij \ynagrode") : PLUGIN_CONTINUE
	
	menu_display(id, menu, 0)
}

public action_equip(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	switch(item)
	{
		case 0: display_weaponmenu(id, MENU_PRIMARY)
		case 1: equipweapon(id, EQUIP_ALL)
		case 2:
		{
			g_showmenu[id] = false
			equipweapon(id, EQUIP_ALL);
			ColorChat(id, GREEN, "[%s]^x01 Wpisz ^x04/guns^x01 na chacie zeby przywrocic twoj ekwipunek.", g_tag)
		}
		case 3: equip_mvpweapon(id)
	}
	
	if(item > 0)
	{
		g_menufailsafe[id] = false
	}
	return PLUGIN_HANDLED
}


public display_weaponmenu(id, menuid)
{
	static maxitem

	if(isGametype(1))
		maxitem = menuid == MENU_PRIMARY ? sizeof(g_primaryweaponsZM) : sizeof(g_secondaryweapons)
	if(isGametype(2))
		maxitem = menuid == MENU_PRIMARY ? sizeof(g_primaryweaponsDM) : sizeof(g_secondaryweapons)
	
	new temp[512]
	formatex(temp, 511, "\y%s", menuid == MENU_PRIMARY ? "Ciezkie bronie" : "Bron krotka")	
	new menu = menu_create(temp, menuid == MENU_PRIMARY ? "action_prim" : "action_sec")
	
  	for(new i = 0; i < maxitem; i++) 
	{
		if(isGametype(1))
			formatex(temp, 511, "%s", menuid == MENU_PRIMARY ? g_primaryweaponsZM[i][0]: g_secondaryweapons[i][0])
		if(isGametype(2))
			formatex(temp, 511, "%s", menuid == MENU_PRIMARY ? g_primaryweaponsDM[i][0]: g_secondaryweapons[i][0])
		menu_additem(menu, temp)
  	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public action_prim(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED

	g_player_weapons[id][0] = item
	equipweapon(id, EQUIP_PRI)
	
	display_weaponmenu(id, MENU_SECONDARY)
		
	return PLUGIN_HANDLED
}

public action_sec(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	g_menufailsafe[id] = false

	g_player_weapons[id][1] = item
	equipweapon(id, EQUIP_SEC)
	equipweapon(id, EQUIP_GREN)

	return PLUGIN_HANDLED
}

public equip_randomweapon(id)
{
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED

	if(id == g_winnerid)
	{
		equip_mvpweapon(id)
	}
	else {
		g_player_weapons[id][0] = random(sizeof(g_primaryweaponsDM))
		equipweapon(id, EQUIP_PRI)

		g_player_weapons[id][1] = random(sizeof(g_secondaryweapons))
		equipweapon(id, EQUIP_SEC)
		equipweapon(id, EQUIP_GREN)
	}

	return PLUGIN_HANDLED
}

public native_is_user_zombie(index)
	return g_zombie[index] == true ? 1 : 0

public native_game_started()
	return g_gamestarted

public native_infect_user(victim, attacker)
{
	if(g_gamestarted)
		infect_user(victim, attacker)
}

public native_cure_user(index)
	cure_user(index)
	
public native_add_money(index, money)
	g_moneymodifier[index] = money;
	
public Float:native_get_regendelay(index)
	return g_regendelaymodifier[index];
	
public native_set_regendelay(index, Float:delay) {
	new Float:something = DATA_REGENDELAY
	g_regendelaymodifier[index] = (delay>0.0001 || delay<5.0) ? delay : something
}
public native_is_user_firstzombie(index)
	return g_preinfect[index] == true ? 1 : 0

public native_get_player_modelent(index)
{
	return g_modelent[index];
}

public native_respawn_zombie(index)
{

	if(!is_user_connected(index) || is_user_alive(index) || is_user_hltv(index))
		return HAM_IGNORED

	ExecuteHamB(Ham_CS_RoundRespawn, index)
	infect_user(index, -1)
	set_zombie_attibutes(index)

	set_task(0.3, "change_usermodel", index)
	g_lives[index] = 1

	return HAM_IGNORED

}

public native_set_user_kbimmunity(id, Float:fReduction, bool:bUserCrouched)
{

	if(bUserCrouched == true)
	{
		if(isDucking(id))
			g_kbReduction[id] = fReduction;
	} else
		g_kbReduction[id] = fReduction;
}

MessageScreenFade(const id, const Float:fInTime, const Float:fHoldTime, const Float:fOutTime, const iRed, const iGreen, const iBlue, const iAlpha)
{
    message_begin(MSG_ONE, MESSAGE_SCREEN_FADE, _, id);
    write_short(min(floatround(fInTime * 4096), 65535));
    write_short(65535);
    write_short(FFADE_OUT);
    write_byte(iRed);
    write_byte(iGreen);
    write_byte(iBlue);
    write_byte(iAlpha);
    message_end();
    new aData[DATA_SCREENFADE_SIZE];
    aData[DSS_OutTime] = _:fOutTime;
    aData[DSS_Red] = iRed;
    aData[DSS_Green] = iGreen;
    aData[DSS_Blue] = iBlue;
    aData[DSS_Alpha] = iAlpha;
    set_task(fInTime + fHoldTime, "MessageScreenFadeOut", id, aData, sizeof aData);
}

public MessageScreenFadeOut(const aData[DATA_SCREENFADE_SIZE], const id)
{
    message_begin(MSG_ONE, MESSAGE_SCREEN_FADE, _, id);
    write_short(min(floatround(aData[DSS_OutTime] * 4096), 65535));
    write_short(0);
    write_short(FFADE_IN);
    write_byte(aData[DSS_Red]);
    write_byte(aData[DSS_Green]);
    write_byte(aData[DSS_Blue]);
    write_byte(aData[DSS_Alpha]);
    message_end();
}

Ham:get_player_resetmaxspeed_func(){
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}

stock fm_set_user_team(index, team, update = 1)
{
	set_pdata_int(index, 114, team)
	if(update)
	{
		emessage_begin(MSG_ALL, g_msg_teaminfo)
		ewrite_byte(index)
		ewrite_string(g_teaminfo[team])
		emessage_end()
	}
	return 1
}

stock fm_get_user_bpammo(index, weapon)
{
	static offset
	switch(weapon)
	{
		case CSW_AWP: offset = 377
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: offset = 378
		case CSW_M249: offset = 379
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: offset = 380
		case CSW_M3, CSW_XM1014: offset = 381
		case CSW_USP, CSW_UMP45, CSW_MAC10: offset = 382
		case CSW_FIVESEVEN, CSW_P90: offset = 383
		case CSW_DEAGLE: offset = 384
		case CSW_P228: offset = 385
		case CSW_GLOCK18, CSW_TMP, CSW_ELITE, CSW_MP5NAVY: offset = 386
		default: offset = 0
	}
	return offset ? get_pdata_int(index, offset) : 0
}

stock fm_set_user_bpammo(index, weapon, amount)
{
	static offset
	switch(weapon)
	{
		case CSW_AWP: offset = 377
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: offset = 378
		case CSW_M249: offset = 379
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: offset = 380
		case CSW_M3, CSW_XM1014: offset = 381
		case CSW_USP, CSW_UMP45, CSW_MAC10: offset = 382
		case CSW_FIVESEVEN, CSW_P90: offset = 383
		case CSW_DEAGLE: offset = 384
		case CSW_P228: offset = 385
		case CSW_GLOCK18, CSW_TMP, CSW_ELITE, CSW_MP5NAVY: offset = 386
		default: offset = 0
	}
	
	if(offset) 
		set_pdata_int(index, offset, amount)
	
	return 1
}

stock fm_set_user_nvg(index, onoff = 1)
{
	static nvg
	nvg = get_pdata_int(index, 129)
	
	set_pdata_int(index, 129, onoff == 1 ? nvg | HAS_NVG : nvg & ~HAS_NVG)
	return 1
}

stock reset_user_model(index)
{
	set_pev(index, pev_rendermode, kRenderNormal)
	set_pev(index, pev_renderamt, 0.0)

	if(fm_has_custom_model(index))
		fm_set_entity_visibility(g_modelent[index], 0)
}

/*stock remove_user_model(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(pev_valid(ent)) 
		engfunc(EngFunc_RemoveEntity, ent)

	g_modelent[id] = 0
}*/

stock set_zombie_attibutes(index)
{
	if(!is_user_alive(index)) 
		return

	g_zombie[index] = true

	if(!task_exists(TASKID_STRIPNGIVE + index))
		set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + index)
	
	set_pev(index, pev_health, float(g_healthmodifier[index]))
	set_pev(index, pev_armorvalue, 0.0)
	
	fm_set_user_armortype(index, 0)
	fm_set_user_nvg(index)

	if(fm_has_custom_model(index))
		fm_remove_model_ents(index)
	
	fm_set_playermodel_ent(index, g_preinfect[index] ? "hellslum" : "slum")

	static effects
	effects = pev(index, pev_effects)
	
	if(effects & EF_DIMLIGHT)
	{
		message_begin(MSG_ONE, g_msg_flashlight, _, index)
		write_byte(0)
		write_byte(100)
		message_end()
		
		set_pev(index, pev_effects, effects & ~EF_DIMLIGHT)
	}
}

stock fm_set_user_money(index, addmoney, update = 1)
{
	static money
	money = fm_get_user_money(index) + addmoney
	
	set_pdata_int(index, 115, money)
	
	if(update)
	{
		message_begin(MSG_ONE, g_msg_money, _, index)
		write_long(clamp(money, 0, 16000))
		write_byte(1)
		message_end()
	}
	return 1
}

stock equipweapon(id, weapon)
{
	if(!is_user_alive(id)) 
		return
	
	static weaponid[2], weaponent
	
	if(weapon & EQUIP_PRI)
	{
		weaponent = fm_lastprimary(id)

		if(isGametype(1))
			weaponid[1] = get_weaponid(g_primaryweaponsZM[g_player_weapons[id][0]][1])
		if(isGametype(2))
			weaponid[1] = get_weaponid(g_primaryweaponsDM[g_player_weapons[id][0]][1])

		
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
				fm_strip_user_gun(id, weaponid[0])
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
		{
			if(isGametype(1))
				fm_give_item(id, g_primaryweaponsZM[g_player_weapons[id][0]][1])
			if(isGametype(2))
				fm_give_item(id, g_primaryweaponsDM[g_player_weapons[id][0]][1])
		}
			
		
		fm_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]])
	}
	
	if(weapon & EQUIP_SEC)
	{

		weaponid[1] = get_weaponid(g_secondaryweapons[g_player_weapons[id][1]][1])
	
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
				fm_strip_user_gun(id, weaponid[0])
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			fm_give_item(id, g_secondaryweapons[g_player_weapons[id][1]][1])
		
		fm_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]])
	}
	
	if(weapon & EQUIP_GREN)
		fm_give_item(id, "weapon_hegrenade")
	
}

stock equip_mvpweapon(id)
{
	if(isGametype(2))
	{
		fm_give_item(id, "weapon_flashbang")
		switch(random(2))
		{
			case 0: fm_give_item(id, "weapon_m3")
			case 1: fm_give_item(id, "weapon_xm1014")
		}
	} else 
	{
		fm_give_item(id, "weapon_smokegrenade")
		switch(random(3))
		{
			case 0: fm_give_item(id, "weapon_g3sg1")
			case 1: fm_give_item(id, "weapon_sg550")
			case 2: fm_give_item(id, "weapon_m249")
		}
	}

	equipweapon(id, EQUIP_SEC)
	equipweapon(id, EQUIP_GREN)
}

stock add_delay(index, const task[])
{
	switch(index)
	{
		case 1..8:   set_task(0.1, task, index)
		case 9..16:  set_task(0.2, task, index)
		case 17..24: set_task(0.3, task, index)
		case 25..32: set_task(0.4, task, index)
	}
}

stock sprawdz(zombi = false)
{
	new zombie, human;
	zombie = human = 0;
	
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(is_user_alive(i))
		{
			if(g_zombie[i]) zombie++
			else human++
		}
	}
	return zombi ? zombie : human
}

stock bool:sprawdz_bronie(id, disallowed) {
	new weapons[32], num;
	return bool:(get_user_weapons(id, weapons, num) & disallowed);
}

stock bool:allow_infection()
{
	static count
	count = 0

	static index

	for(index = 1; index <= g_maxplayers; index++)
	{
		if(is_user_alive(index) && !g_zombie[index]) 
			count++
	}
	
	return (count > 1) ? true : false
}

stock multiply_hp(index, Float: multiplier)
{
	set_pev(index, pev_health, g_healthmodifier[index]*multiplier)
}

stock CheckRespawnAbility(victim)
{
	if(isGametype(2))
	{
		if(g_zombie[victim] && !g_roundended) {
			new money_reward[33], Float:fRespTime;

			fRespTime = get_pcvar_float(cvar_resptime) + (get_pcvar_float(cvar_spawnlimit) - g_lives[victim]) * 5
			g_respcount[victim] = fRespTime
			money_reward[victim] = get_pcvar_num(cvar_respmoney)
			fm_set_user_money(victim, money_reward[victim])
			set_task( 0.1, "resp_countdown", victim, _, _, "a", floatround(fRespTime)*10 )
			set_task(fRespTime, "respawn_player", TASKID_RESPAWN+victim)
			ColorChat(victim, RED, "[Deathmatch]^x01 Dostajesz ^x04$%i^x01 za wykonywanie celow mapy.", money_reward[victim])
		}
	}
}

// Set Player Model on Entity
stock fm_set_playermodel_ent(id, const modelindex[])
{
	// Make original player entity invisibl without hiding shadows or firing effects
	fm_set_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransTexture, 1)
	
	// Format model string
	static model[100]
	formatex(model, charsmax(model), "models/player/%s/%s.mdl", modelindex, modelindex)
	if(!fm_has_custom_model(id))
	{
		static ent
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if(pev_valid(ent))
		{
			engfunc(EngFunc_SetModel, ent, model)
			set_pev(ent, pev_classname, MODEL_CLASSNAME)
			set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
			set_pev(ent, pev_aiment, id)
			set_pev(ent, pev_owner, id)
				
			g_modelent[id] = ent
		}
	}
	else
	{
		engfunc(EngFunc_SetModel, g_modelent[id], model)
		fm_set_entity_visibility(g_modelent[id], 1)
	}

}

stock fm_has_custom_model( id )
{
    return pev_valid( g_modelent[id] ) ? true : false;
}

stock fm_set_weaponmodel_ent( id )
{
    // Get the player's p_ weapon model
    static model[100]
    pev( id, pev_weaponmodel2, model, charsmax( model ) )
    
    // Check if the entity assigned to this player exists
    if ( !pev_valid(g_weaponent[id]) )
    {
        // If it doesn't, proceed to create a new one
        g_weaponent[id] = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) )
        
        // If it failed to create for some reason, at least this will prevent further "Invalid entity" errors...
        if ( !pev_valid( g_weaponent[id] ) ) return;
        
        // Set its classname
        set_pev( g_weaponent[id], pev_classname, WEAPONMODEL_CLASSNAME )
        
        // Make it follow the player
        set_pev( g_weaponent[id], pev_movetype, MOVETYPE_FOLLOW )
        set_pev( g_weaponent[id], pev_aiment, id )
        set_pev( g_weaponent[id], pev_owner, id )
    }
    
    // Entity exists now, set its model
    engfunc( EngFunc_SetModel, g_weaponent[id], model )
}
stock fm_remove_model_ents( id )
{
    // Make the player visible again
    set_pev( id, pev_rendermode, kRenderNormal )
    
    // Remove "playermodel" ent if present
    if ( pev_valid( g_modelent[id] ) )
    {
        engfunc( EngFunc_RemoveEntity, g_modelent[id] )
        g_modelent[id] = 0
    }
    // Remove "weaponmodel" ent if present
    if ( pev_valid( g_weaponent[id] ) )
    {
        engfunc( EngFunc_RemoveEntity, g_weaponent[id] )
        g_weaponent[id] = 0
    }
}
stock fm_update_weapon_ent( id )
{
	 if ( pev_valid( g_weaponent[id] ) )
    {
        engfunc( EngFunc_RemoveEntity, g_weaponent[id] )
        g_weaponent[id] = 0
    }
}