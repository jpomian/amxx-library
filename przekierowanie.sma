#include <amxmodx>

new g_pCvarNoweIP;

public plugin_init() {
	register_plugin("Proste Przekierowanie", "1.0", "Dawid");

	g_pCvarNoweIP = register_cvar("przekierowanie_noweip", "145.239.16.96:27015");
}

public client_authorized(id) {
	if(!is_user_bot(id) && !is_user_hltv(id)) {
		new szIP[32];

		get_pcvar_string(g_pCvarNoweIP, szIP, charsmax(szIP));
		client_cmd(id,"^"connect^"%s", szIP);
		
		set_task(0.5, "InfoSteam", id);
	}
}

public InfoSteam(id) {
	if(is_user_connected(id) || is_user_connecting(id)) {
		new szIP[32];
		get_pcvar_string(g_pCvarNoweIP, szIP, charsmax(szIP));
		server_cmd("kick ^"#%d^" ^"Serwer zostal zamkniety, nowe IP w konsoli: %s^"", get_user_userid(id), szIP);
	}
}
