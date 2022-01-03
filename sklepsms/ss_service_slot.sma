#include <amxmodx>
#include <sms_shop>

new /*bez const*/srv[__srv] = {
"Rezerwacja slota", // Nazwa uslugi.
SS_TYPE_TIME, // Typ uslugi.
1, // Czy dodawac haslo ?
4, // Ilosc elementow po wybraniu uslugi.
0, // Zostawic na 0.
{ 7, 14, 30, 60 }, // Liczby do kolejnych elementow.
{ 1.23, 2.46, 4.92, 7.38 }, // Ceny kolejnych elementow.
1, // Czy usluga moze zostac kupiona wiele razy (chyba ze typem jest czas a gracz ma juz usluge) ?
{ 0, 0, 0 }, // Jakie flagi nalezy miec aby moc kupic poszczegolny element ?
{ ADMIN_RESERVATION, ADMIN_RESERVATION, ADMIN_RESERVATION } // Jakich flag nie mozna miec zeby moc kupic poszczegolny element ?
};
new const subnames[][] = { "7 dni", "14 dni", "30 dni", "60 dni" }; // Nazwy kolejnych elementow.

new g_iSlot;

public plugin_init()
{
	register_plugin("[SKLEP-SMS] Usluga: Rezerwacja slota", "1.0", "FastKilleR");
	
	g_iSlot = ss_register_service2(srv, subnames, sizeof subnames);
}

public ss_client_service(id, service, number)
{
	if(service == g_iSlot)
	{
		set_user_flags(id, get_user_flags(id) | ADMIN_RESERVATION);
		return SS_CONTINUE;
	}
	
	return SS_CONTINUE;
}
