#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <colorchat>
#include <fakemeta>
#include <biohazard>

#define PLUGIN "Biohazard Shop"
#define VERSION "1.0"
#define AUTHOR "Mixtaz"

#define OFFSET_NVGOGGLES    129
#define HAS_NVGS (1<<0)
#define USES_NVGS (1<<8)

#define is_vip(%1) (get_user_flags(%1) & ADMIN_LEVEL_H)
#define VIP_BONUS 5
#define ItemRegister(%1,%2,%3) formatex(%1, charsmax(%1), "%s \r [\y%i $\r]", %2, %3-((%3/100)*g_iDiscount[id]))
#define RestrictedItemRegister(%1,%2,%3,%4,%5) formatex(%1, charsmax(%1), "%s \r [\y%i $\r] \d(%i/%i)", %2, %3-((%3/100)*g_iDiscount[id]), %4, %5)
#define isNotElligible(%1) (!is_user_alive(%1) || !game_started())

native give_user_napalmnade(id);
native get_user_zombiemadness(id);
native set_user_kbimmunity(id, Float:fReduction, bool:isDucking);
native respawn_zombie(id);

native get_rank_order(id);
native get_user_rank(id, szReturn[], iLen);

enum ITEM_TYPE {
    HP,
    FB,
    AMMO
}

new g_iBlinkAcct, gmsgNVGToggle, maxplayers;
new g_hasConsumed[33][ITEM_TYPE];
new g_iDiscount[33], g_bNotified[33];
new bool: unAmmo[33];
new const g_hardscream[] = "zombie/ciezka.wav"

new g_szItemsTT[][] = 
{
    "+500 HP",
    "Obniżona grawitacja (5 sek.)",
    "Szalone Zombie",
    "Antidotum",
}

new g_iItemsPricesTT[] = 
{
    5000,
    10000,
    14000,
    16000   
}

new g_szItemsCT[][] = 
{
    "Flashbang",
    "HE",
    "Zamrazacz",
    "Dodatkowa Wiertarka",
    "Podpalacz",
    "Unlimited Ammo [VIP]"
}

new g_iItemsPricesCT[] = 
{
    2500, 
    4000,
    6500,
    8000,
    10000,
    16000  
}

new g_itemLimit[ITEM_TYPE] =
{
    1,
    2,
    1
}

new const g_ShopCommands[][] =
{
    "say /sklep",
    "say_team /sklep",
    "say /buy",
    "say_team /buy"
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    g_iBlinkAcct = get_user_msgid("BlinkAcct") //msg
    
    for(new i=0; i < sizeof g_ShopCommands; i++)
		register_clcmd(g_ShopCommands[i], "cmdShopDirect")

    register_logevent("round_start", 2, "1=Round_Start")
    maxplayers = get_maxplayers()

    register_event("CurWeapon", "UnlimitedAmmo", "be", "1=1")

    register_clcmd("chooseteam", "cmdShopDirect");

}

public plugin_precache()
{
	precache_sound(g_hardscream);
}

public round_start() {
    for(new i=1; i<maxplayers;i++) {
            g_hasConsumed[i][HP] = 0;
            g_hasConsumed[i][FB] = 0;
            unAmmo[i] = false;
    }
}

