#include <sourcemod>

#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

#define L4D_TEAM_SURVIVOR 2

// ===variables===
char g_sLogPath[PLATFORM_MAX_PATH];

int g_iTotalFFDamage[MAXPLAYERS + 1]; // total friendly fire damage
int g_iStatFFDmg[MAXPLAYERS + 1]; // total friendly fire damage for stats command
int g_iDoorUses[MAXPLAYERS + 1]; // total amount of door uses

float g_flLastFFTime[MAXPLAYERS + 1]; // last time this player did FF damage
float g_flLastDoorUseTime[MAXPLAYERS + 1]; // last time this player used a door
float flPainPillsDecay = 0.27;

Handle g_hFFTimer[MAXPLAYERS + 1]; // Delay announcement messages to accumulate damage from weapons like shotguns

ConVar cv_DmgThreshold;
ConVar cv_DmgInterval;
ConVar cv_SelfHealThreshold;
ConVar cv_MinSurvHealth;
ConVar cv_DoorSpamThreshold;
ConVar cv_DoorSpamResetDelay;
ConVar cvarPainPillsDecay;

enum
{
	Announcement_FriendlyFire = 0,
	Announcement_SelfHealGrief = 1,
	Announcement_DoorSpammer = 2,
};

public Plugin myinfo = {
	name = "[L4D2] Gamers ala Pro",
	author = "caxanga334",
	description = "Gamers ala Pro L4D2 Plugin.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

public void OnPluginStart()
{
	CreateLogFile();
	//LoadTranslations("gp_l4d2.phrases");
	
	cv_DmgThreshold = CreateConVar("sm_ff_dmg_threshould", "30", "How much cumulative friendly fire damage a player must deal in order to trigger an alert.", FCVAR_NONE, true, 15.0, false);
	cv_DmgInterval = CreateConVar("sm_ff_reset_time", "15", "If a player does not cause any friendly fire damage in this time, reset the player's total damage.", FCVAR_NONE, true, 5.0, true, 300.0);
	cv_SelfHealThreshold = CreateConVar("sm_self_heal_min_threshold", "30", "If a player self heal amount is less than this value consider griefing", FCVAR_NONE, true, 1.0, true, 99.0);
	cv_MinSurvHealth = CreateConVar("sm_min_survivor_health", "50", "Health amount to consider if a survivor needs healing", FCVAR_NONE, true, 20.0, true, 90.0);
	cv_DoorSpamThreshold = CreateConVar("sm_door_spam_threshold", "10", "If the number if door uses in the time interval is greater then this value consider griefing", FCVAR_NONE, true, 10.0, true, 30.0);
	cv_DoorSpamResetDelay = CreateConVar("sm_door_spam_reset_delay", "6", "If a client does not use a checkpoint door for this many seconds, reset the client use count", FCVAR_NONE, true, 2.0, true, 15.0);
	AutoExecConfig(true, "plugin.gp_l4d2");
	
	if (cvarPainPillsDecay == INVALID_HANDLE)
	{
		cvarPainPillsDecay = FindConVar("pain_pills_decay_rate");
		if (cvarPainPillsDecay != INVALID_HANDLE)
		{
			HookConVarChange(cvarPainPillsDecay, OnPainPillsDecayChanged);
			flPainPillsDecay = cvarPainPillsDecay.FloatValue;
		}
	}
	
	RegConsoleCmd("sm_ffstats", Command_FFStats, "Shows how much friendly fire each player did in the current map");

	HookEvent("player_hurt_concise", Event_PlayerHurtConcise, EventHookMode_Post);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("door_open", Event_DoorUse, EventHookMode_Post);
	HookEvent("door_close", Event_DoorUse, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode_Post);
}

public void OnMapStart()
{
	CreateLogFile();
	for(int p = 1; p <= MaxClients; p++)
	{
		g_iTotalFFDamage[p] = 0;
		g_iStatFFDmg[p] = 0;
		g_iDoorUses[p] = 0;
		g_flLastFFTime[p] = 0.0;
		g_flLastDoorUseTime[p] = 0.0;
	}
}

public void OnClientDisconnect(int client)
{
	g_iTotalFFDamage[client] = 0;
	g_iStatFFDmg[client] = 0;
	g_iDoorUses[client] = 0;
	g_flLastDoorUseTime[client] = 0.0;
	g_flLastFFTime[client] = 0.0;
}

// ==== ConVar Hooks ====
public void OnPainPillsDecayChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	flPainPillsDecay = StringToFloat(newValue);
}

