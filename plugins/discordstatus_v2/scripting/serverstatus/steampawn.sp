
static int s_updatesRequested = 0;

public void SteamPawn_OnRestartRequested()
{
	if (cfg_UpdateRequested.enabled)
	{
		if (--s_updatesRequested <= 0)
		{
			SendMessage_OnUpdateRequested();
			s_updatesRequested = 2; // Don't spam update requests
		}
	}
}
