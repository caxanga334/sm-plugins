public void CreateConVars()
{
	g_cvarHookedDecalFrequency = FindConVar("decalfrequency");
	g_iOldDecalFreqVal = g_cvarHookedDecalFrequency.IntValue;
	g_cvarHookedDecalFrequency.IntValue = 0;

	g_cvarDecalFrequency = CreateConVar("sm_decalfrequency", "10.0", "Controls how often clients can spray", FCVAR_NOTIFY);

	g_cvarEnableSprays = CreateConVar("sm_spraymanager_enablesprays", "1", "Enable or disable all sprays usage");
	g_cvarAuthorizedFlags = CreateConVar("sm_spraymanager_authorizedflags", "b,z", "Authorizes specific flags to spray when usage is disabled server side");

	g_cvarEnableSprays.AddChangeHook(ConVarChanged_EnableSpray);
	g_cvarAuthorizedFlags.AddChangeHook(ConVarChanged_AuthorizedFlags);

	HookConVarChange(g_cvarHookedDecalFrequency, ConVarChanged_DecalFrequency);

	g_cvarUseProximityCheck = CreateConVar("sm_spraymanager_blockoverspraying", "1", "Blocks people from overspraying each other", FCVAR_NOTIFY);

	g_cvarSendSpraysToConnectingClients = CreateConVar("sm_spraymanager_sendspraystoconnectingclients", "1", "Try to send active sprays to connecting clients");

	g_cvarUsePersistentSprays = CreateConVar("sm_spraymanager_persistentsprays", "1", "Re-spray sprays when their client-sided lifetime (in rounds) expires");

	g_cvarMaxSprayLifetime = CreateConVar("sm_spraymanager_maxspraylifetime", "2", "If not using persistent sprays, remove sprays after their global lifetime (in rounds) exceeds this number");

	g_cvarSprayBanLength = CreateConVar("sm_spraymanager_spraybanlength", "0", "How long to ban a player from spraying for", FCVAR_NOTIFY);

	g_cvarDefaultBehavior = CreateConVar("sm_spraymanager_defaultbehavior", "1", "Default behavior for sprays (0 = Block spray until client passed all verifications | 1 = Allow spray)", FCVAR_NOTIFY);

	g_cvarFramesToSkip = CreateConVar("sm_spraymanager_framestoskip", "10", "Number of frames to skip before trace a player spray", FCVAR_NOTIFY, true, 0.0, true, 66.0);
	g_cvarFramesToSkip.AddChangeHook(ConVarChanged_FramesToSkip);
	g_iFramesToSkip = g_cvarFramesToSkip.IntValue;
}

public void ConVarChanged_EnableSpray(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetConVars();
}

public void ConVarChanged_AuthorizedFlags(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetConVars(false);
}

public void ConVarChanged_DecalFrequency(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) != 0)
	{
		LogMessage("ConVar \"decalfrequency\" needs to be 0 at all times, please use sm_decalfrequency instead.");
		cvar.IntValue = 0;
	}
}

public void ConVarChanged_FramesToSkip(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	int iNewValue = StringToInt(sNewValue);
	cvar.IntValue = iNewValue;
	g_iFramesToSkip = iNewValue;
}

void GetConVars(bool bDeleteSprays = true)
{
	g_bEnableSprays = g_cvarEnableSprays.BoolValue;

	if (bDeleteSprays && !g_bEnableSprays)
		RemoveAllSprays();

	char sAuthorizedFlags[64];
	g_cvarAuthorizedFlags.GetString(sAuthorizedFlags, sizeof(sAuthorizedFlags));

	char sSplitedFlags[32][3];
	int iSentences = ExplodeString(sAuthorizedFlags, ",", sSplitedFlags, sizeof(sSplitedFlags), 3);
	for (int j = 0; j < sizeof(g_iAuthorizedFlags); j++)
		g_iAuthorizedFlags[j] = -1;

	int i = 0;
	while (i < iSentences)
	{
		if (strlen(sSplitedFlags[i]) == 1)
			g_iAuthorizedFlags[i] = sSplitedFlags[i][0];
		else
			g_iAuthorizedFlags[i] = 0;
		i++;
	}
	if (i < sizeof(g_iAuthorizedFlags))
		g_iAuthorizedFlags[i] =  -1;
}