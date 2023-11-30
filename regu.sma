#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define BIO_WEB_LINK "biohazard.gameclan.pl"

new g_regType[33];

new const RulesCommands[][] =
	{
		"say /regulamin",
		"say_team /regulamin",
		"say /zasady",
		"say_team /zasady",
        "say /regu",
		"say_team /regu",
        "say /rules",
		"say_team /rules"
	};

public plugin_init()
{
    register_plugin("Regulamin MOTD", "0.1", "Mixtaz");
    
    for(new i=0; i < sizeof RulesCommands; i++)
        register_clcmd(RulesCommands[i], "cmdReguMenu")
}

public cmdReguMenu(id)
{
    new regumenu = menu_create("Regulaminy serwera", "regHandler");
    menu_additem(regumenu, "Zasady \dOgolne");
    menu_additem(regumenu, "Zasady dla \yCT");
    menu_additem(regumenu, "Zasady dla \rZombie^n");
    menu_display(id, regumenu);
}

public regHandler(id, menu, item)
{
    switch(item){
		case 0: reguOgolne(id);
		case 1: reguCT(id);
		case 2: reguZM(id);
	}

    ColorChat(id, GREEN, "[Regulamin]^x01 Jezeli okno MOTD nie pojawia sie, sprawdz Nasza oficjalna strone!")
    ColorChat(id, GREEN, "[Link]^x01 Link: biohazard.gameclan.pl. Mozesz go skopiowac w swojej konsoli.") 
    
    client_print(id, print_console, "*************************")
    client_print(id, print_console, "Link: %s", BIO_WEB_LINK)
    client_print(id, print_console, "*************************")
}

public reguOgolne(id)
{
    g_regType[id] = 1

    new regumenu = menu_create("Regulamin Ogólny", "regTypeHandler");
    menu_additem(regumenu, "Pełna wersja regulaminu \d(MOTD)^n")
    menu_addtext2(regumenu, "\y1.\w Zakaz używania cheatów, skryptów i wspomagaczy.")
    menu_addtext2(regumenu, "\y2.\w Zakaz nadmiernego spamowania na czacie lub przy użyciu mikrofonu") 
    menu_addtext2(regumenu, "\y3.\w Mikrofon jest dozwolony tylko po przejściu mutacji")
    menu_addtext2(regumenu, "\y4.\w Zakaz reklamowania innych serwerów lub sieci serwerów")
    menu_addtext2(regumenu, "\y5.\w Nie wolno podszywać się pod adminów bądź innych graczy")
    menu_addtext2(regumenu, "\y6.\w Na serwerze obowiązuje minimalna kultura osobista.")

    menu_additem(regumenu, "Zapoznałem sie z regulaminem \d(Wyjście)^n")
    menu_addtext2(regumenu, "\y7.\w Zakaz usilnego proszenia o przesłanie pieniędzy w grze")
    menu_addtext2(regumenu, "\y8.\w Zakaz składania bezpodstawnych zgłoszeń na u@")
    menu_addtext2(regumenu, "\y9.\w Każdy gracz ma obowiązek stosowania się do poleceń wydanych przez admina") 
    menu_addtext2(regumenu, "\y10.\w Granie na aktywnym banie jest zakazane i grozi banem permanentnym")
    menu_addtext2(regumenu, "\y11.\w Zakaz nabijania sobie czasu gry na SPEC")
    menu_addtext2(regumenu, "\y12.\w Administracja wyższa zastrzega sobie prawo do zbanowania każdej osoby.")

    menu_additem(regumenu, "Zapoznałem sie z regulaminem \d(Wyjście)^n")
    menu_addtext2(regumenu, "\y13.\w W przypadku bana czas płatnej usługi (np. VIP) nie będzie zatrzymany")
    menu_addtext2(regumenu, "\y14.\w Regulamin może ulec zmianie w dowolnym czasie.")

    menu_setprop(regumenu, MPROP_NEXTNAME, "Dalej");
    menu_setprop(regumenu, MPROP_BACKNAME, "Wstecz");
    menu_setprop(regumenu, MPROP_EXIT , MEXIT_NEVER);

    menu_display(id, regumenu);
}

