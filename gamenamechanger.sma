#include <amxmodx>
#include <fakemeta>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

#pragma semicolon 1

static const GameNames[][] =
{
	"Respawn na wejsciu",
	"Sklep pod M",
	"Mapcykl [Dzien-Noc]",
    "Tryb Deathmatch w nocy",
    "biohazard.gameclan.pl"
};

static const Float:Interval = 60.0;
static const AllowRepeat = false;

new current_name_id;
new g_map[3];

public plugin_init()
{
    register_plugin("x", "v0.1", AUTHOR);

    set_task(Interval, "change_game_name", .flags = "b");

    register_forward(FM_GetGameDescription, "update_game_name");

    if(equali(g_map, "zm", 2))
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Biohazard")
	}
	else if(equali(g_map, "ze", 2))
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Escape")
	}
	else
	{
		formatex(g_tag, charsmax(g_tag), "Zombie Deathmatch")
	}


}

public change_game_name()
{
    if(!AllowRepeat)
    {
        new last = current_name_id,
            Array:available;
        
        available = ArrayCreate(1, 1);

        ForRange(i, 0, sizeof(GameNames) - 1)
        {
            if(i == last)
            {
                continue;
            }

            ArrayPushCell(available, i);
        }

        current_name_id = ArrayGetCell(available, random_num(0, ArraySize(available) - 1));
        
        ArrayDestroy(available);
    }
    else
    {
        current_name_id = random_num(0, sizeof(GameNames) - 1);
    }
}

public update_game_name()
{
    forward_return(FMV_STRING, GameNames[current_name_id]);

    return FMRES_SUPERCEDE;
} 