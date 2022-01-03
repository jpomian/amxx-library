#include < amxmodx >
#include < amxmisc >
#include < colorchat >
#include < sqlx >

#pragma compress 1

#define PREFIX "Errorhead.pl" // Nazwa forum - do zmiany

#define SERVER_NAME "Zombie Biohazard" // Nazwa serwera - do zmiany

#define	TABLE_NAME "report_system" // Nie ruszać

#define	TYPE_REPORT "cs16" // Nie ruszać

#define DB_CALL "INSERT INTO `%s` (player, reported, chat, time, server, type) VALUES ('%s', '%s', '%s', %d, '%s', '%s')"

new Handle:SqlConnection;

new g_szName[33][64];
new reported[33][64];
new callReason;

new bool:isAdminOnline;

new const callReasons[][] = {
	"Brak Powodu",
	"Kampienie na polowaniu",
	"Blokowanie kampy",
	"Rozwalanie kladek bez ZM",
	"Obrazanie",
	"Naduzywanie micro",
	"Cheatowanie"
};


new const callCommands[][] = {
	"say /wezwij",
	"say_team /wezwij",
	"say /zglos",
	"say_team /zglos",
	"say /report",
	"say_team /report"
}

public plugin_init( )
{

	for(new i=0; i < sizeof callCommands; i++)
    register_clcmd(callCommands[i], "CallMenu")

	set_task(180.0, "ShowInfos", _, _, _, "b");
}

public plugin_cfg( )
{
	SqlConnection = SQL_MakeDbTuple( "hostfox.pl:3306" , "errorhea_systemreport", "]lueRi%3_.cY" , "errorhea_systemreport" );
}

public client_authorized(id) {
	if(get_user_flags(id) & ADMIN_BAN)
		isAdminOnline = true;
	
	get_user_name(id, g_szName[id], 63);
}

public client_disconnected(id) {
	if(get_user_flags(id) & ADMIN_BAN) {
		isAdminOnline = false;
		for(new i = 1; i <= 32; i++) {
			if(!is_user_connected(i) || i == id) continue;

			if(get_user_flags(i) & ADMIN_BAN)
				isAdminOnline = true;
		}
	}
}

public client_disconnect(id) {
	if(get_user_flags(id) & ADMIN_BAN) {
		isAdminOnline = false;
		for(new i = 1; i <= 32; i++) {
			if(!is_user_connected(i) || i == id) continue;

			if(get_user_flags(i) & ADMIN_BAN)
				isAdminOnline = true;
		}
	}
}
	
public ShowInfos() {
	for(new i = 1; i <= 32; i++) 
	{
		if(!is_user_connected(i)) continue;
		
		ColorChat(i, RED, "^x04[%s]^x01 Uzyj komendy^x03 /zglos^x01 aby zglosic gracza na forum!", PREFIX);
	}
}

public CallMenu(id)
{
	if(isAdminOnline) {
		client_print(id, print_center, "Admin jest na serwerze! Zglos cheatera na u@!");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("Zglos cheatera:^n\dNieuzasadnione zgloszenia beda karane!\y", "CallMenuHandler");
	new callback = menu_makecallback("CallMenuCallback");
	new players[32], pnum, tempid;
	new szTempid[10];

	get_players(players, pnum);

	for( new i; i<pnum; i++ ) {
		tempid = players[i];
		if(is_user_hltv(tempid)) continue;
		
		if(get_user_flags(tempid) & ADMIN_BAN) {
			new szStr[256];
			formatex(szStr, 255, "%s\y (ADMIN)", g_szName[tempid]);
			num_to_str(tempid, szStr, charsmax(szStr));
			menu_additem(menu, g_szName[tempid], szTempid, 0, callback);
		}
		else {
			num_to_str(tempid, szTempid, charsmax(szTempid));
			menu_additem(menu, g_szName[tempid], szTempid, 0);
		}
	}

	menu_display(id, menu);

	return PLUGIN_CONTINUE;
}

public CallMenuCallback(id, menu, item)
	return ITEM_DISABLED;

public CallMenuHandler(id, menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);

	new tempid = str_to_num(data);
	get_user_name(tempid, reported[id], 63);

	ReasonsMenu(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public ReasonsMenu(id) {
	new menu = menu_create("Wybierz Powod", "ReasonsMenuHandler");

	new reason[64];
	for(new i = 1; i < sizeof(callReasons); i++) {
		formatex(reason, charsmax(reason), "%s", callReasons[i]);
		menu_additem(menu, reason);
	}

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ReasonsMenuHandler(id, menu, item) {
	if( item == MENU_EXIT ) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	callReason = item+1;
	SendCall(id);

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public SendCall(id) {
	new Query[320];

	replace_all(g_szName[id], 63, "'", "''");
	replace_all(reported[id], 63, "'", "''");
	formatex( Query, charsmax(Query), DB_CALL, TABLE_NAME, g_szName[id], reported[id], callReasons[callReason], get_systime(), SERVER_NAME, TYPE_REPORT )
	SQL_ThreadQuery( SqlConnection, "QueryHandler", Query );

	client_print(id, print_center, "Wezwanie zostalo wyslane pomyslnie!");
}

public QueryHandler( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iDataSize, Float:flQueueTime )
{
	switch( iFailState ) {
		case TQUERY_CONNECT_FAILED: {
			log_amx( "Failed to connect to the database (%i): %s", iError, szError );
		}
		case TQUERY_QUERY_FAILED: {
			log_amx( "Error on query for QueryHandler() (%i): %s", iError, szError );
		}
		default: { /* NOTHING TO LOG */ }
	}
}