#include <amxmodx>
#include <amxmisc>


public plugin_init()
{
	register_plugin("You Must Duck!", "1.0", "Kowalsky")
	register_clcmd("amx_kucaj", "wymusKucniecieGracza", ADMIN_BAN, "<nick | #id> - wymusza kucniecie na graczu")
}

public wymusKucniecieGracza(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new szTarget[32]
	read_argv(1, szTarget, 31)
	
	new iTarget = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ONLY_ALIVE)
	
	if(iTarget)
		client_cmd(id, "+duck")
	
	return PLUGIN_CONTINUE;
}