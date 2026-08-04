#include <sourcemod>
#include <version_auto>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Bot Physics Fix",
	author = "caxanga334",
	description = "Fixes bot physics bounding box going out of sync.",
	version = "1.1.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

Handle g_updatevphysicscall = null;
int g_m_pPhysicsController_offset;
Address g_pPhysicsController;
bool g_PhysicsControllerOffsetSet;

public void OnPluginStart()
{
	GameData gd = new GameData("bot_physics_fix.games");

	if (gd == null)
	{
		SetFailState("Failed to load gamedata/bot_physics_fix.games.txt gamedata file!");
		return;
	}

	int offset = gd.GetOffset("CBasePlayer::m_pPhysicsController");
	g_m_pPhysicsController_offset = 0;
	g_PhysicsControllerOffsetSet = false;

	// hopefully the relative offset never becomes -1
	if (offset != -1)
	{
		g_m_pPhysicsController_offset = offset;
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

void SetupPhysicsControllerOffset(int client)
{
	if (g_PhysicsControllerOffsetSet) { return; }

	int offset = g_m_pPhysicsController_offset;
	int offset_oldorigin = FindDataMapInfo(client, "m_oldOrigin");

	if (offset_oldorigin < 0)
	{
		SetFailState("Could not obtain offset of CBasePlayer::m_oldOrigin via datamap!");
		return;
	}

	int actual_offset = offset_oldorigin + offset;
	LogMessage("Computed offset for CBasePlayer::m_pPhysicsController is %i", actual_offset);
#if SOURCEMOD_V_MINOR >= 13
	g_pPhysicsController = actual_offset;
#else
	g_pPhysicsController = view_as<Address>(actual_offset);
#endif
	g_PhysicsControllerOffsetSet = true;
}

void Frame_Test(any data)
{
	HasPhysicsController(view_as<int>(data));
}

public void OnClientPutInServer(int client)
{
	SetupPhysicsControllerOffset(client);

	if (IsFakeClient(client))
	{
		HasPhysicsController(client);
		RequestFrame(Frame_Test, view_as<any>(client));

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

bool HasPhysicsController(int client)
{
	if (!g_PhysicsControllerOffsetSet)
	{
		// will probably crash
		return true;
	}

#if SOURCEMOD_V_MINOR >= 13
	Address pEntity = GetEntityAddress(client);
	Address pPhysicsController = LoadAddressFromAddress(pEntity + g_pPhysicsController);
	// PrintToServer("%L -- pPhysicsController == %lX", client, pPhysicsController);

	return pPhysicsController != Address_Null;
#else
	// SM 1.12
	// BUGBUG!! This won't work on x64!
	int ptr = GetEntData(client, view_as<int>(g_pPhysicsController), 4);
	return ptr != 0;
#endif
}

void BotPostThink(int client)
{
	// Ignore dead bots
	if (!IsPlayerAlive(client))
	{
		return;
	}

	if (!HasPhysicsController(client))
	{
		return;
	}

	float pos[3];
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vNewVPhysicsPosition", pos);
	GetEntPropVector(client, Prop_Data, "m_vNewVPhysicsVelocity", vel);
	float time = GetGameTime();
	time += GetTickInterval();
	SDKCall(g_updatevphysicscall, client, pos, vel, time);
}