// ==== Commands ====
public Action Command_FFStats(int client, int args)
{
	ReplyToCommand(client, "Friendly Fire Stats: Player - Amount");
	for(int p = 1;p <=MaxClients;p++)
	{
		if(IsValidClient(p) && !IsFakeClient(p))
		{
			ReplyToCommand(client ,"%N - %i", p, g_iStatFFDmg[p]);
		}
	}
	return Plugin_Handled;
}

// ==== Events ====
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
	
	g_iStatFFDmg[iAttacker] += iDamage;
	
	g_flLastFFTime[iAttacker] = GetEngineTime() + cv_DmgInterval.FloatValue;
	if(g_iTotalFFDamage[iAttacker] >= cv_DmgThreshold.IntValue)
	{
		if( g_hFFTimer[iAttacker] == null ) // Timer already exists
		{
			g_hFFTimer[iAttacker] = CreateTimer(1.0, Timer_AnnounceFF, GetClientUserId(iAttacker));
		}
	}
	
	return Plugin_Continue;
}

public Action Event_DoorUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int checkpoint = view_as<int>(event.GetBool("checkpoint"));
	
	if( !IsValidClient(client) )
		return Plugin_Continue;
		
	if( GetClientTeam(client) != L4D_TEAM_SURVIVOR )
		return Plugin_Continue;
		
	if( checkpoint == 0 ) // ignore non checkpoint doors
		return Plugin_Continue;
		
	if(g_flLastDoorUseTime[client] > GetEngineTime())
	{
		g_iDoorUses[client] += 1;
	}
	else
	{
		g_iDoorUses[client] = 1;
	}
	
	g_flLastDoorUseTime[client] = GetEngineTime() + cv_DoorSpamResetDelay.FloatValue;
	
	if(g_iDoorUses[client] > cv_DoorSpamThreshold.IntValue)
	{
		AnnounceToAdmins(client, Announcement_DoorSpammer, g_iDoorUses[client]);
	}
	
	return Plugin_Continue;
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iHealer = GetClientOfUserId(event.GetInt("userid"));
	int iPatient = GetClientOfUserId(event.GetInt("subject"));
	int iHealAmount = event.GetInt("health_restored");
	
	if( !IsValidClient(iHealer) || !IsValidClient(iPatient) )
	{
		return Plugin_Continue;
	}
	
	if( iHealer == iPatient ) // self heal
	{
		if(IsFakeClient(iHealer))
			return Plugin_Continue; // ignore bots
			
		if( iHealAmount < cv_SelfHealThreshold.IntValue )
		{
			if( IsSelfHealGriefing(iHealer) )
			{
				AnnounceToAdmins(iHealer, Announcement_SelfHealGrief, iHealAmount);
			}
		}
		
		LogToFileEx(g_sLogPath, "[HEAL] Player \"%L\" self healed for \"%i\" health", iHealer, iHealAmount);
	}
	else
		LogToFileEx(g_sLogPath, "[HEAL] Player \"%L\" healed \"%L\" for \"%i\" health", iHealer, iPatient, iHealAmount);
	
	return Plugin_Continue;
}

public Action Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	
	if( !IsValidClient(victim) || !IsValidClient(attacker) )
		return Plugin_Continue;
		
	if( GetClientTeam(victim) != GetClientTeam(attacker) )
		return Plugin_Continue;
	
	LogToFileEx(g_sLogPath, "[INFO] Player \"%L\" was incapacitated by \"%L\" with weapon \"%s\"", victim, attacker, weapon);
	
	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int reviver = GetClientOfUserId(event.GetInt("userid"));
	int patient = GetClientOfUserId(event.GetInt("subject"));
	int lastlife = view_as<int>(event.GetBool("lastlife"));
	int ledge = view_as<int>(event.GetBool("ledge_hang"));
	char blackwhite[8], ledgehang[8];
	
	if( !IsValidClient(reviver) || !IsValidClient(patient) )
		return Plugin_Continue;
	
	blackwhite = lastlife == 1 ? "Yes" : "No";
	ledgehang = ledge == 1 ? "Yes" : "No";
	
	LogToFileEx(g_sLogPath, "[INFO] Player \"%L\" was revived by \"%L\" (Black and White: %s | Hanging from a ledge: %s)", patient, reviver, blackwhite, ledgehang);
	
	return Plugin_Continue;
}

