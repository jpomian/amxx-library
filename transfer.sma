#include <amxmodx>
#include <cstrike>

new g_donation_amount[33];
new g_donation_receiver[33][2];
new g_menuid;

public plugin_init() {
	register_plugin("Donation with chat input", "1.0", "[ --{-@ ]");
	register_clcmd("say", "cmd_say");
	register_clcmd("say_team", "cmd_say");
	register_menucmd((g_menuid = register_menuid("donatemenu")), 1023, "donatemenu_handler");
}

public cmd_say(id) {
	
	new text[10];
	read_args(text, charsmax(text));
	
	remove_quotes(text);
	trim(text);
	
	if ( equali(text[1], "/daj") ) {
		g_donation_amount[id] = 0;
		playermenu(id);
		return PLUGIN_HANDLED;
	}
	
	new menuid, keys;
	get_user_menu(id, menuid, keys);
	
	if ( menuid != g_menuid )
		return PLUGIN_CONTINUE;
	
	new i;
	while ( isdigit(text[i++]) ) { }
	
	if ( i == 1 || text[i] != 0 )
		return PLUGIN_CONTINUE;
	
	g_donation_amount[id] = clamp(str_to_num(text), 0, cs_get_user_money(id));
	donatemenu(id);
	
	return PLUGIN_HANDLED;
}

playermenu(id) {
	
	new hMenu = menu_create("Wybierz gracza ktoremu chcesz przelac kase:", "playermenu_handler");
	new players[32], playersnum, info[3], name[32];
	
	get_players(players, playersnum, "h");
	
	for ( new i = 0 ; i < playersnum ; i++ ) {
		
		if ( players[i] == id )
			continue;
		
		info[0] = players[i];
		info[1] = get_user_userid(players[i]);
		
		get_user_name(players[i], name, charsmax(name));
		menu_additem(hMenu, name, info);
	}
	
	menu_display(id, hMenu);
}

public playermenu_handler(id, hMenu, item) {
	
	if ( item == MENU_EXIT ) {
		menu_destroy(hMenu);
		return;
	}
	
	new temp, info[3];
	
	menu_item_getinfo(hMenu, item, temp, info, charsmax(info), _, _, temp);
	menu_destroy(hMenu);
	
	g_donation_receiver[id][0] = info[0];
	g_donation_receiver[id][1] = info[1];
	donatemenu(id);
}

donatemenu(id) {
	
	if ( ! is_user_connected(g_donation_receiver[id][0]) || g_donation_receiver[id][1] != get_user_userid(g_donation_receiver[id][0]) ) {
		client_print(id, print_chat, "Odbiorca opuscil gre.");
		return;
	}
	
	new menubody[512], name[32], keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_0;
	get_user_name(g_donation_receiver[id][0], name, charsmax(name));
	
	new len = formatex(menubody, charsmax(menubody), "\
\yOdbiorca: \r%s^n\yWybierz ilosc lub wprowadz na czacie.^n^nTwoja kasa: \r$%d^n^n\
\r1. \w+5000^n\
\r2. \w-5000^n\
\r3. \w+1000^n\
\r4. \w-1000^n\
\r5. \w+500^n\
\r6. \w-500^n\
\r7. \w+100^n\
\r8. \w-100^n^n", name, g_donation_amount[id]);

	if ( g_donation_amount[id] ) {
		len += formatex(menubody[len], charsmax(menubody) - len, "\r9. \wWyslij kase^n");
		keys |= MENU_KEY_9;
	}
	else {
		len += formatex(menubody[len], charsmax(menubody) - len, "\d9. Wyslij kase^n");
	}
	
	formatex(menubody[len], charsmax(menubody) - len, "\r0. \wWyjdz");

	show_menu(id, keys, menubody, _, "donatemenu");
}

public donatemenu_handler(id, key) {
	
	if ( ! is_user_connected(g_donation_receiver[id][0]) || g_donation_receiver[id][1] != get_user_userid(g_donation_receiver[id][0]) ) {
		client_print(id, print_chat, "Odbiorca opuscil gre.");
		return;
	}
	
	switch ( key ) {
		case 0 : g_donation_amount[id] += 5000;
		case 1 : g_donation_amount[id] -= 5000;
		case 2 : g_donation_amount[id] += 1000;
		case 3 : g_donation_amount[id] -= 1000;
		case 4 : g_donation_amount[id] += 500;
		case 5 : g_donation_amount[id] -= 500;
		case 6 : g_donation_amount[id] += 100;
		case 7 : g_donation_amount[id] -= 100;
	
		case 8 : {
			donate(id, g_donation_receiver[id][0], clamp(g_donation_amount[id], 0, cs_get_user_money(id)));
			return;
		}
		
		case 9 : return;
	}
	
	g_donation_amount[id] = clamp(g_donation_amount[id], 0, cs_get_user_money(id));
	donatemenu(id);
}

donate(giver, receiver, amount) {
	
	if ( ! amount )
		return;
	
	new reducedAmount = amount/2

	new giver_name[32], receiver_name[32];
	
	get_user_name(giver, giver_name, charsmax(giver_name));
	get_user_name(receiver, receiver_name, charsmax(receiver_name));
	
	cs_set_user_money(giver, cs_get_user_money(giver) - amount);
	cs_set_user_money(receiver, cs_get_user_money(receiver) + reducedAmount);
	
	client_print(giver, print_chat, "Wyslales $%d do %s.", reducedAmount, receiver_name);
	client_print(receiver, print_chat, "%s wyslal $%d do ciebie.", giver_name, reducedAmount);
}