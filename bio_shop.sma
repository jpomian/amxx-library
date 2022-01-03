#include <amxmodx>
#include <colorchat>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <Achievements>
#include <biohazard>

native give_user_napalmnade(id)
	native give_user_knockbackimmunity(id, Float:time)
	native get_user_zombiemadness(id)
	native respawn_zombie(id)
	
#define PLUGIN "Sklep Ghost"
#define VERSION "0.2"
#define AUTHOR "Mixtaz"

#define is_vip(%1) get_user_flags(%1) & ADMIN_LEVEL_H
#define is_vip_plus(%1) get_user_flags(%1) & ADMIN_LEVEL_G
#define ReductionCalcMethod(%1) GetUnlocksCount(%1)-g_handleThreshold
#define ItemRegister(%1,%2,%3) formatex(%1, charsmax(%1), "%s \r [\y%i $\r]", %2, %3-((%3/100)*g_priceReduction[id]))

#define OFFSET_NVGOGGLES    129
#define HAS_NVGS (1<<0)
#define USES_NVGS (1<<8)

new gmsgNVGToggle

new bool: unAmmo[33];
new g_perkUsed[33];
new g_priceReduction[33];

new const g_handleThreshold = 5;
new const g_vipBonus = 10;

enum (+=1) {
	VIP_UNLIMITED_LIMIT = 1,
	VIPPLUS_UNLIMITED_LIMIT
}

new times_used[33], maxgraczy;

enum ItemInfo { _Opis[50], _Cena }

new const ItemyTT[][ItemInfo] = {
	{ "+500 HP",	3000 },
	{ "Respawn",	5000} ,
	{ "Ciezka Dupa", 10000 },
	{ "Szalone Zombie", 12000 },
	{ "Antidotum", 16000 }
}
new const ItemyCT[][ItemInfo] = {
	{ "HE", 5000 },
	{ "Zamrazacz", 5000 },
	{ "Podpalacz", 5000 },
	{ "Flara", 1000 },
	{ "Noktowizor", 2000},
	{ "Autokampa", 16000 },
	{ "Nieskonczona amunicja [VIP]", 16000 }
} 

new const SklepCommands[][] =
{
"say /sklep",
"say_team /sklep",
"say /buy",
"say_team /buy"
}

