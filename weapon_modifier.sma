#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
//#include <biohazard>

native is_user_zombie(id)
native is_user_nemesis(id)

#define CSW_THIGHPACK 	0
#define CSW_SHIELD		2
#define CSW_BACKPACK	32

// Offsets
const OFFSET_USE_STOPPED 			= 0;
const OFFSET_PDATA					= 2;
const OFFSET_LINUX_WEAPONS 			= 4;
const OFFSET_LINUX		 			= 5;
const OFFSET_WEAPON_OWNER			= 41;
const OFFSET_ID						= 43;
const OFFSET_NEXT_PRIMARY_ATTACK	= 46;
const OFFSET_NEXT_SECONDARY_ATTACK 	= 47;
const OFFSET_TIME_WEAPON_IDLE 		= 48;
const OFFSET_IN_RELOAD 				= 54;
const OFFSET_IN_SPECIAL_RELOAD 		= 55;
const OFFSET_NEXT_ATTACK			= 83;
const OFFSET_FOV					= 363;
const OFFSET_ACTIVE_ITEM 			= 373;

new const g_customization_file_cfg[] = "weapon_modifier.cfg"
new const g_customization_file_ini[] = "weapon_modifier.ini"

new const g_weapon_ent_names[][] = {"", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18",
"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90", "all"};

new const g_weapon_ent_names_all[][] = {"weapon_thighpack", "weapon_p228", "weapon_shield", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp",
"weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90", "w_backpack"};

new const g_model_default[][] = {"models/w_thighpack.mdl", "models/w_p228.mdl", "models/w_shield.mdl", "models/w_scout.mdl", "models/w_hegrenade.mdl",
"models/w_xm1014.mdl", "models/w_c4.mdl", "models/w_mac10.mdl", "models/w_aug.mdl", "models/w_smokegrenade.mdl", "models/w_elite.mdl", "models/w_fiveseven.mdl",
"models/w_ump45.mdl", "models/w_sg550.mdl", "models/w_galil.mdl", "models/w_famas.mdl", "models/w_usp.mdl", "models/w_glock18.mdl", "models/w_awp.mdl",
"models/w_mp5.mdl", "models/w_m249.mdl", "models/w_m3.mdl", "models/w_m4a1.mdl", "models/w_tmp.mdl", "models/w_g3sg1.mdl", "models/w_flashbang.mdl",
"models/w_deagle.mdl", "models/w_sg552.mdl", "models/w_ak47.mdl", "models/w_knife.mdl", "models/w_p90.mdl", "models/w_backpack.mdl"};

new const g_max_bpammo[] = {-1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100};
new const g_max_clip[] = {-1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50};
new const g_ammo_type[][] = {"", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp", "556nato", "556nato", "556nato", "45acp",
"9mm", "338magnum", "9mm", "556natobox", "buckshot", "556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm"};
new const g_ammo_weapon[] = {0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE, CSW_P228, CSW_ELITE, CSW_FLASHBANG,
CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4};
new const SECONDARY_WEAPONS_BIT_SUM = (1 << CSW_P228)|(1 << CSW_ELITE)|(1 << CSW_FIVESEVEN)|(1 << CSW_USP)|(1 << CSW_GLOCK18)|(1 << CSW_DEAGLE)
new const SHOTGUN_WEAPONS_BIT_SUM = (1 << CSW_M3)|(1 << CSW_XM1014)
new const ALREADY_SECONDARY_ATTACK = (1 << CSW_KNIFE)|(1 << CSW_USP)|(1 << CSW_GLOCK18)|(1 << CSW_FAMAS)|(1 << CSW_M4A1)

new const g_sound_knife_default[][] = {
	"weapons/knife_deploy1.wav",
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	"weapons/knife_hitwall1.wav",
	"weapons/knife_slash1.wav",
	"weapons/knife_slash2.wav",
	"weapons/knife_stab.wav"
};

enum()
{
	WEAPON_DAMAGE = 0,
	WEAPON_RECOIL,
	WEAPON_SPEED,
	WEAPON_W_GLOW,
	WEAPON_P_GLOW,
	WEAPON_UNLIMITED_CLIP,
	WEAPON_UNLIMITED_BPAMMO,
	WEAPON_KNOCKBACK,
	WEAPON_AUTO_FIRE,
	WEAPON_ZOOM,

	MAX_WM
};
new g_cvar_weapon[CSW_P90+3][MAX_WM];
new g_cvar_knockback;
new g_cvar_knockback_zvel;
new g_cvar_knockback_dist;
new g_pcvar_ff;

enum()
{
	V_ = 0,
	P_,
	W_,
	
	ALL_MODELS
};
new g_model_weapon[ALL_MODELS][CSW_P90+2][128];
new g_sound_weapon[sizeof(g_sound_knife_default)][128];

new g_ent_weaponmodel[33];
new g_has_ammo[33];
new g_weapon[33];

new Trie:g_trie_wmodel;

new g_msg_curweapon;
new g_msg_ammopickup;

new g_maxplayers;

new bool: g_isImmune[33];

