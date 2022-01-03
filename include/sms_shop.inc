#if defined _smsshop_included
#endinput
#endif
#define _smsshop_included

#define SS_TYPE_TIME 0
#define SS_TYPE_AMOUNT 1
#define SS_TYPE_OTHER 2

#define SS_CONTINUE PLUGIN_CONTINUE
#define SS_STOP PLUGIN_HANDLED

enum __srv { __name[33], __type, __password, __subcount, __preparednames, __numbers[64], Float:__prices[64], __reusable, __necessary[64], __blocked[64] };

native ss_prepare_array(any:...);
/* Do uzycia w ss_register_service() w parametrze @prepared_names. */

native ss_register_service(service[], type, password, subservices, prepared_names, numbers[], Float:prices[], reusable, necessary[], blocked[]);
/* Rejestruje nowa usluge. Nalezy uzywac w plugin_init().
   
   @service - Nazwa uslugi.
   @type - Typ uslugi. Od tego zalezy poprawnosc tekstu oraz zapis (SS_TYPE_TIME).
   @password - Czy do uslugi dolaczane jest haslo na nick.
   @subservices - Ilosc poduslug. Moze byc 0/1 jesli nie ma zadnych poduslug.
   @prepared_names - Przygotowane nazwy kolejnych poduslug. Przy braku to pole nie jest uzywane.
   @numbers - Liczby przy kolejnych poduslugach. Moze to byc czas trwania uslugi (SS_TYPE_TIME), jakas ilosc lub identyfikator.
				Przy braku poduslug nalezy wypelnic tylko index 0.
   @prices - Ceny kolejnych poduslug zgodnie z cenami podanymi w API. Przy braku poduslug nalezy wypelnic tylko index 0.
   @reusable - Czy usluga moze byc kupowana kilka razy (dodatkowy zapis w bazie danych). Nie uzywane przy SS_TYPE_TIME.
   @necessary - Flagi potrzebne do kupienia kolejnych poduslug.
   @blocked - Przy jakich flagach dana podusluga nie jest dostepna. Jesli zadna nie jest dostepna, blokowana jest cala usluga.
   
   @return - Zwracany jest identyfikator uslugi lub -1 jesli wystapil blad.
*/

native ss_get_user_service(id, service);
/* Sprawdza czy gracz ma dana usluge.
   
   @id - Identyfikator gracza.
   @service - Identyfikator uslugi.
   
   @return - Zwraca zapisana liczbe kupionej poduslugi lub czas timestamp w ktorym wygasnie jesli typem jest SS_TYPE_TIME. -1 jesli gracz nie ma danej uslugi.
*/

forward ss_client_service(id, service, number)
/* Wywolywany w momencie przyznania graczowi uslugi (wejscie na serwer/kupienie uslugi)
   
   @id - Identyfikator gracza.
   @service - Identyfikator uslugi.
   @subservice - Liczba przy kupionej podusludze. -1 gdy brak.
   
   Nalezy zwrocic SS_STOP, aby zatrzymac proces nadawania uslugi przez ewentualne  inne pluginy.
*/

stock ss_register_service2(service_table[__srv], const subnames_table[][], subnames_len = 0)
{
	for(new i = 0; i < subnames_len; ++i)
	{
		service_table[__preparednames] = ss_prepare_array(subnames_table[i]);
	}
	
	return ss_register_service(service_table[__name],
	service_table[__type],
	service_table[__password],
	service_table[__subcount],
	service_table[__preparednames],
	service_table[__numbers],
	service_table[__prices],
	service_table[__reusable],
	service_table[__necessary],
	service_table[__blocked]);
}
