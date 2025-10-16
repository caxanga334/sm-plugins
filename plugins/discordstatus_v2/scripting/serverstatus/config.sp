// Server Status config loader

static StringMap g_webhookURLs = null;
static StringMap g_webhookNames = null;
static StringMap g_webhookAvatars = null;

enum struct BaseConfig
{
	bool enabled;
	char key[64];
	char mention[128];
	bool hasmention;
}

enum struct ServerStartConfig
{
	bool enabled;
	char key[64];
	char mention[128];
	bool hasmention;
	bool sendIP;
}

enum struct SeedConfig
{
	bool enabled;
	char key[64];
	char mention[128];
	bool hasmention;
	bool sendIP;
	float cooldown;
}

enum struct SourceBansConfig
{
	bool enabled;
	char key[64];
	char mention[128];
	bool hasmention;
	char sburl[1024];
	bool hasurl;
}

enum struct DemoRequestConfig
{
	bool enabled;
	char key[64];
	char mention[128];
	bool hasmention;
	char accessurl[1024];
	bool hasaccessurl;
	float cooldown;
}

BaseConfig cfg_JoinLeave;
ServerStartConfig cfg_ServerStart;
BaseConfig cfg_GameEvents;
BaseConfig cfg_CallAdmin;
BaseConfig cfg_SourceTV;
SeedConfig cfg_Seed;
SourceBansConfig cfg_SourceBans;
BaseConfig cfg_NativeVotes;
DemoRequestConfig cfg_DemoRequests;
BaseConfig cfg_UpdateRequested;

bool Config_IsWebhookURLValid(const char[] url)
{
	if (StrContains(url, "discord.com/api/webhooks/") == -1)
	{
		return false;
	}

	return true;
}

void Config_GetWebHookURL(const char[] requester, const char[] key, char[] out, int size)
{
	if (!g_webhookURLs.GetString(key, out, size))
	{
		ThrowError("Failed to get Webhook URL from Key ID \"%s\" for \"%s\"!", key, requester);
	}
}

bool ConfigUtil_StringToBoolean(const char[] str)
{
	if (strncmp(str, "yes", 3, false) == 0)
	{
		return true;
	}
	if (strncmp(str, "true", 4, false) == 0)
	{
		return true;
	}
	if (strncmp(str, "no", 2, false) == 0)
	{
		return false;
	}
	if (strncmp(str, "false", 5, false) == 0)
	{
		return false;
	}

	int i = StringToInt(str);

	return i != 0;
}

void Config_Init()
{
	cfg_JoinLeave.enabled = false;
	cfg_JoinLeave.key = "";
	cfg_JoinLeave.hasmention = false;
	cfg_JoinLeave.mention = "";

	cfg_ServerStart.enabled = false;
	cfg_ServerStart.key = "";
	cfg_ServerStart.hasmention = false;
	cfg_ServerStart.sendIP = false;
	cfg_ServerStart.mention = "";

	cfg_GameEvents.enabled = false;
	cfg_GameEvents.key = "";
	cfg_GameEvents.hasmention = false;
	cfg_GameEvents.mention = "";

	cfg_CallAdmin.enabled = false;
	cfg_CallAdmin.key = "";
	cfg_CallAdmin.hasmention = false;
	cfg_CallAdmin.mention = "";

	cfg_SourceTV.enabled = false;
	cfg_SourceTV.key = "";
	cfg_SourceTV.hasmention = false;
	cfg_SourceTV.mention = "";

	cfg_Seed.enabled = false;
	cfg_Seed.key = "";
	cfg_Seed.hasmention = false;
	cfg_Seed.mention = "";
	cfg_Seed.sendIP = false;

	cfg_SourceBans.enabled = false;
	cfg_SourceBans.key = "";
	cfg_SourceBans.hasmention = false;
	cfg_SourceBans.mention = "";
	cfg_SourceBans.sburl = "";
	cfg_SourceBans.hasurl = false;

	cfg_NativeVotes.enabled = false;
	cfg_NativeVotes.key = "";
	cfg_NativeVotes.hasmention = false;
	cfg_NativeVotes.mention = "";

	cfg_DemoRequests.enabled = false;
	cfg_DemoRequests.key = "";
	cfg_DemoRequests.hasmention = false;
	cfg_DemoRequests.mention = "";
	cfg_DemoRequests.accessurl = "";
	cfg_DemoRequests.hasaccessurl = false;
	cfg_DemoRequests.cooldown = 900.0;

	cfg_UpdateRequested.enabled = false;
	cfg_UpdateRequested.key = "";
	cfg_UpdateRequested.hasmention = false;
	cfg_UpdateRequested.mention = "";
}