new const g_shopgreetings[] = "zombie/powitanie.wav"
new const g_hardscream[] = "zombie/ciezka.wav"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	for(new i=0; i < sizeof SklepCommands; i++)
		register_clcmd(SklepCommands[i], "cmdPodzial")
	
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1);
	register_logevent("Poczatek_Rundy", 2, "1=Round_Start")
	register_event("CurWeapon", "UnlimitedAmmo", "be", "1=1")

	maxgraczy=get_maxplayers()
}
public plugin_precache()
{
	precache_sound(g_shopgreetings);
	precache_sound(g_hardscream);
}
public client_connect(id)
{
	if(is_user_connected(id) && !is_user_hltv(id)){
		unAmmo[id] = false;
		g_perkUsed[id] = false;
	}
}
public client_authorized(id)
{
	g_priceReduction[id] = is_vip(id) ? ReductionCalcMethod(id) + g_vipBonus : ReductionCalcMethod(id) < 0 ? 0 : ReductionCalcMethod(id)
}
public client_disconnected(id)
{
	unAmmo[id] = false;
	g_perkUsed[id] = false;
}
public Poczatek_Rundy() for(new i=1; i<maxgraczy;i++) times_used[i]=0;
public cmdPodzial(id)
{
	client_cmd(id,"spk %s", g_shopgreetings)
	
	if(is_user_zombie(id))
		SklepTT(id)
	else
		SklepCT(id)

	if(GetUnlocksCount(id) < 10)
			ColorChat(id, GREEN, "[Sklep]^x01 10 pierwszych osiagniec nie daje znizki.")
	
	return PLUGIN_HANDLED;
}
public SklepTT(id)
{
	
	g_priceReduction[id] = is_vip(id) ? ReductionCalcMethod(id) + g_vipBonus : ReductionCalcMethod(id) < 0 ? 0 : ReductionCalcMethod(id)
	
	new tytulTT[60], hTT;
	new itemStrBufferTT[50]
	new numer1[10]
	formatex(tytulTT, charsmax(tytulTT), "Sklep Zombie - Znizka\r [%i %%]\d %s", g_priceReduction[id], is_vip(id) ? "(Dodatkowa znizka VIP)" : "");
	new menuTT = menu_create(tytulTT, "SklepTT_Handler");

	hTT = menu_makecallback("TTShop_Callback");
	
	ItemRegister(itemStrBufferTT, ItemyTT[0][_Opis], ItemyTT[0][_Cena])
	menu_additem(menuTT, itemStrBufferTT, numer1, _, hTT)

	for(new i = 1; i < sizeof(ItemyTT); i++) {
		num_to_str(i, numer1, 9)
		ItemRegister(itemStrBufferTT, ItemyTT[i][_Opis], ItemyTT[i][_Cena])
		menu_additem(menuTT, itemStrBufferTT, numer1)
	}

	menu_setprop(menuTT, MPROP_EXIT, 0);
	menu_display(id, menuTT);
	
	return PLUGIN_HANDLED
}
public TTShop_Callback(id, hMenu, iItem)
{
	if(iItem == 0) return times_used[id] >= 3 ? ITEM_DISABLED : ITEM_ENABLED;

	return ITEM_ENABLED;		
}
public SklepTT_Handler(id, menuTT, item)
{
	if(is_user_zombie(id) && is_user_connected(id)){
		new money = cs_get_user_money(id)
		g_priceReduction[id] = is_vip(id) ? ReductionCalcMethod(id) + g_vipBonus : ReductionCalcMethod(id) < 0 ? 0 : ReductionCalcMethod(id)
		
		set_dhudmessage(222, 46, 24, -1.0, 0.3, 1, 0.02, 1.0, 0.01, 0.1);
		
		if(item == MENU_EXIT)
		{
			return PLUGIN_CONTINUE;
		}
		switch(item)
		{
			case 0:
			{
				if(is_user_alive(id) && money >= ItemyTT[0][_Cena]-((ItemyTT[0][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyTT[0][_Cena]-((ItemyTT[0][_Cena]/100)*g_priceReduction[id]))
					set_user_health(id, get_user_health(id) + 500)
					times_used[id]++
					show_dhudmessage(id, "Zakupiono %s", ItemyTT[0][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyTT[0][_Cena]-((ItemyTT[0][_Cena]/100)*g_priceReduction[id]) - money, ItemyTT[0][_Opis])
				}
			}
			case 1:
			{
				if(!is_user_alive(id)){
					if(money >= ItemyTT[1][_Cena]-((ItemyTT[1][_Cena]/100)*g_priceReduction[id])){
						Reduce(id, ItemyTT[1][_Cena]-((ItemyTT[1][_Cena]/100)*g_priceReduction[id]))
						respawn_zombie(id)
						show_dhudmessage(id, "Zakupiono %s", ItemyTT[1][_Opis]);  
						} else {
						ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyTT[1][_Cena]-((ItemyTT[1][_Cena]/100)*g_priceReduction[id]) - money, ItemyTT[1][_Opis])
					}
				} else
				ColorChat(id, GREEN, "[Sklep]^x01 Jestes zywy, nie mozesz kupic respawnu.")
			}
			case 2:
			{
				if(is_user_alive(id) && money >= ItemyTT[2][_Cena]-((ItemyTT[2][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyTT[2][_Cena]-((ItemyTT[2][_Cena]/100)*g_priceReduction[id]))
					give_user_knockbackimmunity(id, 5.0)
					give_efekty(id)
					show_dhudmessage(id, "Zakupiono %s", ItemyTT[2][_Opis]);
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyTT[2][_Cena]-((ItemyTT[2][_Cena]/100)*g_priceReduction[id]) - money, ItemyTT[2][_Opis])
				}
			}
			case 3:
			{
				if(is_user_alive(id) && money >= ItemyTT[3][_Cena]-((ItemyTT[3][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyTT[3][_Cena]-((ItemyTT[3][_Cena]/100)*g_priceReduction[id]))
					give_user_knockbackimmunity(id, 5.0)
					get_user_zombiemadness(id)
					show_dhudmessage(id, "Zakupiono %s", ItemyTT[3][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyTT[3][_Cena]-((ItemyTT[3][_Cena]/100)*g_priceReduction[id]) - money, ItemyTT[3][_Opis])
				}
			}
			case 4:
			{
				if(is_user_alive(id) && money >= ItemyTT[4][_Cena]-((ItemyTT[4][_Cena]/100)*g_priceReduction[id])){
					check_prerequisities(id)
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyTT[4][_Cena]-((ItemyTT[4][_Cena]/100)*g_priceReduction[id]) - money, ItemyTT[4][_Opis])
				}
			}
		}
	} else
	return PLUGIN_CONTINUE;
	
	return PLUGIN_CONTINUE;
}
public give_efekty(id)
{
	new origin[3]
	get_user_origin(id, origin)

	emit_sound( id, CHAN_VOICE, g_hardscream, 1.0, ATTN_NORM, 0, PITCH_NORM )
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_PARTICLEBURST) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
	
}
public check_prerequisities(id)
{    
	new ts[32], tsnum
	new maxplayers = get_maxplayers()
	new CsTeams:team
	
	for (new i=1; i<=maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
		{
			continue
		}
		team = cs_get_user_team(i)
		
		if (team == CS_TEAM_T)
		{
			ts[tsnum++] = i
		}
	}
	
	/* Check user last zombie */
	if (tsnum == 1)
	{
		ColorChat(id, GREEN, "[Sklep]^x01 Jestes ostatnim zombie.")
		return PLUGIN_HANDLED
	}

	if(is_user_firstzombie(id))
	{
		ColorChat(id, GREEN, "[Sklep]^x01 Jestes matka zombie.")
		return PLUGIN_HANDLED
	}
	
	/* Check user alive */
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	/* Check user zombie */
	if(!is_user_zombie(id))
		return PLUGIN_HANDLED
	
	/* Set user to survivor */
	Reduce(id, ItemyTT[4][_Cena]-((ItemyTT[4][_Cena]/100)*g_priceReduction[id]))
	set_dhudmessage(0, 0, 220, -1.0, 0.3, 1, 0.02, 1.0, 0.01, 0.1);  
	show_dhudmessage(id, "Zakupiono Antidotum")
	set_user_human(id)
	
	return PLUGIN_HANDLED
}
public SklepCT(id)
{
	g_priceReduction[id] = is_vip(id) ? ReductionCalcMethod(id) + g_vipBonus : ReductionCalcMethod(id) < 0 ? 0 : ReductionCalcMethod(id)
	
	static menuCT, hCT;
	new itemStrBufferCT[50]
	new tytulCT[96];
	new numer2[10]
	
	formatex(tytulCT, charsmax(tytulCT), "Sklep Czlowieka - Znizka\r [%i %%]\d %s", g_priceReduction[id], is_vip(id) ? "(Dodatkowa znizka VIP)" : "");
	menuCT = menu_create(tytulCT, "SklepCT_Handler");
	
	for(new i = 0; i < sizeof(ItemyCT)-1; i++) {
		num_to_str(i, numer2,9)
		ItemRegister(itemStrBufferCT, ItemyCT[i][_Opis], ItemyCT[i][_Cena])
		menu_additem(menuCT, itemStrBufferCT, numer2)
	}
	hCT = menu_makecallback("CTShop_Callback");
	ItemRegister(itemStrBufferCT, ItemyCT[6][_Opis], ItemyCT[6][_Cena])
	menu_additem(menuCT, itemStrBufferCT, numer2, _, hCT);
	menu_setprop(menuCT, MPROP_EXIT, 0);
	menu_display(id, menuCT);
	
	return PLUGIN_HANDLED
}
public CTShop_Callback(id, hMenu, iItem)
{
	if(iItem == 6)
	{
		if(is_vip(id))
			return g_perkUsed[id] < VIP_UNLIMITED_LIMIT ? ITEM_ENABLED : ITEM_DISABLED;
		if(is_vip_plus(id))
			return g_perkUsed[id] < VIPPLUS_UNLIMITED_LIMIT ? ITEM_ENABLED : ITEM_DISABLED;
	}
	return ITEM_DISABLED;		
}
public SklepCT_Handler(id, menuCT, item)
{
	if(!is_user_zombie(id) && is_user_alive(id)){
		new money = cs_get_user_money(id)
		g_priceReduction[id] = is_vip(id) ? ReductionCalcMethod(id) + g_vipBonus : ReductionCalcMethod(id) < 0 ? 0 : ReductionCalcMethod(id)
		
		set_dhudmessage(24, 46, 222, -1.0, 0.3, 1, 0.02, 1.0, 0.01, 0.1);
		
		if(item == MENU_EXIT)
		{
			return PLUGIN_CONTINUE;
		}
		switch(item)
		{
			case 0:
			{
				if(money >= ItemyCT[0][_Cena]-((ItemyCT[0][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[0][_Cena]-((ItemyCT[0][_Cena]/100)*g_priceReduction[id]))
					give_item(id, "weapon_hegrenade");
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[0][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[0][_Cena]-((ItemyCT[0][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[0][_Opis])
				}
			}
			case 1:
			{
				if(money >= ItemyCT[1][_Cena]-((ItemyCT[1][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[1][_Cena]-((ItemyCT[1][_Cena]/100)*g_priceReduction[id]))
					give_item(id, "weapon_smokegrenade")
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[1][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[1][_Cena]-((ItemyCT[1][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[1][_Opis])
				}
			}
			case 2:
			{
				if(money >= ItemyCT[2][_Cena]-((ItemyCT[2][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[2][_Cena]-((ItemyCT[2][_Cena]/100)*g_priceReduction[id]))
					give_user_napalmnade(id)
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[2][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[2][_Cena]-((ItemyCT[2][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[2][_Opis])
				}
			}
			case 3:
			{
				if(money >= ItemyCT[3][_Cena]-((ItemyCT[3][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[3][_Cena]-((ItemyCT[3][_Cena]/100)*g_priceReduction[id]))
					give_item(id, "weapon_flashbang");
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[3][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[3][_Cena]-((ItemyCT[3][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[3][_Opis])
				}
			}
			case 4:
			{
				if(money >= ItemyCT[4][_Cena]-((ItemyCT[4][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[4][_Cena]-((ItemyCT[4][_Cena]/100)*g_priceReduction[id]))
					cs_set_user_nvg(id, 1)
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[4][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[4][_Cena]-((ItemyCT[4][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[4][_Opis])
				}
			}
			case 5:
			{
				if(money >= ItemyCT[5][_Cena]-((ItemyCT[5][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[5][_Cena]-((ItemyCT[5][_Cena]/100)*g_priceReduction[id]))
					switch(random(2))
					{
						case 0: give_item(id, "weapon_g3sg1")
						case 1: give_item(id, "weapon_sg550")
					}
					set_dhudmessage(24, 46, 222, -1.0, 0.4, 1, 0.02, 1.0, 0.01, 0.1);  
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[5][_Opis]);  
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[5][_Cena]-((ItemyCT[5][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[5][_Opis])
				}
			}
			case 6:
			{
				if(money >= ItemyCT[6][_Cena]-((ItemyCT[6][_Cena]/100)*g_priceReduction[id])){
					Reduce(id, ItemyCT[6][_Cena]-((ItemyCT[6][_Cena]/100)*g_priceReduction[id]))
					set_dhudmessage(24, 46, 222, -1.0, 0.4, 1, 0.02, 1.0, 0.01, 0.1);  
					show_dhudmessage(id, "Zakupiono %s", ItemyCT[6][_Opis]); 
					ColorChat(id, GREEN, "[Sklep]^x01 Wykorzystano ^x04%i/%i^x01 tego przedmiotu.", g_perkUsed[id]++, is_vip(id) ? VIP_UNLIMITED_LIMIT : VIPPLUS_UNLIMITED_LIMIT)
					unAmmo[id] = true;
					set_user_clip(id, 31)
					} else {
					ColorChat(id, GREEN, "[Sklep]^x01 Brakuje Ci^x04 %i $^x01 aby kupic^x03 %s", ItemyCT[6][_Cena]-((ItemyCT[6][_Cena]/100)*g_priceReduction[id]) - money, ItemyCT[6][_Opis])
				}
			}
		}
	}
	return PLUGIN_CONTINUE;
}
public UnlimitedAmmo(id)
{
	if (!is_user_alive(id) || !unAmmo[id]) return 0
	
	set_user_clip(id, 31)
	
	return 0
}
public Fwd_PlayerSpawn_Post(id){ 
	if (is_user_alive(id)){
		unAmmo[id] = false;
	}
} 
stock Reduce(id, amount)
	cs_set_user_money(id, cs_get_user_money(id) - amount)

stock set_user_clip(id, ammo)
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _)
	get_weaponname(weapon, weaponname, 31)
	while ((weaponid = engfunc(EngFunc_FindEntityByString, weaponid, "classname", weaponname)) != 0)
		if (pev(weaponid, pev_owner) == id)
	{
		set_pdata_int(weaponid, 51, ammo, 4)
		return weaponid
	}
	return 0
}
/* Set user to survivor */
stock set_user_human(id)
{
	cure_user(id)
	
	/* Remove user Nvgs */
	Remove_User_Nvgs(id)
	
	/* Set user health to 100 */
	set_user_health(id, 100)
	
	/* Set user to CT TEAM */
	cs_set_user_team(id, CS_TEAM_CT)
	
	/* reset user model */
	cs_reset_user_model(id)
}

/* ConnorMcLeod by BeasT */
Remove_User_Nvgs(id)
{
new iNvgs = get_pdata_int(id, OFFSET_NVGOGGLES, 5)
if( !iNvgs )
{
	return
}
if( iNvgs & USES_NVGS )
{
	emit_sound(id, CHAN_ITEM, "items/nvg_off.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	emessage_begin(MSG_ONE, gmsgNVGToggle, _, id)
	ewrite_byte(0)
	emessage_end()
}
set_pdata_int(id, OFFSET_NVGOGGLES, 0, 5)
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