#define is_user_valid_connected(%1)	(1 <= %1 <= g_maxplayers && is_user_connected(%1))
public plugin_precache()
{
	fn_load_customization();
}
public plugin_init()
{
	new plugin_name[] = "Weapon Modifier";
	new plugin_version[] = "v1.56";
	new plugin_author[] = "Kiske";
	
	new i;
	new j;
	new buffer[64];
	
	new wm_cvars[][] = {"damage", "recoil", "speed", "wglow", "pglow", "unclip", "unbpammo", "kb", "autofire", "zoom"};
	
	register_plugin(plugin_name, plugin_version, plugin_author);
	
	register_event("AmmoX", "event_AmmoX", "be");
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem");
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1);
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1);
	
	// Register CVARS
	for(i = 0; i < CSW_P90+2; i++)
	{
		// Get Weapon and Change Models
		if(i != 0 && i != 2 && i != 31) // weapon_thighpack(0) , weapon_shield (2) and w_backpack(31)
			RegisterHam(Ham_Item_Deploy, g_weapon_ent_names_all[i], "fw_Item_Deploy_Post", 1);
		
		if(g_weapon_ent_names[i][0])
		{
			// Recoil , Speed , Auto Fire Pistol and Zoom
			if(i != 31) // all is 31
			{
				RegisterHam(Ham_Weapon_PrimaryAttack, g_weapon_ent_names[i], "fw_Weapon_PrimaryAttack_Post", 1); // Recoil , Speed and Auto Fire Pistol
				
				// Zoom
				if(!((1 << i) & ALREADY_SECONDARY_ATTACK))
				{
					RegisterHam(Ham_Item_PostFrame, g_weapon_ent_names[i], "fw_Item_PostFrame");
					RegisterHam(Ham_Item_Holster, g_weapon_ent_names[i], "fw_Item_Holster");
					RegisterHam(Ham_CS_Item_GetMaxSpeed, g_weapon_ent_names[i], "fw_CS_Item_GetMaxSpeed");
					RegisterHam(Ham_Weapon_Reload, g_weapon_ent_names[i], ((1 << i) & SHOTGUN_WEAPONS_BIT_SUM) ? "fw_Weapon_Shotgun_Reload_Post" : "fw_Weapon_Reload_Post", 1);
				}
			}
			
			// Remove weapon_ from the names
			replace(g_weapon_ent_names[i], 17, "weapon_", "");
			
			for(j = 0; j < MAX_WM; j++)
			{
				formatex(buffer, charsmax(buffer), "wm_%s_%s", wm_cvars[j], g_weapon_ent_names[i]);
				
				switch(j)
				{
					case WEAPON_KNOCKBACK: g_cvar_weapon[i][j] = register_cvar(buffer, "0.00");
					case WEAPON_AUTO_FIRE:
					{
						if(i == 31) // all is 31
						{
							g_cvar_weapon[i][j] = register_cvar(buffer, "0");
							continue;
						}
						
						if((1 << i) & SECONDARY_WEAPONS_BIT_SUM)
							g_cvar_weapon[i][j] = register_cvar(buffer, "0");
					}
					case WEAPON_ZOOM:
					{
						if(!((1 << i) & ALREADY_SECONDARY_ATTACK))
							g_cvar_weapon[i][j] = register_cvar(buffer, "off");
					}
					default: g_cvar_weapon[i][j] = register_cvar(buffer, "off");
				}
			}
		}
	}
	
	// Extra Cvars for W_ models glow :)
	g_cvar_weapon[CSW_THIGHPACK][WEAPON_W_GLOW] = register_cvar("wm_wglow_thighpack", "off");
	g_cvar_weapon[CSW_SHIELD][WEAPON_W_GLOW] = register_cvar("wm_wglow_shield", "off");
	g_cvar_weapon[CSW_HEGRENADE][WEAPON_W_GLOW] = register_cvar("wm_wglow_hegrenade", "off");
	g_cvar_weapon[CSW_C4][WEAPON_W_GLOW] = register_cvar("wm_wglow_c4", "off");
	g_cvar_weapon[CSW_SMOKEGRENADE][WEAPON_W_GLOW] = register_cvar("wm_wglow_smokegrenade", "off");
	g_cvar_weapon[CSW_FLASHBANG][WEAPON_W_GLOW] = register_cvar("wm_wglow_flashbang", "off");
	g_cvar_weapon[CSW_BACKPACK][WEAPON_W_GLOW] = register_cvar("wm_wglow_backpack", "off");
	
	// Extra Cvars for P_ models glow :)
	g_cvar_weapon[CSW_HEGRENADE][WEAPON_P_GLOW] = register_cvar("wm_pglow_hegrenade", "off");
	g_cvar_weapon[CSW_C4][WEAPON_P_GLOW] = register_cvar("wm_pglow_c4", "off");
	g_cvar_weapon[CSW_SMOKEGRENADE][WEAPON_P_GLOW] = register_cvar("wm_pglow_smokegrenade", "off");
	g_cvar_weapon[CSW_FLASHBANG][WEAPON_P_GLOW] = register_cvar("wm_pglow_flashbang", "off");
	
	// Cvars for knockback
	g_cvar_knockback = register_cvar("wm_knockback", "1");
	g_cvar_knockback_zvel = register_cvar("wm_kb_zvel", "1");
	g_cvar_knockback_dist = register_cvar("wm_kb_dist", "220");
	g_pcvar_ff = get_cvar_pointer("mp_friendlyfire");
	
	new wmodels[][] = {"models/w_shield.mdl", "models/w_thighpack.mdl", "models/w_c4.mdl", "models/w_backpack.mdl"};
	
	g_trie_wmodel = TrieCreate();
	
	for(i = 0; i < sizeof(wmodels); i++)
		TrieSetCell(g_trie_wmodel, wmodels[i], 1);
	
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_EmitSound, "fw_EmitSound");
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	g_msg_curweapon = get_user_msgid("CurWeapon");
	g_msg_ammopickup = get_user_msgid("AmmoPickup");
	
	register_message(g_msg_curweapon, "message_CurWeapon");
	
	g_maxplayers = get_maxplayers();
}

public plugin_cfg()
{
	new cfgdir[32];
	get_configsdir(cfgdir, charsmax(cfgdir));
	
	server_cmd("exec %s/%s", cfgdir, g_customization_file_cfg);
}
public plugin_natives()
{
	register_native("give_user_knockbackimmunity", "give_immunity", 1)
}
public plugin_end()
{
	TrieDestroy(g_trie_wmodel);
}

public client_disconnected(id)
{
	g_has_ammo[id] = 0;
	
	fm_remove_model_ents(id);
}