public client_authorized(id)
{
    g_iDiscount[id] = is_vip(id) ? VIP_BONUS : 0;
    get_rank_order(id);
}
public cmdShopDirect(id)
{
    // cs_set_user_money(id, 16000)
    new iRank, szRank[32];
    iRank = get_rank_order(id);
    get_user_rank(id, szRank, charsmax(szRank))
    g_iDiscount[id] = is_vip(id) ? VIP_BONUS + iRank : iRank;

    is_user_zombie(id) ? cmdShopTT(id) : cmdShopCT(id);
    
    if(!g_bNotified[id])
    {
        ColorChat(id, GREEN, "[Sklep]^x01 Zaaplikowano znizke dla rangi:^x04 %s^x01. Poziom znizki: ^x04%i%%%%^x01.", szRank, iRank)
        g_bNotified[id] = true;
    }
    return PLUGIN_HANDLED;
}
public cmdShopTT(id)
{
    new Temp[101];
    
    formatex(Temp,100, "Sklep Zombie \w[Znizka: \y%i %%\w]", g_iDiscount[id]);
    new menu = menu_create(Temp, "handler_ShopMenuTT")
    
    new szItemName[64]

    RestrictedItemRegister(szItemName, g_szItemsTT[ 0 ], g_iItemsPricesTT[ 0 ], g_hasConsumed[id][HP], g_itemLimit[HP])
    menu_additem(menu, szItemName)

    for(new i=1; i<sizeof(g_szItemsTT) && i<sizeof(g_iItemsPricesTT); i++)
    {
        ItemRegister(szItemName, g_szItemsTT[ i ], g_iItemsPricesTT[ i ])
        menu_additem(menu, szItemName)
    }
    
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
    
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}
public cmdShopCT(id)
{
    new Temp[101];
    
    formatex(Temp,100, "Sklep Czlowieka \w[Znizka: \y%i %%\w]", g_iDiscount[id]);
    new menu = menu_create(Temp, "handler_ShopMenuCT")
    
    new szItemName[64]

    RestrictedItemRegister(szItemName, g_szItemsCT[ 0 ], g_iItemsPricesCT[ 0 ], g_hasConsumed[id][FB], g_itemLimit[FB])
    menu_additem(menu, szItemName)

    for(new i=1; i<sizeof(g_szItemsCT) - 1 && i<sizeof(g_iItemsPricesCT) - 1; i++)
    {
        ItemRegister(szItemName, g_szItemsCT[ i ], g_iItemsPricesCT[ i ])
        menu_additem(menu, szItemName)
    }
    
    RestrictedItemRegister(szItemName, g_szItemsCT[ 5 ], g_iItemsPricesCT[ 5 ], g_hasConsumed[id][AMMO], g_itemLimit[AMMO])
    menu_additem(menu, szItemName)

    menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
    
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}

