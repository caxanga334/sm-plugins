
enum ActionType
{
	ACTION_LOGONLY = 0, // Only logs to the server file
	ACTION_WARN_ADMINS, // Prints a message to admins on the server
	ACTION_PUBLIC_NOTICE, // Prints a public message to chat
	ACTION_KILL, // Kills the player if applicable
	ACTION_KICK, // Kicks the player from the server
	ACTION_LOCALBAN, // Bans the player using the engine's built in ban system
	ACTION_BAN, // Bans the player via a ban management system (SourceBans). Fallback to local if not available

	MAX_VALID_ACTIONS
}

enum struct AutoModConfig
{
	int default_ban_length;
	int max_ff_damage;
	ActionType ff_action;
	float ff_reset_time;
	bool ff_ignore_bots;
	bool ff_ignore_fire;
}

bool Config_ParseBoolean(const char[] entry)
{
	if (strncmp(entry, "yes", 3, false) == 0)
	{
		return true;
	}

	if (strncmp(entry, "true", 4, false) == 0)
	{
		return true;
	}

	if (strncmp(entry, "no", 2, false) == 0)
	{
		return false;
	}

	if (strncmp(entry, "false", 5, false) == 0)
	{
		return false;
	}

	return StringToInt(entry) != 0;
}

AutoModConfig g_cfg;

void Config_Init()
{
	g_cfg.default_ban_length = 120;
	g_cfg.ff_action = ACTION_LOGONLY;
	g_cfg.ff_ignore_bots = false;
	g_cfg.ff_ignore_fire = false;
	g_cfg.ff_reset_time = 10.0;
	g_cfg.max_ff_damage = 150;
}

void Config_Load()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/l4d_automod.cfg");

	KeyValues kv = new KeyValues("automod");

	if (!kv.ImportFromFile(file))
	{
		SetFailState("Failed to load config file \"%s\"!", file);
	}

	if (!kv.JumpToKey("settings"))
	{
		SetFailState("Invalid config file \"%s\"!", file);
	}
	else
	{
		g_cfg.default_ban_length = kv.GetNum("default_ban_length", 120);
		int action = kv.GetNum("friendlyfire_action", 0);

		if (action < 0 || action >= view_as<int>(MAX_VALID_ACTIONS))
		{
			LogError("Invalid action %i at key \"friendlyfire_action\"!", action);
			action = 0;
		}

		g_cfg.ff_action = view_as<ActionType>(action);

		g_cfg.max_ff_damage = kv.GetNum("friendlyfire_limit", 150);
		g_cfg.ff_reset_time = kv.GetFloat("friendlyfire_time", 10.0);
		
		char value[8];
		kv.GetString("friendlyfire_ignore_bots", value, sizeof(value), "no");
		g_cfg.ff_ignore_bots = Config_ParseBoolean(value);

		kv.GetString("friendlyfire_ignore_fire", value, sizeof(value), "no");
		g_cfg.ff_ignore_fire = Config_ParseBoolean(value);
	}

	kv.GoBack();

	delete kv;

	LogMessage("Config loaded.");
}