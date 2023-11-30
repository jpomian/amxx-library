#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#define PLUGIN "Kaboom!"
#define VERSION "1.1"
#define AUTHOR "R3X"

new const gszModels[][] = {
	"w_hegrenade.mdl",
	"w_flashbang.mdl"
};


new gcvarEnabled;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_touch("*", "grenade", "fwTouchGrenade2");
	register_touch("grenade", "*", "fwTouchGrenade");
	
	gcvarEnabled = register_cvar("amx_kaboom", "1");
}

public fwTouchGrenade2(ent, nade) {
	fwTouchGrenade(nade, ent);
}

public fwTouchGrenade(nade, ent) {
	if(!get_pcvar_num(gcvarEnabled)) return;
	
	if(pev_valid(ent) && pev(ent, pev_solid) == SOLID_TRIGGER) return;
	
	new szModel[32];
	pev(nade, pev_model, szModel, 31);
	
	for(new i=0;i<sizeof(gszModels); i++)
		if(equal(szModel[7], gszModels[i])){
			set_pev(nade, pev_dmgtime, get_gametime());
			dllfunc(DLLFunc_Think, nade);
			break;
		}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
