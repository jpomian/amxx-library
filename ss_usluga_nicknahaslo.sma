/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <colorchat>
#include <nvadmins>
#include <smsshop>

new g_iUsluga;

#define NAZWA_DL "Nick na haslo" 				//Nazwa uslugi wyswietlana w menu
#define NAZWA_KR "nicknahaslo" 					//nazwa uslugi uzywana w logach, jako okienko MOTD itd.
#define FLAGA "z"						//flaga jaka ma dostac gracz

new const g_szJednostkaIlosci[][][] = {
	{ "7", "7 dni" },
	{ "14", "14 dni" },
	{ "30", "30 dni" },
	{ "90", "90 dni" }
	//Wypisz tutaj po kolei dlugosci uslug
	//Format: "kr. czas", "dl. czas"
	//dlugi czas - wyswietlany jest w np. menu
	//krotki czas - wykorzystywany w skryptach, aby dana usluga byla dostepna na zawsze wpisz -1
	//Pamietaj ze ostatnia usluga nie ma na koncu po klamrze przecinka!
}

new const g_szCena[][][] = {
	{ "1,23", "1,23 zl SMS" },
	{ "2,46", "2,46 zl SMS" },
	{ "3,69", "3,69 zl SMS" },
	{ "7,38", "7,38 zl SMS / 5 zl przelew" }
	//Wypisz tutaj w takiej samej kolejnosci jak dlugosci uslug ich ceny
	//Format: "kr. cena", "dl. cena"
	//krotka cena - cena SMSa uslugi - zlotowki i grosze oddzielone przecinkiem
	//dluga cena - cena wyswietlana w menu
	//Pamietaj ze ostatnia linijka nie ma na koncu po klamrze przecinka!
}

new bool:g_bHaslo[33];
new g_szOstatnioWpisaneHaslo[33][32];

public plugin_init() 
{
	new szNazwa[64]; formatex(szNazwa, 63, "Sklep SMS: Usluga %s", NAZWA_DL);
	register_plugin(szNazwa, "1.0", "d0naciak");
	
	g_iUsluga = ss_register_service(NAZWA_DL, NAZWA_KR, 0);
	
	for(new i = 0; i < sizeof g_szJednostkaIlosci; i++)
		ss_add_service_qu(g_iUsluga, g_szJednostkaIlosci[i][1], g_szJednostkaIlosci[i][0], g_szCena[i][1], g_szCena[i][0]);
	
	register_clcmd("WpiszHaslo", "cmd_HasloWpisane");
}

public client_connect(id)
	g_bHaslo[id] = false;
	
public ss_buy_service_pre(id, iUsluga, iJednostkaIlosci)
{
	if(iUsluga != g_iUsluga)
		return SS_CONTINUE;
	
	g_bHaslo[id] = true;
	client_cmd(id, "messagemode WpiszHaslo");
	ColorChat(id, GREEN, "[SKLEPSMS]^x01 Wpisz teraz haslo jakie ma byc ustawione na twoim nicku.");
	ColorChat(id, GREEN, "[SKLEPSMS]^x01 Haslo nie moze przekraczac^x03 32 znakow!");
	
	return SS_STOP;
}

public cmd_HasloWpisane(id)
{
	if(!g_bHaslo[id])
		return PLUGIN_CONTINUE;
	
	g_bHaslo[id] = false;

	read_argv(1, g_szOstatnioWpisaneHaslo[id], 31);
	ColorChat(id, GREEN, "[SKLEPSMS]^x01 Wpisano haslo:^x03 %s", g_szOstatnioWpisaneHaslo[id]);

	ss_go_to_choosing_pay_method(id);
	return PLUGIN_HANDLED;
}

public ss_buy_service_post(id, iUsluga, iJednostkaIlosci)
{
	if(iUsluga != g_iUsluga)
		return SS_CONTINUE;
	
	new szDataWaznosci[32], szNick[64];
			
	get_user_name(id, szNick, 63);
	
	if(equal(g_szJednostkaIlosci[iJednostkaIlosci][0], "-1")) 
		copy(szDataWaznosci, 31, g_szJednostkaIlosci[iJednostkaIlosci][0]);
	else
		na_get_data_after_days(str_to_num(g_szJednostkaIlosci[iJednostkaIlosci][0]), szDataWaznosci, 31);
	
	na_add_admin(szNick, 1, g_szOstatnioWpisaneHaslo[id], FLAGA, szDataWaznosci, NAZWA_KR);
	na_edit_admin(szNick, 1, 0, "", "", g_szOstatnioWpisaneHaslo[id]);
	
	ss_finalize_user_service(id);
	
	return SS_CONTINUE;
}