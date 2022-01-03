#if defined _ranks_included
	#endinput
#endif
#define _ranks_included

/*
	Gets player's rank.

	@param index 	Valid 1-32 player index.

	@return			-1 if player is not connected.
					-1 if invalid amount of parameters was given.
*/
native ranks_get_user_rank(index);

/*
	Gets rank name by reference.

	@param index 	Rank index.
	@param output	Variable to get the name into.
	@param length	Max length of the name.

	@noreturn

	@error	 		Output isnt formated if invalid amount of parameters was given or invalid length was given.
*/
native ranks_get_rank_name(index, output[], length);

/*
	Gets rank kills.

	@param index	Rank index.
	@param which	1 - Rank's lower range, 2 - rank's upper range.

	@return			-1 if invalid param was given.
					-1 if invalid amount of parameters was given.
*/
native ranks_get_rank_kills(index, which);

/*
	Gets amount of ranks loaded.
*/
native ranks_get_ranks_count();