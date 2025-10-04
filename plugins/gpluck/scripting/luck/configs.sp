
static bool s_randomname_isvalid;

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
		SetFailState("Failed to laod the random name list! Error \"%s\" while parsing the file at line %i col %i!", szerror, line, col);
	}

	PrintToServer("[GP Luck] Random name list loaded!");
	delete smc;
}