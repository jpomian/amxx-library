#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <nvault>

#tryinclude "biohazard.cfg"

enum(+= 100)
{
	TASKID_STRIPNGIVE,
	TASKID_INITROUND,
	TASKID_STARTROUND,
	TASKID_BALANCETEAM,
	TASKID_UPDATESCR,
	TASKID_SPAWNDELAY,
	TASKID_CHECKSPAWN
}

#define DATA_REGENDELAY 0.1 // co ile ma regenerowac zycie zombie jak stoi
#define DATA_HITREGENDELAY 4 // czas jaki trzeba odczekac po otrzymanych obrazeniach, zeby zycie sie regenerowalo
#define DATA_HPREGEN 7 // ile hp ma regenerowac

#define EQUIP_PRI (1<<0)
#define EQUIP_SEC (1<<1)
#define EQUIP_GREN (1<<2)
#define EQUIP_ALL (1<<0 | 1<<1 | 1<<2)

#define HAS_NVG (1<<0)
#define ATTRIB_BOMB (1<<1)
#define DMG_HEGRENADE (1<<24)

#define MODEL_CLASSNAME "player_model"
#define IMPULSE_FLASHLIGHT 100

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
#define _random(%1) random_num(0, %1 - 1)
#define AMMOWP_NULL (1<<0 | 1<<CSW_KNIFE | 1<<CSW_FLASHBANG | 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)

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

new modele[] = "models/p_zombibomb.mdl"

new g_vault, g_szAuthID[33][35], infects[33];

new g_maxplayers, g_buyzone, g_sync_dmgdisplay, g_msg_money,
    g_fwd_spawn, g_fwd_result, g_fwd_infect, g_fwd_gamestart, 
    g_msg_flashlight, g_msg_teaminfo, g_msg_scoreinfo, 
    Float:g_vecvel[3], bool:g_brestorevel, bool:g_gamestarted,
    bool:g_roundstarted, bool:g_roundended
    
new cvar_skyname, cvar_autoteambalance[4], cvar_starttime, 
    cvar_weaponsmenu, cvar_lights, cvar_killbonus, cvar_enabled, 
    cvar_gamedescription, cvar_moneybonus, cvar_zombiespeed, cvar_zombiehp, 
    cvar_punishsuicide, cvar_gametype, cvar_respawnmoney, cvar_infectmoney
    
new bool:g_zombie[33], bool:g_waszombie[33], bool:g_falling[33], bool:g_disconnected[33], bool:g_blockmodel[33], 
     bool:g_showmenu[33], bool:g_menufailsafe[33], bool:g_suicide[33],
	 g_victim[33], g_modelent[33], g_player_weapons[33][2], g_msg_screenfade,
	 g_msg_deathmsg, g_msg_scoreattrib, weapons[33], Float:g_regendelay[33], 
	 Float:g_regendelaymodifier[33], Float:g_maxspeedmodifier[33], g_healthmodifier[33], g_moneymodifier[33], g_rounds_elapsed;

new g_map[32];