public event_AmmoX(id)
{
	if(!g_weapon[id])
        return;
		
	static bpammo_cvar[10];
	static bpammo_cvar_temp[10];
	static bpammo_cvar_int;
	static mode;
	mode = 0;
	
	get_pcvar_string(g_cvar_weapon[g_weapon[id]][WEAPON_UNLIMITED_BPAMMO], bpammo_cvar, charsmax(bpammo_cvar));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_UNLIMITED_BPAMMO], bpammo_cvar_temp, charsmax(bpammo_cvar_temp));
	
	bpammo_cvar_int = str_to_num(bpammo_cvar);
	
	if(!equali(bpammo_cvar_temp, "off") || bpammo_cvar_int)
		mode = 1;
	
	if(!mode)
		return;
	
	static type;
	type = read_data(1);
	
	if(type >= sizeof(g_ammo_weapon))
		return;
	
	static weapon;
	weapon = g_ammo_weapon[type];
	
	if(g_max_bpammo[weapon] <= 2)
		return;
	
	static amount;
	amount = read_data(2);
	
	if(amount < g_max_bpammo[weapon])
	{
		// The BP Ammo refill code causes the engine to send a message, but we
		// can't have that in this forward or we risk getting some recursion bugs.
		// For more info see: https://bugs.alliedmods.net/show_bug.cgi?id=3664
		
		static args[1];
		args[0] = weapon;
		
		set_task(0.1, "fn_refill_bpammo", id, args, sizeof(args));
	}
}
public give_immunity(id, Float:time)
{
	g_isImmune[id] = true;
	set_task(time, "take_immunity", id)
}
public take_immunity(id)
	g_isImmune[id] = false;

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(victim == attacker || !is_user_valid_connected(attacker))
		return HAM_IGNORED;
	
	static dmg_cvar[10];
	static dmg_cvar_k[10];
	static dmg_cvar_temp[10];
	static dmg_cvar_temp_k[10];
	
	get_pcvar_string(g_cvar_weapon[g_weapon[attacker]][WEAPON_DAMAGE], dmg_cvar, charsmax(dmg_cvar));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_DAMAGE], dmg_cvar_temp, charsmax(dmg_cvar_temp));
	
	copy(dmg_cvar_k, charsmax(dmg_cvar_k), dmg_cvar);
	copy(dmg_cvar_temp_k, charsmax(dmg_cvar_temp_k), dmg_cvar_temp);
	
	if(fn_contain_words(dmg_cvar_k) || fn_contain_words(dmg_cvar_temp_k))
	{
		fn_replace_words(dmg_cvar_k, charsmax(dmg_cvar_k));
		fn_replace_words(dmg_cvar_temp_k, charsmax(dmg_cvar_temp_k));
		
		static Float:dmg;
		
		if(equali(dmg_cvar_temp, "off")) dmg = str_to_float(dmg_cvar_k);
		else dmg = str_to_float(dmg_cvar_temp_k);
		
		switch((equali(dmg_cvar_temp, "off")) ? dmg_cvar[0] : dmg_cvar_temp[0])
		{
			case '+':
			{
				if(dmg < 1.00) return HAM_IGNORED;
				damage += dmg;
			}
			case '-':
			{
				if(dmg < 1.00) return HAM_IGNORED;
				damage -= dmg;
			}
			case '*':
			{
				if(dmg == 1.00) return HAM_IGNORED;
				damage *= dmg;
			}
			case '/':
			{
				if(dmg == 0.00) return HAM_IGNORED; // Can't divide by 0
				damage /= dmg;
			}
			case '=':
			{
				if(dmg < 1.00) return HAM_IGNORED;
				damage = dmg;
			}
		}
		
		SetHamParamFloat(4, damage);
	}
	
	return HAM_IGNORED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	fm_remove_model_ents(victim);
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], trace_handle, damage_type)
{
	if(victim == attacker || !is_user_valid_connected(attacker))
		return HAM_IGNORED;
	
	if(!get_pcvar_num(g_cvar_knockback))
		return HAM_IGNORED;
	
	if(!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	if(!get_pcvar_num(g_pcvar_ff) && (cs_get_user_team(attacker) == cs_get_user_team(victim)))
		return HAM_IGNORED;
	
	if(!is_user_zombie(victim))
		return HAM_IGNORED;

	//static kb_duck;
	static origin1[3];
	static origin2[3];
	
	get_user_origin(victim, origin1);
	get_user_origin(attacker, origin2);
	
	if(get_distance(origin1, origin2) > get_pcvar_num(g_cvar_knockback_dist))
		return HAM_IGNORED;
	
	static Float:velocity[3];
	entity_get_vector(victim, EV_VEC_velocity, velocity);
	
	xs_vec_mul_scalar(direction, damage, direction);
	
	static Float:kb_cvar;
	
	//kb_duck = entity_get_int(victim, EV_INT_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND);
	
	if(get_pcvar_float(g_cvar_weapon[31][WEAPON_KNOCKBACK]) == 0.00) kb_cvar = get_pcvar_float(g_cvar_weapon[g_weapon[attacker]][WEAPON_KNOCKBACK]);
	else kb_cvar = get_pcvar_float(g_cvar_weapon[31][WEAPON_KNOCKBACK]);
	
	if(kb_cvar > 0.00)
		xs_vec_mul_scalar(direction, kb_cvar, direction);

	if(g_isImmune[victim])
		xs_vec_mul_scalar(direction, 0.0, direction);
	
	if(is_user_nemesis(victim))
		xs_vec_mul_scalar(direction, 0.1, direction);
	
	xs_vec_add(velocity, direction, direction);
	
	if(!get_pcvar_num(g_cvar_knockback_zvel))
		direction[2] = velocity[2];
	
	entity_set_vector(victim, EV_VEC_velocity, direction);
	
	return HAM_IGNORED;
}

public fw_AddPlayerItem(id, weapon_ent)
{
	static extra_ammo;
	extra_ammo = entity_get_int(weapon_ent, EV_INT_iuser1);
	
	if(extra_ammo)
	{
		static weaponid;
		weaponid = cs_get_weapon_id(weapon_ent);
		
		ExecuteHamB(Ham_GiveAmmo, id, extra_ammo, g_ammo_type[weaponid], g_max_bpammo[weaponid]);
		entity_set_int(weapon_ent, EV_INT_iuser1, 0);
	}
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == OFFSET_USE_STOPPED && is_user_valid_connected(caller))
	{
		fm_remove_model_ents(caller);
		fn_replace_weapon_models(caller, g_weapon[caller]);
	}
}

