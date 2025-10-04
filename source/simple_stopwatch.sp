#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Simple Stopwatch",
	author = "caxanga334",
	description = "A simple stopwatch using in-game time.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

float g_time[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_stopwatch", Command_StopWatch, 0, "Starts/Stops the stop watch.");
}

public void OnClientDisconnect(int client)
{
	g_time[client] = -1.0;
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_time); i++)
	{
		g_time[i] = -1.0;
	}
}

Action Command_StopWatch(int client, int args)
{
	if (g_time[client] > 0.0)
	{
		float time = GetGameTime() - g_time[client];
		g_time[client] = -1.0;
		ReplyToCommand(client, "Time elapsed: %f\n", time);
		return Plugin_Handled;
	}

	// start the timer, set the start timestamp
	g_time[client] = GetGameTime();
	ReplyToCommand(client, "Timer started!\n");

	return Plugin_Handled;
}