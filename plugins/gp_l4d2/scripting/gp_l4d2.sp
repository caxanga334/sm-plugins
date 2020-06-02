#include <sourcemod>

#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

// ===variables===

int g_iTotalFFDamage[MAXPLAYERS + 1]; // total friendly fire damage

float g_flLastFFTime[MAXPLAYERS + 1]; // last time this player did FF damage

ConVar cv_DmgThreshold;
ConVar cv_DmgInterval;

public Plugin myinfo = {
	name = "[L4D2] Gamers ala Pro",
	author = "caxanga334",
	description = "Gamers ala Pro L4D2 Plugin.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

public void OnPluginStart()
{
	cv_DmgThreshold = CreateConVar("sm_ff_dmg_threshould", "30", "How much cumulative friendly fire damage a player must deal in order to trigger an alert.", FCVAR_NONE, true, 15.0, false);
	cv_DmgInterval = CreateConVar("sm_ff_reset_time", "30", "If a player does not cause any friendly fire damage in this time, reset the player's total damage.", FCVAR_NONE, true, 5.0, true, 300.0);
	AutoExecConfig(true, "plugin.gp_l4d2");

	HookEvent("player_hurt_concise", Event_PlayerHurtConcise, EventHookMode_Post);
}

public void OnMapStart()
{
	for(int p = 1; p <= MaxClients; p++)
	{
		g_iTotalFFDamage[p] = 0;
		g_flLastFFTime[p] = 0.0;
	}
}

public Action Event_PlayerHurtConcise(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = event.GetInt("attackerentid");
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iDamage = event.GetInt("dmg_health");
	
	if( !IsValidClient(iAttacker) || !IsValidClient(iVictim) )
	{
		return Plugin_Continue;
	}
	
	if( IsFakeClient(iAttacker) ) // ignore friendly fire from bots
	{
		return Plugin_Continue;
	}
	
	if( GetClientTeam(iAttacker) != GetClientTeam(iVictim) )
	{
		return Plugin_Continue;
	}
	
	if(g_flLastFFTime[iAttacker] > GetEngineTime())
	{
		g_iTotalFFDamage[iAttacker] += iDamage;
	}
	else
	{
		
		g_iTotalFFDamage[iAttacker] = iDamage;
	}
	
	g_flLastFFTime[iAttacker] = GetEngineTime() + cv_DmgInterval.FloatValue;
	if(g_iTotalFFDamage[iAttacker] >= cv_DmgThreshold.IntValue)
	{
		AnnounceFFToAdmins(iAttacker);
	}
	
	return Plugin_Continue;
}

void AnnounceFFToAdmins(int client)
{
	static float flLastAnnouncement[MAXPLAYERS + 1] = 0.0;
	char auth[64];
	GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
	
	if(flLastAnnouncement[client] < GetEngineTime())
	{
		for(int p = 1; p <= MaxClients; p++)
		{
			if(IsValidClient(p))
			{
				if(CheckCommandAccess(p, "gp_l4d2_admin", ADMFLAG_KICK, true))
				{
					PrintToChat(p, "[SM] Warning: Excessive friendly fire caused by \"%N\" < %s > (Damage: %i)", client, auth, g_iTotalFFDamage[client]);
				}
			}
		}
		LogMessage("Excessive friendly fire caused by \"%L\"", client);
		flLastAnnouncement[client] = GetEngineTime() + 5.0;
	}
}

bool IsValidClient(int client)
{
	if(client == 0 || client > MaxClients) { return false; }
	if(!IsClientConnected(client)) { return false; }
	return IsClientInGame(client);
}