#include <amxmodx>
#include <amxmisc>
#include <time>
#include <fakemeta>
#include <sqlx>
#include <unixtime>
#include <ColorChat>

#define USING_TIMEZONE UT_TIMEZONE_UTC // for compatibility plugin and mysql timestamp

// uncomment if mysql should delete all expired entries (else will be removed only on player connection/unmute)
//#define MYSQL_FORCE_CLEAR

new pHost, pUser, pPass, pDatabase;
new szHost[64], szUser[64], szPass[64], szDatabase[64];
new Handle:hTuple;

// uncomment if hltv should hear all players
#define HLTV_LISTEN

new const adminlisten_flag = ADMIN_CHAT;
new const adminvoice_flag = ADMIN_CHAT;
new const mute_flag = ADMIN_CHAT;

new const menu_times[] = { 2, 5, 10, 30, 60, 180, 720, 1440, 4320, 0 };

new const alive_hear = 2; // 0 - zywi slysza wszystkich, 1 - zywi slysza zywych, 2 - zywi slysza team

enum _mute { _time, _flags[4] };
new mute[33][_mute];
new bool:muted[33][33];

new selected[33][3];
new bool:bAdminVoice[33];

public plugin_precache()
{
	register_dictionary("time.txt");
}

public plugin_init()
{
	register_plugin("Community Manager", "1.0", "FastKilleR");
	
	register_clcmd("say", "say_handle");
	register_clcmd("say_team", "say_team_handle");
	register_clcmd("amx_gagmenu", "cmd_mutemenu", mute_flag, "- Mute menu");
	register_clcmd("amx_mutemenu", "cmd_mutemenu", mute_flag, "- Mute menu");
	register_clcmd("amx_mute_menu", "cmd_mutemenu", mute_flag, "- Mute menu");
	register_clcmd("mute_time", "mute_time");
	register_clcmd("+voiceadmin", "voiceadmin_on");
	register_clcmd("-voiceadmin", "voiceadmin_off");
	
	register_concmd("amx_gag", "cmd_mute", mute_flag, "<nick> [time] [flags] | a - chat, b - team chat, c - voice");
	register_concmd("amx_mute", "cmd_mute", mute_flag, "<nick> [time] [flags] | a - chat, b - team chat, c - voice");
	register_concmd("amx_ungag", "cmd_unmute", mute_flag, "<nick> - Unmute player");
	register_concmd("amx_unmute", "cmd_unmute", mute_flag, "<nick> - Unmute player");
	
	register_forward(FM_Voice_SetClientListening, "Voice_SetClientListening");
	register_forward(FM_Sys_Error, "GameShutdown");
	register_forward(FM_GameShutdown, "GameShutdown");
	register_forward(FM_ServerDeactivate, "GameShutdown");
	
	pHost = register_cvar("mute_sql_host", "sql.pukawka.pl"); 
	pUser = register_cvar("mute_sql_user", "898035"); 
	pPass = register_cvar("mute_sql_pass", "zmKOLOSEUM");
	pDatabase = register_cvar("mute_sql_database", "898035_cmanager");
	
	server_exec();
	set_task(0.1, "sql_init");
	
	set_task(1.0, "Second", .flags="b");
}

public plugin_cfg()
{
	set_cvar_num("sv_alltalk", 0);
}

public sql_init()
{
	get_pcvar_string(pHost, szHost, charsmax(szHost));
	get_pcvar_string(pUser, szUser, charsmax(szUser));
	get_pcvar_string(pPass, szPass, charsmax(szPass));
	get_pcvar_string(pDatabase, szDatabase, charsmax(szDatabase));
	
	hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
	
	new qCommand[512];
	formatex(qCommand, charsmax(qCommand), "CREATE TABLE IF NOT EXISTS `mute` (`nick` VARCHAR(64), `authid` VARCHAR(35) NOT NULL,\
	`flags` VARCHAR(4) NOT NULL DEFAULT 'abc', `start` TIMESTAMP(2) NOT NULL DEFAULT CURRENT_TIMESTAMP(2),\
	`end` TIMESTAMP(2) NOT NULL DEFAULT '0000-00-00 00:00:00.00', `admin` VARCHAR(64), \
	PRIMARY KEY(`authid`)) DEFAULT CHARSET `utf8` COLLATE `utf8_general_ci`");
	SQL_ThreadQuery(hTuple, "TableHandle_Init", qCommand);
}

