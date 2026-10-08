
#if defined _SteamWorks_Included

static int s_updatesRequested = 0;

public Action SteamWorks_RestartRequested()
{
	if (cfg_UpdateRequested.enabled)
	{
		if (--s_updatesRequested <= 0)
		{
			SendMessage_OnUpdateRequested();
			s_updatesRequested = 2; // Don't spam update requests
		}
	}

    return Plugin_Continue;
}

#endif // defined _SteamWorks_Included
