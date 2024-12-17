
// mark as stock to suppress "symbol is never used" errors, this function is used but depending on the available includes
// the functions that make use of it might not get compiled 
stock bool IsValidClientIndex(int client)
{
	return client > 0 && client <= MaxClients;
}

// see above for the stock reason
stock void GetClientSteamID(int client, char[] buffer, int size, AuthIdType type = AuthId_Engine)
{
	if (!GetClientAuthId(client, type, buffer, size, true))
	{
		FormatEx(buffer, size, "");
	}
}

void GetServerName(char[] name, int size)
{
	FindConVar("hostname").GetString(name, size);
	char replace1[128];
	c_remove1.GetString(replace1, sizeof(replace1));
	char replace2[128];
	c_remove2.GetString(replace2, sizeof(replace2));

	if(strlen(replace1) > 1) { ReplaceString(name, size, replace1, "", false); }
	if(strlen(replace2) > 1) { ReplaceString(name, size, replace2, "", false); }
}

void GetMapName(char[] name, int size)
{
	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if(!GetMapDisplayName(buffer, name, size))
	{
		strcopy(name, size, buffer);
	}
}

int GetServerMaxSlots()
{
#if defined _l4dh_included

	if(g_engine == Engine_Left4Dead || g_engine == Engine_Left4Dead2)
	{
		switch(L4D_GetGameModeType())
		{
			case GAMEMODE_COOP, GAMEMODE_SURVIVAL:
			{
				return 4;
			}
			case GAMEMODE_VERSUS, GAMEMODE_SCAVENGE:
			{
				return 8;
			}
		}
	}

#endif

	int slots = MaxClients;
	ConVar cVisible = FindConVar("sv_visiblemaxplayers");
	int visibleslots;
	if(cVisible != null) {
		visibleslots = cVisible.IntValue;
	}
	
	if(visibleslots > 0 && visibleslots <= MaxClients) {
		slots = visibleslots;
	}
	
	return slots;
}

int GetDynamicClientCount()
{
	int clients = 0;
	
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(IsPlayingMannVsMachine() && IsFakeClient(i)) // Don't count bots in MvM
			continue;

		if((g_engine == Engine_Left4Dead || g_engine == Engine_Left4Dead2) && IsFakeClient(i))
			continue;

		if(IsClientSourceTV(i))
			continue;

		if(IsClientReplay(i))
			continue;

		clients++;
	}

	return clients;
}

/**
 * Discord safe name
 * 
 * @param client     Client index
 * @param name       Name buffer
 * @param size       Buffer size
 */
/**void GetClientNameSafe(int client, char[] name, int size)
{
	GetClientName(client, name, size);
	ReplaceString(name, size, "@", "＠");
	ReplaceString(name, size, "'", "'");
	ReplaceString(name, size, "\"", "＂");
	ReplaceString(name, size, "ʖ", " ");
	ReplaceString(name, size, "м", "m");
	ReplaceString(name, size, "เ", "i");
	ReplaceString(name, size, "и", "n");
	ReplaceString(name, size, "ק", "p");
	ReplaceString(name, size, "я", "r");
	ReplaceString(name, size, "µ", "u");
	ReplaceString(name, size, "ℓ", "l");
}**/

/**
 * Construct the server IP Address
 * 
 * @param buffer		Buffer to store the IP Address
 * @param size			Buffer size
 * 
 * @return				True on success, false on error
 */
bool BuildServerIPAddr(char[] buffer, int size)
{
	// Priorize DNS if one is set
	char dns[128];
	c_dns.GetString(dns, sizeof(dns));

	if (strlen(dns) > 5)
	{
		strcopy(buffer, size, dns);
		return true;
	}

// need SMLIB for converting long to IP
#if defined __steampawn_included && defined _smlib_server_included
	if (g_steampawn)
	{
		int sdrIP = SteamPawn_GetSDRFakeIP();

		if (sdrIP != 0)
		{
			LongToIP(sdrIP, buffer, size);
			LogMessage("Found SDR IP address via SteamPawn. (%s)", buffer);
			return true;
		}
	}
#endif

#if defined _SteamWorks_Included
	if (g_steamworks)
	{
		int ipaddr[4];

		if (SteamWorks_GetPublicIP(ipaddr))
		{
			FormatEx(buffer, size, "%i.%i.%i.%i", ipaddr[0], ipaddr[1], ipaddr[2], ipaddr[3]);
			LogMessage("Found IP Address via SteamWorks (%s)", buffer);
			return true;
		}
	}
#endif

#if defined _smlib_server_included
	if (Server_GetIPString(buffer, size, false))
	{
		return true;
	}
#endif

	strcopy(buffer, size, "FAILED TO RETREIVE IP ADDRESS");
	return false;
}

void GetServerHostPort(int& port)
{

#if defined __steampawn_included
	if (g_steampawn)
	{
		int sdrport = SteamPawn_GetSDRFakePort(0); // get the first port

		if (sdrport != 0)
		{
			port = sdrport;
			return;
		}
	}
#endif

	ConVar cv_hostport = null;
	cv_hostport = FindConVar("hostport");

	if (cv_hostport == null)
	{
		ThrowError("Failed to find \"hostport\" convar!");
		return;
	}

	char szPort[32];
	cv_hostport.GetString(szPort, sizeof(szPort));
	port = StringToInt(szPort);
}