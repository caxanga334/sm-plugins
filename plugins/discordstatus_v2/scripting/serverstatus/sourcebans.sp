// SourceBans messages

#if defined _sourcebanspp_included

public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
	if (cfg_SourceBans.enabled)
	{
		SendMessage_OnSBBanAdded(iAdmin, iTarget, iTime, sReason);
	}
}

#endif

#if defined _sourcecomms_included

public void SourceComms_OnBlockAdded(int client, int target, int time, int type, char[] reason)
{
	if (cfg_SourceBans.enabled)
	{
		SendMessage_OnSBCommsBlockAdded(client, target, time, type, reason);
	}
}

#endif