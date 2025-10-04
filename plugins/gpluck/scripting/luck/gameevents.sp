// Game Events

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = event.GetInt("userid");
	int deathflags = event.GetInt("death_flags");

	if(deathflags & TF_DEATHFLAG_DEADRINGER)
	{
		return Plugin_Continue;
	}

	if(victim)
	{
		RequestFrame(OnClientDeath, victim);
	}

	return Plugin_Continue;
}