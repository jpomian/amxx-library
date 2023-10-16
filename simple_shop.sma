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

native give_user_napalmnade(id);
native get_user_zombiemadness(id);

native toggle_lesser_kbimmunity(id);
native toggle_full_kbimmunity(id);


enum ITEM_TYPE {
    FB,
    HP
}

new g_iBlinkAcct, gmsgNVGToggle, maxplayers;
new g_hasConsumed[33][ITEM_TYPE];

new g_szItemsTT[][] = 
{
    "+500 HP",
    "Obniżona grawitacja (5 sek.)",
    "Antidotum",
    "Szalone Zombie"
}

new g_iItemsPricesTT[] = 
{
    2000,
    8000,
    10000,
    14000   
}

new g_szItemsCT[][] = 
{
    "Flashbang",
    "Noktowizor",
    "Zamrazacz",
    "HE",
    "Podpalacz",
    "Autokampa"
}

new g_iItemsPricesCT[] = 
{
    2000, 
    2000, 
    5000,
    5000,
    8000,
    14000   
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
    
    g_iBlinkAcct = get_user_msgid("BlinkAcct")
    
    for(new i=0; i < sizeof g_ShopCommands; i++)
		register_clcmd(g_ShopCommands[i], "cmdShopDirect")

    register_logevent("round_start", 2, "1=Round_Start")
    maxplayers = get_maxplayers()

}

public round_start() {
    for(new i=1; i<maxplayers;i++) {
            g_hasConsumed[i][FB] = 0;
            g_hasConsumed[i][HP] = 0;
    }
}


public cmdShopDirect(id)
{
    if(!is_user_alive(id))
        return PLUGIN_HANDLED;
    
    is_user_zombie(id) ? cmdShopTT(id) : cmdShopCT(id);

    return PLUGIN_HANDLED;
}

public cmdShopTT(id)
{
    new Temp[101], money = cs_get_user_money(id);
    
    formatex(Temp,100, "Sklep Zombie", money);
    new menu = menu_create(Temp, "handler_ShopMenuTT")
    
    new szItemName[64]

    if( money < g_iItemsPricesTT[0] || g_hasConsumed[id][HP] == 2 )
        formatex(szItemName, charsmax(szItemName), "\d%s ($%d) [%i/2]", g_szItemsTT[ 0 ], g_iItemsPricesTT[ 0 ], g_hasConsumed[id][HP])
    else
        formatex(szItemName, charsmax(szItemName), "%s (\r$%d\w) [\r%i\w/\r2\w]", g_szItemsTT[ 0 ], g_iItemsPricesTT[ 0 ], g_hasConsumed[id][HP])

    menu_additem(menu, szItemName)

    for(new i=1; i<sizeof(g_szItemsTT) && i<sizeof(g_iItemsPricesTT); i++)
    {
        if( money < g_iItemsPricesTT[i] )
        {
            formatex(szItemName, charsmax(szItemName), "\d%s ($%d)", g_szItemsTT[ i ], g_iItemsPricesTT[ i ])
        }
        else {
            formatex(szItemName, charsmax(szItemName), "%s (\r$%d\w)", g_szItemsTT[ i ], g_iItemsPricesTT[ i ])
        }
        menu_additem(menu, szItemName)
    }
    
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
    
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}

public cmdShopCT(id)
{
    new Temp[101], money = cs_get_user_money(id);
    
    formatex(Temp,100, "Sklep Czlowieka", money);
    new menu = menu_create(Temp, "handler_ShopMenuCT")
    
    new szItemName[64]

    if( money < g_iItemsPricesCT[0] || g_hasConsumed[id][FB] == 2 )
        formatex(szItemName, charsmax(szItemName), "\d%s ($%d) [%i/2]", g_szItemsCT[ 0 ], g_iItemsPricesCT[ 0 ], g_hasConsumed[id][FB])
    else
        formatex(szItemName, charsmax(szItemName), "%s (\r$%d\w) [\r%i\w/\r2\w]", g_szItemsCT[ 0 ], g_iItemsPricesCT[ 0 ], g_hasConsumed[id][FB])
    
    menu_additem(menu, szItemName)
        
    for(new i=1; i<sizeof(g_szItemsCT) && i<sizeof(g_iItemsPricesCT); i++)
    {
        if( money < g_iItemsPricesCT[i] )
        {
            formatex(szItemName, charsmax(szItemName), "\d%s ($%d)", g_szItemsCT[ i ], g_iItemsPricesCT[ i ])
        }
        else {
            formatex(szItemName, charsmax(szItemName), "%s (\r$%d\w)", g_szItemsCT[ i ], g_iItemsPricesCT[ i ])
        }
        menu_additem(menu, szItemName)
    }
    
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

    new money = cs_get_user_money(id);
    new new_money = cs_get_user_money(id) - g_iItemsPricesTT[item];
    
    if( money < g_iItemsPricesTT[item] )
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
                else {
                    set_user_health(id, get_user_health(id) + 500)

                    g_hasConsumed[id][HP]++;
                
                    client_print(id, print_center, "Zakupiono (%s)", g_szItemsTT[item]);

                    cs_set_user_money(id, new_money);
                }
        }
        case 1:
        {
                set_user_gravity(id, 0.375)
                toggle_lesser_kbimmunity(id)

                set_task(5.0, "cease_lesser_effect", id)

                client_print(id, print_center, "Zakupiono (%s)", g_szItemsTT[item]);
                
                cs_set_user_money(id, new_money);
        }
        case 2:
        {
            if(check_prerequisities(id)) {

                set_user_human(id)
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsTT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 3:
        {

                get_user_zombiemadness(id)
                toggle_full_kbimmunity(id)

                set_task(5.0, "cease_full_effect", id)

                client_print(id, print_center, "Zakupiono (%s)", g_szItemsTT[item]);
                
                cs_set_user_money(id, new_money);
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

    new money = cs_get_user_money(id);
    new new_money = cs_get_user_money(id) - g_iItemsPricesCT[item];
    
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
            else if(g_hasConsumed[id][FB] == 2) {
                Met_Item_Threshold( id );
            }
            else {
                give_item(id, "weapon_flashbang");

                g_hasConsumed[id][FB]++;
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 1: 
        {
            if( cs_get_user_nvg(id) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                cs_set_user_nvg(id, 1)
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
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
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 3:
        {
            if( user_has_weapon(id, CSW_HEGRENADE) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                give_item(id, "weapon_hegrenade");
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
                cs_set_user_money(id, new_money);
            }
        }
        case 4:
        {
            if( user_has_weapon(id, CSW_HEGRENADE) )
            {
                Cannot_Carry_Anymore( id );
            }
            else {
                give_user_napalmnade( id )
                
                client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
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
                
            client_print(id, print_center, "Zakupiono (%s)", g_szItemsCT[item]);
                
            cs_set_user_money(id, new_money);
        }
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public cease_lesser_effect(id)
{
    set_user_gravity(id, 1.0)
    toggle_lesser_kbimmunity(id)
}

public cease_full_effect(id)
{
    toggle_full_kbimmunity(id)
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
    client_print(id, print_center, "Nie masz kasy.");

    message_begin(MSG_ONE_UNRELIABLE, g_iBlinkAcct, .player=id);
    {
        write_byte(2);
    }
    message_end();
}

Cannot_Carry_Anymore( id )
{
    client_print(id, print_center, "Masz pelny ekwipunek.");
}

Met_Item_Threshold( id )
{
    client_print(id, print_center, "Nie mozesz kupic wiecej w tej rundzie.");
} 