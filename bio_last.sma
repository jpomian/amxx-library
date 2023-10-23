#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <biohazard>
 
#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"
 
#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)
 
static const PlayersThreshold = 5;
static const SoundPath[] = "zombie/last.wav";
static const HealthAmount = 250;
static const DefaultHealth = 2000;
 
enum _:ItemsEnumerator (+= 1)
{
        ITEMS_ONE_VS_ONE,
        ITEMS_ONE_VS_MANY
};
 
new bool:items_given[33][ItemsEnumerator];
 
public plugin_init()
{
        register_plugin("x", "v0.1", AUTHOR);
                
        register_event("DeathMsg", "player_death", "a");
 
        RegisterHam(Ham_Spawn, "player", "player_spawned", true);
}
 
public plugin_precache()
{
        precache_sound(SoundPath);
}
 
public player_spawned(index)
{
        if(!is_user_alive(index))
        {
                return;
        }
 
        items_given[index][ITEMS_ONE_VS_MANY] = false;
        items_given[index][ITEMS_ONE_VS_ONE] = false;
}

public player_death()
{
 
        new last_ct = get_last_alive(),
                alive_tts = get_alive(2);
 
        // More than one CT.
        if(!is_user_connected(last_ct))
        {
                return;
        }
 
        set_dhudmessage(185, 48, 48, -1.0, 0.16, 1, 6.0, 3.0);
        
        if(alive_tts > 0) {
        if(alive_tts == 1)
        {
                show_dhudmessage(0, "Zombie VS CT!^nPolowanie - schodzimy z kamp i wysokosci!");
                
                emit_sound(0, CHAN_VOICE, SoundPath, 1.0, ATTN_NORM, 0, PITCH_NORM);
 
                if(!items_given[last_ct][ITEMS_ONE_VS_ONE])
                {

                        get_user_health(last_ct) >= DefaultHealth ? set_user_health(last_ct, get_user_health(last_ct) + HealthAmount) : set_user_health(last_ct, DefaultHealth + HealthAmount);
 
                        items_given[last_ct][ITEMS_ONE_VS_ONE] = true;
                }
        }
        else
        {
                new postfix[10],
                        last_ct_name[32];
                
                get_user_name(last_ct, last_ct_name, charsmax(last_ct_name));
 
                switch(alive_tts)
                {
                        case 2..4: { formatex(postfix, charsmax(postfix), "ow"); }
                        case 5..21: { formatex(postfix, charsmax(postfix), "ow"); }
                        case 22.24: { formatex(postfix, charsmax(postfix), "ow"); }
                        case 25..31: { formatex(postfix, charsmax(postfix), "ow"); }
                }
 
                show_dhudmessage(0, "Zombie %s VS %i CTk%s^nPolowanie - schodzimy z kamp i wysokosci!", last_ct_name, alive_tts, postfix);
 
                if(!items_given[last_ct][ITEMS_ONE_VS_MANY])
                {
                        
                        set_user_health(last_ct, get_user_health(last_ct) + (HealthAmount * alive_tts));

                        get_user_health(last_ct) >= DefaultHealth ? set_user_health(last_ct, get_user_health(last_ct) + (HealthAmount * alive_tts)) : set_user_health(last_ct, DefaultHealth + (HealthAmount * alive_tts));
 
                        items_given[last_ct][ITEMS_ONE_VS_MANY] = true;
                }
        }
        }
}
 
get_last_alive(bool:skip_bots = true)
{
        new index,
                counter;

        ForPlayers(i)
        {
                if(!is_user_alive(i) || (skip_bots && is_user_bot(i)) || !is_user_zombie(i))
                {
                        continue;
                }
 
                index = i;
                counter++;
        }
 
        return (counter > 1 ? 0 : index);
}
 
get_alive(team, bool:skip_bots = true)
{
        new alive;
 
        ForPlayers(i)
        {
                if(!is_user_alive(i) || (skip_bots && is_user_bot(i)) || get_user_team(i) != team || is_user_zombie(i))
                {
                        continue;
                }
 
                alive++;
        }
 
        return alive;
}