#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1
#define MAX_COMMAND_ARGS 32

public Plugin myinfo =
{
	name = "[DEV] Client Command Logger",
	author = "caxanga334",
	description = "Logs client commands.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

char g_logFile[PLATFORM_MAX_PATH];

void BuildLogFilePath()
{
	char date[64];
	FormatTime(date, sizeof(date), "%Y-%m-%d");
	BuildPath(Path_SM, g_logFile, PLATFORM_MAX_PATH, "logs/client_commands_%s.log", date);
}


public void OnPluginStart()
{
	BuildLogFilePath();
}

public void OnMapStart()
{
	BuildLogFilePath();
}

public Action OnClientCommand(int client, int args)
{
	char cmdname[512];
	
	// arg 0 is the command name
	GetCmdArg(0, cmdname, sizeof(cmdname));

	char msg[8192];

	FormatEx(msg, sizeof(msg), "%L sent client command %s with %i args: ", client, cmdname, args);

	for (int i = 1; i <= args; i++)
	{
		if (i == MAX_COMMAND_ARGS) { break; }

		char buffer[256];

		GetCmdArg(i, buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "\"%s\" ", buffer); // add space
		StrCat(msg, sizeof(msg), buffer);
	}

	LogToFile(g_logFile, "%s", msg);
	return Plugin_Continue;
}