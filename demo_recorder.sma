#include <amxmodx>

const MAX_LENGTH = 64;

new Float:Timeout, DemoName[MAX_LENGTH];

public plugin_init() {
	register_plugin("Demo Recorder", "2.4.1", "F@nt0M");

	bind_pcvar_float(create_cvar(
		.name = "amx_demo_timeout",
		.string = "5.0",
		.has_min = true,
		.min_val = 0.0
	), Timeout);

	hook_cvar_change(create_cvar(
		.name = "amx_demo_format",
		.string = "BIOHAZARD-%mapname%"
	), "HookChangeFormat");
}

public plugin_cfg() {
	HookChangeFormat(get_cvar_pointer("amx_demo_format"));
}

public HookChangeFormat(const pcvar) {
	get_pcvar_string(pcvar, DemoName, charsmax(DemoName));

	new map[32];
	get_mapname(map, charsmax(map));
	replace(DemoName, charsmax(DemoName), "%mapname%", map);
}

public client_putinserver(id) {
	if (!is_user_bot(id) && !is_user_hltv(id)) {
		if (Timeout > 0.0) {
			set_task(Timeout, "TaskStop", id);
		} else {
			TaskStop(id);
		}
	}
}

public client_disconnected(id) {
	remove_task(id)
}

public TaskStop(id) {
	if (is_elligible(id)) {
		client_cmd(id, "stop");
		set_task(0.2, "TaskRecord", id);
	}
}

public TaskRecord(const id) {
	if (is_elligible(id)) {
		client_cmd(id, "record ^"%s^"", DemoName);
		set_task(5.0, "TaskMessage", id);
	}
}

stock bool:is_steam(auth[]) {

	return bool:(contain(auth, "STEAM_0:0:") != -1 || contain(auth, "STEAM_0:1:") != -1);

}

stock bool:is_elligible(id)
{
	new sid[35];
	get_user_authid(id, sid, charsmax(sid))

	if(is_user_connected(id) && is_steam(sid))
		return true;

	return false;
}