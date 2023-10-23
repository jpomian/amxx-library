#include <amxmodx>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)
#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)

enum _:TimeTableEnumerator (+= 1)
{
	LOWER_RANGE,
	UPPER_RANGE,
	TIME
};

#define DefaultTime 2

/*
	[0] - Lower range
	[1] - Upper range
	[2] - Time

	Example:
		{1, 6, 2} is: "If there is 1, 2, 3, 4, 5 or 6 players on the server, round time is 2."
*/
static const TimeTable[][] =
{
	{ 1,	6,		DefaultTime },
	{ 8,	14,		DefaultTime + 1 },
	{ 15,	20,		DefaultTime + 2 },
	{ 21,	32,		DefaultTime + 3 }
};

new g_pcvar_roundtime, g_pcvar_extendable;

public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	register_logevent("RoundStart", 2, "1=Round_Start");

	g_pcvar_roundtime = get_cvar_pointer("mp_roundtime")

	g_pcvar_extendable = register_cvar("mp_roundextend", "0")
}

public RoundStart()
{
	new players_amount = get_players_amount(),
	round_time = players_amount_to_round_time(players_amount),
	extend = get_pcvar_num(g_pcvar_extendable)

	set_pcvar_num(g_pcvar_roundtime, round_time+extend)
}

players_amount_to_round_time(amount)
{
	ForArray(i, TimeTable)
	{
		if(amount < TimeTable[i][LOWER_RANGE] || amount > TimeTable[i][UPPER_RANGE])
		{
			continue;
		}
		
		return TimeTable[i][TIME];
	}

	return DefaultTime;
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