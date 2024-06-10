
#include "webhook_util.sp"

// shared webhook url buffer
static char s_webhook_url[WEBHOOK_URL_MAX_SIZE];

void SendMessage_OnClientJoin(int client)
{
	if(!client) { return; }

	int maxslots = GetServerMaxSlots();
	char mapname[64];
	char servername[64];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	char contents[128];

	if (cfg_JoinLeave.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_JoinLeave.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_JoinLeave.key);

	Embed embed1 = new Embed(servername, "Client joined the server!");
	embed1.SetTimeStampNow();
	embed1.SetColor(3447003);

	char steamid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)))
	{
		steamid = "";
	}

	char buffer[512];
	FormatEx(buffer, sizeof(buffer), "%N (%s)", client, steamid);

	EmbedField fieldclient = new EmbedField("Client", buffer, false);
	embed1.AddField(fieldclient);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	char szslots[32];
	FormatEx(szslots, sizeof(szslots), "%i of %i", GetDynamicClientCount(), maxslots);
	EmbedField field11 = new EmbedField("Slots", szslots, true);
	embed1.AddField(field11);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("JoinLeave", cfg_JoinLeave.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

void SendMessage_OnClientLeave()
{
	int maxslots = GetServerMaxSlots();
	char mapname[64];
	char servername[128];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	char contents[128];

	if (cfg_JoinLeave.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_JoinLeave.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_JoinLeave.key);

	Embed embed1 = new Embed(servername, "Client left the server!");
	embed1.SetTimeStampNow();
	embed1.SetColor(16753920);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	char szslots[32];
	FormatEx(szslots, sizeof(szslots), "%i of %i", GetDynamicClientCount(), maxslots);
	EmbedField field11 = new EmbedField("Slots", szslots, true);
	embed1.AddField(field11);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("JoinLeave", cfg_JoinLeave.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the server has started
 */
void SendMessage_OnServerStart()
{
	char mapname[64];
	char servername[128];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	char contents[128];

	if (cfg_ServerStart.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_ServerStart.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_ServerStart.key);
	
	char buffer[128];
	Embed embed1 = new Embed(servername, "Server started!");
	embed1.SetTimeStampNow();
	embed1.SetColor(5763719);

	if (cfg_ServerStart.sendIP)
	{
		int svport = 0;
		GetServerHostPort(svport);
		FormatEx(buffer, sizeof(buffer), "%s:%i", g_ipaddr, svport);

		EmbedField fieldAddress = new EmbedField("IP Address", buffer, true);
		embed1.AddField(fieldAddress);
	}

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("ServerStart", cfg_ServerStart.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#if defined _l4dh_included

/**
 * Sends a message informing that the server has started
 */
void SendMessage_L4D_OnGameMode(int gamemode)
{
	char mapname[64];
	char servername[128];
	char szgamemode[16];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	switch(gamemode)
	{
		case GAMEMODE_COOP: strcopy(szgamemode, sizeof(szgamemode), "COOP");
		case GAMEMODE_SURVIVAL: strcopy(szgamemode, sizeof(szgamemode), "SURVIVAL");
		case GAMEMODE_VERSUS: strcopy(szgamemode, sizeof(szgamemode), "VERSUS");
		case GAMEMODE_SCAVENGE: strcopy(szgamemode, sizeof(szgamemode), "SCAVENGE");
		default: return;
	}

	char contents[128];

	if (cfg_GameEvents.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_GameEvents.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_GameEvents.key);

	Embed embed1 = new Embed(servername, "Game mode changed.");
	embed1.SetTimeStampNow();
	embed1.SetColor(65535);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	EmbedField field2 = new EmbedField("Game Mode", szgamemode);
	embed1.AddField(field2);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("GameEvents", cfg_GameEvents.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the round has started (L4D)
 */
void SendMessage_L4D_OnRoundStart()
{
	char mapname[64];
	char servername[128];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	char contents[128];

	if (cfg_GameEvents.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_GameEvents.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_GameEvents.key);

	Embed embed1 = new Embed(servername, "Round Started");
	embed1.SetTimeStampNow();
	embed1.SetColor(32768);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("GameEvents", cfg_GameEvents.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#endif

/**
 * Sends a message informing that the round has started (L4D)
 */
void SendMessage_TF2_OnMvMWaveStart(int wave, int max)
{
	char mapname[64];
	char servername[128];
	char missioname[128];
	char waveinfo[16];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));
	GetMapDisplayName(mapname, mapname, sizeof(mapname));
	TF2MvM_GetMissionName(missioname, sizeof(missioname));
	FormatEx(waveinfo, sizeof(waveinfo), "%i of %i waves", wave, max);

	char contents[128];

	if (cfg_GameEvents.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_GameEvents.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_GameEvents.key);

	Embed embed1 = new Embed(servername, "Mann vs Machine Wave Started");
	embed1.SetTimeStampNow();
	embed1.SetColor(2013304);

	EmbedField fieldmap = new EmbedField("Map", mapname, false);
	embed1.AddField(fieldmap);

	EmbedField fieldwaveinfo = new EmbedField("Current Mission", missioname, true);
	embed1.AddField(fieldwaveinfo);

	EmbedField fieldwavenum = new EmbedField("Wave Info", waveinfo, true);
	embed1.AddField(fieldwavenum);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("GameEvents", cfg_GameEvents.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#if defined _stvmngr_included

void SendMessage_OnSTVRecordingStart(const char[] filename)
{
	char servername[96];
	GetServerName(servername, sizeof(servername));
	Format(servername, sizeof(servername), "[SourceTV] %s", servername);

	char contents[128];

	if (cfg_SourceTV.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_SourceTV.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, _, cfg_SourceTV.key);

	Embed embed1 = new Embed(servername, "Demo recording started");
	embed1.SetTimeStampNow();
	embed1.SetColor(2031480);

	EmbedField fielddemoname = new EmbedField("File", filename, false);
	embed1.AddField(fielddemoname);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("SourceTV", cfg_SourceTV.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#endif

#if defined _calladmin_included

void SendMessage_OnCallAdminReport(int client, int target, const char[] reason)
{
	char servername[96];
	char tmp[128];
	char name1[MAX_NAME_LENGTH];
	char name2[MAX_NAME_LENGTH];

	GetServerName(servername, sizeof(servername));
	Format(servername, sizeof(servername), "[CallAdmin] %s", servername);

	if (IsValidClientIndex(client))
	{
		GetClientSteamID(client, tmp, sizeof(tmp), AuthId_SteamID64);
		FormatEx(name1, sizeof(name1), "%N (%s)", client, tmp);
	}
	else
	{
		FormatEx(name1, sizeof(name1), "SERVER");
	}

	if (IsValidClientIndex(target))
	{
		GetClientSteamID(target, tmp, sizeof(tmp), AuthId_SteamID64);
		FormatEx(name2, sizeof(name2), "%N (%s)", target, tmp);
	}
	else
	{
		FormatEx(name2, sizeof(name2), "Unknown");
	}

	char contents[128];

	if (cfg_CallAdmin.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_CallAdmin.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "Call Admin", cfg_CallAdmin.key);

	FormatEx(tmp, sizeof(tmp), "Player reported - Report ID %i", CallAdmin_GetReportID());
	Embed embed1 = new Embed(servername, tmp);
	embed1.SetTimeStampNow();
	embed1.SetColor(16711680);

	EmbedField field1 = new EmbedField("Reporter", name1, true);
	embed1.AddField(field1);

	EmbedField field2 = new EmbedField("Target", name2, true);
	embed1.AddField(field2);

	AddSpacer(embed1);

	EmbedField field3 = new EmbedField("Reason", reason, false);
	embed1.AddField(field3);

#if defined _stvmngr_included

	if (g_sourcetvmanager && SourceTV_IsRecording())
	{
		SourceTV_GetDemoFileName(tmp, sizeof(tmp));

		EmbedField field4 = new EmbedField("Demo", tmp, true);
		embed1.AddField(field4);

		FormatEx(tmp, sizeof(tmp), "%i", SourceTV_GetRecordingTick());
		EmbedField field5 = new EmbedField("Tick", tmp, true);
		embed1.AddField(field5);
	}

#endif

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("CallAdmin", cfg_CallAdmin.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

void SendMessage_OnCallAdminReportHandled(int client, int id)
{
	char servername[96];
	char tmp[128];
	char name1[MAX_NAME_LENGTH];

	GetServerName(servername, sizeof(servername));
	Format(servername, sizeof(servername), "[CallAdmin] %s", servername);

	if (IsValidClientIndex(client))
	{
		GetClientSteamID(client, tmp, sizeof(tmp), AuthId_SteamID64);
		FormatEx(name1, sizeof(name1), "%N (%s)", client, tmp);
	}
	else
	{
		FormatEx(name1, sizeof(name1), "SERVER");
	}

	char contents[128];

	if (cfg_CallAdmin.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_CallAdmin.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "Call Admin", cfg_CallAdmin.key);

	FormatEx(tmp, sizeof(tmp), "Reported Handled - %i", id);
	Embed embed1 = new Embed(servername, tmp);
	embed1.SetTimeStampNow();
	embed1.SetColor(39219);

	EmbedField field1 = new EmbedField("Admin", name1, false);
	embed1.AddField(field1);

#if defined _stvmngr_included

	if (g_sourcetvmanager && SourceTV_IsRecording())
	{
		SourceTV_GetDemoFileName(tmp, sizeof(tmp));

		EmbedField field2 = new EmbedField("Demo", tmp, true);
		embed1.AddField(field2);

		FormatEx(tmp, sizeof(tmp), "%i", SourceTV_GetRecordingTick());
		EmbedField field3 = new EmbedField("Tick", tmp, true);
		embed1.AddField(field3);
	}

#endif

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("CallAdmin", cfg_CallAdmin.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

void SendMessage_OnSeedRequest(int requestingClient)
{
	char mapname[64];
	char servername[128];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	char contents[128];

	if (cfg_Seed.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_Seed.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "Seed Request", cfg_Seed.key);
	
	char buffer[512];
	Embed embed1 = new Embed(servername, "This server is looking for players!");
	embed1.SetTimeStampNow();
	embed1.SetColor(32768);

	char steamid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(requestingClient, AuthId_SteamID64, steamid, sizeof(steamid)))
	{
		steamid = "";
	}

	FormatEx(buffer, sizeof(buffer), "%N (%s)", requestingClient, steamid);

	EmbedField fieldclient = new EmbedField("Requester", buffer, false);
	embed1.AddField(fieldclient);

	if (cfg_Seed.sendIP && g_hasip)
	{
		int svport = 0;
		GetServerHostPort(svport);
		FormatEx(buffer, sizeof(buffer), "%s:%i", g_ipaddr, svport);

		EmbedField fieldAddress = new EmbedField("IP Address", buffer, false);
		embed1.AddField(fieldAddress);
	}

	EmbedField fieldmap = new EmbedField("Map", mapname, false);
	embed1.AddField(fieldmap);

	// TO-DO: Add more info for other games
	if (g_engine == Engine_Left4Dead2)
	{
		ConVar mp_gamemode = FindConVar("mp_gamemode");

		if (mp_gamemode != null)
		{
			mp_gamemode.GetString(buffer, sizeof(buffer));

			EmbedField fieldGM = new EmbedField("Game Mode", buffer, false);
			embed1.AddField(fieldGM);
		}
	}

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("Seed", cfg_Seed.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#endif

#if defined _sourcebanspp_included

void SendMessage_OnSBBanAdded(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
	char servername[128];
	GetServerName(servername, sizeof(servername));

	char adminName[MAX_NAME_LENGTH];
	char adminSID[MAX_AUTHID_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	char targetSID[MAX_AUTHID_LENGTH];

	if (iAdmin == 0)
	{
		adminName = "CONSOLE";
		adminSID = "";
	}
	else
	{
		GetClientName(iAdmin, adminName, sizeof(adminName));

		if (!GetClientAuthId(iAdmin, AuthId_SteamID64, adminSID, sizeof(adminSID)))
		{
			adminSID = "";
		}
	}

	GetClientName(iTarget, targetName, sizeof(targetName));

	if (!GetClientAuthId(iTarget, AuthId_SteamID64, targetSID, sizeof(targetSID)))
	{
		targetSID = "";
	}

	char contents[128];

	if (cfg_SourceBans.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_SourceBans.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "SourceBans", cfg_SourceBans.key);

	char buffer[1024];
	Embed embed1 = new Embed("View on SourceBans Web", "A player has been banned.");
	embed1.SetTimeStampNow();
	embed1.SetColor(16656146);

	EmbedField field0 = new EmbedField("Server", servername, false);
	embed1.AddField(field0);
	FormatEx(buffer, sizeof(buffer), "%s (%s)", adminName, adminSID);
	EmbedField field1 = new EmbedField("Admin", buffer, false);
	embed1.AddField(field1);
	FormatEx(buffer, sizeof(buffer), "%s (%s)", targetName, targetSID);
	EmbedField field2 = new EmbedField("Target", buffer, false);
	embed1.AddField(field2);
	
	if (iTime == 0)
	{
		FormatEx(buffer, sizeof(buffer), "Permanent");
	}
	else
	{
		FormatMessage_Time(iTime, buffer, sizeof(buffer));
	}

	EmbedField field3 = new EmbedField("Ban Length", buffer, false);
	embed1.AddField(field3);
	EmbedField field4 = new EmbedField("Ban Reason", sReason, false);
	embed1.AddField(field4);

	if (cfg_SourceBans.hasurl)
	{
		char webSID[MAX_AUTHID_LENGTH];
		
		if (GetClientAuthId(iTarget, AuthId_Steam2, webSID, sizeof(webSID)))
		{
			FormatEx(buffer, sizeof(buffer), "%sindex.php?p=banlist&advSearch=%s&advType=steamid&Submit", cfg_SourceBans.sburl, webSID);
			embed1.SetURL(buffer);
		}
	}

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("SourceBans", cfg_SourceBans.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#endif

#if defined _sourcecomms_included

void SendMessage_OnSBCommsBlockAdded(int admin, int target, int time, int type, char[] reason)
{
	char servername[128];
	GetServerName(servername, sizeof(servername));

	char adminName[MAX_NAME_LENGTH];
	char adminSID[MAX_AUTHID_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	char targetSID[MAX_AUTHID_LENGTH];

	if (admin == 0)
	{
		adminName = "CONSOLE";
		adminSID = "";
	}
	else
	{
		GetClientName(admin, adminName, sizeof(adminName));

		if (!GetClientAuthId(admin, AuthId_SteamID64, adminSID, sizeof(adminSID)))
		{
			adminSID = "";
		}
	}

	GetClientName(target, targetName, sizeof(targetName));

	if (!GetClientAuthId(target, AuthId_SteamID64, targetSID, sizeof(targetSID)))
	{
		targetSID = "";
	}

	char contents[128];

	if (cfg_SourceBans.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_SourceBans.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "SourceBans", cfg_SourceBans.key);

	char buffer[1024];
	Embed embed1 = new Embed("View on SourceBans Web", "A player has been banned.");
	embed1.SetTimeStampNow();
	embed1.SetColor(16656146);

	EmbedField field0 = new EmbedField("Server", servername, false);
	embed1.AddField(field0);
	FormatEx(buffer, sizeof(buffer), "%s (%s)", adminName, adminSID);
	EmbedField field1 = new EmbedField("Admin", buffer, false);
	embed1.AddField(field1);
	FormatEx(buffer, sizeof(buffer), "%s (%s)", targetName, targetSID);
	EmbedField field2 = new EmbedField("Target", buffer, false);
	embed1.AddField(field2);

	if (time < 0)
	{
		FormatEx(buffer, sizeof(buffer), "Session");
	}
	else if (time == 0)
	{
		FormatEx(buffer, sizeof(buffer), "Permanent");
	}
	else
	{
		FormatMessage_Time(time, buffer, sizeof(buffer));
	}

	
	EmbedField field3 = new EmbedField("Block Length", buffer, false);
	embed1.AddField(field3);

	switch (type)
	{
		case TYPE_MUTE:
		{
			buffer = "Muted";
		}
		case TYPE_GAG:
		{
			buffer = "Gagged";
		}
		case TYPE_SILENCE:
		{
			buffer = "Silenced";
		}
	}

	EmbedField field4 = new EmbedField("Block Type", buffer, false);
	embed1.AddField(field4);
	EmbedField field5 = new EmbedField("Block Reason", reason, false);
	embed1.AddField(field5);

	if (cfg_SourceBans.hasurl)
	{
		char webSID[MAX_AUTHID_LENGTH];
		
		if (GetClientAuthId(target, AuthId_Steam2, webSID, sizeof(webSID)))
		{
			FormatEx(buffer, sizeof(buffer), "%sindex.php?p=commslist&advSearch=%s&advType=steamid&Submit", cfg_SourceBans.sburl, webSID);
			embed1.SetURL(buffer);
		}
	}

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("SourceBans", cfg_SourceBans.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}

#endif

void SendMessage_L4D_OnNativeVote(int client, const char[] issue, const char[] option)
{
	char servername[128];
	char contents[128];
	char buffer[512];
	char votename[128];
	char voteoption[256];
	GetServerName(servername, sizeof(servername));

	FormatMessage_L4D_NativeVote(issue, option, votename, sizeof(votename), voteoption, sizeof(voteoption));

	if (cfg_NativeVotes.hasmention)
	{
		strcopy(contents, sizeof(contents), cfg_NativeVotes.mention);
	}
	else
	{
		contents = "";
	}

	Webhook webhook = Config_CreateWebHook(contents, "Vote Logger", cfg_NativeVotes.key);

	Embed embed1 = new Embed(servername, "A vote has been called.");
	embed1.SetTimeStampNow();
	embed1.SetColor(149502);

	if (!GetClientAuthId(client, AuthId_SteamID64, buffer, sizeof(buffer)))
	{
		buffer = "";
	}

	Format(buffer, sizeof(buffer), "%N (%s)", client, buffer);
	EmbedField field1 = new EmbedField("Caller", buffer, false);
	embed1.AddField(field1);
	EmbedField field2 = new EmbedField("Issue", votename, true);
	embed1.AddField(field2);
	EmbedField field3 = new EmbedField("Option", voteoption, true);
	embed1.AddField(field3);

	webhook.AddEmbed(embed1); 

	Config_GetWebHookURL("SourceBans", cfg_NativeVotes.key, s_webhook_url, sizeof(s_webhook_url));
	webhook.Execute(s_webhook_url, OnWebHookExecuted);

	delete webhook;
}