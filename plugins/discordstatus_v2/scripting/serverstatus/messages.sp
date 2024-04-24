/**
 * 
 * --- Adds space between two embed fields
 * EmbedField fieldspacer = new EmbedField("\n_ _", "\n_ _", false);
 * embed1.AddField(fieldspacer);
 * 
 */

void AddSpacer(Embed &embed)
{
	EmbedField fieldspacer = new EmbedField("\n_ _", "\n_ _", false);
	embed.AddField(fieldspacer);
}

void SendMessage_OnClientJoin(int client)
{
	if(!client) { return; }

	int maxslots = GetServerMaxSlots();
	char mapname[64];
	char servername[64];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));


	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

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

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

void SendMessage_OnClientLeave()
{
	int maxslots = GetServerMaxSlots();
	char mapname[64];
	char servername[64];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));


	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

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

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the server has started
 */
void SendMessage_OnServerStart()
{
	char mapname[64];
	char servername[64];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");
	
	char buffer[128];
	Embed embed1 = new Embed(servername, "Server started!");
	embed1.SetTimeStampNow();
	embed1.SetColor(5763719);

	if (c_announceIP.BoolValue)
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
	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the server has started
 */
void SendMessage_L4D_OnGameMode(int gamemode)
{
	char mapname[64];
	char servername[64];
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

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

	Embed embed1 = new Embed(servername, "Game mode changed.");
	embed1.SetTimeStampNow();
	embed1.SetColor(65535);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	EmbedField field2 = new EmbedField("Game Mode", szgamemode);
	embed1.AddField(field2);

	webhook.AddEmbed(embed1); 

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the round has started (L4D)
 */
void SendMessage_L4D_OnRoundStart()
{
	char mapname[64];
	char servername[64];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

	Embed embed1 = new Embed(servername, "Round Started");
	embed1.SetTimeStampNow();
	embed1.SetColor(32768);

	EmbedField fieldmap = new EmbedField("Map", mapname, true);
	embed1.AddField(fieldmap);

	webhook.AddEmbed(embed1); 

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

/**
 * Sends a message informing that the round has started (L4D)
 */
void SendMessage_TF2_OnMvMWaveStart(int wave, int max)
{
	char mapname[64];
	char servername[64];
	char missioname[128];
	char waveinfo[16];
	GetServerName(servername, sizeof(servername));
	GetMapName(mapname, sizeof(mapname));
	GetMapDisplayName(mapname, mapname, sizeof(mapname));
	TF2MvM_GetMissionName(missioname, sizeof(missioname));
	FormatEx(waveinfo, sizeof(waveinfo), "%i of %i waves", wave, max);

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

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

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

void SendMessage_OnSTVRecordingStart(const char[] filename)
{
	char servername[96];
	GetServerName(servername, sizeof(servername));
	Format(servername, sizeof(servername), "[SourceTV] %s", servername);

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Server Status");

	Embed embed1 = new Embed(servername, "Demo recording started");
	embed1.SetTimeStampNow();
	embed1.SetColor(2031480);

	EmbedField fielddemoname = new EmbedField("File", filename, false);
	embed1.AddField(fielddemoname);

	webhook.AddEmbed(embed1); 

	webhook.Execute(g_primarywebhook, OnWebHookExecuted);

	delete webhook;
}

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

	char mention[64];
	c_calladmin_mention.GetString(mention, sizeof(mention));

	if (!mention[0])
	{
		mention = "@here";
	}

	Webhook webhook = new Webhook(mention);
	webhook.SetUsername("Call Admin");

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

	if (g_sourcetvmanager && SourceTV_IsRecording())
	{
		SourceTV_GetDemoFileName(tmp, sizeof(tmp));

		EmbedField field4 = new EmbedField("Demo", tmp, true);
		embed1.AddField(field4);

		FormatEx(tmp, sizeof(tmp), "%i", SourceTV_GetRecordingTick());
		EmbedField field5 = new EmbedField("Tick", tmp, true);
		embed1.AddField(field5);
	}

	webhook.AddEmbed(embed1); 

	webhook.Execute(g_adminwebhook, OnWebHookExecuted);

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

	Webhook webhook = new Webhook("");
	webhook.SetUsername("Call Admin");

	FormatEx(tmp, sizeof(tmp), "Reported Handled - %i", id);
	Embed embed1 = new Embed(servername, tmp);
	embed1.SetTimeStampNow();
	embed1.SetColor(39219);

	EmbedField field1 = new EmbedField("Admin", name1, false);
	embed1.AddField(field1);

	if (g_sourcetvmanager && SourceTV_IsRecording())
	{
		SourceTV_GetDemoFileName(tmp, sizeof(tmp));

		EmbedField field2 = new EmbedField("Demo", tmp, true);
		embed1.AddField(field2);

		FormatEx(tmp, sizeof(tmp), "%i", SourceTV_GetRecordingTick());
		EmbedField field3 = new EmbedField("Tick", tmp, true);
		embed1.AddField(field3);
	}

	webhook.AddEmbed(embed1); 

	webhook.Execute(g_adminwebhook, OnWebHookExecuted);

	delete webhook;
}