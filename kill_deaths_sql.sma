#include <amxmodx>
#include <csx>
#include <hamsandwich>
#include <colorchat>
#include <sqlx>

#define PLUGIN "sql"
#define VERSION "1.0"
#define AUTHOR "Dla CheQ :D"

//Do topki
#define TOP_DATA_BUFFER_SIZE 1536
//
//Zmienne
new nazwa_gracza[33][48]
new Handle:g_SqlTuple
new bool:WczytaneDane[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	//Cvary
	register_cvar("amx_test_host", "localhost") 
	register_cvar("amx_test_user", "root")
	register_cvar("amx_test_pass", "root") 
	register_cvar("amx_test_db", "db")
	//Polaczenie z baza
	set_task(1.0, "polacz")
	RegisterHam(Ham_Spawn, "player", "respawn", 1) // Spawn gracza = Zapis danych do bazy 
	register_clcmd("say /top15","Topka") // Wyłącz statsx.amxx żeby zobaczyć efekt , komenda na 15 najlepszych graczy :P
	register_clcmd("say /rank","rank") // To samo wyłącz statsx.amxx + komenda na swój ranking
}
public polacz()
{
	//Pobieranie cvarow
	new Host[32], User[32], Pass[32], DB[32]
	get_cvar_string("amx_test_host", Host, 31)
	get_cvar_string("amx_test_user", User, 31)
	get_cvar_string("amx_test_pass", Pass, 31)
	get_cvar_string("amx_test_db", DB, 31) 
	//Tworzenie połączenia
	g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,DB)
	
	//Błąd jeśli nie może się połączyć etc.
	new error, szError[128]
	new Handle:hConn = SQL_Connect(g_SqlTuple,error,szError, 127)
	if(error){
		log_amx("Error: %s", szError)
		return;
	}
	//Połączył się tworzy tabelke Pierw sprawdza czy ona przypadkiem nie istnieje, w tabeli bedzie znajdował się name czyli nick gracza max znaków 64 oraz ile razy zabił
	new Handle:Queries = SQL_PrepareQuery(hConn,"CREATE TABLE IF NOT EXISTS `Test` (name VARCHAR(64) NOT NULL, kill INT(10) NOT NULL DEFAULT 0, PRIMARY KEY(name))") 
	//Nazwa tabelki Test ;)
	//Uwalanianie połączenia z bazą
	SQL_Execute(Queries)
	SQL_FreeHandle(Queries)
	SQL_FreeHandle(hConn)
}
public plugin_end()
{
	SQL_FreeHandle(g_SqlTuple) // Koniec mapy zamykamy , uwalniamy połączenie
}

public client_disconnected(id)
{
	save(id) // Gracz wychodzi zapisz
}
public client_authorized(id)
{
	get_user_name(id, nazwa_gracza[id], charsmax(nazwa_gracza[])) // Pobieranie nicku gracza do zmiennej w pierwszym połączeniu tylko pobierze w drugim będzie sprawdzał ( patrz client_connect)
	replace_all(nazwa_gracza[id], charsmax(nazwa_gracza[]), "'", "\'")
	WczytaneDane[id] = false
	load(id)
}
public load(id)
{
	//Pobieranie nicku gracza + sprawdzanie tego nicku + zamiana jesli w nicku wystepuje znak ' lub `
	new szTemp[512]
	
	new data[1] //Zmienna
	data[0] = id // Id gracza 
	
	formatex(szTemp,charsmax(szTemp),"SELECT * FROM `Test` WHERE `name` = '%s'", nazwa_gracza[id]) // Wyciągamy z bazy nick gracza
	SQL_ThreadQuery(g_SqlTuple,"register_client",szTemp, data, sizeof(data))
}

public register_client(failstate, Handle:query, error[],errcode, data[], datasize)
{
	if(failstate != TQUERY_SUCCESS){
		log_amx("<Query> Error: %s", error)
		return;
	}
	new id = data[0];
	if(!is_user_connected(id) && !is_user_connecting(id)) // Gracz nie połączony anuluje akcje
		return;
	
	if(SQL_NumRows(query)) // Zapytanie znalazlo gracza z tym nickiem 
	{
		WczytaneDane[id] = true  // Zmienna na true 
		// Jesli do pluginu zrobisz własną zmienną musisz ją przechwycić tutaj ,w tym przypadku zabójstwa gracza nie trzeba do to istnieje juz w <csx>
		//Przechwycić można tak
		// Zmienna[id]  = SQL_ReadResult(query, SQL_FieldNameToNum(query,"Nazwa kolumny"));
	} 
	else // Nie ma nic trzeba dodać gracza do bazy
	{
		//Pobieranie nicku gracza etc.
		new stats[8], bodyhits[8]
		get_user_stats(id, stats, bodyhits)
		
		new szTemp[512], data[1]
		data[0] = id
		formatex(szTemp,charsmax(szTemp),"INSERT INTO `Test` (`name`, `kill`) VALUES ('%s','%d')", nazwa_gracza[id], stats) // Dodajemy do bazy dane nick i ilosc zabojstw
		SQL_ThreadQuery(g_SqlTuple,"IgnoreHandleInsert",szTemp,data, 1)
	}
}
public save(id)
{       
	if(!WczytaneDane[id]) // Jeśli nie wczytało danych musi jeszcze raz załadować się  żeby nick nie stracił swojej wartośći zmiennej
	{
		load(id);
		return PLUGIN_HANDLED;
	}
	//Pobieranie nicku etc.
	new szTemp[512]
	new stats[8],bodyhits[8]
	get_user_stats(id, stats, bodyhits)
	
	formatex(szTemp,charsmax(szTemp),"UPDATE `Test` SET `kill` = '%d' WHERE `name` = '%s'",stats, nazwa_gracza[id]) // Zmienia wartosc zabojstw gdzie nick = nick_gracza
	SQL_ThreadQuery(g_SqlTuple,"IgnoreHandleSave",szTemp)
	return PLUGIN_CONTINUE
}