public reguCT(id)
{
    g_regType[id] = 2

    new regumenu = menu_create("Regulamin Ogólny", "regTypeHandler");
    menu_additem(regumenu, "Pełna wersja regulaminu \d(MOTD)^n")
    menu_addtext2(regumenu, "\y1.\w Zakaz blokowania wejścia do kamp pozostałym graczom CT.")
    menu_addtext2(regumenu, "\y2.\w Zakaz wpychania Zombie na innych CT lub innym graczom CT do kampy") 
    menu_addtext2(regumenu, "\y3.\w Zakaz wchodzenia na tekstury map")
    menu_addtext2(regumenu, "\y4.\w Zakaz niszczenia kładek na których nie znajduje się żaden Zombie")
    menu_addtext2(regumenu, "\y5.\w Zakazuje się oddawania się dla Zombie bez walki")
    menu_addtext2(regumenu, "\y6.\w Zakaz odpalania przycisków na mapach escape samemu")

    menu_additem(regumenu, "Zapoznałem sie z regulaminem \d(Wyjście)^n")
    menu_addtext2(regumenu, "\y7.\w Zakaz dublowania broni, czyli zbierania wielu broni z mapy do kampy")

    menu_setprop(regumenu, MPROP_NEXTNAME, "Dalej");
    menu_setprop(regumenu, MPROP_BACKNAME, "Wstecz");
    menu_setprop(regumenu, MPROP_EXIT , MEXIT_NEVER);

    menu_display(id, regumenu);
}

public reguZM(id)
{
    g_regType[id] = 3

    new regumenu = menu_create("Regulamin Ogólny", "regTypeHandler");
    menu_additem(regumenu, "Pełna wersja regulaminu \d(MOTD)^n")
    menu_addtext2(regumenu, "\y1.\w Zakaz nadużywania komendy reconnect lub retry")
    menu_addtext2(regumenu, "\y2.\w Zakaz wychodzenia z premedytacją jako ostatni Zombie") 
    menu_addtext2(regumenu, "\y3.\w Zabrania się zarażania przez tekstury. Czyli tam gdzie spoza tekstury kampy/zza ściany wystaje model gracza CT")
    menu_addtext2(regumenu, "\y4.\w Zakaz prowadzenia trybu gry pasywnego Zombie. Tj. umyślne niezarażanie graczy z CT")
    menu_addtext2(regumenu, "\y5.\w Zakaz griefiengu, utrudniania gry swoim współgraczom z drużyny")
    menu_addtext2(regumenu, "\y6.\w Zakaz wpychania pozostałych graczy Zombie w strefe zagrożenia. Strefa zagrożenia to obszar który kończy sie natychmiastowym zgonem")

    menu_additem(regumenu, "Zapoznałem sie z regulaminem \d(Wyjście)^n")    
    menu_addtext2(regumenu, "\y7.\w Zombie musi wykonywać cele mapy. Zabrania się używania pojazdów na mapach, jeżeli nie dąży to w żaden sposób do wygrania rundy.")

    menu_setprop(regumenu, MPROP_NEXTNAME, "Dalej");
    menu_setprop(regumenu, MPROP_BACKNAME, "Wstecz");
    menu_setprop(regumenu, MPROP_EXIT , MEXIT_NEVER);


    menu_display(id, regumenu);
}

public regTypeHandler(id, menu, item)
{
    switch(item){
		case 0: CmdMotd(id);
	}
}

public CmdMotd(client)
{
    new website[128], motd[256];

    switch(g_regType[client]){
		case 1: formatex(website, charsmax(website), "http://biohazard.gameclan.pl/reg/ogolny.html");
		case 2: formatex(website, charsmax(website), "http://biohazard.gameclan.pl/reg/ct.html");
		case 3: formatex(website, charsmax(website), "http://biohazard.gameclan.pl/reg/zm.html");
	}

    formatex(motd, sizeof(motd) - 1,\
        "<html><head><meta http-equiv=^"Refresh^" content=^"0;url=%s^"></head><body><p><center>LOADING...</center></p></body></html>",\
            website);
    
    show_motd(client, motd);

}