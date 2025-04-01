#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "GetRandomFloat Test Plugin",
	author = "caxanga334",
	description = "Tests GetRandomFloat",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

public void OnMapStart()
{
	CreateTimer(0.1, Timer_PrintFloats, view_as<any>(0));
}

Action Timer_PrintFloats(Handle timer, any data)
{
	int iter = view_as<int>(data);

	if (iter == 1000)
	{
		return Plugin_Stop;
	}

	iter++;
	CreateTimer(0.1, Timer_PrintFloats, view_as<any>(iter));

	for(int i = 0; i < 10; i++)
	{
		LogMessage("GetRandomFloat(0.0, 1.0) = %3.8f", GetRandomFloat(0.0, 1.0));
	}

	return Plugin_Stop;
}