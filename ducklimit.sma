#include <amxmodx>
#include <fakemeta>
#include <xs>

const ButtonBits = ( IN_DUCK );

new adjusted_mltpr, max_speed;

public plugin_init() 
{
    adjusted_mltpr = register_cvar( "amx_duck_adjuster", "0.120" );
    max_speed = register_cvar( "amx_duck_maxspeed", "200.0" );

    register_forward( FM_CmdStart , "fw_FMCmdStart" );
}

public fw_FMCmdStart( id , handle , seed )
{
    if ( get_uc( handle , UC_Buttons ) & ButtonBits )
    {
        static Float:Velocity[3]
	
        pev(id, pev_velocity, Velocity)

        if (Velocity[0] > max_speed || Velocity[1] > max_speed || Velocity[2] > max_speed)  
        {
	    xs_vec_mul_scalar( Velocity, get_pcvar_float(adjusted_mltpr), Velocity)
	    set_pev(id, pev_velocity, Velocity)
        }
    }
    return FMRES_IGNORED
}