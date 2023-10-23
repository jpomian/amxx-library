#include <amxmodx>
#include <fakemeta>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

#pragma semicolon 1

static const GameNames[][] =
{
	"Respawn na wejsciu",
	"Rangi Wojskowe",
	"Powered by Discord",
	"Cykl dzienny [9-21]",
    "TeamPlay!"
};

static const Float:Interval = 60.0;
static const AllowRepeat = false;

new current_name_id;

public plugin_init()
{
    register_plugin("x", "v0.1", AUTHOR);

    set_task(Interval, "change_game_name", .flags = "b");

    register_forward(FM_GetGameDescription, "update_game_name");
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