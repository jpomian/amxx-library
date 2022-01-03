#include <amxmodx>
#include <fakemeta>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

#define pev_flare pev_iuser4
#define flare_id 1337
#define is_ent_flare(%1) (pev(%1, pev_flare) == flare_id) ? 1 : 0

new g_trailSpr
new g_sprite_grenade_trail[64] = "sprites/laserbeam.spr"

new cvar_smokeflare, cvar_smokeflare_dur
public plugin_init()
{
	register_plugin("smoke flare", "0.1", "mini_midget/cheap_suit")
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_precache() 
	g_trailSpr = precache_model(g_sprite_grenade_trail)

public plugin_init2()
{
	register_forward(FM_SetModel, "fwd_setmodel")	
	register_forward(FM_Think, "fwd_think")
	cvar_smokeflare = register_cvar("bh_flare_enable",   "1")
	cvar_smokeflare_dur = register_cvar("bh_flare_duration", "90.0")
}

public fwd_setmodel(ent, const model[]) 
{
	if(!pev_valid(ent) || !equal(model[9], "flashbang.mdl"))
		return FMRES_IGNORED
	
	static classname[32], rgb[3]; pev(ent, pev_classname, classname, 31)
	if(equal(classname, "grenade") && get_pcvar_num(cvar_smokeflare))
	{
		rgb[0] = random_num(50,200) // r
		rgb[1] = random_num(50,200) // g
		rgb[2] = random_num(50,200) // b

		set_pev(ent, pev_effects, EF_BRIGHTLIGHT)
		set_pev(ent, pev_flare,   flare_id)
		set_pev(ent, pev_nextthink, get_gametime() + get_pcvar_float(cvar_smokeflare_dur))
		fm_set_rendering(ent, kRenderFxGlowShell, rgb[0], rgb[1], rgb[2], kRenderNormal, 16)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(ent) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(rgb[0]) // r
		write_byte(rgb[1]) // g
		write_byte(rgb[2]) // b
		write_byte(200) // brightness
		message_end()
		
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_think(ent) if(pev_valid(ent) && is_ent_flare(ent))
	engfunc(EngFunc_RemoveEntity, ent)

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	static Float:color[3]; color[2] = float(b), color[0] = float(r), color[1] = float(g)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode,  render)
	set_pev(entity, pev_renderamt,   float(amount))

	return 1
}