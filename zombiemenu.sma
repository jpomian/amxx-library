#include <amxmodx>
#include <cstrike>
#include <fun>
#include <colorchat>

#define PLUGIN "Zombie Menu"
#define VERSION "0.1"
#define AUTHOR "Mixtaz"

#define DC_INV_LINK "https://discord.gg/czW5ccEur"

native mapm_start_vote();

new g_testmenu, regumenu, AdmHandl, Tech, Vip, Spec, MapM; // tworzymy zmienną globalną, uchwyt dla menu
//new g_szHTML[ 364 ] = "<html><head><meta http-equiv='Refresh' content='0; URL=https://errorhead.pl/topic/14707-regulamin-serwera-ghost-mode/></head><body bgcolor=black><center>";

new const MenuCommands[][] =
	{
		"say /menu",
		"say_team /menu",
		"say menu",
		"say_team menu"
	};
new const AdminMenuCommands[][] =
	{
		"say /a",
		"say_team /a"
	};
new const RulesCommands[][] =
	{
		"say /regulamin",
		"say_team /regulamin",
		"say /zasady",
		"say_team /zasady"
	};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i=0; i < sizeof AdminMenuCommands; i++)
    register_clcmd(AdminMenuCommands[i], "adminmenu")

	for(new i=0; i < sizeof MenuCommands; i++)
    register_clcmd(MenuCommands[i], "nowemenu")

	for(new i=0; i < sizeof RulesCommands; i++)
    register_clcmd(RulesCommands[i], "menuregulamin")

	register_clcmd("say /limit", "cmdShowMapLimit")
	register_clcmd("say /dc", "showDiscordLinkCmd")
	register_clcmd("say /rangi", "showRangiCmd")

	register_clcmd("chooseteam", "cmdChooseTeam");
}
public plugin_cfg()
{
	g_testmenu = menu_create("\rZombie \wBiohazard", "nowemenuhandle");
	menu_additem(g_testmenu, "\ySklep \d(/buy)");
	menu_additem(g_testmenu, "Wyslij kase \d(/daj)")
	menu_additem(g_testmenu, "Menu Techniczne");
	Tech = menu_create("\dMenu Techniczne", "TechHandler");
	menu_additem(Tech, "Menu Mutowania");
	menu_additem(Tech, "Przejdz na specta/Wroc do gry^n^n")
	menu_additem(Tech, "Powrot do glownego menu");
	menu_additem(g_testmenu, "Informacje o Vipie");
	Vip = menu_create("\dZbior informacji o Vipie^n^n\wAby zakupic VIP, napisz\r /sklepsms", "VipHandler");
	menu_additem(Vip, "Przywileje Vipa");
	menu_additem(Vip, "Gracze Vip Online^n^n");
	menu_additem(Vip, "Powrot do glownego menu");
	menu_additem(g_testmenu, "Mapy");
	MapM = menu_create("\dMenu Map", "MapHandler");
	menu_additem(MapM, "Limit graczy na mape");
	menu_additem(MapM, "Zanominuj^n^n")
	menu_additem(MapM, "Powrot do glownego menu");
	menu_additem(g_testmenu, "Roundsoundy");
	menu_additem(g_testmenu, "Lista rang");
	menu_additem(g_testmenu, "Dolacz na nasz serwer \yDiscord\w!^n^n");

	// menu_setprop(g_testmenu, MPROP_PERPAGE, 0);
	menu_setprop(Tech , MPROP_EXIT , MEXIT_NEVER);

	AdmHandl = menu_create("Menu Admina", "adminmenuhandle");
	menu_additem(AdmHandl, "Menu Wyciszania");
	menu_additem(AdmHandl, "Menu Teleportacji");
	menu_additem(AdmHandl, "Menu zaaw. obserwatora");
	menu_additem(AdmHandl, "Wlacz/Wylacz szcz. info o polaczeniu");
	menu_additem(AdmHandl, "Wymus glosowanie \d(z zapisem do logow)^n^n");

	Spec = menu_create("\dUkryj/Pokaz klawisze/siebie na liscie", "SpecHandler");
	menu_additem(Spec, "Ukryj sie na spec");
	menu_additem(Spec, "Wlacz klawisze u gracza");
}
public nowemenu(id) {
	menu_display(id, g_testmenu);

	return PLUGIN_HANDLED;
}
public adminmenu(id){
	if(get_user_flags(id) & ADMIN_KICK){
		menu_display(id, AdmHandl);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public nowemenuhandle(id, menu, item) {
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) { 
		case 0: cmdExecute(id, "say /sklep")
		case 1: cmdExecute(id, "say /daj")
		case 2: menu_display(id, Tech, 0)
		case 3: menu_display(id, Vip, 0)
		case 4: menu_display(id, MapM, 0)
		case 5: cmdExecute(id, "say /rs")
		case 6: cmdExecute(id, "say /rangi")
		case 7: showDiscordLinkCmd(id)
		// case 9: show_menu(id, 0, "^n", 1);
	}

	return PLUGIN_HANDLED;
}

public TechHandler(id, menu, item){
	switch(item){
		case 0: cmdExecute(id, "say /mute")
		case 1: cmdExecute(id, get_user_team(id) == 3 ? "say /back" : "say /spec")
		case 2: menu_display(id, g_testmenu)
	}
}
public VipHandler(id, menu, item){
	switch(item){
		case 0: cmdExecute(id, "say /vip")
		case 1: cmdExecute(id, "say /vips")
		case 2: menu_display(id, g_testmenu)
	}
}
public MapHandler(id, menu, item){
	switch(item){
		case 0: show_motd( id,"limit.txt","Limit graczy")
		case 1: cmdExecute(id, "say /mapy")
		case 2: menu_display(id, g_testmenu)
	}
}

public adminmenuhandle(id, menu, item) {
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: cmdExecute(id, "amx_gagmenu")
		case 1: cmdExecute(id, "amx_teleport")
		case 2: menu_display(id, Spec, 0)
		case 3: cmdExecute(id, "say /playerinfo")
		case 4: mapm_start_vote()
	}
	return PLUGIN_HANDLED;
}