public handler_ShopMenuTT(id, menu, item)
{
    if( item == MENU_EXIT )
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    
    if( !is_user_zombie(id) )
    {
        return PLUGIN_HANDLED;
    }

    if(isNotElligible(id))
    {
        MustMeetRequirements(id);
    }

    new itemAdjustedPrice = g_iItemsPricesTT[item] - (g_iItemsPricesTT[item]/100)*g_iDiscount[id]
    new money = cs_get_user_money(id);
    new new_money = cs_get_user_money(id) - itemAdjustedPrice;
    set_dhudmessage(225, 0, 0, -1.0, 0.7, 2, 0.01, 3.0, 0.02, 0.02)

    
    if( money < itemAdjustedPrice )
    {
        NotEnoughMoney( id );
        menu_display(id, menu);
        return PLUGIN_HANDLED;
    }
    
    switch(item)
    {
        case 0: 
        {
                if( g_hasConsumed[id][HP] == g_itemLimit[HP] )
                {
                    Met_Item_Threshold( id );
                }
                else {
                    set_user_health(id, get_user_health(id) + 500)

                    g_hasConsumed[id][HP]++;
                
                    show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])

                    cs_set_user_money(id, new_money);
                }
        }
        case 1:
        {
            
                set_user_gravity(id, 0.6)
                set_user_kbimmunity(id, 0.5, false);
                set_task(5.0, "cease_lesser_effect", id)

                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
        }
        case 2:
        {

                get_user_zombiemadness(id)
                set_user_kbimmunity(id, 1.0, false);

                set_task(5.0, "cease_full_effect", id)

                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
        }
        case 3:
        {
            if(check_prerequisities(id)) {

                set_user_human(id)
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
            }
        }
    }
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public handler_ShopMenuCT(id, menu, item)
{
    if( item == MENU_EXIT )
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    if( is_user_zombie(id) )
    {
        return PLUGIN_HANDLED;
    }

    if(isNotElligible(id))
    {
        MustMeetRequirements(id);
    }

    new itemAdjustedPrice = g_iItemsPricesCT[item] - (g_iItemsPricesCT[item]/100)*g_iDiscount[id]
    new money = cs_get_user_money(id);
    new new_money = cs_get_user_money(id) - itemAdjustedPrice;
    set_dhudmessage(0, 0, 200, -1.0, 0.7, 2, 0.01, 3.0, 0.02, 0.02)
    
    
    if( money < g_iItemsPricesCT[item] )
    {
        NotEnoughMoney( id );
        menu_display(id, menu);
        return PLUGIN_HANDLED;
    }
    
    switch(item)
    {
        case 0: 
        {
            if( cs_get_user_bpammo( id, CSW_FLASHBANG ) == 2 )
            {
                Cannot_Carry_Anymore( id );
            }
            else if( g_hasConsumed[id][FB] == g_itemLimit[FB] )
            {
                Met_Item_Threshold( id );
            }
            else
            {
                give_item(id, "weapon_flashbang");
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);

                cs_set_user_money(id, new_money);

                g_hasConsumed[id][FB]++;
            }
        }
        case 1:
        {
            if( user_has_weapon(id, CSW_HEGRENADE) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                give_item(id, "weapon_hegrenade");
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 2:
        {
            if( user_has_weapon(id, CSW_SMOKEGRENADE) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                give_item(id, "weapon_smokegrenade");
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 3:
        {
            switch(random(2))
			{
				case 0: give_item(id, "weapon_mac10")
				case 1: give_item(id, "weapon_tmp")
			}
                
            show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
            cs_set_user_money(id, new_money);
        }
        case 4:
        {
            
            if( user_has_weapon(id, CSW_HEGRENADE) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                give_user_napalmnade( id )
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }

        case 5:
        {
            if(!is_vip(id))
            {
                Not_A_VipPlayer(id)
            }
            else if( g_hasConsumed[id][AMMO] == g_itemLimit[AMMO] )
            {
                Met_Item_Threshold( id );
            }
                else {
                    unAmmo[id] = true;

                    g_hasConsumed[id][AMMO]++;

                    set_user_clip(id, 31)
                
                    show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);

                    cs_set_user_money(id, new_money);
                }
        }
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public cease_lesser_effect(id)
{
    set_user_gravity(id, 1.0)
    set_user_kbimmunity(id, 0.0, false);
}

public cease_full_effect(id)
{
    set_user_kbimmunity(id, 0.0, false);
}

public give_user_effects(id)
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

public UnlimitedAmmo(id)
{
	if (!is_user_alive(id) || !unAmmo[id]) return 0
	
	set_user_clip(id, 31)
	
	return 0
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
		return false;
	}

	if(is_user_firstzombie(id))
	{
		ColorChat(id, GREEN, "[Sklep]^x01 Jestes matka zombie.")
		return false;
	}
	
	/* Check user alive */
	if(!is_user_alive(id))
		return false;
	
	/* Check user zombie */
	if(!is_user_zombie(id))
		return false;
	
	return true;
}

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

NotEnoughMoney( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Nie masz na to kasy...")

    message_begin(MSG_ONE_UNRELIABLE, g_iBlinkAcct, .player=id);
    {
        write_byte(2);
    }
    message_end();
}

Cannot_Carry_Anymore( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Masz pelny ekwipunek.")
}

Met_Item_Threshold( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Nie mozesz kupic wiecej w tej rundzie.")
} 

Not_A_VipPlayer( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Przedmiot zarezerwowany dla graczy VIP.")
}

MustMeetRequirements( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Poczekaj na rozpoczecie infekcji.")
}