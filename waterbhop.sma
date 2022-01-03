#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.0.1"

public plugin_init()
{
    register_plugin("No Jump", VERSION, "ConnorMcLeod")

    RegisterHam(Ham_Player_Jump, "player", "Player_Jump")
}

public Player_Jump(id)
{
    if( pev( id, pev_waterlevel ) )
    {
        static iOldbuttons ; iOldbuttons = entity_get_int(id, EV_INT_oldbuttons)
        if( !(iOldbuttons & IN_JUMP) )
        {
            entity_set_int(id, EV_INT_oldbuttons, iOldbuttons | IN_JUMP)
            return HAM_HANDLED
        }
    }
    
    return HAM_IGNORED
} 