// ==== Timers ====
public Action Timer_AnnounceFF(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if( IsValidClient(client) )
		AnnounceToAdmins(client, Announcement_FriendlyFire, 0);
		
	g_hFFTimer[client] = null;
}

// ==== Functions ====

void AnnounceToAdmins(int client, int announcementtype, any data)
{
	static float flLastAnnouncement[MAXPLAYERS + 1] = 0.0;
	char auth[64];
	GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));
	
	switch( announcementtype )
	{
		case Announcement_FriendlyFire:
		{
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
				LogToFileEx(g_sLogPath,"[GRIEFING] Excessive friendly fire caused by \"%L\". Total damage caused so far: \"%i\"", client, g_iTotalFFDamage[client]);
				flLastAnnouncement[client] = GetEngineTime() + 3.0;
			}
		}
		case Announcement_SelfHealGrief:
		{
			if(flLastAnnouncement[client] < GetEngineTime())
			{
				for(int p = 1; p <= MaxClients; p++)
				{
					if(IsValidClient(p))
					{
						if(CheckCommandAccess(p, "gp_l4d2_admin", ADMFLAG_KICK, true))
						{
							PrintToChat(p, "[SM] Warning: Player \"%N\" < %s > (Amount: %i) self healed while other players were in need.", client, auth, data);
						}
					}
				}
				flLastAnnouncement[client] = GetEngineTime() + 1.0;
			}
		}
		case Announcement_DoorSpammer:
		{
			if(flLastAnnouncement[client] < GetEngineTime())
			{
				for(int p = 1; p <= MaxClients; p++)
				{
					if(IsValidClient(p))
					{
						if(CheckCommandAccess(p, "gp_l4d2_admin", ADMFLAG_KICK, true))
						{
							PrintToChat(p, "[SM] Warning: Player \"%N\" < %s > (Amount: %i) is spamming the checkpoint door.", client, auth, data);
						}
					}
				}
				LogToFileEx(g_sLogPath, "[GRIEFING] Player \"%L\" is spamming the checkpoint door. Door uses: %i", client, data);
				flLastAnnouncement[client] = GetEngineTime() + 2.0;
			}
		}
		default:
		{
			LogError("Invalid announcement type (%i)!", announcementtype);
		}
	}
}

// checks if a self heal was an act of griefing
// client -> Player who self healed
bool IsSelfHealGriefing(int client)
{
	int iHealth, iTempHealth;

	for(int p = 1;p <= MaxClients;p++)
	{
		if(IsValidClient(p) && p != client)
		{
			if( GetClientTeam(p) == L4D_TEAM_SURVIVOR ) // Is Survivor
			{
				if( L4D_IsSurvivorGoingToDie(p) ) // Survivor is going to die ( Black and White )
				{
					LogToFileEx(g_sLogPath,"[GRIEFING] Griefing Detected! Player \"%L\" self healed while player \"%L\" was black and white.", client, p);
					return true;
				}
					
				if( L4D_IsSurvivorIncapacitated(p) ) // Survivor is incapacitated
				{
					LogToFileEx(g_sLogPath,"[GRIEFING] Griefing Detected! Player \"%L\" self healed while player \"%L\" was incapacitated.", client, p);
					return true;
				}
			
				iHealth = GetClientHealth(p);
				iTempHealth = L4D_GetPlayerTempHealth(p);
				
				if( iHealth + iTempHealth < cv_MinSurvHealth.IntValue ) // is Survivor health less than minimum health threshold
				{
					LogToFileEx(g_sLogPath,"[GRIEFING] Griefing Detected! Player \"%L\" self healed while player \"%L\" had %i health and %i temp health.", client, p, iHealth, iTempHealth);
					return true;
				}
			}
		}
	}
	
	return false;
}

int L4D_GetPlayerTempHealth(int client)
{
	if (!IsValidClient(client) || GetClientTeam(client) != L4D_TEAM_SURVIVOR || !IsPlayerAlive(client))
	{
		return 0;
	}

	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * flPainPillsDecay)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

bool L4D_IsSurvivorIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

bool L4D_IsSurvivorGoingToDie(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send,"m_isGoingToDie", 1));
}

bool IsValidClient(int client)
{
	if(client == 0 || client > MaxClients) { return false; }
	if(!IsClientConnected(client)) { return false; }
	return IsClientInGame(client);
}

void CreateLogFile() { // creates the log file in the system
	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y%m%d"); // add date to file name
	// Path used for logging.
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/left4dead2_%s.log", cTime);
}