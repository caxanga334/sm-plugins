
char g_logfile[PLATFORM_MAX_PATH];

void Logger_BuildFilePath()
{
	char timestring[64];
	FormatTime(timestring, sizeof(timestring), "%Y-%m-%d"); // add date to file name
	// Path used for logging.
	BuildPath(Path_SM, g_logfile, sizeof(g_logfile), "logs/l4d_automod_%s.log", timestring);
}

void Logger_LogFriendlyFire(int client, int victim)
{
	char buffer[4096];

	FormatEx(buffer, sizeof(buffer), "[FRIENDLY FIRE] %L did excessive friendly fire damage against %L.", client, victim);

#if defined _stvmngr_included
	if (g_sourcetvmanager && SourceTV_IsRecording())
	{
		char demofile[PLATFORM_MAX_PATH];
		SourceTV_GetDemoFileName(demofile, sizeof(demofile));
		char demoinfo[PLATFORM_MAX_PATH + 32];
		FormatEx(demoinfo, sizeof(demoinfo), " SourceTV Demo: %s (%i)", SourceTV_GetRecordingTick());

		StrCat(buffer, sizeof(buffer), demoinfo);
	}
#endif

	LogToFileEx(g_logfile, "%s", buffer);
}