public IgnoreHandleInsert(failstate, Handle:query, error[], errnum, data[], size){ // Jeśli błąd to loguje
	if(failstate != TQUERY_SUCCESS){
		log_amx("<Query> Error: %s", error);
		return;
	}
	WczytaneDane[data[0]] = true; // Jesli wszystko bedzie dobrze zmienna zmieni wartosc na true ( patrz funckja register_client    SQL_ThreadQuery(g_SqlTuple,"IgnoreHandleInsert",szTemp,data, 1)
}

public IgnoreHandleSave(failstate, Handle:query, error[], errnum, data[], size){  // Jeśli błąd to loguje
	if(failstate != TQUERY_SUCCESS){
		log_amx("<Query> Error: %s", error);
		return;
	}
}
public respawn(id)
{
	if(is_user_alive(id))
	{
		// Jeśli zyje zapisz dane , pozwoli to na lepszy odczyt top15 , oraz ranku :D
		save(id)
	}
}
public rank(id)
{
	//Zmianne
	new Data[1]
	Data[0] = id
	new stats[8],bodyhits[8]
	get_user_stats(id, stats, bodyhits)
	new szTemp[512]
	format(szTemp,charsmax(szTemp),"SELECT COUNT(*) FROM `Test` WHERE `kill` >= %d", stats) // Wyciaganie z bazy count czyli w tej sytuacji twoje miejsce
	SQL_ThreadQuery(g_SqlTuple,"Rank2",szTemp,Data,1)
	
	return PLUGIN_CONTINUE
}

public Rank2(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	new count = 0
	count = SQL_ReadResult(Query,0)
	if(count == 0)
	count = 1
	
	new id
	id = Data[0]
	new stats[8],bodyhits[8]
	get_user_stats(id, stats, bodyhits)
	ColorChat(id, RED, "^x01 Zajmujesz %i miejsce z %d zabojstwami.", count,stats) // Miejsce + ilość zabójstw
	
	return PLUGIN_HANDLED
}
public Topka(id)
{
	//Zmienne
	new szTemp[512]
	static Data[2]
	
	Data[0] = id
	
	format(szTemp,charsmax(szTemp),"SELECT * FROM Test ORDER BY kill DESC LIMIT 15")  // Wyciaganie  15 Najlepszych DESC czyli od największej do najmniejszej
	SQL_ThreadQuery(g_SqlTuple,"top",szTemp,Data,1)
}

public top(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState) 
	{
		log_amx("SQL Error: %s (%d)", Error, Errcode) // Błąd loguje error
		return PLUGIN_HANDLED
	}
	new id
	id = Data[0]
	static Data[TOP_DATA_BUFFER_SIZE], Title[33], Len, Place // Zmienne
	
	Place = 0
	// Wygląd motd znalazłem gdzieś na Allied ogólnie wygląd motd
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<center><table frame='^"border^"' width='^"600^"' cellspacing='^"0^"' bordercolor=^"#4A4344^" style='^"color:#56A5EC;text-align:center;^"'>")
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tbody><tr><td><b>#</b></td><td><b>Nick</b></td><td><b>Zabojstwa</b></td></tr>")
	
	while(SQL_MoreResults(Query))
	{
		Place++ // Pozycja ++
		static name[48],kill // Zmienne
		SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"name"),name,47) // Nick graczy kolumna 0
		kill = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"kill"))   // zabójstwa kolumna pierwsza pobieranie ich wartośći
		//Zamienianie nicku jeśli jest w nim < >
		replace_all(name, 32, "<", "")
		replace_all(name, 32, ">", "")
		
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tr>")// Pokazanie nicków pozycji ilośći zabójstw
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td><font color=^"Red^">%d</font></td>", Place)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%s</td>", name)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%d</td>", kill)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "</tr>")
		
		SQL_NextRow(Query) 
	}
	
	Len += formatex(Data[Len],TOP_DATA_BUFFER_SIZE - Len,"")
	
	formatex(Title, 32, "Top 15") // Tytuł
	show_motd(id, Data, Title) // Pokazanie motd
	
	return PLUGIN_HANDLED
}