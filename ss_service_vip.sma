#include <amxmodx>
#include <sms_shop>

new /*bez const*/srv[__srv] = {
"VIP", // Nazwa uslugi.
SS_TYPE_TIME, // Typ uslugi.
1, // Czy dodawac haslo ?
5, // Ilosc elementow po wybraniu uslugi.
0, // Zostawic na 0.
{ 1, 3, 7, 14, 30 }, // Liczby do kolejnych elementow.
{ 2.46, 6.15, 11.07, 17.22, 23.37 }, // Ceny kolejnych elementow.
1, // Czy usluga moze zostac kupiona wiele razy (chyba ze typem jest czas a gracz ma juz usluge) ?
{ 0, 0, 0 }, // Jakie flagi nalezy miec aby moc kupic poszczegolny element ?
{ ADMIN_LEVEL_G, ADMIN_LEVEL_G, ADMIN_LEVEL_G, ADMIN_LEVEL_G, ADMIN_LEVEL_G } // Jakich flag nie mozna miec zeby moc kupic poszczegolny element ?
};
new const subnames[][] = { "1 dzien", "3 dni", "7 dni", "14 dni", "30 dni"}; // Nazwy kolejnych elementow.

new g_iVip;

public plugin_init()
{
	register_plugin("[SKLEP-SMS] Usluga: VIP", "1.0", "FastKilleR");
	g_iVip = ss_register_service2(srv, subnames, sizeof subnames);
}

public ss_client_service(id, service, number)
{
	if(service == g_iVip)
	{
		set_user_flags(id, get_user_flags(id) | ADMIN_LEVEL_H);
		return SS_CONTINUE;
	}
	
	return SS_CONTINUE;
}