public TableHandle_Init(FailState, Handle:Query, Error[], Errorcode, Data[], DataSize, Float:QueryTime)
{
	if(Errorcode)
		log_amx("[INIT] Blad w zapytaniu (#%i): %s", Errorcode, Error);
	
	switch(FailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[INIT] Nie mozna polaczyc sie z baza danych.");
			return PLUGIN_CONTINUE;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[INIT] Zapytanie anulowane.");
			return PLUGIN_CONTINUE;
		}
	}
	
	log_amx("Mute Database loaded. Query time: %f", QueryTime);
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	selected[id][0] = 0;
	selected[id][1] = 0;
	selected[id][2] = 0;
	mute[id][_time] = 0;
	bAdminVoice[id] = false;
	client_cmd(id, "-voicerecord");
	
	for(new i = 1; i <= 32; ++i)
	{
		muted[id][i] = false;
		muted[i][id] = false;
	}
	
	new sid[35];
	get_user_authid(id, sid, charsmax(sid));
	
	new qCommand[216], Data[1];
	formatex(qCommand, charsmax(qCommand), "SELECT * FROM `mute` WHERE `authid` = '%s'", sid);
	Data[0] = id;
	SQL_ThreadQuery(hTuple, "TableHandle_Check", qCommand, Data, 1);
}

public TableHandle_Check(FailState, Handle:Query, Error[], Errorcode, Data[], DataSize, Float:QueryTime)
{
	new id = Data[0];
	
	if(Errorcode)
		log_amx("[CHECK] Blad w zapytaniu (#%i): %s", Errorcode, Error);
	
	switch(FailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[CHECK] Nie mozna polaczyc sie z baza danych.");
			return PLUGIN_CONTINUE;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[CHECK] Zapytanie anulowane.");
			return PLUGIN_CONTINUE;
		}
	}
	
	if(SQL_MoreResults(Query))
	{
		new szEnd[24];
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "end"), szEnd, charsmax(szEnd));
		
		if(equali(szEnd, "0000-00-00 00:00:00.00"))
		{
			mute[id][_time] = -1;
		}
		else
		{
			new szYear[5], szMonth[3], szDay[3], szHour[3], szMinute[3], szSecond[3];
			strtok(szEnd, szYear, charsmax(szYear), szEnd, charsmax(szEnd), '-', 1);
			strtok(szEnd, szMonth, charsmax(szMonth), szEnd, charsmax(szEnd), '-', 1);
			strtok(szEnd, szDay, charsmax(szDay), szEnd, charsmax(szEnd), ' ', 1);
			strtok(szEnd, szHour, charsmax(szHour), szEnd, charsmax(szEnd), ':', 1);
			strtok(szEnd, szMinute, charsmax(szMinute), szEnd, charsmax(szEnd), ':', 1);
			strtok(szEnd, szSecond, charsmax(szSecond), szEnd, charsmax(szEnd), '.', 1);
			
			new unix = TimeToUnix(str_to_num(szYear), str_to_num(szMonth), str_to_num(szDay), str_to_num(szHour), str_to_num(szMinute), str_to_num(szSecond), USING_TIMEZONE);
			
			new y, m, d, h, mi, s;
			date(y, m, d);
			time(h, mi, s);
			
			new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
			
			if(current >= unix)
			{
				new sid[35], qCommand[216];
				get_user_authid(id, sid, charsmax(sid));
				formatex(qCommand, charsmax(qCommand), "DELETE FROM `mute` WHERE `mute`.`authid` = '%s'", sid);
				SQL_ThreadQuery(hTuple, "TableHandle_Delete", qCommand);
				
				mute[id][_time] = 0;
				return PLUGIN_CONTINUE;
			}
			
			mute[id][_time] = unix;
		}
		
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "flags"), mute[id][_flags], 3);
		return PLUGIN_CONTINUE;
	}
	
	mute[id][_time] = 0;
	return PLUGIN_CONTINUE;
}

