#include <amxmodx>
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

#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)


native give_user_napalmnade(id);
native get_user_zombiemadness(id);
native set_user_kbimmunity(id, Float:fReduction, bool:isDucking);
native respawn_zombie(id);

native get_rank_order(id);
native get_user_rank(id, szReturn[], iLen);

enum ITEM_TYPE {
    RESP,
    HP,
    AMMO
}

new const g_hardscream[] = "zombie/dupa_activated.wav";

new g_iBlinkAcct, gmsgNVGToggle, maxplayers;
new g_hasConsumed[33][ITEM_TYPE];
new g_iDiscount[33];
new bool: unAmmo[33], bool:g_bNotified[33] = false;
new sprPlus;


new g_szItemsTT[][] = 
{
    "+500 HP",
    "Respawn",
    "Obniżona grawitacja (5 sek.)",
    "Ciezka Dupa",
    "Szalone Zombie",
    "Antidotum",
}

new g_iItemsPricesTT[] = 
{
    3000,
    4000,
    8000,
    12000,
    14000,
    16000   
}

new g_szItemsCT[][] = 
{
    "HE",
    "Zamrazacz",
    "Podpalacz",
    "Flara",
    "Noktowizor",
    "Autokampa",
    "Unlimited Ammo [VIP]"
}

new g_iItemsPricesCT[] = 
{
    5000, 
    5500, 
    7500,
    500,
    2000,
    14000,
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
    sprPlus = precache_model("sprites/heal.spr");
}

public round_start() {
    for(new i=1; i<maxplayers;i++) {
            g_hasConsumed[i][HP] = 0;
            g_hasConsumed[i][RESP] = 0;
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
    // cs_set_user_money(id, 16000);
    new iRank, szRank[32];
    iRank = get_rank_order(id);
    get_user_rank(id, szRank, charsmax(szRank))
    g_iDiscount[id] = is_vip(id) ? VIP_BONUS + iRank : iRank;

    is_user_zombie(id) ? cmdShopTT(id) : cmdShopCT(id);
    
    if(!g_bNotified[id] && iRank > 0)
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

    RestrictedItemRegister(szItemName, g_szItemsTT[ 1 ], g_iItemsPricesTT[ 1 ], g_hasConsumed[id][RESP], g_itemLimit[RESP])
    menu_additem(menu, szItemName)

    for(new i=2; i<sizeof(g_szItemsTT) && i<sizeof(g_iItemsPricesTT); i++)
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

    for(new i=0; i<sizeof(g_szItemsCT) - 1 && i<sizeof(g_iItemsPricesCT) - 1; i++)
    {
        ItemRegister(szItemName, g_szItemsCT[ i ], g_iItemsPricesCT[ i ])
        menu_additem(menu, szItemName)
    }
    
    RestrictedItemRegister(szItemName, g_szItemsCT[ 6 ], g_iItemsPricesCT[ 6 ], g_hasConsumed[id][AMMO], g_itemLimit[AMMO])
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
                if( g_hasConsumed[id][HP] == 2 )
                {
                    Met_Item_Threshold( id );
                }
                else if(isNotElligible(id))
                {
                    MustMeetRequirements( id );
                }
                else {
                    set_user_health(id, get_user_health(id) + 500)

                    g_hasConsumed[id][HP]++;
                
                    show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])

                    cs_set_user_money(id, new_money);

                    show_healsprite(id)
                }
        }
        case 1: 
        {
                if(is_user_alive(id))
                {
                    Cant_When_Alive( id );
                }
                else if( g_hasConsumed[id][RESP] == 1 )
                {
                    Met_Item_Threshold( id );
                }
                else {
                    respawn_zombie(id)

                    g_hasConsumed[id][RESP]++;
                
                    show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])

                    cs_set_user_money(id, new_money);

                    set_task(1.5, "Give_Players_Info", id);
                }
        }
        case 2:
            {
                if(isNotElligible(id))
                {
                    MustMeetRequirements( id );
                }   
                set_user_gravity(id, 0.375)
                set_user_kbimmunity(id, 0.5, false)
                set_task(5.0, "cease_lesser_effect", id)

                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
        }
        case 3:
        {
                if(isNotElligible(id))
                {
                    MustMeetRequirements( id );
                } 
                set_user_kbimmunity(id, 1.0, true)
                give_user_effects(id)
                set_task(5.0, "cease_full_effect", id)

                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
        }
        case 4:
        {
                get_user_zombiemadness(id)
                set_user_kbimmunity(id, 1.0, false)

                set_task(5.0, "cease_full_effect", id)

                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsTT[item])
                
                cs_set_user_money(id, new_money);
        }
        case 5:
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

    new itemAdjustedPrice = g_iItemsPricesCT[item] - (g_iItemsPricesCT[item]/100)*g_iDiscount[id]
    new money = cs_get_user_money(id);
    new new_money = cs_get_user_money(id) - itemAdjustedPrice;

    set_dhudmessage(0, 0, 200, -1.0, 0.7, 2, 0.01, 3.0, 0.02, 0.02)
    
    if( money < itemAdjustedPrice )
    {
        NotEnoughMoney( id );
        menu_display(id, menu);
        return PLUGIN_HANDLED;
    }

    if(isNotElligible(id))
    {
        MustMeetRequirements( id );
        return PLUGIN_HANDLED;
    }
    
    switch(item)
    {
        case 0:
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
        case 1:
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
        case 2:
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
        case 3: 
        {
            if( cs_get_user_bpammo( id, CSW_FLASHBANG ) == 2 )
            {
                Cannot_Carry_Anymore( id );
            }
            else
            {
                give_item(id, "weapon_flashbang");
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 4: 
        {
            if( cs_get_user_nvg(id) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                cs_set_user_nvg(id, 1)
                
                show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }

        case 5:
        {
            
            switch(random(2))
			{
				case 0: give_item(id, "weapon_g3sg1")
				case 1: give_item(id, "weapon_sg550")
			}
                
            show_dhudmessage(id, "Zakupiono (%s)", g_szItemsCT[item]);
                
            cs_set_user_money(id, new_money);
        }

        case 6:
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
    set_user_kbimmunity(id, 0.0, false)
}

public cease_full_effect(id)
{
    set_user_kbimmunity(id, 0.0, false)
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

public show_healsprite(id)
{
    new Float:fOrigin[3];
 
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SPRITE);
    write_coord_f(fOrigin[0]);
    write_coord_f(fOrigin[1]);
    write_coord_f(fOrigin[2]);
    write_short(sprPlus);
    write_byte(20);
    write_byte(255);
    message_end();
}

public Give_Players_Info(id)
{
    new szName[32];
    get_user_name(id, szName, charsmax(szName))

    ColorChat(0, RED, "[Biohazard]^x01 Zombie %s wrócił do zywych!", szName)
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

Cant_When_Alive( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Tylko gdy jestes martwy!")
}

Not_A_VipPlayer( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Przedmiot zarezerwowany dla graczy VIP.")
}

MustMeetRequirements( id )
{
    ColorChat(id, GREEN, "[Sklep]^x01 Poczekaj na rozpoczecie infekcji.")
}