#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "[TF2C] Time Limit Enforcer",
	author = "caxanga334",
	description = "Enforces mp_timelimit on the server.",
	version = "1.0.0",
	url = "github.com/caxanga334"
};


public void OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, Timer_CallDoLogic, .flags = TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
	CreateTimer(15.0, Timer_CallDoLogic, .flags = TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_CallDoLogic(Handle timer)
{
	DoLogic();
}

void DoLogic()
{
	int ent = FindEntityByClassname(INVALID_ENT_REFERENCE, "tf_gamerules");

	if (ent != INVALID_ENT_REFERENCE)
	{
		// this makes the game to end mid round on the time limit
		SetVariantBool(true);
		AcceptEntityInput(ent, "SetStalemateOnTimelimit", 0, 0);
	}

	// Prevent the time limit from changing
	GameRules_SetPropFloat("m_flMapResetTime", 0.0);
}