#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <caxanga334>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "Gamers ala Pro Respawn",
	author = "caxanga334",
	description = "Gamers ala Pro Instant Respawn Plugin",
	version = "1.0.0",
	url = "https://www.gamersalapro.com"
}

public void OnPluginStart() {
	LoadTranslations("common.phrases.txt");
	
	HookEvent( "player_death", E_PlayerDeath );
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if( IsValidClient(client) && (TF2_GetClientTeam(client) == TFTeam_Red || TF2_GetClientTeam(client) == TFTeam_Blue) )
	{
		if( !IsPlayerAlive(client) )
		{
			if( buttons & IN_ATTACK )
			{
				int iObserverTarget = GetEntProp(client, Prop_Send, "m_hObserverTarget");
				if( IsValidClient(iObserverTarget) && (TF2_GetClientTeam(client) == TF2_GetClientTeam(iObserverTarget)) && IsPlayerAlive(iObserverTarget) )
				{
					DataPack DP_RespawnTimer;
					DP_RespawnTimer.WriteCell(client);
					DP_RespawnTimer.WriteCell(iObserverTarget);
					CreateDataTimer(0.25, Timer_TeleToObserver, DP_RespawnTimer);
					TF2_RespawnPlayer(client);
				}
			}
			if( buttons & IN_RELOAD )
			{
				TF2_RespawnPlayer(client);
			}
		}
	}


	return Plugin_Continue;
}

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int deathflags = event.GetInt("death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;

	PrintCenterText(client, "PRESS [MOUSE1] TO RESPAWN AT SPECTATING TARGET. PRESS [RELOAD] TO RESPAWN.");
	
	return Plugin_Continue;
}

public Action Timer_TeleToObserver(Handle timer, DataPack DP_RespawnTimer)
{
	int client = DP_RespawnTimer.ReadCell();
	int target = DP_RespawnTimer.ReadCell();
	float OriginVec[3], AnglesVec[3];
	
	if( IsValidClient(client) && IsValidClient(target) )
	{
		if( IsPlayerAlive(client) && IsPlayerAlive(target) )
		{
			GetClientAbsOrigin(target, OriginVec);
			GetClientAbsAngles(target, AnglesVec);
			TeleportEntity(client, OriginVec, AnglesVec, NULL_VECTOR);
		}
	}
	
	return Plugin_Stop;
}