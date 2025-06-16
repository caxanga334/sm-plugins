#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

float vec3_origin[3];
float g_jointime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Player Spawn Position Logger",
	author = "caxanga334",
	description = "Logs the position of when players spawns.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

public void OnPluginStart()
{
	vec3_origin[0] = 0.0;
	vec3_origin[1] = 0.0;
	vec3_origin[2] = 0.0;
}

public void OnClientPutInServer(int client)
{
	g_jointime[client] = GetGameTime();

	SDKHook(client, SDKHook_SpawnPost, OnPlayerSpawnPost);
}

void OnPlayerSpawnPost(int entity)
{
	CreateTimer(0.3, Timer_OnPlayerSpawned, view_as<any>(GetClientSerial(entity)), TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_OnPlayerSpawned(Handle timer, any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (client != 0)
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);

		float range = GetVectorDistance(origin, vec3_origin, false);
		float now = GetGameTime();
		float time = now - g_jointime[client];

		if (range <= 64.0)
		{
			LogError("%3.4f: Client %L spawned at <%3.4f %3.4f %3.4f> within %3.4f range of the map origin! Time since join %3.4f", 
			now, client, origin[0], origin[1], origin[2], range, time);
		}
	}
}