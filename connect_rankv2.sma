#include <amxmodx>
#include <colorchat>
#include < csx >

#define PLUGIN "Team join info"
#define VERSION "1.0"
#define AUTHOR "AMXX Community"

#define SFX_PATH "bhz_custom/enter.wav"

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_event( "TeamInfo", "join_team", "a")
}

public plugin_precache()
{
	precache_sound(SFX_PATH);
}

public join_team()
{    
    new id = read_data(1)
    static user_team[32]
    
    read_data(2, user_team, 31)    
    
    if(!is_user_connected(id) || !is_user_bot(id))
        return PLUGIN_CONTINUE    
    
    new szName[ 32 ], stats[8], body[8], iRank;
    get_user_name( id, szName, 31 );

    iRank = get_user_stats(id, stats, body)

    switch(user_team[0])
    {
        case 'C':  
        {
           ColorChat(0, TEAM_COLOR, "[System] ^x01 %s (Ranking: ^x03%i^x01) ^x01 wszedl na serwer.", szName, iRank);      
        }
            
        case 'T': 
        {
            ColorChat(0, TEAM_COLOR, "[System] ^x01 %s (Ranking: ^x03%i^x01) ^x01 wszedl na serwer.", szName, iRank);
        }
        
        case 'S':  
        {
            ColorChat(0, TEAM_COLOR, "[System] ^x01 %s (Ranking: ^x03%i^x01) ^x01 wszedl na serwer.", szName, iRank);
        }

    }

    emit_sound( 0, CHAN_VOICE, SFX_PATH, 1.0, ATTN_NORM, 0, PITCH_NORM )

    return PLUGIN_CONTINUE
    
}  