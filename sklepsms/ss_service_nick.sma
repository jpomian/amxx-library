#include <amxmodx>
#include <sms_shop>
#include <sqlx>

new /*bez const*/srv[__srv] = {
"Rezerwacja nicku", // Nazwa uslugi.
SS_TYPE_TIME, // Typ uslugi.
1, // Czy dodawac haslo ?
4, // Ilosc elementow po wybraniu uslugi.
0, // Zostawic na 0.
{ 30, 60, 120, 365 }, // Liczby do kolejnych elementow.
{ 2.46, 3.69, 6.15, 11.07 }, // Ceny kolejnych elementow.
1, // Czy usluga moze zostac kupiona wiele razy (chyba ze typem jest czas a gracz ma juz usluge) ?
{ 0, 0, 0, 0 }, // Jakie flagi nalezy miec aby moc kupic poszczegolny element ?
{ 0, 0, 0, 0 } // Jakich flag nie mozna miec zeby moc kupic poszczegolny element ?
};
new const subnames[][] = { "30 dni", "60 dni", "120 dni", "365 dni" }; // Nazwy kolejnych elementow.

new Handle:hTuple;

public plugin_init()
{
	register_plugin("[SKLEP-SMS] Usluga: Rezerwacja nicku", "1.0", "FastKilleR");
	ss_register_service2(srv, subnames, sizeof subnames);
	
	new szHost[64], szUser[64], szPass[64], szDatabase[64];
	get_cvar_string("ss_sql_host", szHost, charsmax(szHost));
	get_cvar_string("ss_sql_user", szUser, charsmax(szUser));
	get_cvar_string("ss_sql_pass", szPass, charsmax(szPass));
	get_cvar_string("ss_sql_database", szDatabase, charsmax(szDatabase));
	hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase)
}

public client_authorized(id)
{
	new qCommand[512], Data[1], szName[32];
	Data[0] = id;
	get_user_name(id, szName, charsmax(szName));
	formatex(qCommand, charsmax(qCommand), "SELECT * FROM `smsshop` WHERE (`%s` = '0' OR `%s` >= '%i') AND `nick` = ^"%s^"",
	srv[__name], srv[__name], get_systime(), szName);
	SQL_ThreadQuery(hTuple, "checkSql", qCommand, Data, 1);
}

public checkSql(FailState, Handle:Query, Error[], Errorcode, Data[], DataSize, Float:QueryTime)
{
	if(Errorcode)
		return;
	
	new szAuthID[35], szIP[16];
	get_user_authid(Data[0], szAuthID, charsmax(szAuthID));
	get_user_ip(Data[0], szIP, charsmax(szIP), 1);
	
	while(SQL_MoreResults(Query))
	{
		switch(SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "save")))
		{
			case 1:
			{
				new szCheck[35];
				SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "authid"), szCheck, charsmax(szCheck));
				
				if(!equali(szCheck, szAuthID))
				{
					server_cmd("kick #%i Zle SteamID ! Ten nick ma rezerwacje.", get_user_userid(Data[0]));
					return;
				}
			}
			case 2:
			{
				new szCheck[16];
				SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ip"), szCheck, charsmax(szCheck));
				
				if(!equali(szCheck, szIP))
				{
					server_cmd("kick #%i Zly adres IP ! Ten nick ma rezerwacje.", get_user_userid(Data[0]));
					return;
				}
			}
		}
		
		SQL_NextRow(Query);
	}
}
