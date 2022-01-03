#include <amxmodx>
#include <sms_shop>

new /*bez const*/srv[__srv] = {
"VIP", // Nazwa uslugi.
SS_TYPE_TIME, // Typ uslugi.
1, // Czy dodawac haslo ?
3, // Ilosc elementow po wybraniu uslugi.
0, // Zostawic na 0.
{ 14, 30, 60 }, // Liczby do kolejnych elementow.
{ 6.15, 11.07, 17.22 }, // Ceny kolejnych elementow.
1, // Czy usluga moze zostac kupiona wiele razy (chyba ze typem jest czas a gracz ma juz usluge) ?
{ 0, 0, 0 }, // Jakie flagi nalezy miec aby moc kupic poszczegolny element ?
{ ADMIN_LEVEL_H, ADMIN_LEVEL_H, ADMIN_LEVEL_H } // Jakich flag nie mozna miec zeby moc kupic poszczegolny element ?
};
new const subnames[][] = { "14 dni", "30 dni", "60 dni" }; // Nazwy kolejnych elementow.

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