public TableHandle_Delete(FailState, Handle:Query, Error[], Errorcode, Data[], DataSize, Float:QueryTime)
{
	if(Errorcode)
		log_amx("[DELETE] Blad w zapytaniu (#%i): %s", Errorcode, Error);
	
	switch(FailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[DELETE] Nie mozna polaczyc sie z baza danych.");
			return PLUGIN_CONTINUE;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[DELETE] Zapytanie anulowane.");
			return PLUGIN_CONTINUE;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public say_handle(id)
{
	new say[180];
	read_args(say, charsmax(say));
	remove_quotes(say);
	
	if(equali(say, "/mute"))
	{
		MuteMenu(id, 0);
		return PLUGIN_CONTINUE;
	}
	
	if(equali(say, "/vm") || equali(say, "/glos") || equali(say, "/cm"))
	{
		switch(alive_hear)
		{
			case 0: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich graczy^1.");
			case 1: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich zywych graczy^1.");
			case 2: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich graczy z teamu^1.");
		}
		
		ColorChat(id, GREEN, "[CM]^3 Martwi gracze^1 slysza^3 wszystkich graczy^1.");
		return PLUGIN_CONTINUE;
	}
	
	if(equali(say, "/buy") || equali(say, "/menu") || equali(say, "/achs"))
		return PLUGIN_CONTINUE;

	if(get_user_flags(id) & ADMIN_CHAT && say[0] == '@')
		return PLUGIN_CONTINUE;
	
	if(mute[id][_time] && containi(mute[id][_flags], "a") > -1)
	{
		if(mute[id][_time] == -1)
		{
			client_print(id, print_chat, "Jestes zmutowany. Nie mozesz pisac.");
			return PLUGIN_HANDLED;
		}
		
		new y, m, d, h, mi, s;
		date(y, m, d);
		time(h, mi, s);
		
		new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
		
		if(current < mute[id][_time])
		{
			client_print(id, print_chat, "Jestes zmutowany. Nie mozesz pisac.");
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public say_team_handle(id)
{
	new say[180];
	read_args(say, charsmax(say));
	remove_quotes(say);
	
	if(equali(say, "/mute"))
	{
		MuteMenu(id, 0);
		return PLUGIN_CONTINUE;
	}
	
	if(equali(say, "/vm") || equali(say, "/glos") || equali(say, "/cm"))
	{
		switch(alive_hear)
		{
			case 0: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich graczy^1.");
			case 1: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich zywych graczy^1.");
			case 2: ColorChat(id, GREEN, "[CM]^3 Zywi gracze^1 slysza^3 wszystkich graczy z teamu^1.");
		}
		
		ColorChat(id, GREEN, "[CM]^3 Martwi gracze^1 slysza^3 wszystkich graczy^1.");
		return PLUGIN_CONTINUE;
	}
	
	if(equali(say, "/buy") || equali(say, "/daj") || equali(say, "/achs"))
		return PLUGIN_CONTINUE;
	
	if(mute[id][_time] && containi(mute[id][_flags], "b") > -1)
	{
		if(mute[id][_time] == -1)
		{
			ColorChat(id, GREEN, "[CM]^x01 Jestes zmutowany. Nie mozesz pisac jeszcze przez^x04 %d:%02d.", mute[id][_time]/60, mute[id][_time]);
			return PLUGIN_HANDLED;
		}
		
		new y, m, d, h, mi, s;
		date(y, m, d);
		time(h, mi, s);
		
		new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
		
		if(current < mute[id][_time])
		{
			ColorChat(id, GREEN, "[CM]^x01 Jestes zmutowany. Nie mozesz pisac jeszcze przez^x04 %d:%02d.", mute[id][_time]/60, mute[id][_time]);
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public MuteMenu(id, page)
{
	new menu = menu_create("\yMute:", "MuteMenu_Handle");
	
	for(new i = 1; i <= 32; ++i)
	{
		if(!is_user_connected(i))
			continue;
		
		new nick[32], item[48];
		get_user_name(i, nick, charsmax(nick));
		copy(item, charsmax(item), nick);
		if(muted[id][i]) add(item, charsmax(item), " \y(Muted)");
		
		menu_additem(menu, item, nick);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, page);
}

public MuteMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	new dostep, nick[32], itemname[48], cb;
	menu_item_getinfo(menu, item, dostep, nick, charsmax(nick), itemname, charsmax(itemname), cb);
	menu_destroy(menu);
	
	new target = get_user_index(nick);
	
	if(!target)
	{
		MuteMenu(id, item / 7);
		return;
	}
	
	muted[id][target] = !muted[id][target];
	client_print(id, print_chat, "%smutowano gracza %s", muted[id][target] ? "Z" : "Od", nick);
	MuteMenu(id, item / 7);
}

public cmd_mute(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED_MAIN;
	
	new arg[32], arg2[12], arg3[4];
	read_argv(1, arg, charsmax(arg));
	read_argv(2, arg2, charsmax(arg2));
	read_argv(3, arg3, charsmax(arg3));
	trim(arg2);
	
	new target = cmd_target(id, arg, 3);
	
	if(!target)
		return PLUGIN_HANDLED_MAIN;
	
	if(mute[target][_time])
	{
		console_print(id, "Wybrany gracz jest juz zmutowany.");
		return PLUGIN_HANDLED_MAIN;
	}
	
	new argc = read_argc();
	
	if(argc >= 3 && !is_str_num(arg2))
	{
		console_print(id, "Musisz podac dodatnia liczbe calkowita lub 0 !");
		return PLUGIN_HANDLED_MAIN;
	}
	
	new iArg2 = argc >= 3 ? str_to_num(arg2) : 5;
	
	new y, m, d, h, mi, s;
	date(y, m, d);
	time(h, mi, s);
	
	new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
	
	if(iArg2)
	{
		current += iArg2 * 60;
		mute[target][_time] = current;
	}
	else mute[target][_time] = -1;
	
	format(mute[target][_flags], 3, "");
	if(containi(arg3, "a") > -1) add(mute[target][_flags], 3, "a");
	if(containi(arg3, "b") > -1) add(mute[target][_flags], 3, "b");
	if(containi(arg3, "c") > -1) add(mute[target][_flags], 3, "c");
	
	new nick[32], admin[32], sid[35], szEnd[24], qCommand[512];
	get_user_name(target, nick, charsmax(nick));
	get_user_name(id, admin, charsmax(admin));
	if(!id && cvar_exists("amxbans_servernick")) get_cvar_string("amxbans_servernick", admin, charsmax(admin));
	get_user_authid(target, sid, charsmax(sid));
	UnixToTime(current, y, m, d, h, mi, s, USING_TIMEZONE);
	if(iArg2) formatex(szEnd, charsmax(szEnd), "%04i-%02i-%02i %02i:%02i:%02i.00", y, m, d, h, mi, s);
	else formatex(szEnd, charsmax(szEnd), "0000-00-00 00:00:00.00");
	formatex(qCommand, charsmax(qCommand), "INSERT INTO `mute` SET `nick` = ^"%s^", `authid` = '%s', `flags` = '%s',\
	`end` = '%s', `admin` = ^"%s^"", nick, sid, mute[target][_flags], szEnd, admin);
	SQL_ThreadQuery(hTuple, "TableHandle_Add", qCommand);
	
	new sp[160];
	get_time_length(LANG_SERVER, iArg2, timeunit_minutes, sp, charsmax(sp));
	console_print(id, "Gracz %s zostal zmutowany na %s.", nick, iArg2 ? sp : "zawsze");
	
	format(sp, charsmax(sp), "zmutowal %s na %s (", nick, iArg2 ? sp : "zawsze");
	
	if(containi(arg3, "a") > -1) add(sp, charsmax(sp), "chat, ");
	if(containi(arg3, "b") > -1) add(sp, charsmax(sp), "team, ");
	if(containi(arg3, "c") > -1) add(sp, charsmax(sp), "voice");
	
	if(strlen(sp) >= 2 && sp[strlen(sp)-2] == ',')
	{
		sp[strlen(sp)-1] = 0;
		sp[strlen(sp)-1] = 0;
	}
	
	add(sp, charsmax(sp), ")");
	show_activity(id, admin, sp);
	
	return PLUGIN_HANDLED_MAIN;
}

public cmd_unmute(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED_MAIN;
	
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	new target = cmd_target(id, arg, 3);
	
	if(!target)
		return PLUGIN_HANDLED_MAIN;
	
	if(!mute[target][_time])
	{
		console_print(id, "Wybrany gracz nie jest zmutowany.");
		return PLUGIN_HANDLED_MAIN;
	}
	
	new nick[32], admin[32], sid[35], qCommand[216];
	get_user_name(target, nick, charsmax(nick));
	get_user_name(id, admin, charsmax(admin));
	if(!id && cvar_exists("amxbans_servernick")) get_cvar_string("amxbans_servernick", admin, charsmax(admin));
	get_user_authid(target, sid, charsmax(sid));
	formatex(qCommand, charsmax(qCommand), "DELETE FROM `mute` WHERE `mute`.`authid` = '%s'", sid);
	SQL_ThreadQuery(hTuple, "TableHandle_Delete", qCommand);
	
	mute[target][_time] = 0;
	
	console_print(id, "Gracz %s zostal odmutowany.", nick);
	show_activity(id, admin, "odmutowal %s", nick);
	
	return PLUGIN_HANDLED_MAIN;
}

public TableHandle_Add(FailState, Handle:Query, Error[], Errorcode, Data[], DataSize, Float:QueryTime)
{
	if(Errorcode)
		log_amx("[ADD] Blad w zapytaniu (#%i): %s", Errorcode, Error);
	
	switch(FailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[ADD] Nie mozna polaczyc sie z baza danych.");
			return PLUGIN_CONTINUE;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[ADD] Zapytanie anulowane.");
			return PLUGIN_CONTINUE;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public cmd_mutemenu(id, level, cid)
{
	static s_cid;
	if(cid) s_cid = cid;
	
	if(level == 0 && cid == 0)
	{
		if(!cmd_access(id, mute_flag, s_cid, 1))
			return PLUGIN_HANDLED_MAIN;
	}
	else if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED_MAIN;
	
	new menu = menu_create("\yZmutuj gracza", "cmd_mutemenu_time");
	new cb = menu_makecallback("cb_mutemenu");
	
	for(new i = 1; i <= 32; ++i)
	{
		if(!is_user_connected(i))
			continue;
		
		new nick[32], item[48];
		get_user_name(i, nick, charsmax(nick));
		copy(item, charsmax(item), nick);
		
		if(mute[i][_time])
		{
			add(item, charsmax(item), " \y(Zmutowany: ");
			add(item, charsmax(item), mute[i][_flags]);
			add(item, charsmax(item), ")");
		}
		
		menu_additem(menu, item, nick, _, cb);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
	return PLUGIN_HANDLED_MAIN;
}

public cb_mutemenu(id, menu, item)
{
	if(item == MENU_EXIT)
		return ITEM_ENABLED;
	
	new dostep, nick[32], itemname[48], cb;
	menu_item_getinfo(menu, item, dostep, nick, charsmax(nick), itemname, charsmax(itemname), cb);
	
	new target = get_user_index(nick);
	
	if(get_user_flags(target) & ADMIN_IMMUNITY && target != id)
		return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public cmd_mutemenu_time(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	new dostep, nick[32], itemname[48], cb;
	menu_item_getinfo(menu, item, dostep, nick, charsmax(nick), itemname, charsmax(itemname), cb);
	menu_destroy(menu);
	
	new target = get_user_index(nick);
	
	if(!target || get_user_flags(target) & ADMIN_IMMUNITY && target != id)
	{
		cmd_mutemenu(id, 0, 0);
		return;
	}
	
	selected[id][0] = target;
	
	if(mute[target][_time])
	{
		new szTitle[128], sp[64], iTime = (mute[target][_time] - get_systime() - 7200)
		get_time_length(LANG_SERVER, iTime, timeunit_seconds, sp, charsmax(sp));
		formatex(szTitle, charsmax(szTitle), "\yCzy chcesz odmutowac tego gracza ?^n\w%s^nPozostaly czas:^n\y%s", nick, (iTime > 0) ? sp : "na zawsze");
		menu = menu_create(szTitle, "cmd_mutemenu_del");
		
		menu_additem(menu, "Tak");
		menu_additem(menu, "Nie");
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		
		menu_display(id, menu);
		return;
	}
	
	new szTitle[64];
	formatex(szTitle, charsmax(szTitle), "\w%s^n\yWybierz czas:", nick);
	menu = menu_create(szTitle, "cmd_mutemenu_flags");
	
	menu_additem(menu, "Wlasny czas");
	
	for(new i = 0; i < sizeof menu_times; ++i)
	{
		if(menu_times[i])
		{
			new sp[64], szTime[12];
			get_time_length(LANG_SERVER, menu_times[i], timeunit_minutes, sp, charsmax(sp));
			num_to_str(menu_times[i], szTime, charsmax(szTime));
			menu_additem(menu, sp, szTime);
		}
		else menu_additem(menu, "Na zawsze", "0");
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
}

public cmd_mutemenu_del(id, menu, item)
{
	menu_destroy(menu);
	
	if(item == MENU_EXIT)
		return;
	
	if(item == 1)
	{
		cmd_mutemenu(id, 0, 0);
		return;
	}
	
	new nick[32], admin[32], sid[35], qCommand[216];
	get_user_name(selected[id][0], nick, charsmax(nick));
	get_user_name(id, admin, charsmax(admin));
	if(!id && cvar_exists("amxbans_servernick")) get_cvar_string("amxbans_servernick", admin, charsmax(admin));
	get_user_authid(selected[id][0], sid, charsmax(sid));
	formatex(qCommand, charsmax(qCommand), "DELETE FROM `mute` WHERE `mute`.`authid` = '%s'", sid);
	SQL_ThreadQuery(hTuple, "TableHandle_Delete", qCommand);
	
	mute[selected[id][0]][_time] = 0;
	
	console_print(id, "Gracz %s zostal odmutowany.", nick);
	show_activity(id, admin, "odmutowal %s", nick);
	
	cmd_mutemenu(id, 0, 0);
}

public cmd_mutemenu_flags(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	new dostep, info[12], itemname[48], cb;
	menu_item_getinfo(menu, item, dostep, info, charsmax(info), itemname, charsmax(itemname), cb);
	menu_destroy(menu);
	
	if(!selected[id][0] || get_user_flags(selected[id][0]) & ADMIN_IMMUNITY && selected[id][0] != id || mute[selected[id][0]][_time])
	{
		cmd_mutemenu(id, 0, 0);
		return;
	}
	
	if(!item)
	{
		client_cmd(id, "messagemode mute_time");
		return;
	}
	
	selected[id][1] = str_to_num(info);
	cmd_mutemenu_flags2(id);
}

public cmd_mutemenu_flags2(id)
{
	new nick[32], sp[64], szTitle[96];
	get_user_name(selected[id][0], nick, charsmax(nick));
	get_time_length(LANG_SERVER, selected[id][1], timeunit_minutes, sp, charsmax(sp));
	formatex(szTitle, charsmax(szTitle), "\w%s^nCzas: %s^n\yWybierz flagi:", nick, selected[id][1] ? sp : "Na zawsze");
	
	new menu = menu_create(szTitle, "cmd_mutemenu_flags3");
	
	if(selected[id][2] & (1<<0)) menu_additem(menu, "\yChat");
	else menu_additem(menu, "\wChat");
	if(selected[id][2] & (1<<1)) menu_additem(menu, "\yTeam Chat");
	else menu_additem(menu, "\wTeam Chat");
	if(selected[id][2] & (1<<2)) menu_additem(menu, "\yVoice");
	else menu_additem(menu, "\wVoice");
	
	menu_addblank(menu, 0);
	
	if(selected[id][2])
		menu_additem(menu, "Zmutuj");
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
}

public cmd_mutemenu_flags3(id, menu, item)
{
	menu_destroy(menu);
	
	if(item == MENU_EXIT)
		return;
	
	if(item == 3)
	{
		cmd_mutemenu_done(id);
		return;
	}
	
	if(selected[id][2] & (1<<item)) selected[id][2] &= ~(1<<item);
	else selected[id][2] |= (1<<item);
	cmd_mutemenu_flags2(id);
}

public mute_time(id)
{
	if(!(get_user_flags(id) & mute_flag))
		return PLUGIN_HANDLED_MAIN;
	
	new arg[12];
	read_argv(1, arg, charsmax(arg));
	trim(arg);
	
	if(!is_str_num(arg))
	{
		client_print(id, print_chat, "Musisz podac dodatnia liczbe calkowita lub 0 !");
		cmd_mutemenu(id, 0, 0);
		return PLUGIN_HANDLED_MAIN;
	}
	
	selected[id][1] = str_to_num(arg);
	cmd_mutemenu_flags2(id);
	return PLUGIN_HANDLED_MAIN;
}

public cmd_mutemenu_done(id)
{
	new y, m, d, h, mi, s;
	date(y, m, d);
	time(h, mi, s);
	
	new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
	
	if(selected[id][1])
	{
		current += selected[id][1] * 60;
		mute[selected[id][0]][_time] = current;
	}
	else mute[selected[id][0]][_time] = -1;
	
	format(mute[selected[id][0]][_flags], 3, "");
	if(selected[id][2] & (1<<0)) add(mute[selected[id][0]][_flags], 3, "a");
	if(selected[id][2] & (1<<1)) add(mute[selected[id][0]][_flags], 3, "b");
	if(selected[id][2] & (1<<2)) add(mute[selected[id][0]][_flags], 3, "c");
	
	new nick[32], admin[32], sid[35], szEnd[24], qCommand[512];
	get_user_name(selected[id][0], nick, charsmax(nick));
	get_user_name(id, admin, charsmax(admin));
	if(!id && cvar_exists("amxbans_servernick")) get_cvar_string("amxbans_servernick", admin, charsmax(admin));
	get_user_authid(selected[id][0], sid, charsmax(sid));
	UnixToTime(current, y, m, d, h, mi, s, USING_TIMEZONE);
	if(selected[id][1]) formatex(szEnd, charsmax(szEnd), "%04i-%02i-%02i %02i:%02i:%02i.00", y, m, d, h, mi, s);
	else formatex(szEnd, charsmax(szEnd), "0000-00-00 00:00:00.00");
	formatex(qCommand, charsmax(qCommand), "INSERT INTO `mute` SET `nick` = ^"%s^", `authid` = '%s', `flags` = '%s',\
	`end` = '%s', `admin` = ^"%s^"", nick, sid, mute[selected[id][0]][_flags], szEnd, admin);
	SQL_ThreadQuery(hTuple, "TableHandle_Add", qCommand);
	
	new sp[160];
	get_time_length(LANG_SERVER, selected[id][1], timeunit_minutes, sp, charsmax(sp));
	console_print(id, "Gracz %s zostal zmutowany na %s.", nick, selected[id][1] ? sp : "zawsze");
	
	format(sp, charsmax(sp), "zmutowal %s na %s (", nick, selected[id][1] ? sp : "zawsze");
	
	if(selected[id][2] & (1<<0)) add(sp, charsmax(sp), "chat, ");
	if(selected[id][2] & (1<<1)) add(sp, charsmax(sp), "team, ");
	if(selected[id][2] & (1<<2)) add(sp, charsmax(sp), "voice");
	
	if(strlen(sp) >= 2 && sp[strlen(sp)-2] == ',')
	{
		sp[strlen(sp)-1] = 0;
		sp[strlen(sp)-1] = 0;
	}
	
	add(sp, charsmax(sp), ")");
	if(sp[strlen(sp)-1] == '/') sp[strlen(sp)-1] = 0;
	show_activity(id, admin, sp);
	
	cmd_mutemenu(id, 0, 0);
}

public client_authorized(id)
{
	if(!(get_user_flags(id) & adminvoice_flag))
	{
		if(bAdminVoice[id])
		{
			client_cmd(id, "-voicerecord");
			bAdminVoice[id] = false;
		}
	}
}

public voiceadmin_on(id)
{
	if(bAdminVoice[id])
	{
		if(!(get_user_flags(id) & adminvoice_flag))
		{
			bAdminVoice[id] = false;
			client_cmd(id, "-voicerecord");
		}
		
		return PLUGIN_HANDLED_MAIN;
	}
	
	if(!(get_user_flags(id) & adminvoice_flag))
		return PLUGIN_HANDLED_MAIN;
	
	client_cmd(id, "+voicerecord");
	bAdminVoice[id] = true;
	
	ColorChat(0, GREEN, "[!]^1 Cisza!^3 Admin^1 przemawia.");
	
	return PLUGIN_HANDLED_MAIN;
}

public voiceadmin_off(id)
{
	if(!bAdminVoice[id])
		return PLUGIN_HANDLED_MAIN;
	
	client_cmd(id, "-voicerecord");
	bAdminVoice[id] = false;
	
	return PLUGIN_HANDLED_MAIN;
}

public Voice_SetClientListening(receiver, sender, listen)
{
	#if defined HLTV_LISTEN
	if(is_user_hltv(receiver) && (!mute[sender][_time] || containi(mute[sender][_flags], "c") == -1))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true);
		forward_return(FMV_CELL, true);
		return FMRES_SUPERCEDE;
	}
	#endif
	
	if(muted[receiver][sender])
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false);
		forward_return(FMV_CELL, false);
		return FMRES_SUPERCEDE;
	}
	
	if(is_user_alive(receiver) && !(get_user_flags(receiver) & adminlisten_flag) && !bAdminVoice[sender])
	{
		if(alive_hear >= 1 && !is_user_alive(sender) || alive_hear >= 2 && get_user_team(sender) != get_user_team(receiver))
		{
			engfunc(EngFunc_SetClientListening, receiver, sender, false);
			forward_return(FMV_CELL, false);
			return FMRES_SUPERCEDE;
		}
	}
	
	new bool:someone;
	for(new i = 1; i <= 32; ++i)
	{
		if(is_user_connected(i) && bAdminVoice[i])
		{
			someone = true;
			break;
		}
	}
	
	if(someone && !bAdminVoice[sender])
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false);
		forward_return(FMV_CELL, false);
		return FMRES_SUPERCEDE;
	}
	
	if(mute[sender][_time] && containi(mute[sender][_flags], "c") > -1)
	{
		if(mute[sender][_time] == -1)
		{
			engfunc(EngFunc_SetClientListening, receiver, sender, false);
			forward_return(FMV_CELL, false);
			return FMRES_SUPERCEDE;
		}
		
		new y, m, d, h, mi, s;
		date(y, m, d);
		time(h, mi, s);
		
		new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
		
		if(mute[sender][_time] > current)
		{
			engfunc(EngFunc_SetClientListening, receiver, sender, false);
			forward_return(FMV_CELL, false);
			return FMRES_SUPERCEDE;
		}
	}
	
	engfunc(EngFunc_SetClientListening, receiver, sender, true);
	forward_return(FMV_CELL, true);
	return FMRES_SUPERCEDE;
}

public Second()
{
	for(new i = 1; i <= 32; ++i)
	{
		if(!is_user_connected(i) || mute[i][_time] <= 0)
			continue;
		
		new y, m, d, h, mi, s;
		date(y, m, d);
		time(h, mi, s);
		
		new current = TimeToUnix(y, m, d, h, mi, s, USING_TIMEZONE);
		
		if(mute[i][_time] <= current)
		{
			mute[i][_time] = 0;
			
			new sid[35], qCommand[216];
			get_user_authid(i, sid, charsmax(sid));
			formatex(qCommand, charsmax(qCommand), "DELETE FROM `mute` WHERE `mute`.`authid` = '%s'", sid);
			SQL_ThreadQuery(hTuple, "TableHandle_Delete", qCommand);
			
			new nick[32];
			get_user_name(i, nick, charsmax(nick));
			client_print(0, print_chat, "%s nie jest juz zmutowany", nick);
		}
	}
}

public plugin_end()
{
	mysql_force_clear();
}

public GameShutdown()
{
	mysql_force_clear();
}

public mysql_force_clear()
{
	#if !defined MYSQL_FORCE_CLEAR
	return;
	#else
	new qCommand[216];
	formatex(qCommand, charsmax(qCommand), "DELETE FROM `mute` WHERE `end` != '0000-00-00 00:00:00.00' AND `end` < CURRENT_TIMESTAMP(2)");
	SQL_ThreadQuery(Query, "TableHandle_Delete", qCommand);
	#endif
}
