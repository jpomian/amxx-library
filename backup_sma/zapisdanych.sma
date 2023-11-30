#include <amxmodx>
#include <sqlx>

new const g_SqlInfo[][] =
{ 
    "145.239.236.240",        // HOST 
    "srv66457",        // USER 
    "rmV7KCSYSV",    // User's password 
    "srv66457"       // Database Name 
}

enum playerData {
	SteamID[ 33 ],
	Nick[ 64 ],
	Kills,
    Infections,
};

new Handle: g_SqlTuple;
new gPlayer[ 33 ][ playerData ];

public plugin_init() {
	register_plugin("Sample Data Storage", "0.1a", "Mixtaz");
	register_event("DeathMsg", "registerKill", "a");
	register_clcmd("say /zabicia", "showStats");
	set_task(0.1, "init_sqldata");
}

public init_sqldata()
{
    g_SqlTuple = SQL_MakeDbTuple(g_SqlInfo[0], g_SqlInfo[1], g_SqlInfo[2], g_SqlInfo[3]);

    new qCommand[512];
    formatex(qCommand, charsmax(qCommand), "CREATE TABLE IF NOT EXISTS `statystyki` (`authid` VARCHAR(35) NOT NULL, `nick` VARCHAR(64) NOT NULL, \
	`kill` INT(11) NOT NULL  DEFAULT 0, `infections` INT(11) NOT NULL  DEFAULT 0, \
	PRIMARY KEY(`authid`)) DEFAULT CHARSET `utf8` COLLATE `utf8_general_ci`");

    SQL_ThreadQuery(g_SqlTuple, "TableHandle_Init", qCommand);
}

public client_putinserver( id ) {
	clearUserData(id);
	get_user_authid( id, gPlayer[ id ][ SteamID ], 32 );
	get_user_name( id, gPlayer[ id ][ Nick ], 63 );	 

	new qCommand[216], ids[1]; ids[0] = id;
	formatex(qCommand, charsmax(qCommand), "SELECT * FROM `statystyki` WHERE `authid` = ^"%s^" ORDER BY `authid` LIMIT 1", gPlayer[ id ][ SteamID ]);
	SQL_ThreadQuery(g_SqlTuple, "handleLoadData", qCommand, ids, 1);
}

public client_disconnected(id) {
	new qCommand[216]
	formatex(qCommand, charsmax(qCommand), "UPDATE `statystyki` SET `kill` = %d, `infections` = %d WHERE `authid` = ^"%s^"", gPlayer[ id ][ Kills ], gPlayer[ id ][ Infections ], gPlayer[ id ][ SteamID ]);
	SQL_ThreadQuery(g_SqlTuple, "handleStandard", qCommand);
	clearUserData(id);
}

public registerKill() {
	new kid = read_data(1);
	new vid = read_data(2);
	
	if(kid != vid && get_user_team(kid) != get_user_team(vid))
		gPlayer[kid][Kills]++;
}

public handleLoadData(failstate, Handle:query, error[], errnum, data[], size){
	if(failstate != TQUERY_SUCCESS){
		log_amx("SQL Load error: %s",error);
		return;
	}
	
	new id = data[0], qCommand[216];
	if(!is_user_connected(id)) return;
	
	if(SQL_MoreResults(query)) {
		gPlayer[id][Kills]		= SQL_ReadResult(query, 2);
		gPlayer[id][Infections]	= SQL_ReadResult(query, 3);
	} else {		
		formatex(qCommand, charsmax(qCommand), "INSERT INTO `statystyki` (`authid`, `nick`) VALUES (^"%s^", ^"%s^")", gPlayer[ id ][ SteamID ], gPlayer[ id ][ Nick ]);
		SQL_ThreadQuery(g_SqlTuple, "handleStandard", qCommand);
	}
}

public handleStandard(failstate, Handle:query, error[], errnum, data[], size) {
	if(failstate != TQUERY_SUCCESS) {
		log_amx("SQL Insert error: %s",error);
		return;
	}
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
	
	log_amx("[Biohazard] Zaladowano baze danych w czasie: %f", QueryTime);
	return PLUGIN_CONTINUE;
}

public showStats(id)
{
	client_print(id, print_chat, "Witaj! Masz %i zabic i %i infekcji", gPlayer[id][Kills], gPlayer[id][Infections])
}

public plugin_end()
{
    SQL_FreeHandle(g_SqlTuple);
}

stock clearUserData(id)
{
	gPlayer[id][Kills] = 0;
	gPlayer[id][Infections] = 0;
}