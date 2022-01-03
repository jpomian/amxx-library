#include <amxmodx>
#include <cstrike>
#include <fun>

#define PLUGIN "Zombie Menu"
#define VERSION "0.1"
#define AUTHOR "Mixtaz"

native mapm_start_vote()

new g_testmenu, regumenu, AdmHandl, Tech, Vip, Spec, Head; // tworzymy zmienną globalną, uchwyt dla menu
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

	register_clcmd("chooseteam", "cmdChooseTeam");
}
public plugin_cfg()
{
	g_testmenu = menu_create("\rNowy Biohazard", "nowemenuhandle");
	menu_additem(g_testmenu, "\rSklep");
	menu_additem(g_testmenu, "\yPrzelej pieniadze");
	menu_additem(g_testmenu, "Osiagniecia^n");
	menu_additem(g_testmenu, "Menu Techniczne");
	Tech = menu_create("\dMenu Techniczne^n^n\wW razie jakichkolwiek klopotow prosze kierowac informacje na:^n\rerrorhead.pl\w.", "TechHandler");
	menu_additem(Tech, "Menu Mutowania");
	menu_additem(Tech, "\rWl/Wyl.\w Liste Obserwatorow");
	menu_additem(Tech, "Przejdz na specta/Wroc do gry")
	menu_additem(Tech, "Powrot do glownego menu");
	menu_additem(g_testmenu, "Informacje o Vipie");
	Vip = menu_create("\dZbior informacji o Vipie^n^n\wAby zakupic VIP, napisz\r /sklepsms", "VipHandler");
	menu_additem(Vip, "Przywileje Vipa");
	menu_additem(Vip, "Gracze Vip Online");
	menu_additem(Vip, "\ySklepSMS^n^n");
	menu_additem(Vip, "Powrot do glownego menu");
	menu_additem(g_testmenu, "Nominuj Mapy^n");
	menu_additem(g_testmenu, "Zobacz Ranking");
	menu_additem(g_testmenu, "Roundsoundy");
	menu_additem(g_testmenu, "Medale^n")
	menu_additem(g_testmenu, "\dOpusc Menu");

	menu_setprop(g_testmenu, MPROP_PERPAGE, 0);
	menu_setprop(g_testmenu , MPROP_EXIT , MEXIT_NEVER); //Dont allow Menu to exit
	menu_setprop(Tech , MPROP_EXIT , MEXIT_NEVER);

	AdmHandl = menu_create("Menu Admina", "adminmenuhandle");
	menu_additem(AdmHandl, "Menu \dOzywiania");
	menu_additem(AdmHandl, "Menu \dWyciszania");
	menu_additem(AdmHandl, "Menu \dTeleportacji");
	menu_additem(AdmHandl, "Menu \dSpeclist^n^n");
	Spec = menu_create("\dUkryj/Pokaz klawisze/siebie na liscie", "SpecHandler");
	menu_additem(Spec, "Ukryj sie na spec");
	menu_additem(Spec, "Wlacz klawisze u gracza");
	menu_additem(AdmHandl, "Menu \rWaznych", _, ADMIN_IMMUNITY);
	Head = menu_create("\dUkryj/Pokaz klawisze/siebie na liscie", "HeadHandler");
	menu_additem(Head, "Wymus glosowanie");
	menu_additem(Head, "Tryb Nemesis");
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
		case 2: cmdExecute(id, "say /achs")
		case 3: menu_display(id, Tech, 0)
		case 4: menu_display(id, Vip, 0)
		case 5: cmdExecute(id, "say /mapy")
		case 6: cmdExecute(id, "say /top15")
		case 7: cmdExecute(id, "say /rs")
		case 8: cmdExecute(id, "say /medale")
		case 9: show_menu(id, 0, "^n", 1);
	}

	return PLUGIN_HANDLED;
}
public TechHandler(id, menu, item){
	switch(item){
		case 0: cmdExecute(id, "say /mute")
		case 1: cmdExecute(id, "say /speclist")
		case 2: cmdExecute(id, get_user_team(id) == 3 ? "say /back" : "say /spec")
		case 3: menu_display(id, g_testmenu)
	}
}
public VipHandler(id, menu, item){
	switch(item){
		case 0: cmdExecute(id, "say /vip")
		case 1: cmdExecute(id, "say /vips")
		case 2: cmdExecute(id, "say /sklepsms")
		case 3: menu_display(id, g_testmenu)
	}
}
public adminmenuhandle(id, menu, item) {
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: cmdExecute(id, "amx_ozyw")
		case 1: cmdExecute(id, "amx_gagmenu")
		case 2: cmdExecute(id, "amx_teleport")
		case 3: menu_display(id, Spec, 0)
		case 4: menu_display(id, Head, 0)
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
public HeadHandler(id, menu, item)
{
	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: mapm_start_vote()
		case 1: cmdExecute(id, "say /nemesis")
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
	regumenu = menu_create("Regulaminy serwera^nPelny regulamin znajduje sie na \rErrorhead.pl", "regumenu_handler");
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
