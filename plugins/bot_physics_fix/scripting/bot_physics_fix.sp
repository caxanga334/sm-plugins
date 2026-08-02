#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Bot Physics Fix",
	author = "caxanga334",
	description = "Fixes bot physics bounding box going out of sync.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

Handle g_updatevphysicscall = null;

public void OnPluginStart()
{
	GameData gd = new GameData("bot_physics_fix.games");

	if (gd == null)
	{
		SetFailState("Failed to load gamedata/bot_physics_fix.games.txt gamedata file!");
		return;
	}

	// void CBasePlayer::UpdateVPhysicsPosition( const Vector &position, const Vector &velocity, float secondsToArrival )
	StartPrepSDKCall(SDKCall_Entity);
	
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CBasePlayer::UpdateVPhysicsPosition"))
	{
		SetFailState("Failed to setup CBasePlayer::UpdateVPhysicsPosition SDKCall.");
	}

	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	g_updatevphysicscall = EndPrepSDKCall();

	if (g_updatevphysicscall == null)
	{
		SetFailState("CBasePlayer::UpdateVPhysicsPosition SDKCall setup failed!");
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		// This sdkcall requires a valid physics object and OnClientPutInServer is too early, wait a bit before hooking.
		CreateTimer(5.0, Timer_HookBot, view_as<any>(GetClientSerial(client)), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Timer_HookBot(Handle timer, any data)
{
	int bot = GetClientFromSerial(view_as<int>(data));

	if (bot != 0)
	{
		// PhysicsSimulate would be the correct function that requires gamedata and dhooks.
		SDKHook(bot, SDKHook_PostThink, BotPostThink);
	}
}

void BotPostThink(int client)
{
	float pos[3];
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vNewVPhysicsPosition", pos);
	GetEntPropVector(client, Prop_Data, "m_vNewVPhysicsVelocity", vel);
	float time = GetGameTime();
	time += GetTickInterval();
	SDKCall(g_updatevphysicscall, client, pos, vel, time);
}