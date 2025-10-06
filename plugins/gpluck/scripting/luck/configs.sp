
static bool s_randomname_isvalid;

enum struct MainConfig_s
{
	float roll_cooldown_min;
	float roll_cooldown_max;
	float duration_min;
	float duration_max;
	bool red_allowed;
	bool blu_allowed;
	bool allow_bots;
	bool autoroll_bots;

	float GetRollCooldown()
	{
		return Math_GetRandomFloat(this.roll_cooldown_min, this.roll_cooldown_max);
	}

	float GetEffectLength()
	{
		return Math_GetRandomFloat(this.duration_min, this.duration_max);
	}

	void Validate()
	{
		if (this.roll_cooldown_min >= this.roll_cooldown_max)
		{
			this.roll_cooldown_min = 70.0;
			this.roll_cooldown_max = 180.0;
		}

		if (this.duration_min >= this.duration_max)
		{
			this.duration_min = 30.0;
			this.duration_max = 60.0;
		}
	}
}
MainConfig_s g_config;

static bool Config_ParseBoolean(const char[] value)
{
	if (strcmp(value, "true", false) == 0)
	{
		return true;
	}
	if (strcmp(value, "yes", false) == 0)
	{
		return true;
	}
	if (strcmp(value, "false", false) == 0)
	{
		return false;
	}
	if (strcmp(value, "no", false) == 0)
	{
		return false;
	}

	return StringToInt(value) != 0;
}

static SMCResult RandomNameLoader_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	if (s_randomname_isvalid) { return SMCParse_Continue; }

	if (strcmp(name, "LuckRandomNames", false) != 0)
	{
		LogError("Error while loading random names config file at line %i col %i");
		return SMCParse_HaltFail;
	}

	s_randomname_isvalid = true;
	return SMCParse_Continue;
}

static SMCResult RandomNameLoader_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (strlen(key) > 1)
	{
		g_RandomNames1.PushString(key);
	}

	if (strlen(value))
	{
		g_RandomNames2.PushString(value);
	}

	return SMCParse_Continue;
}

static bool s_mainparserValid;

static SMCResult MainConfig_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	if (!s_mainparserValid)
	{
		if (strcmp(name, "LuckMainConfig", false) == 0)
		{
			return SMCParse_Continue;
		}
		else
		{
			return SMCParse_HaltFail;
		}
	}

	return SMCParse_Continue;
}

static SMCResult MainConfig_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (strcmp(key, "cooldown_min", false) == 0)
	{
		g_config.roll_cooldown_min = StringToFloat(value);
	}
	else if (strcmp(key, "cooldown_max", false) == 0)
	{
		g_config.roll_cooldown_max = StringToFloat(value);
	}
	else if (strcmp(key, "duration_min", false) == 0)
	{
		g_config.duration_min = StringToFloat(value);
	}
	else if (strcmp(key, "duration_max", false) == 0)
	{
		g_config.duration_max = StringToFloat(value);
	}
	else if (strcmp(key, "red_allowed", false) == 0)
	{
		g_config.red_allowed = Config_ParseBoolean(value);
	}
	else if (strcmp(key, "blu_allowed", false) == 0)
	{
		g_config.blu_allowed = Config_ParseBoolean(value);
	}
	else if (strcmp(key, "allow_bots", false) == 0)
	{
		g_config.allow_bots = Config_ParseBoolean(value);
	}
	else if (strcmp(key, "autoroll_bots", false) == 0)
	{
		g_config.autoroll_bots = Config_ParseBoolean(value);
	}

	return SMCParse_Continue;
}

static SMCResult MainConfig_EndSection(SMCParser smc)
{
	if (s_mainparserValid)
	{
		s_mainparserValid = false;
	}

	return SMCParse_Continue;
}

void Config_LoadMain()
{
	char path[PLATFORM_MAX_PATH];
	s_mainparserValid = false;

	BuildPath(Path_SM, path, sizeof(path), "configs/gpluck/main.cfg");

	if (!FileExists(path))
	{
		SetFailState("Failed to load the main config file! File \"%s\" does not exists!", path);
		return;
	}

	SMCParser smc = new SMCParser();
	smc.OnEnterSection = MainConfig_NewSection;
	smc.OnKeyValue = MainConfig_KeyValue;
	smc.OnLeaveSection = MainConfig_EndSection;

	int line = 0;
	int col = 0;
	SMCError error = smc.ParseFile(path, line, col);

	if (error != SMCError_Okay)
	{
		char szerror[256];
		SMC_GetErrorString(error, szerror, sizeof(szerror));
		delete smc;
		SetFailState("Failed to load the main config file! Error \"%s\" while parsing the file at line %i col %i!", szerror, line, col);
	}

	delete smc;
}

void Config_LoadRandomNames()
{
	char path[PLATFORM_MAX_PATH];
	SMCParser smc = new SMCParser();
	s_randomname_isvalid = false;
	smc.OnEnterSection = RandomNameLoader_NewSection;
	smc.OnKeyValue = RandomNameLoader_KeyValue;

	g_RandomNames1.Clear();
	g_RandomNames2.Clear();

	PrintToServer("[GP Luck] Loading random name list.");

	BuildPath(Path_SM, path, sizeof(path), "configs/gpluck/random_names.cfg");

	if (!FileExists(path))
	{
		delete smc;
		SetFailState("Failed to load the random name list! File \"%s\" does not exists!", path);
	}

	int line = 0;
	int col = 0;
	SMCError error = smc.ParseFile(path, line, col);

	if (error != SMCError_Okay)
	{
		char szerror[256];
		SMC_GetErrorString(error, szerror, sizeof(szerror));
		delete smc;
		SetFailState("Failed to load the random name list! Error \"%s\" while parsing the file at line %i col %i!", szerror, line, col);
	}

	PrintToServer("[GP Luck] Random name list loaded!");
	delete smc;
}