public plugin_precache()
{
	register_plugin("Biohazard", "1", "cheap_suit") //skillownia es
	
	cvar_enabled = register_cvar("bh_enabled", "1")

	if(!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_gamedescription = register_cvar("bh_gamedescription", "Klasyczny Zombie.")
	cvar_gametype = register_cvar("bh_gametype","1")
	cvar_skyname = register_cvar("bh_skyname", "black")
	cvar_lights = register_cvar("bh_lights", "e")
	cvar_starttime = register_cvar("bh_starttime", "12.0")
	cvar_punishsuicide = register_cvar("bh_punishsuicide", "1")
	cvar_weaponsmenu = register_cvar("bh_weaponsmenu", "1")
	cvar_killbonus = register_cvar("bh_kill_bonus", "2")
	
	cvar_respawnmoney = register_cvar("bh_respawnmoney", "0")
	cvar_infectmoney = register_cvar("bh_infectionmoney", "300")
	
	cvar_moneybonus = register_cvar("vip_bonusmoney", "2000")
	cvar_zombiespeed = register_cvar("vip_zombiespeed", "280")
	cvar_zombiehp = register_cvar("vip_zombiehp", "500")
			
	precache_model(DEFAULT_PMODEL)
	precache_model(DEFAULT_WMODEL)
	precache_model(modele)
	
	new i
		
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

	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
	if(ent)
	{
		fm_set_kvd(ent, "density", FOG_DENSITY, "env_fog")
		fm_set_kvd(ent, "rendercolor", FOG_COLOR, "env_fog")
	}
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
	register_forward(FM_GetGameDescription, "fwd_gamedescription")
	register_forward(FM_CreateNamedEntity, "fwd_createnamedentity")
	register_forward(FM_ClientKill, "fwd_clientkill")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink_post", 1)
	register_forward(FM_PlayerPostThink, "fwd_player_postthink")
	register_forward(FM_SetClientKeyValue, "fwd_setclientkeyvalue")

	RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player")
	RegisterHam(Ham_Killed, "player", "bacon_killed_player")
	RegisterHam(Ham_Spawn, "player", "bacon_spawn_player_post", 1)
	RegisterHam(Ham_Use, "func_tank", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankmortar", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankrocket", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tanklaser", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_pushable", "bacon_use_pushable")
	RegisterHam(Ham_Touch, "func_pushable", "bacon_touch_pushable")
	RegisterHam(Ham_Touch, "weaponbox", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "bacon_touch_weapon")
	
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
	
	new skyname[32]
	get_pcvar_string(cvar_skyname, skyname, 31)
		
	if(strlen(skyname) > 0)
		set_cvar_string("sv_skyname", skyname)
	
	new lights[2]
	get_pcvar_string(cvar_lights, lights, 1)
	
	if(strlen(lights) > 0)
	{
		set_task(3.0, "task_lights", _, _, _, "b")
		
		set_cvar_num("sv_skycolor_r", 0)
		set_cvar_num("sv_skycolor_g", 0)
		set_cvar_num("sv_skycolor_b", 0)
	}
	
	//set_task(0.1, "task_showtruehealth", _, _, _, "b")

	g_vault = nvault_open("jb_packi")
	if(g_vault == INVALID_HANDLE)
		set_fail_state("Nie moge otworzyc pliku");
}

public plugin_end()
{
	if(get_pcvar_num(cvar_enabled))
		set_pcvar_num(cvar_autoteambalance[0], cvar_autoteambalance[1])

	nvault_close(g_vault)
}

public plugin_natives()
{
	register_library("biohazardf")
	register_native("infect_user", "native_infect_user", 1)
	register_native("cure_user", "native_cure_user", 1)
	register_native("game_started", "native_game_started", 1)
	register_native("is_user_zombie", "native_is_user_zombie", 1)	
	register_native("add_zombie_health", "native_add_health", 1)
	register_native("add_bonus_money", "native_add_money", 1)
	register_native("add_zombie_maxspeed", "native_add_maxspeed", 1)
	register_native("get_zombie_regendelay", "native_get_regendelay", 1)
	register_native("set_zombie_regendelay", "native_set_regendelay", 1)
	register_native("get_user_infections","return_infections", 1)
	register_native("set_user_infections","set_infections", 1)

}

public client_authorized(id)
{
	get_user_authid( id , g_szAuthID[id] , charsmax( g_szAuthID[] ) );
	load_infections(id)
	g_healthmodifier[id] = (is_vip(id) ? DEFAULT_HEALTH+(infects[id]/10)+(get_pcvar_num(cvar_zombiehp)) : DEFAULT_HEALTH+(infects[id]/10));
}

public client_connect(id)
{
	g_showmenu[id] = true
	g_blockmodel[id] = true
	g_zombie[id] = false
	g_waszombie[id] = false;
	g_disconnected[id] = false
	g_falling[id] = false
	g_menufailsafe[id] = false
	g_victim[id] = 0
	g_player_weapons[id][0] = -1
	g_player_weapons[id][1] = -1
	new Float:delay = DATA_REGENDELAY
	g_regendelaymodifier[id] = delay;
	g_maxspeedmodifier[id] = (is_vip(id) ? get_pcvar_float(cvar_zombiespeed) : fm_get_user_maxspeed(id));
	g_moneymodifier[id] = 0;

	remove_user_model(g_modelent[id])
}

public client_disconnected(id)
{
	remove_task(TASKID_STRIPNGIVE + id)
	remove_task(TASKID_UPDATESCR + id)
	remove_task(TASKID_SPAWNDELAY + id)
	remove_task(TASKID_CHECKSPAWN + id)

	g_disconnected[id] = true
	remove_user_model(g_modelent[id])

	save_infections(id)
}

public cmd_jointeam(id)
{
	if(is_user_alive(id) && g_zombie[id])
	{
		client_print(id, print_center, "Nie jest dozwolona zmiana teamow.")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
	
public cmd_enablemenu(id)
{	
	if(get_pcvar_num(cvar_weaponsmenu))
	{
		client_print(id, print_chat, "%s", !g_showmenu[id] ?  "Twoj ekwipunek zostal przywrocony." : "Twoje menu ekwipunku jest aktualnie wlaczone.")
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
	static killer
	killer = get_msg_arg_int(1)

	if(is_user_connected(killer) && g_zombie[killer])
		set_msg_arg_string(4, g_zombie_weapname)
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
					
					if(team == _:CS_TEAM_CT)
					{
						fm_set_user_armor(id, 100)						
					}
				}
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
	
	if(!sprawdz()) {
		for(new i = 1; i <= g_maxplayers; i++) if(g_zombie[i]) g_waszombie[i] = true;
		client_print(0, print_center, "Zombie Wygralo")
	}
	else if(!sprawdz(true)) client_print(0, print_center, "Ludzie ogarneli")
	else
	{
		for(new i = 1; i <= g_maxplayers; i++) { 
			if(g_zombie[i]) {
				add_delay(i, "zabij");
				g_waszombie[i] = true;
			}
		}			
		client_print(0, print_center, "Zombie ginie z glodu")	
	}
	
	remove_task(TASKID_BALANCETEAM) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	set_task(0.1, "task_balanceteam", TASKID_BALANCETEAM)
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
	}
	
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	set_task(get_pcvar_float(cvar_starttime), "task_initround", TASKID_INITROUND)
	show_announcement()
}
public show_announcement()
{
	g_rounds_elapsed += 1;


	new p_playernum;
	p_playernum = get_playersnum(1);
	new hostname[64]
	get_cvar_string("hostname", hostname, charsmax(hostname))
	

	set_dhudmessage(255, 255, 255, -1.0, 0.16, _, 5.0, 5.0)
	show_dhudmessage(0, "Witamy na %s (%i/%i)",hostname,  p_playernum, g_maxplayers);
	set_dhudmessage(255, 69, 0, -1.0, 0.2, _, 5.0, 5.0)
	show_dhudmessage(0, "Mapa: %s (Runda: %i)", g_map, g_rounds_elapsed);

	new rndctstr[21]
	num_to_word(g_rounds_elapsed, rndctstr, 20);
	client_cmd(0, "spk ^"vox/round %s^"",rndctstr)

	return PLUGIN_CONTINUE;
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
		
		else if(weapon == CSW_SMOKEGRENADE) set_pev(id, pev_weaponmodel2, modele);
		
			
		if(weapon != CSW_KNIFE  && weapon != CSW_SMOKEGRENADE && !task_exists(TASKID_STRIPNGIVE + id))
			set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + id)
								
		return PLUGIN_CONTINUE
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
	if(!is_user_alive(id) || !g_zombie[id])
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
		static Float:fallvelocity
		pev(id, pev_flFallVelocity, fallvelocity)
		
		g_falling[id] = fallvelocity >= 350.0 ? true : false
	}

	if(g_gamestarted)
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

public fwd_gamedescription() 
{ 
	static gamename[32]
	get_pcvar_string(cvar_gamedescription, gamename, 31)
	
	forward_return(FMV_STRING, gamename)
	
	return FMRES_SUPERCEDE
}  

public fwd_createnamedentity(entclassname)
{
	static classname[10]
	engfunc(EngFunc_SzFromIndex, entclassname, classname, 9)
	
	return (classname[7] == 'c' && classname[8] == '4') ? FMRES_SUPERCEDE : FMRES_IGNORED
}

public fwd_clientkill(id)
{
	if(get_pcvar_num(cvar_punishsuicide) && is_user_alive(id))
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

public bacon_touch_weapon(ent, id)
	return (is_user_alive(id) && g_zombie[id]) ? HAM_SUPERCEDE : HAM_IGNORED

public bacon_use_tank(ent, caller, activator, use_type, Float:value)
	return (is_user_alive(caller) && g_zombie[caller]) ? HAM_SUPERCEDE : HAM_IGNORED

public bacon_use_pushable(ent, caller, activator, use_type, Float:value)
	return HAM_SUPERCEDE

public bacon_takedamage_player(victim, inflictor, attacker, Float:damage, damagetype)
{
	if(damagetype & DMG_GENERIC || victim == attacker || !is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(!g_gamestarted || (!g_zombie[victim] && !g_zombie[attacker]) || ((damagetype & DMG_HEGRENADE) && g_zombie[attacker]) || (g_zombie[attacker] && g_zombie[victim]))
		return HAM_SUPERCEDE

	if(is_vip(attacker))
	{
		if(!g_zombie[attacker] && g_zombie[victim]) 
		{
			set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1) 
			ShowSyncHudMsg(attacker, g_sync_dmgdisplay, "%d^n", pev(victim, pev_health)) 
		}
	}
	if(!g_zombie[attacker] && (damagetype & DMG_HEGRENADE))
	{
		damage *= 8.0
		SetHamParamFloat(4, damage)
	}
	
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
	
	return HAM_HANDLED
}

public bacon_killed_player(victim, killer, shouldgib)
{	
	if(!is_user_alive(killer) || g_zombie[killer] || !g_zombie[victim])
		return HAM_IGNORED
	
	static killbonus
	killbonus = get_pcvar_num(cvar_killbonus)
	
	if(killbonus)
		set_pev(killer, pev_frags, pev(killer, pev_frags) + float(killbonus))
				
	if(!user_has_weapon(killer, CSW_SMOKEGRENADE))
		fm_give_item(killer, "weapon_smokegrenade")
		
	fm_set_user_money(killer, 500);
	
	switch(get_pcvar_num(cvar_gametype))	
	{
		case 0,2:
		{
			if(g_zombie[victim])
				set_task(0.5, "respawn_player", victim)
		}
	}	
		
	return HAM_IGNORED
}

public respawn_player(id)
{
	ExecuteHamB(Ham_CS_RoundRespawn, id) 
	infect_user(id, -1)
	fm_set_user_money(id, get_pcvar_num(cvar_respawnmoney))
}

public bacon_spawn_player_post(id)
{	
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	static team
	team = fm_get_user_team(id)
	
	if(team != _:CS_TEAM_T && team != _:CS_TEAM_CT)
		return HAM_IGNORED
	
	fm_set_user_nvg(id, 0)

	
	if(pev(id, pev_rendermode) == kRenderTransTexture)
		reset_user_model(id)
	
	set_task(0.3, "task_spawned", TASKID_SPAWNDELAY + id)
	set_task(5.0, "task_checkspawn", TASKID_CHECKSPAWN + id)
	

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
	
	if(is_user_alive(id))
	{		
		if(g_suicide[id])
		{
			g_suicide[id] = false
			
			user_silentkill(id)
			remove_task(TASKID_CHECKSPAWN + id)

			client_print(id, print_chat, "Zostales ukarany za popelnienie samobojstwa.")
			
			return
		}
		
		if(get_pcvar_num(cvar_weaponsmenu) && g_roundstarted && g_showmenu[id] && !g_zombie[id])
			display_equipmenu(id)
		
		if(g_gamestarted)
		{			
			static team
			team = fm_get_user_team(id)
			
			if(team == _:CS_TEAM_T && !g_zombie[id])
				fm_set_user_team(id, _:CS_TEAM_CT)
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
	
/*public task_showtruehealth()
{
	set_hudmessage(_, _, _, 0.03, 0.93, _, 0.2, 0.2)
	
	static id;
	for(id = 1; id <= g_maxplayers; id++) if(is_user_alive(id) && !is_user_bot(id) && g_zombie[id])
	{		
		ShowSyncHudMsg(id, g_sync_hpdisplay, "Zycie: %d", get_user_health(id))
	}
}*/

public task_lights()
{
	static light[2]
	get_pcvar_string(cvar_lights, light, 1)
	
	engfunc(EngFunc_LightStyle, 0, light)
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
			fm_set_user_money(attacker, get_pcvar_num(cvar_infectmoney))
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

		set_pev(id, pev_weaponmodel2, (weapons[id] == CSW_SMOKEGRENADE) ? modele : "")
		set_pev(id, pev_viewmodel2, DEFAULT_WMODEL)
		if(is_vip(id)) 
		{
			fm_set_user_maxspeed(id, get_pcvar_float(cvar_zombiespeed))
		}
		
	}
}

public task_initround()
{
	static zombiecount, newzombie
	zombiecount = 0
	newzombie = 0

	static players[32], num, id
	get_players(players, num, "a")

	if(num > 1)
	{
		for(new i = 0; i < num; i++) 
			g_zombie[players[i]] = false
		
		new zombies;
		if(get_pcvar_num(cvar_gametype) == 1)	
			zombies = clamp(floatround(num * 0.25), 1, 31)
		else
			zombies = clamp(floatround(num * 0.50), 1, 31)
			
		new i = 0
		while(i < zombies)
		{
			id = players[_random(num)]
			if(!g_zombie[id])
			{
				g_zombie[id] = true
				i++
			}
		}
		
		for(new i = 0; i < num; i++) if(g_zombie[players[i]])
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
			if(id == newzombie || g_zombie[id])
			{
				infect_user(id, 0)
				multiply_hp(id, 2.0)

				new name[33], msgStrBuffer[128];
				get_user_name(id, name, charsmax(name))

				set_dhudmessage(250, 50, 0, -1.0, 0.16, 1, 0.01, 6.0, 1.0, 1.0)
				formatex(msgStrBuffer, charsmax(msgStrBuffer), "%s jest pierwszym zombie!", name)

				if(zombies == 1)
				{
					show_dhudmessage(0, msgStrBuffer)
				}
				else if(zombies > 1)
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

	new Float:Random_Float[3]
	for(new i = 0; i < 3; i++) Random_Float[i] = random_float(-100.0, 100.0)
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
	
	fm_set_user_team(victim, _:CS_TEAM_T)
	set_zombie_attibutes(victim)

	if(attacker != 0 && is_user_alive(attacker))
	{
		infects[attacker]++
		save_infections(attacker)
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

	reset_user_model(id)
	fm_set_user_nvg(id, 0)
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

	static bool:hasweap
	hasweap = ((g_player_weapons[id][0]) != -1 && (g_player_weapons[id][1] != -1)) ? true : false
	
	menu_additem(menu, "Nowa bron")
	menu_additem(menu, "Poprzedni krok", "", !hasweap ? ADMIN_IMMUNITY : 0)
	menu_additem(menu, "Nie pokazuj menu ponownie", "", !hasweap ? ADMIN_IMMUNITY : 0)
	
	menu_display(id, menu, 0)
}

public action_equip(id, menu, item)
{
	if(item == MENU_EXIT)
		menu_destroy(menu)
	
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
			client_print(id, print_chat, "Wpisz ^"/guns^" na chacie zeby przywrocic twoj ekwipunek.")
		}
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
	maxitem = menuid == MENU_PRIMARY ? sizeof g_primaryweapons : sizeof g_secondaryweapons
	
	new temp[512]
	formatex(temp, 511, "\y%s", menuid == MENU_PRIMARY ? "Ciezkie bronie" : "Bron krotka")	
	new menu = menu_create(temp, menuid == MENU_PRIMARY ? "action_prim" : "action_sec")
	
  	for(new i = 0; i < maxitem; i++) 
	{
		formatex(temp, 511, "%s", menuid == MENU_PRIMARY ? g_primaryweapons[i][0]: g_secondaryweapons[i][0])
		menu_additem(menu, temp)
  	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public action_prim(id, menu, item)
{
	if(item == MENU_EXIT)
		menu_destroy(menu)
	
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
		menu_destroy(menu)
	
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	g_menufailsafe[id] = false

	g_player_weapons[id][1] = item
	equipweapon(id, EQUIP_SEC)
	equipweapon(id, EQUIP_GREN)

	return PLUGIN_HANDLED
}
public load_infections(id)
{
	new szData[8];
	new szKey[40];

	formatex( szKey , charsmax( szKey ) , "%s-INFECTIONS" , g_szAuthID[id] );

	//If data was found
	if ( nvault_get( g_vault , szKey , szData , charsmax( szData ) ) )
	{
		new infects_parsed[16];
		parse(szData, infects_parsed, 15)

		infects[id]=str_to_num(infects_parsed)
	}

	return PLUGIN_CONTINUE
}  

public save_infections(id)
{
	new szInfects[7];        //Data holder for the money amount
	new szKey[40];        //Key used to save money "STEAM_0:0:1234MONEY"

	formatex( szKey , charsmax( szKey ) , "%s-INFECTIONS" , g_szAuthID[id] );
	formatex( szInfects , charsmax( szInfects ) , "%d" , infects[id] );

	nvault_set( g_vault , szKey , szInfects );

	return PLUGIN_CONTINUE
}
public return_infections(id)
{
	return infects[id];
}
public set_infections(id, amount)
{
	infects[id] = amount	
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
	
public native_add_health(index, health)
	g_healthmodifier[index] = (is_vip(index) ? DEFAULT_HEALTH+(get_pcvar_num(cvar_zombiehp)+(infects[index]/10))+health : DEFAULT_HEALTH+(infects[index]/10))+health;
	
public native_add_money(index, money)
	g_moneymodifier[index] = money;
	
public native_add_maxspeed(index, Float:maxspeed)
	g_maxspeedmodifier[index] = (is_vip(index) ? get_pcvar_float(cvar_zombiespeed) : fm_get_user_maxspeed(index))+maxspeed;
	
public Float:native_get_regendelay(index)
	return g_regendelaymodifier[index];
	
public native_set_regendelay(index, Float:delay) {
	new Float:something = DATA_REGENDELAY
	g_regendelaymodifier[index] = (delay>0.0001 || delay<5.0) ? delay : something
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

	if(pev_valid(g_modelent[index]))
		fm_set_entity_visibility(g_modelent[index], 0)
}

stock remove_user_model(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(pev_valid(ent)) 
		engfunc(EngFunc_RemoveEntity, ent)

	g_modelent[id] = 0
}

stock set_zombie_attibutes(index)
{
	if(!is_user_alive(index)) 
		return

	g_zombie[index] = true

	if(!task_exists(TASKID_STRIPNGIVE + index))
		set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + index)
	
	set_pev(index, pev_health, float(g_healthmodifier[index]))
	set_pev(index, pev_body, 0)
	set_pev(index, pev_armorvalue, 0.0)
	set_pev(index, pev_renderamt, 0.0)
	set_pev(index, pev_rendermode, kRenderTransTexture)
	
	fm_set_user_armortype(index, 0)
	fm_set_user_nvg(index)
		
	if(!pev_valid(g_modelent[index]))
	{
		static ent
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if(pev_valid(ent))
		{
			engfunc(EngFunc_SetModel, ent, DEFAULT_PMODEL)
			set_pev(ent, pev_classname, MODEL_CLASSNAME)
			set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
			set_pev(ent, pev_aiment, index)
			set_pev(ent, pev_owner, index)
				
			g_modelent[index] = ent
		}
	}
	else
	{
		engfunc(EngFunc_SetModel, g_modelent[index], DEFAULT_PMODEL)
		fm_set_entity_visibility(g_modelent[index], 1)
	}

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

stock randomly_pick_zombie()
{
	static data[4]
	data[0] = 0 
	data[1] = 0 
	data[2] = 0 
	data[3] = 0
	
	static index, players[2][32]
	for(index = 1; index <= g_maxplayers; index++)
	{
		if(!is_user_alive(index)) 
			continue
		
		if(g_zombie[index])
		{
			data[0]++
			players[0][data[2]++] = index
		}
		else 
		{
			data[1]++
			players[1][data[3]++] = index
		}
	}

	if(data[0] > 0 &&  data[1] < 1) 
		return players[0][_random(data[2])]
	
	return (data[0] < 1 && data[1] > 0) ?  players[1][_random(data[3])] : 0
}

stock equipweapon(id, weapon)
{
	if(!is_user_alive(id)) 
		return
	
	static weaponid[2], weaponent
	
	if(weapon & EQUIP_PRI)
	{
		weaponent = fm_lastprimary(id)
		weaponid[1] = get_weaponid(g_primaryweapons[g_player_weapons[id][0]][1])
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
				fm_strip_user_gun(id, weaponid[0])
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			fm_give_item(id, g_primaryweapons[g_player_weapons[id][0]][1])
		
		fm_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]])
	}
	
	if(weapon & EQUIP_SEC)
	{
		weaponent = fm_lastsecondry(id)
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