void Config_Load()
{
	Config_Init();

	if (g_webhookURLs != null)
	{
		delete g_webhookURLs;
		delete g_webhookNames;
		delete g_webhookAvatars;
		g_webhookURLs = null;
		g_webhookNames = null;
		g_webhookAvatars = null;
	}

	g_webhookURLs = new StringMap();
	g_webhookNames = new StringMap();
	g_webhookAvatars = new StringMap();

	char file[PLATFORM_MAX_PATH];
	KeyValues kv = new KeyValues("DiscordStatus");
	BuildPath(Path_SM, file, sizeof(file), "configs/discordstatus.cfg");

	if (!kv.ImportFromFile(file))
	{
		SetFailState("Failed to load config file \"%s\"", file);
	}

	char key[64];
	char value[WEBHOOK_URL_MAX_SIZE];    

	if (!kv.JumpToKey("WebHookURLs", false))
	{
		SetFailState("Failed to find key \"WebHookURLs\"!");
	}
	else
	{
		if (!kv.GotoFirstSubKey(false))
		{
			SetFailState("Invalid config file!");
		}
		else
		{
			do
			{
				kv.GetSectionName(key, sizeof(key));
				kv.GetString(NULL_STRING, value, sizeof(value));

				if (g_webhookURLs.ContainsKey(key))
				{
					LogError("Duplicate webhook ID \"%s\"!", key);
					continue;
				}

				if (!Config_IsWebhookURLValid(value))
				{
					LogError("%s: Invalid webhook URL \"%s\"", key, value);
					continue;
				}

				g_webhookURLs.SetString(key, value);
			}
			while(kv.GotoNextKey(false))

			kv.GoBack();
		}

		kv.GoBack();
	}

	if (kv.JumpToKey("WebHookConfig"))
	{
		StringMapSnapshot snapshot = g_webhookURLs.Snapshot();

		for (int i = 0; i < snapshot.Length; i++)
		{
			snapshot.GetKey(i, key, sizeof(key));

			if (kv.JumpToKey(key))
			{
				kv.GetString("Name", value, sizeof(value));

				if (strlen(value) > 3)
				{
					g_webhookNames.SetString(key, value);
				}
				
				kv.GetString("Avatar", value, sizeof(value));

				if (StrContains(value, "http", false) != -1)
				{
					g_webhookAvatars.SetString(key, value);
				}

				kv.GoBack();
			}
		}

		delete snapshot;
		kv.GoBack();
	}

	if (!kv.JumpToKey("Messages"))
	{
		SetFailState("Failed to find \"Messages\" key!");
	}
	else
	{
		if (kv.JumpToKey("JoinLeave"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_JoinLeave.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_JoinLeave.key, sizeof(cfg_JoinLeave.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_JoinLeave.hasmention = true;
				strcopy(cfg_JoinLeave.mention, sizeof(cfg_JoinLeave.mention), value);
			}

			kv.GoBack();
		}

		if (kv.JumpToKey("ServerStart"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_ServerStart.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("SendIP", value, sizeof(value));
			cfg_ServerStart.sendIP = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_ServerStart.key, sizeof(cfg_ServerStart.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_ServerStart.hasmention = true;
				strcopy(cfg_ServerStart.mention, sizeof(cfg_ServerStart.mention), value);
			}

			kv.GoBack();
		}

		if (kv.JumpToKey("GameEvents"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_GameEvents.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_GameEvents.key, sizeof(cfg_GameEvents.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_GameEvents.hasmention = true;
				strcopy(cfg_GameEvents.mention, sizeof(cfg_GameEvents.mention), value);
			}

			kv.GoBack();
		}

#if defined _calladmin_included

		if (kv.JumpToKey("CallAdmin"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_CallAdmin.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_CallAdmin.key, sizeof(cfg_CallAdmin.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_CallAdmin.hasmention = true;
				strcopy(cfg_CallAdmin.mention, sizeof(cfg_CallAdmin.mention), value);
			}

			kv.GoBack();
		}

#endif

#if defined _stvmngr_included

		if (kv.JumpToKey("SourceTV"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_SourceTV.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_SourceTV.key, sizeof(cfg_SourceTV.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_SourceTV.hasmention = true;
				strcopy(cfg_SourceTV.mention, sizeof(cfg_SourceTV.mention), value);
			}

			kv.GoBack();
		}

		if (kv.JumpToKey("DemoRequests"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_DemoRequests.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_DemoRequests.key, sizeof(cfg_DemoRequests.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_DemoRequests.hasmention = true;
				strcopy(cfg_DemoRequests.mention, sizeof(cfg_DemoRequests.mention), value);
			}

			kv.GetString("AccessURL", cfg_DemoRequests.accessurl, sizeof(cfg_DemoRequests.accessurl), "null");

			if (strcmp(cfg_DemoRequests.accessurl, "null") != 0)
			{
				cfg_DemoRequests.hasaccessurl = true;
			}

			cfg_DemoRequests.cooldown = kv.GetFloat("Cooldown", 900.0);

			kv.GoBack();
		}

#endif

		if (kv.JumpToKey("Seed"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_Seed.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("SendIP", value, sizeof(value));
			cfg_Seed.sendIP = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_Seed.key, sizeof(cfg_Seed.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_Seed.hasmention = true;
				strcopy(cfg_Seed.mention, sizeof(cfg_Seed.mention), value);
			}

			cfg_Seed.cooldown = kv.GetFloat("Cooldown", 900.0);

			kv.GoBack();
		}

#if defined _sourcebanspp_included

		if (kv.JumpToKey("SourceBans"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_SourceBans.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_SourceBans.key, sizeof(cfg_SourceBans.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_SourceBans.hasmention = true;
				strcopy(cfg_SourceBans.mention, sizeof(cfg_SourceBans.mention), value);
			}

			kv.GetString("SourceBansWebURL", cfg_SourceBans.sburl, sizeof(cfg_SourceBans.sburl));

			if (StrContains(cfg_SourceBans.sburl, "http", false) != -1)
			{
				cfg_SourceBans.hasurl = true;
			}

			kv.GoBack();
		}

#endif

		if (kv.JumpToKey("NativeVotes"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_NativeVotes.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_NativeVotes.key, sizeof(cfg_NativeVotes.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_NativeVotes.hasmention = true;
				strcopy(cfg_NativeVotes.mention, sizeof(cfg_NativeVotes.mention), value);
			}

			kv.GoBack();
		}

#if defined __steampawn_included
		if (kv.JumpToKey("UpdateRequested"))
		{
			kv.GetString("Enabled", value, sizeof(value));
			cfg_UpdateRequested.enabled = ConfigUtil_StringToBoolean(value);
			kv.GetString("WebHookKey", cfg_UpdateRequested.key, sizeof(cfg_UpdateRequested.key));
			kv.GetString("Mention", value, sizeof(value), "null");

			if (strcmp(value, "null") != 0)
			{
				cfg_UpdateRequested.hasmention = true;
				strcopy(cfg_UpdateRequested.mention, sizeof(cfg_UpdateRequested.mention), value);
			}

			kv.GoBack();
		}
#endif

		kv.GoBack();
	}

	delete kv;

	if (g_webhookURLs.Size == 0)
	{
		LogError("Set URLs at \"%s\"", file);
		SetFailState("No valids webhook URLs added to the config file.");
	}

	LogMessage("Discord Server Status plugin configuration fully loaded.");
	LogMessage("JoinLeave: %s ServerStart: %s GameEvents: %s CallAdmin: %s SourceTV: %s Server Seed: %s SourceBans: %s Native Votes: %s Demo Requests: %s Updated Requests: %s", 
		cfg_JoinLeave.enabled ? "Enabled" : "Disabled",
		cfg_ServerStart.enabled ? "Enabled" : "Disabled",
		cfg_GameEvents.enabled ? "Enabled" : "Disabled",
		cfg_CallAdmin.enabled ? "Enabled" : "Disabled",
		cfg_SourceTV.enabled ? "Enabled" : "Disabled",
		cfg_Seed.enabled ? "Enabled" : "Disabled",
		cfg_SourceBans.enabled ? "Enabled" : "Disabled",
		cfg_NativeVotes.enabled ? "Enabled" : "Disabled",
		cfg_DemoRequests.enabled ? "Enabled" : "Disabled",
		cfg_UpdateRequested.enabled ? "Enabled" : "Disabled");
}

Webhook Config_CreateWebHook(const char[] contents = "", const char[] defaultusername = "Server Status", const char[] key)
{
	char buffer[1024];

	Webhook wh = new Webhook(contents);

	if (g_webhookNames.GetString(key, buffer, sizeof(buffer)))
	{
		wh.SetUsername(buffer);
	}
	else
	{
		wh.SetUsername(defaultusername);
	}

	if (g_webhookAvatars.GetString(key, buffer, sizeof(buffer)))
	{
		wh.SetAvatarURL(buffer);
	}

	return wh;
}