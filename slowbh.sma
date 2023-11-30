#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <biohazard>

// the minimum bhops for a player to do in a row before being slowed down
#define MIN_BHOPS_BEFORE_SLOWDOWN 3

#define MAX_BHOP_FRAMES 5

#define FL_ONGROUND2 (FL_ONGROUND|FL_PARTIALGROUND|FL_INWATER|FL_CONVEYOR|FL_FLOAT)
#define IsOnGround(%1) !!(get_entity_flags(%1) & FL_ONGROUND2)

new g_is_alive[33];
new g_was_on_ground[33];
new g_ground_frames[33];
new g_bhop_counter[33];

new bhopspeed_reduction;

public plugin_init()
{
    register_plugin("Bhop Slow Down", "0.1", "Exolent");
    
    RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1);
    RegisterHam(Ham_Killed, "player", "FwdPlayerKilled", 1);

    bhopspeed_reduction = register_cvar("amx_bhop_reduceby", "87.5", ADMIN_IMMUNITY)

}

public client_disconnected(client)
{
    g_is_alive[client] = 0;
}

public client_PreThink(client)
{
    if( !g_is_alive[client] || !is_user_zombie(client)) return;
    
    new on_ground = IsOnGround(client);
    
    if( !on_ground
    && g_was_on_ground[client]
    && (get_user_oldbutton(client) & IN_JUMP)
    && g_ground_frames[client] < MAX_BHOP_FRAMES
    )
    {
        g_bhop_counter[client]++;
        switch(g_bhop_counter[client])
        {
            case 4: ChangeVelocity(client, 90.0)
            case 5: ChangeVelocity(client, 95.0)
            case 6..99: ChangeVelocity(client, 100.0)
        }
    }
    else if( on_ground && g_ground_frames[client] >= MAX_BHOP_FRAMES )
    {
        g_bhop_counter[client] = 0;
    }
    
    if( on_ground )
    {
        g_ground_frames[client]++;
    }
    else
    {
        g_ground_frames[client] = 0;
    }
    
    g_was_on_ground[client] = on_ground;
}

public FwdPlayerSpawn(client)
{
    if( is_user_alive(client) )
    {
        g_is_alive[client] = 1;
        g_was_on_ground[client] = 0;
        g_ground_frames[client] = 0;
        g_bhop_counter[client] = 0;
    }
}

public FwdPlayerKilled(client, killer, shouldgib)
{
    g_is_alive[client] = 0;
}

stock ChangeVelocity(client, Float:div)
{
    static Float:velocity[3];
    entity_get_vector(client, EV_VEC_velocity, velocity);
            
    velocity[0] = velocity[0] * get_pcvar_float(bhopspeed_reduction) / div;
    velocity[1] = velocity[1] * get_pcvar_float(bhopspeed_reduction) / div;
            
    entity_set_vector(client, EV_VEC_velocity, velocity);
    // client_cmd(client, "spk %s", SOUND) 
}