public fw_Item_Deploy_Post(weapon_ent)
{
	if(!pev_valid(weapon_ent))
		return;
	
	static id;
	id = fm_get_weapon_ent_owner(weapon_ent);
	
	if(!pev_valid(id))
		return;
	
	fm_remove_model_ents(id);
	
	static weaponid;
	weaponid = cs_get_weapon_id(weapon_ent);
	
	if(weaponid != CSW_C4 && 
	weaponid != CSW_SHIELD &&
	weaponid != CSW_HEGRENADE &&
	weaponid != CSW_FLASHBANG &&
	weaponid != CSW_SMOKEGRENADE)
		g_weapon[id] = weaponid;
	
	// Replace Weapon Models
	fn_replace_weapon_models(id, weaponid);
}

public fw_Weapon_PrimaryAttack_Post(weapon_ent) // Recoil , Speed and Auto Fire Pistol
{
	if(!pev_valid(weapon_ent))
		return HAM_IGNORED;
	
	static id;
	id = fm_get_weapon_ent_owner(weapon_ent);
	
	if(!pev_valid(id) || cs_get_weapon_ammo(weapon_ent) < 1)
		return HAM_IGNORED;
	
	// Recoil
	static Float:def_recoil[3];
	entity_get_vector(id, EV_VEC_punchangle, def_recoil);
	
	static recoil_cvar[10];
	static recoil_cvar_k[10];
	static recoil_cvar_temp[10];
	static recoil_cvar_temp_k[10];
	
	get_pcvar_string(g_cvar_weapon[g_weapon[id]][WEAPON_RECOIL], recoil_cvar, charsmax(recoil_cvar));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_RECOIL], recoil_cvar_temp, charsmax(recoil_cvar_temp));
	
	copy(recoil_cvar_k, charsmax(recoil_cvar_k), recoil_cvar);
	copy(recoil_cvar_temp_k, charsmax(recoil_cvar_temp_k), recoil_cvar_temp);
	
	if(fn_contain_words(recoil_cvar_k) || fn_contain_words(recoil_cvar_temp_k))
	{
		fn_replace_words(recoil_cvar_k, charsmax(recoil_cvar_k));
		fn_replace_words(recoil_cvar_temp_k, charsmax(recoil_cvar_temp_k));
		
		static Float:recoil;
		
		if(equali(recoil_cvar_temp, "off")) recoil = str_to_float(recoil_cvar_k);
		else recoil = str_to_float(recoil_cvar_temp_k);
		
		switch((equali(recoil_cvar_temp, "off")) ? recoil_cvar[0] : recoil_cvar_temp[0])
		{
			case '+':
			{
				if(recoil == 0.00) return HAM_IGNORED;
				def_recoil[0] += recoil;
			}
			case '-':
			{
				if(recoil == 0.00) return HAM_IGNORED;
				def_recoil[0] -= recoil;
			}
			case '*':
			{
				if(recoil == 1.00) return HAM_IGNORED;
				def_recoil[0] *= recoil;
			}
			case '/':
			{
				if(recoil == 0.00) return HAM_IGNORED; // Can't divide by 0
				def_recoil[0] /= recoil;
			}
			case '=':
			{
				def_recoil[0] = recoil;
				if(recoil == 0)
					def_recoil[1] = def_recoil[2] = recoil;
			}
		}
		
		entity_set_vector(id, EV_VEC_punchangle, def_recoil);
	}
	
	// Speed
	static Float:def_speed[3];
	def_speed[0] = get_pdata_float(weapon_ent, OFFSET_NEXT_PRIMARY_ATTACK, OFFSET_LINUX_WEAPONS);
	def_speed[1] = get_pdata_float(weapon_ent, OFFSET_NEXT_SECONDARY_ATTACK, OFFSET_LINUX_WEAPONS);
	def_speed[2] = get_pdata_float(weapon_ent, OFFSET_TIME_WEAPON_IDLE, OFFSET_LINUX_WEAPONS);
	
	static speed_cvar[10];
	static speed_cvar_k[10];
	static speed_cvar_temp[10];
	static speed_cvar_temp_k[10];
	
	get_pcvar_string(g_cvar_weapon[g_weapon[id]][WEAPON_SPEED], speed_cvar, charsmax(speed_cvar));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_SPEED], speed_cvar_temp, charsmax(speed_cvar_temp));
	
	copy(speed_cvar_k, charsmax(speed_cvar_k), speed_cvar);
	copy(speed_cvar_temp_k, charsmax(speed_cvar_temp_k), speed_cvar_temp);
	
	if(fn_contain_words(speed_cvar_k) || fn_contain_words(speed_cvar_temp_k))
	{
		fn_replace_words(speed_cvar_k, charsmax(speed_cvar_k));
		fn_replace_words(speed_cvar_temp_k, charsmax(speed_cvar_temp_k));
		
		static Float:speed;
		
		if(equali(speed_cvar_temp, "off")) speed = str_to_float(speed_cvar_k);
		else speed = str_to_float(speed_cvar_temp_k);
		
		switch((equali(speed_cvar_temp, "off")) ? speed_cvar[0] : speed_cvar_temp[0])
		{
			case '+':
			{
				if(speed == 0.00) return HAM_IGNORED;
				def_speed[0] += speed;
				def_speed[1] += speed;
				def_speed[2] += speed;
			}
			case '-':
			{
				if(speed == 0.00) return HAM_IGNORED;
				def_speed[0] -= speed;
				def_speed[1] -= speed;
				def_speed[2] -= speed;
			}
			case '*':
			{
				if(speed == 1.00) return HAM_IGNORED;
				def_speed[0] *= speed;
				def_speed[1] *= speed;
				def_speed[2] *= speed;
			}
			case '/':
			{
				if(speed == 0.00) return HAM_IGNORED; // Can't divide by 0
				def_speed[0] /= speed;
				def_speed[1] /= speed;
				def_speed[2] /= speed;
			}
			case '=': def_speed[0] = def_speed[1] = def_speed[2] = speed;
		}
		
		set_pdata_float(weapon_ent, OFFSET_NEXT_PRIMARY_ATTACK, def_speed[0], OFFSET_LINUX_WEAPONS)
		set_pdata_float(weapon_ent, OFFSET_NEXT_SECONDARY_ATTACK, def_speed[1], OFFSET_LINUX_WEAPONS)
		set_pdata_float(weapon_ent, OFFSET_TIME_WEAPON_IDLE, def_speed[2], OFFSET_LINUX_WEAPONS)
	}
	
	// Auto Fire Pistol
	if((1 << g_weapon[id]) & SECONDARY_WEAPONS_BIT_SUM)
	{
		static autofire_cvar;
		
		if(!get_pcvar_num(g_cvar_weapon[31][WEAPON_AUTO_FIRE])) autofire_cvar = get_pcvar_num(g_cvar_weapon[g_weapon[id]][WEAPON_AUTO_FIRE]);
		else autofire_cvar = 1;
		
		g_has_ammo[id] = autofire_cvar;
	}
	
	return HAM_IGNORED;
}

