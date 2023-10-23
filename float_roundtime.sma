#include <amxmodx>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)
#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)

enum _:TimeTableEnumerator (+= 1)
{
	LOWER_RANGE,
	UPPER_RANGE
};

/*
	[0] - Lower range
	[1] - Upper range
	[2] - Time

	Example:
		{1, 6, 2} is: "If there is 1, 2, 3, 4, 5 or 6 players on the server, round time is 2."
*/
static const TimeTable[][] =
{
	{ 1,	6 },
	{ 7,	12 },
	{ 12,	18 },
	{ 19,	32 }
};

static const Float:FloatSet[] = { 1.5, 2.0, 2.5, 3.0 }

new roundtime

public plugin_init()
{
    register_plugin("x", "v0.1", AUTHOR);
    register_logevent("RoundStart", 2, "1=Round_Start");
    roundtime = get_cvar_pointer("mp_roundtime")
}

public RoundStart()
{
	new players_amount = get_players_amount(),
	round_time = players_amount_to_round_time(players_amount);

	set_pcvar_float(roundtime, Float:round_time)
}

players_amount_to_round_time(amount)
{

    new counted_slot = -1;

    ForArray(i, TimeTable)
	{
		if(amount < TimeTable[i][LOWER_RANGE] || amount > TimeTable[i][UPPER_RANGE])
		{
			continue;
		}

        counted_slot = i //indent
	}

    return FloatSet[counted_slot];
}

get_players_amount()
{
	new a;

	ForPlayers(i)
	{
		if(!is_user_connected(i))
		{
			continue;
		}

		a++;
	}

	return a;
} 