#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <biohazard>

new const g_path[] = "models/biohazard/santahat.mdl"

public plugin_init() {

    register_plugin("Biohazard Santa Hats", "1.1a", "Mixtaz")
    RegisterHam(Ham_Killed, "player", "bacon_killed")
    RegisterHam(Ham_Spawn, "player", "bacon_spawn_post", 1)

}

public plugin_precache()
    engfunc(EngFunc_PrecacheModel, g_path)

public client_disconnected(id)
    remove_hat(id)

public bacon_killed(id, idattacker, shouldgib)
	remove_hat(id)

public bacon_spawn_post(id)
{
    if(is_user_alive(id))
    {
	    is_user_zombie(id) ? equip_hat(id) : remove_hat(id)
    }
}

public event_infect(victim, attacker)
    equip_hat(victim)

stock equip_hat(id)
{
    if(!is_user_alive(id) || pev_valid(fm_find_ent_by_owner(-1, "player_hat", id)))
                            return PLUGIN_CONTINUE

    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    set_pev(iEnt, pev_classname, "player_hat")
    engfunc(EngFunc_SetModel, iEnt, g_path)
    set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
    set_pev(iEnt, pev_aiment, id)
    set_pev(iEnt, pev_owner, id)

    return PLUGIN_CONTINUE
}

stock remove_hat(id)
{
    new iEnt = fm_find_ent_by_owner(-1, "player_hat", id)
    if(pev_valid(iEnt))
        engfunc(EngFunc_RemoveEntity, iEnt)
}