public fw_Item_PostFrame(weapon_ent)
{
	if(!pev_valid(weapon_ent))
		return HAM_IGNORED;
	
	static id;
	id = fm_get_weapon_ent_owner(weapon_ent);
	
	if(!pev_valid(id))
		return HAM_IGNORED;
	
	static button;
	button = entity_get_int(id, EV_INT_button);
	
	if(button & IN_ATTACK2)
	{
		static zoom_cvar[32];
		static zoom_delay[9];
		static zoom_speed[1]; // not interesting here
		static zoom_1[3];
		static zoom_2[3];
		static Float:f_zoom_delay;
		static i_zoom_1;
		static i_zoom_2;
		
		get_pcvar_string(g_cvar_weapon[31][WEAPON_ZOOM], zoom_cvar, charsmax(zoom_cvar));
		
		if(equali(zoom_cvar, "off"))
		{
			get_pcvar_string(g_cvar_weapon[g_weapon[id]][WEAPON_ZOOM], zoom_cvar, charsmax(zoom_cvar));
		
			if(equali(zoom_cvar, "off"))
				return HAM_IGNORED;
		}
		
		parse(zoom_cvar, zoom_delay, charsmax(zoom_delay), zoom_speed, charsmax(zoom_speed), zoom_1, charsmax(zoom_1), zoom_2, charsmax(zoom_2));
		
		f_zoom_delay = str_to_float(zoom_delay);
		i_zoom_1 = clamp(str_to_num(zoom_1), 0, 255);
		i_zoom_2 = clamp(str_to_num(zoom_2), 0, 255);
		
		static fov;
		fov = get_pdata_int(id, OFFSET_FOV, OFFSET_LINUX);
		
		if(fov == 90) fn_SetFov(id, i_zoom_1);
		else if(fov == i_zoom_1) fn_SetFov(id, i_zoom_2);
		else fn_SetFov(id, 90);
		
		ExecuteHamB(Ham_Item_PreFrame, id);
		
		emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);
		set_pdata_float(id, OFFSET_NEXT_ATTACK, f_zoom_delay, OFFSET_LINUX);
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public fw_Item_Holster(weapon_ent)
{
	if(pev_valid(weapon_ent))
	{
		if(ExecuteHamB(Ham_Item_CanHolster, weapon_ent))
			fn_ResetFov(fm_get_weapon_ent_owner(weapon_ent));
	}
}

public fw_CS_Item_GetMaxSpeed(weapon_ent)
{
	if(!pev_valid(weapon_ent))
		return HAM_IGNORED;
	
	static id;
	id = fm_get_weapon_ent_owner(weapon_ent);
	
	if(!pev_valid(id))
		return HAM_IGNORED;
	
	if(get_pdata_int(id, OFFSET_FOV, OFFSET_LINUX) == 90)
		return HAM_IGNORED;
	
	static zoom_cvar[32];
	static zoom_delay[1]; // not interesting here
	static zoom_speed[9];
	static zoom_1[1]; // not interesting here
	static zoom_2[1]; // not interesting here
	static Float:f_zoom_speed;
	
	get_pcvar_string(g_cvar_weapon[31][WEAPON_ZOOM], zoom_cvar, charsmax(zoom_cvar));
	
	if(equali(zoom_cvar, "off"))
	{
		get_pcvar_string(g_cvar_weapon[g_weapon[id]][WEAPON_ZOOM], zoom_cvar, charsmax(zoom_cvar));
	
		if(equali(zoom_cvar, "off"))
			return HAM_IGNORED;
	}
	
	parse(zoom_cvar, zoom_delay, charsmax(zoom_delay), zoom_speed, charsmax(zoom_speed), zoom_1, charsmax(zoom_1), zoom_2, charsmax(zoom_2));
	f_zoom_speed = str_to_float(zoom_speed);

	static Float:f_MaxSpeed;
	f_MaxSpeed = f_zoom_speed;
	
	if(f_MaxSpeed > 0.00)
	{
		SetHamReturnFloat(f_MaxSpeed);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_Weapon_Reload_Post(weapon_ent)
{
	if(pev_valid(weapon_ent))
	{
		if(get_pdata_int(weapon_ent, OFFSET_IN_RELOAD, OFFSET_LINUX_WEAPONS))
			fn_ResetFov(fm_get_weapon_ent_owner(weapon_ent))
	}
}

public fw_Weapon_Shotgun_Reload_Post(weapon_ent)
{
	if(pev_valid(weapon_ent))
	{
		if(get_pdata_int(weapon_ent, OFFSET_IN_SPECIAL_RELOAD, OFFSET_LINUX_WEAPONS) == 1)
			fn_ResetFov(fm_get_weapon_ent_owner(weapon_ent))
	}
}

fn_SetFov(id, fov)
{
	entity_set_float(id, EV_FL_fov, float(fov));
	set_pdata_int(id, OFFSET_FOV, fov, OFFSET_LINUX);
}

fn_ResetFov(id)
{
	if(0 <= get_pdata_int(id, OFFSET_FOV, OFFSET_LINUX) <= 90)
	{
		entity_set_float(id, EV_FL_fov, 90.0);
		set_pdata_int(id, OFFSET_FOV, 90, OFFSET_LINUX);
	}
}

public fw_SetModel(entity, const model[])
{
	if(strlen(model) < 8 || model[7] != 'w' || model[8] != '_')
		return FMRES_IGNORED;
	
	static classname[10];
	static color_all[21];
	
	entity_get_string(entity, EV_SZ_classname, classname, charsmax(classname));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_W_GLOW], color_all, charsmax(color_all));
	
	if(equal(classname, "weaponbox") ||
	TrieKeyExists(g_trie_wmodel, model))
	{
		static i;
		static color[21];
		static p_rgb[3][4];
		static i_rgb[3];
		
		for(i = 0; i < CSW_P90+2; i++)
		{
			if(equali(model, g_model_default[i]))
			{
				get_pcvar_string(g_cvar_weapon[i][WEAPON_W_GLOW], color, charsmax(color));
				if(!equali(color, "off") || !equali(color_all, "off"))
				{
					if(equali(color_all, "off")) parse(color, p_rgb[0], charsmax(p_rgb[]), p_rgb[1], charsmax(p_rgb[]), p_rgb[2], charsmax(p_rgb[]));
					else parse(color_all, p_rgb[0], charsmax(p_rgb[]), p_rgb[1], charsmax(p_rgb[]), p_rgb[2], charsmax(p_rgb[]));
					
					i_rgb[0] = clamp(str_to_num(p_rgb[0]), 0, 255);
					i_rgb[1] = clamp(str_to_num(p_rgb[1]), 0, 255);
					i_rgb[2] = clamp(str_to_num(p_rgb[2]), 0, 255);
					
					fm_set_rendering(entity, kRenderFxGlowShell, i_rgb[0], i_rgb[1], i_rgb[2], kRenderNormal, 16);
				}
				
				if(g_model_weapon[W_][i][0])
				{
					entity_set_model(entity, g_model_weapon[W_][i]);
					return FMRES_SUPERCEDE;
				}
			}
		}
		
		return FMRES_IGNORED;
	}
	
	static Float:dmg_time;
	dmg_time = entity_get_float(entity, EV_FL_dmgtime);
	
	if(dmg_time == 0.0)
		return FMRES_IGNORED;
	
	static pg_rgb[3][3][4];
	static ig_rgb[3][3];
	if(equali(color_all, "off"))
	{
		static color_grenades[3][21];
		
		get_pcvar_string(g_cvar_weapon[CSW_HEGRENADE][WEAPON_W_GLOW], color_grenades[0], charsmax(color_grenades[]));
		get_pcvar_string(g_cvar_weapon[CSW_FLASHBANG][WEAPON_W_GLOW], color_grenades[1], charsmax(color_grenades[]));
		get_pcvar_string(g_cvar_weapon[CSW_SMOKEGRENADE][WEAPON_W_GLOW], color_grenades[2], charsmax(color_grenades[]));
		
		if(!equali(color_grenades[0], "off"))
		{
			parse(color_grenades[0], pg_rgb[0][0], charsmax(pg_rgb[][]), pg_rgb[1][0], charsmax(pg_rgb[][]), pg_rgb[2][0], charsmax(pg_rgb[][]));
			
			ig_rgb[0][0] = clamp(str_to_num(pg_rgb[0][0]), 0, 255);
			ig_rgb[1][0] = clamp(str_to_num(pg_rgb[1][0]), 0, 255);
			ig_rgb[2][0] = clamp(str_to_num(pg_rgb[2][0]), 0, 255);
		}
		if(!equali(color_grenades[1], "off"))
		{
			parse(color_grenades[1], pg_rgb[0][1], charsmax(pg_rgb[][]), pg_rgb[1][1], charsmax(pg_rgb[][]), pg_rgb[2][1], charsmax(pg_rgb[][]));
			
			ig_rgb[0][1] = clamp(str_to_num(pg_rgb[0][1]), 0, 255);
			ig_rgb[1][1] = clamp(str_to_num(pg_rgb[1][1]), 0, 255);
			ig_rgb[2][1] = clamp(str_to_num(pg_rgb[2][1]), 0, 255);
		}
		if(!equali(color_grenades[2], "off"))
		{
			parse(color_grenades[2], pg_rgb[0][2], charsmax(pg_rgb[][]), pg_rgb[1][2], charsmax(pg_rgb[][]), pg_rgb[2][2], charsmax(pg_rgb[][]));
			
			ig_rgb[0][2] = clamp(str_to_num(pg_rgb[0][2]), 0, 255);
			ig_rgb[1][2] = clamp(str_to_num(pg_rgb[1][2]), 0, 255);
			ig_rgb[2][2] = clamp(str_to_num(pg_rgb[2][2]), 0, 255);
		}
	}
	else
	{
		parse(color_all, pg_rgb[0][0], charsmax(pg_rgb[][]), pg_rgb[1][0], charsmax(pg_rgb[][]), pg_rgb[2][0], charsmax(pg_rgb[][]));
		
		ig_rgb[0][0] = ig_rgb[0][1] = ig_rgb[0][2] = clamp(str_to_num(pg_rgb[0][0]), 0, 255);
		ig_rgb[1][0] = ig_rgb[1][1] = ig_rgb[1][2] = clamp(str_to_num(pg_rgb[1][0]), 0, 255);
		ig_rgb[2][0] = ig_rgb[2][1] = ig_rgb[2][2] = clamp(str_to_num(pg_rgb[2][0]), 0, 255);
	}
	
	if(model[9] == 'h' && model[10] == 'e') // HE Grenade
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, ig_rgb[0][0], ig_rgb[1][0], ig_rgb[2][0], kRenderNormal, 16);
		
		// Change Model
		if(g_model_weapon[W_][CSW_HEGRENADE][0])
		{
			entity_set_model(entity, g_model_weapon[W_][CSW_HEGRENADE]);
			return FMRES_SUPERCEDE;
		}
	}
	else if(model[9] == 'f' && model[10] == 'l') // Flash Grenade
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, ig_rgb[0][1], ig_rgb[1][1], ig_rgb[2][1], kRenderNormal, 16);
		
		// Change Model
		if(g_model_weapon[W_][CSW_FLASHBANG][0])
		{
			entity_set_model(entity, g_model_weapon[W_][CSW_FLASHBANG]);
			return FMRES_SUPERCEDE;
		}
	}
	else if(model[9] == 's' && model[10] == 'm') // Smoke Grenade
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, ig_rgb[0][2], ig_rgb[1][2], ig_rgb[2][2], kRenderNormal, 16);
		
		// Change Model
		if(g_model_weapon[W_][CSW_SMOKEGRENADE][0])
		{
			entity_set_model(entity, g_model_weapon[W_][CSW_SMOKEGRENADE]);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_valid_connected(id))
		return FMRES_IGNORED;
	
	new i;
	for(i = 0; i < sizeof(g_sound_knife_default); i++)
	{
		if(equal(sample, g_sound_knife_default[i]) && g_sound_weapon[i][0])
		{
			emit_sound(id, channel, g_sound_weapon[i], volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id, handle)
{
	if(!is_user_alive(id))
		return;
	
	if((1 << g_weapon[id]) & SECONDARY_WEAPONS_BIT_SUM)
	{
		static autofire_cvar;
		
		if(!get_pcvar_num(g_cvar_weapon[31][WEAPON_AUTO_FIRE])) autofire_cvar = get_pcvar_num(g_cvar_weapon[g_weapon[id]][WEAPON_AUTO_FIRE]);
		else autofire_cvar = 1;
		
		if(autofire_cvar)
		{
			static button;
			button = get_uc(handle, UC_Buttons);
			
			if((button & IN_ATTACK) && g_has_ammo[id])
			{
				set_uc(handle, UC_Buttons, button & ~IN_ATTACK);
				g_has_ammo[id] = 0;
			}
		}
	}
}

public message_CurWeapon(msg_id, msg_dest, msg_entity)
{
	if(!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static clip_cvar[10];
	static clip_cvar_temp[10];
	static clip_cvar_int;
	static mode;
	static weapon;
	
	mode = 0;
	weapon = get_msg_arg_int(2);
	
	get_pcvar_string(g_cvar_weapon[g_weapon[msg_entity]][WEAPON_UNLIMITED_CLIP], clip_cvar, charsmax(clip_cvar));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_UNLIMITED_CLIP], clip_cvar_temp, charsmax(clip_cvar_temp));
	
	clip_cvar_int = str_to_num(clip_cvar);
	
	if(!equali(clip_cvar_temp, "off") || clip_cvar_int)
		mode = 1;
	
	if(!mode)
		return;
	
	if(g_max_bpammo[weapon] > 2)
	{
		static weapon_ent;
		weapon_ent = get_pdata_cbase(msg_entity, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
		
		if(pev_valid(weapon_ent))
			cs_set_weapon_ammo(weapon_ent, g_max_clip[weapon])
		
		set_msg_arg_int(3, get_msg_argtype(3), g_max_clip[weapon]);
	}
}

// Functions
fn_contain_words(const string[])
{
	if(contain(string, "+") != -1 ||
	contain(string, "-") != -1 ||
	contain(string, "*") != -1 ||
	contain(string, "/") != -1 ||
	contain(string, "=") != -1)
		return 1;
	
	return 0;
}
fn_replace_words(string[], len)
{
	replace(string, len, "+", "");
	replace(string, len, "-", "");
	replace(string, len, "*", "");
	replace(string, len, "/", "");
	replace(string, len, "=", "");
}
fn_load_customization()
{
	new path[64];
	get_configsdir(path, charsmax(path));
	
	format(path, charsmax(path), "%s/%s", path, g_customization_file_ini);
	
	if(!file_exists(path)) return;
	
	new linedata[1024];
	new key[64];
	new value[960];
	new weaponname[32];
	new file = fopen(path, "rt");
	new i;
	new const soundname[][] = {
		"KNIFE_DEPLOY",
		"KNIFE_HIT_1",
		"KNIFE_HIT_2",
		"KNIFE_HIT_3",
		"KNIFE_HIT_4",
		"KNIFE_HIT_WALL",
		"KNIFE_SLASH_1",
		"KNIFE_SLASH_2",
		"KNIFE_STAB"
	}
	
	while(file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		replace(linedata, charsmax(linedata), "^n", "");
		
		if(!linedata[0] || linedata[0] == ';') continue;
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		// Models
		for(i = 0; i < CSW_P90+2; i++)
		{
			if(g_weapon_ent_names_all[i][0])
			{
				// Remove weapon_ from the names
				copy(weaponname, charsmax(weaponname), g_weapon_ent_names_all[i]);
				
				// Get and precache V_ model
				replace(weaponname, charsmax(weaponname), "weapon_", "V_");
				if(!equali(g_weapon_ent_names_all[i], "weapon_thighpack"))
				{
					if(equali(key, weaponname)) copy(g_model_weapon[V_][i], charsmax(g_model_weapon[][]), value);
					if(g_model_weapon[V_][i][0]) precache_model(g_model_weapon[V_][i]);
				}
				
				// Get and precache P_ model
				replace(weaponname, charsmax(weaponname), "V_", "P_");
				if(equali(key, weaponname)) copy(g_model_weapon[P_][i], charsmax(g_model_weapon[][]), value);
				if(g_model_weapon[P_][i][0]) precache_model(g_model_weapon[P_][i]);
				
				// Get and precache W_ model
				replace(weaponname, charsmax(weaponname), "P_", "W_");
				if(equali(key, weaponname)) copy(g_model_weapon[W_][i], charsmax(g_model_weapon[][]), value);
				if(g_model_weapon[W_][i][0]) precache_model(g_model_weapon[W_][i]);
			}
		}
		
		// Knife Sounds
		for(i = 0; i < sizeof(g_sound_knife_default); i++)
		{
			if(equali(key, soundname[i])) copy(g_sound_weapon[i], charsmax(g_sound_weapon[]), value);
			if(g_sound_weapon[i][0]) precache_model(g_sound_weapon[i]);
		}
	}
	
	if(file)
		fclose(file);
}
fn_replace_weapon_models(id, weaponid)
{
	if(!is_user_alive(id))
		return;
	
	if(g_model_weapon[V_][weaponid][0]) entity_set_string(id, EV_SZ_viewmodel, g_model_weapon[V_][weaponid]);
	if(g_model_weapon[P_][weaponid][0]) entity_set_string(id, EV_SZ_weaponmodel, g_model_weapon[P_][weaponid]);
	
	new color[21];
	new color_all[21];
	
	get_pcvar_string(g_cvar_weapon[weaponid][WEAPON_P_GLOW], color, charsmax(color));
	get_pcvar_string(g_cvar_weapon[31][WEAPON_P_GLOW], color_all, charsmax(color_all));
	
	if(!equali(color, "off") || !equali(color_all, "off"))
	{
		new p_rgb[3][4];
		new i_rgb[3];
		
		if(equali(color_all, "off")) parse(color, p_rgb[0], charsmax(p_rgb[]), p_rgb[1], charsmax(p_rgb[]), p_rgb[2], charsmax(p_rgb[]));
		else parse(color_all, p_rgb[0], charsmax(p_rgb[]), p_rgb[1], charsmax(p_rgb[]), p_rgb[2], charsmax(p_rgb[]));
		
		i_rgb[0] = clamp(str_to_num(p_rgb[0]), 0, 255);
		i_rgb[1] = clamp(str_to_num(p_rgb[1]), 0, 255);
		i_rgb[2] = clamp(str_to_num(p_rgb[2]), 0, 255);
		
		fm_set_weaponmodel_ent(id, i_rgb[0], i_rgb[1], i_rgb[2]);
	}
}
public fn_refill_bpammo(const args[], id)
{
	if(!is_user_alive(id))
		return;
	
	set_msg_block(g_msg_ammopickup, BLOCK_ONCE);
	ExecuteHamB(Ham_GiveAmmo, id, g_max_bpammo[args[0]], g_ammo_type[args[0]], g_max_bpammo[args[0]]);
}

// Stocks
stock fm_set_weaponmodel_ent(id, red = -1, green = -1, blue = -1) // Thanks MeRcyLeZZ for the stock!
{
	static model[128];
	entity_get_string(id, EV_SZ_weaponmodel, model, charsmax(model));
	
	if(!pev_valid(g_ent_weaponmodel[id]))
	{
		g_ent_weaponmodel[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		if(!pev_valid(g_ent_weaponmodel[id])) return;
		
		entity_set_string(g_ent_weaponmodel[id], EV_SZ_classname, "weapon_model");
		entity_set_int(g_ent_weaponmodel[id], EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(g_ent_weaponmodel[id], EV_ENT_aiment, id);
		entity_set_edict(g_ent_weaponmodel[id], EV_ENT_owner, id);
		
		if(red != -1 || green != -1 || blue != -1)
			fm_set_rendering(g_ent_weaponmodel[id], kRenderFxGlowShell, red, green, blue, kRenderNormal, 16);
	}
	
	engfunc(EngFunc_SetModel, g_ent_weaponmodel[id], model);
}
stock fm_remove_model_ents(id) // Thanks MeRcyLeZZ for the stock!
{
	if(pev_valid(g_ent_weaponmodel[id]))
	{
		remove_entity(g_ent_weaponmodel[id]);
		g_ent_weaponmodel[id] = 0;
	}
}
stock cs_weapon_name_to_id(const weapon[]) // Simplified get_weaponid (CS only) -- Thanks MeRcyLeZZ for the stock!
{
	static i;
	for(i = 0; i < sizeof(g_weapon_ent_names) - 1; i++)
	{
		if(equal(weapon, g_weapon_ent_names[i]))
			return i;
	}
	
	return 0;
}
stock fm_get_weapon_ent_owner(ent)
{
	if(pev_valid(ent) != OFFSET_PDATA)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, OFFSET_LINUX_WEAPONS);
}