public SpecHandler(id, menu, item)
{
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: cmdExecute(id, "say /spechide")
		case 1: cmdExecute(id, "say /speckeys")
	}

	return PLUGIN_HANDLED;
}

public cmdChooseTeam(id)
{
	menu_display(id, g_testmenu);
	return PLUGIN_HANDLED;
}
public menuregulamin(id)
{
	regumenu = menu_create("Regulaminy serwera \d(PS: Tu narazie nic nie ma, wiec badz \rgrzeczny!\d)", "regumenu_handler");
	menu_additem(regumenu, "Zasady \dOgolne");
	menu_additem(regumenu, "Zasady dla \rZombie");
	menu_additem(regumenu, "Zasady dla \yCT^n");
	menu_display(id, regumenu);
}
public regumenu_handler(id, menu, item) {
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: show_motd(id,"ogolne.txt", "Zasady Ogolne.")
		case 1: show_motd(id,"forzombie.txt", "Zasady dla Zombie.")
		case 2: show_motd(id,"forct.txt", "Zasady dla CT.")
	}
	return PLUGIN_HANDLED;
}
public cmdShowMapLimit(id)
{
	show_motd( id,"limit.txt","Limit graczy")
}

public showDiscordLinkCmd(id)
{
	ColorChat(id, GREEN, "[Discord]^x01 Link do naszego serwera DC zostal wyslany do Twojej konsoli.")

	client_print(id, print_console, "")
	client_print(id, print_console, "==========================================")
	client_print(id, print_console, "Link: %s", DC_INV_LINK)
	client_print(id, print_console, "==========================================")
}


public showRangiCmd(id)
{
	show_motd( id,"rangi.txt","Lista rang")
}
stock cmdExecute( id , const szText[] , any:... ) {
	
    #pragma unused szText

    if ( id == 0 || is_user_connected( id ) ) {

    	new szMessage[ 256 ];

    	format_args( szMessage ,charsmax( szMessage ) , 1 );

        message_begin( id == 0 ? MSG_ALL : MSG_ONE, 51, _, id )
        write_byte( strlen( szMessage ) + 2 )
        write_byte( 10 )
        write_string( szMessage )
        message_end()
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
