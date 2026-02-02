#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1
#define MAX_COMMAND_ARGS 32

static const int s_bitsArray[] = {
	(1 << 0),
	(1 << 1),
	(1 << 2),
	(1 << 3),
	(1 << 4),
	(1 << 5),
	(1 << 6),
	(1 << 7),
	(1 << 8),
	(1 << 9),
	(1 << 10),
	(1 << 11),
	(1 << 12),
	(1 << 13),
	(1 << 14),
	(1 << 15),
	(1 << 16),
	(1 << 17),
	(1 << 18),
	(1 << 19),
	(1 << 20),
	(1 << 21),
	(1 << 22),
	(1 << 23),
	(1 << 24),
	(1 << 25),
	(1 << 26),
	(1 << 27),
	(1 << 28),
	(1 << 29),
	(1 << 30),
};

public Plugin myinfo =
{
	name = "[DEV] Client Command Logger",
	author = "caxanga334",
	description = "Logs client commands.",
	version = "1.1.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

char g_logFile[PLATFORM_MAX_PATH];
bool g_bLogging;
bool g_bLogButtons[MAXPLAYERS + 1];

void BuildLogFilePath()
{
	char date[64];
	FormatTime(date, sizeof(date), "%Y-%m-%d");
	BuildPath(Path_SM, g_logFile, PLATFORM_MAX_PATH, "logs/client_commands_%s.log", date);
}

public void OnClientPutInServer(int client)
{
	g_bLogButtons[client] = false;
}

Action Command_ToggleLogging(int client, int args)
{
	g_bLogging = !g_bLogging;
	ReplyToCommand(client, "Logging %s.", g_bLogging ? "ENABLED" : "DISABLED");
	return Plugin_Handled;
}

Action Command_ToggleButtonLogging(int client, int args)
{
	g_bLogButtons[client] = !g_bLogButtons[client];
	ReplyToCommand(client, "Button logging is %s.", g_bLogButtons[client] ? "ENABLED" : "DISABLED");
	return Plugin_Handled;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_cl_logger_toggle", Command_ToggleLogging, ADMFLAG_CONFIG, "Toggles client command logging.");
	RegAdminCmd("sm_cl_logger_buttons", Command_ToggleButtonLogging, ADMFLAG_CONFIG, "Toggles client comamnd buttons logging.");

	BuildLogFilePath();
	g_bLogging = true;
}

public void OnMapStart()
{
	BuildLogFilePath();
}

public Action OnClientCommand(int client, int args)
{
	if (!g_bLogging)
	{
		return Plugin_Continue;
	}

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

public void OnClientCommandKeyValues_Post(int client, KeyValues kv)
{
	if (!g_bLogging)
	{
		return;
	}

	char name[256];
	kv.GetSectionName(name, sizeof(name));

	PrintToServer("%N sent KeyValue Command: %s", client, name);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!g_bLogging)
	{
		return;
	}

	if (impulse > 0)
	{
		LogToFile(g_logFile, "%L sent impulse %i", client, impulse);
	}

	if (g_bLogButtons[client] && buttons != 0)
	{
		LogClientButtons(client, buttons);
	}
}

void LogClientButtons(int client, int buttons)
{
	char buffer[32];
	char text[512];
	text[0] = '\0';

	for (int i = 0; i < sizeof(s_bitsArray); i++)
	{
		if ((buttons & s_bitsArray[i]) != 0)
		{
			FormatEx(buffer, sizeof(buffer), "%i|", s_bitsArray[i]);
			StrCat(text, sizeof(text), buffer);
		}
	}

	LogToFile(g_logFile, "%L sent buttons: %s", client, text);
}