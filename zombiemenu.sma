#include <amxmodx>
#include <cstrike>
#include <fun>
#include <colorchat>

#define PLUGIN "Zombie Menu"
#define VERSION "0.1"
#define AUTHOR "Mixtaz"

#define DC_INV_LINK "https://discord.gg/dzjTH5WPpD"

native mapm_start_vote();

new g_testmenu, AdmHandl, Tech, Vip, Spec, MapM, TimeM; // tworzymy zmienną globalną, uchwyt dla menu

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

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i=0; i < sizeof AdminMenuCommands; i++)
    register_clcmd(AdminMenuCommands[i], "adminmenu")

	for(new i=0; i < sizeof MenuCommands; i++)
    register_clcmd(MenuCommands[i], "nowemenu")

	register_clcmd("say /limit", "cmdShowMapLimit")
	register_clcmd("say /dc", "showDiscordLinkCmd")
	register_clcmd("say /rangi", "showRangiCmd")

	register_clcmd("showbriefing", "cmdChooseTeam");
}
public plugin_cfg()
{
	g_testmenu = menu_create("\wMenu Główne [\rZombie Biohazard\w]", "nowemenuhandle");
	menu_additem(g_testmenu, "\ySklep \d(/buy)");
	menu_additem(g_testmenu, "Wyslij kase \d(/daj)")
	menu_additem(g_testmenu, "Menu Techniczne^n");
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
	menu_additem(g_testmenu, "Sprawdz czas gry \d(Konkurs)^n");
	TimeM = menu_create("TOP \r3\w czasu gry, zdobywa kapitalne nagrody!", "TimeHandler");
	menu_additem(TimeM, "Sprawdz swój czas");
	menu_additem(TimeM, "Lista czasów graczy online")
	menu_additem(TimeM, "Najlepszy czas graczy \d[MOTD]^n^n");
	menu_additem(TimeM, "Powrót");
	menu_additem(g_testmenu, "Lista rang");
	menu_additem(g_testmenu, "Dolacz na nasz serwer \yDiscord\w!");
	menu_additem(g_testmenu, "Regulamin^n^n");
	menu_additem(g_testmenu, "\dWYJDŹ")

	menu_setprop(g_testmenu, MPROP_PERPAGE, 0);
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
		case 5: menu_display(id, TimeM, 0)
		case 6: cmdExecute(id, "say /rangi")
		case 7: showDiscordLinkCmd(id)
		case 8: cmdExecute(id, "say /regu")
		case 9: show_menu(id, 0, "^n", 1);
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
		case 0: cmdShowMapLimit(id)
		case 1: cmdExecute(id, "say /mapy")
		case 2: menu_display(id, g_testmenu)
	}
}

public TimeHandler(id, menu, item){
	switch(item){
		case 0: cmdExecute(id, "say /time")
		case 1: cmdExecute(id, "say /timelist")
		case 2: cmdExecute(id, "say /toptime")
		case 3: menu_display(id, g_testmenu)
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
public cmdShowMapLimit(id)
{
	new website[128];
	formatex(website, charsmax(website), "http://biohazard.gameclan.pl/mapy-noc.html");
        
	new motd[256];
	formatex(motd, sizeof(motd) - 1,\
        "<html><head><meta http-equiv=^"Refresh^" content=^"0;url=%s^"></head><body><p><center>LOADING...</center></p></body></html>",\
            website);
    
	show_motd(id, motd);
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
	new website[128];
	formatex(website, charsmax(website), "http://biohazard.gameclan.pl/rangi.html");
        
	new motd[256];
	formatex(motd, sizeof(motd) - 1,\
        "<html><head><meta http-equiv=^"Refresh^" content=^"0;url=%s^"></head><body><p><center>LOADING...</center></p></body></html>",\
            website);
    
	show_motd(id, motd);
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
