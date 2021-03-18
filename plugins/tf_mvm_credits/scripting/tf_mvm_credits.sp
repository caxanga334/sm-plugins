#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <multicolors>

#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

// variables
char g_strMissionName[64]; // The current mission name
int g_iNumWaveFails; // How many waves RED failed
int g_iCurrentWave;
UserMsg g_uRefund;
float g_flAnnounceTimer;

// ConVars
ConVar cv_BaseCredits = null;
ConVar cv_BaseCreditsW666 = null;
ConVar cv_CreditsPerBLUPlayer = null;
ConVar cv_CreditsPerREDPlayer = null;
ConVar cv_CreditsPerWaveLost = null;
ConVar cv_CreditsBonusPerWaveWon = null;
ConVar cv_MaxRequest = null;
ConVar cv_MaxRedPlayers = null;

enum MvMStatsType
{
	MvMStats_CurrentWave = 0,
	MvMStats_PreviousWave,
	MvMStats_RunningTotal,
};

enum
{
	MvMCredits_Dropped = 0,
	MvMCredits_Acquired,
	MvMCredits_Bonus,
};

enum struct eCreditsStruct
{
	int iRequests; // How many credit requests a player made
	int Bonus; // How many bonus credits a player have;
}
eCreditsStruct g_nCredits[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "[TF2] MvM Credits System",
	author = "caxanga334",
	description = "Allows players to get more credits based on conditions.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
}

stock APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	
	if( ev == Engine_TF2 )
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "This plugin is for Team Fortress 2 only.");
		return APLRes_Failure;
	}
}

public void OnPluginStart()
{
	CreateConVar("sm_mvmcredits_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_BaseCredits = CreateConVar("sm_mvmcredits_base", "400", "Base amount of credits to give to players.", FCVAR_NONE, true, 0.0, true, 10000.0);
	cv_BaseCreditsW666 = CreateConVar("sm_mvmcredits_base_wave666", "1000", "Base amount of credits to give to players on wave 666.", FCVAR_NONE, true, 0.0, true, 10000.0);
	cv_CreditsPerBLUPlayer = CreateConVar("sm_mvmcredits_bluplayers", "150", "How many credits are given for each player on BLU team.", FCVAR_NONE, true, 0.0, true, 5000.0);
	cv_CreditsPerREDPlayer = CreateConVar("sm_mvmcredits_redplayers", "200", "How many credits are given for each missing RED player.", FCVAR_NONE, true, 0.0, true, 5000.0);
	cv_CreditsPerWaveLost = CreateConVar("sm_mvmcredits_wavelost", "500", "How many credits are given for each wave lost.", FCVAR_NONE, true, 0.0, true, 5000.0);
	cv_MaxRequest = CreateConVar("sm_mvmcredits_maxrequests", "1", "How many credits requests a single player can make.", FCVAR_NONE, true, 0.0, false);
	cv_MaxRedPlayers = CreateConVar("sm_mvmcredits_maxredplayers", "6", "If the number of RED players is equal or greater than the value set here, deny credit requests.", FCVAR_NONE, true, 0.0, true, 10.0);
	cv_CreditsBonusPerWaveWon = CreateConVar("sm_mvmcredits_wavewon_bonus", "100", "How many credits a player receives per wave won", FCVAR_NONE, true, 0.0, true, 10000.0);
	AutoExecConfig(true, "plugin.mvmcredits");

	RegConsoleCmd("sm_requestcredits", command_requestcredits, "Request MvM Currency");
	RegConsoleCmd("sm_rcredits", command_requestcredits, "Request MvM Currency");
	RegConsoleCmd("sm_requestcredit", command_requestcredits, "Request MvM Currency");
	RegConsoleCmd("sm_rcredit", command_requestcredits, "Request MvM Currency");
	RegConsoleCmd("sm_credits", command_requestcredits, "Request MvM Currency");
	RegConsoleCmd("sm_credit", command_requestcredits, "Request MvM Currency");
	
	HookEvent( "mvm_begin_wave", EventWaveStart );
	HookEvent( "mvm_wave_complete", EventWaveEnd );
	HookEvent( "mvm_wave_failed", EventWaveFailed );
	
	g_uRefund = GetUserMessageId("MVMResetPlayerUpgradeSpending");
	if(g_uRefund == INVALID_MESSAGE_ID) { LogError("Failed to hook MVMResetPlayerUpgradeSpending user message."); }
	HookUserMessage(g_uRefund, Msg_Refund);
}

public void OnMapStart()
{
	if(!IsMvM(true))
		SetFailState("This plugin is for Mann vs Machine only.");
		
	g_iNumWaveFails = 0;
	g_iCurrentWave = 0;
	g_flAnnounceTimer = GetGameTime();
}

public void TF2_OnWaitingForPlayersStart()
{
	char mname[64];
	TF2_GetMvMMissionName(mname, sizeof(mname));
	
	// check if the mission was changed
	if(strcmp(mname, g_strMissionName, false) != 0)
	{
		OnMissionChanged(mname);
	}
	
	// if the last stored wave is not 1 and the current wave is 1, reset wave fails
	if(g_iCurrentWave > 1 && TF2_GetCurrentMvMWave() == 1)
	{
		g_iNumWaveFails = 0;
	}
}

public void OnClientPutInServer(int client)
{
	g_nCredits[client].iRequests = 0;
	g_nCredits[client].Bonus = 0;
}

public Action command_requestcredits(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	if(TF2_GetClientTeam(client) != TFTeam_Red)
		return Plugin_Handled;
	
	if(!CanRequestCredits(client) && !IsBonusAvailable(client))
	{
		ReplyToCommand(client, "You cannot request more credits.");
		return Plugin_Handled;
	}
	
	int redplayers = GetTeamHumanClientCount(view_as<int>(TFTeam_Red));
	if(redplayers >= cv_MaxRedPlayers.IntValue && g_iNumWaveFails == 0)
	{
		ReplyToCommand(client, "There are enough players in RED team to complete this wave without extra credits.");
		return Plugin_Handled;
	}
	
	int credits;
	if(CanRequestCredits(client)) { // Normal requests are unavailable, give bonus
		credits = ComputeCredits(client);
	}
	else {
		credits = GetClientBonusCredits(client);
	}
	
	TF2_SetClientCredits(client, TF2_GetClientCredits(client) + credits);
	ReplyToCommand(client, "You received %i credits.", credits);
	LogAction(client, client, "Player \"%L\" received %i credits.", client, credits);
	if(CanRequestCredits(client)) { // Normal Request
		g_nCredits[client].iRequests += 1;
	}
	else { // Bonus request
		SetClientBonusCredits(client, 0);
	}
	
	return Plugin_Handled;
}

public Action Msg_Refund(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = BfReadByte(msg); //client that used the respec
	RequestFrame(FrameOnClientRefund, client);
}

void FrameOnClientRefund(int client)
{
	g_nCredits[client].iRequests = 0; // Reset number of requests when a clients refund upgrades
}

void OnMissionChanged(char[] newmission)
{
	strcopy(g_strMissionName, sizeof(g_strMissionName), newmission);
	CreateTimer(0.25, Timer_MissionChanged);
	ResetRequestCountAll();
	LogMessage("[TF2-MvM] Mission changed to \"%s\"", newmission);
}

int ComputeCredits(int client)
{
	int credits;
	
	if(TF2_IsWave666())
	{
		credits = cv_BaseCreditsW666.IntValue;
	}
	else
	{
		credits = cv_BaseCredits.IntValue;
	}
	
	// step 1, compute credits from missing players
	int iRedCreds = cv_CreditsPerREDPlayer.IntValue;
	if(iRedCreds > 0)
	{
		int x = 6 - GetTeamHumanClientCount(view_as<int>(TFTeam_Red));
		if(x > 0)
		{
			credits += iRedCreds * x;
		}
	}
	
	// step 2, compute credits based on BLU player count
	int iBluPlayers = GetTeamHumanClientCount(view_as<int>(TFTeam_Blue));
	if(iBluPlayers > 0)
	{
		credits += cv_CreditsPerBLUPlayer.IntValue * iBluPlayers;
	}
	
	// step 3, compute credits based on number of wave losts.
	if(g_iNumWaveFails > 0)
	{
		credits += cv_CreditsPerWaveLost.IntValue * g_iNumWaveFails;
	}
	
	// step 4, check if we are giving bonus
	if(IsBonusAvailable(client))
	{
		credits += GetClientBonusCredits(client);
	}
	
	return credits;
}

int GetClientBonusCredits(int client)
{
	return g_nCredits[client].Bonus;
}

int SetClientBonusCredits(int client, int value = 0)
{
	g_nCredits[client].Bonus = value;
}

bool CanRequestCredits(int client)
{
	return g_nCredits[client].iRequests < cv_MaxRequest.IntValue;
}

bool IsBonusAvailable(int client)
{
	return g_nCredits[client].Bonus > 0;
}

// ==== EVENTS ====

// Wave started
public Action EventWaveStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iCurrentWave = TF2_GetCurrentMvMWave();
}

// Wave ended ( victory )
public Action EventWaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iNumWaveFails--;
	if(g_iNumWaveFails < 0)
		g_iNumWaveFails = 0;
	
	AddBonusToAll(cv_CreditsBonusPerWaveWon.IntValue);
}

// Wave lost
public Action EventWaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	g_iNumWaveFails++;
	ResetRequestCountAll();
	ResetBonusToAll();
	CreateTimer(2.5, Timer_CheckCredits);
	CreateTimer(5.0, Timer_AnnounceFeature);
}

// ==== TIMERS ====
public Action Timer_CheckCredits(Handle timer)
{
	if(TF2_GetCurrentMvMWave() > 1)
	{
		int credits = TF2_GetMvMCreditsCollected(MvMStats_PreviousWave);
		credits += TF2_GetMvMCreditsCollected(MvMStats_PreviousWave, MvMCredits_Bonus);
		for(int i = 1;i <= MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Red)
			{
				if(credits > 0 && TF2_GetClientCredits(i) < credits)
				{
					TF2_SetClientCredits(i, credits);
					LogMessage("[TF2-MvM] Fixed credits for client \"%L\" (%i)", i, credits);
				}
			}
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_MissionChanged(Handle timer)
{
	g_iNumWaveFails = 0;
	return Plugin_Stop;
}

// Announces the plugin command
public Action Timer_AnnounceFeature(Handle timer)
{
	if(g_flAnnounceTimer < GetGameTime()) {
		CPrintToChatAll("{cyan}Type {green}/rcredits{cyan} to receive credits.");
		g_flAnnounceTimer = GetGameTime() + 10.0;
	}
	
	return Plugin_Stop;
}
 
// Reset requests for all clients
void ResetRequestCountAll()
{
	for(int i = 1;i <= MaxClients;i++)
	{
		g_nCredits[i].iRequests = 0;
	}
}

void AddBonusToAll(int amount)
{
	for(int i = 1;i <= MaxClients;i++)
	{
		g_nCredits[i].Bonus += amount;
	}
}

void ResetBonusToAll()
{
	for(int i = 1;i <= MaxClients;i++)
	{
		g_nCredits[i].Bonus = 0;
	}
}

stock void TF2_SetClientCredits(int client, int amount = 0)
{
	if(amount < 0) { amount = 0; }
	
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_nCurrency", amount);
	}
}

stock int TF2_GetClientCredits(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return GetEntProp(client, Prop_Send, "m_nCurrency");
	}
	
	return 0;
}

stock int TF2_GetCurrentMvMWave()
{
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		return GetEntProp( iResource, Prop_Send, "m_nMannVsMachineWaveCount" );
	}
	
	return -1;
}

stock int TF2_GetMaxMvMWave()
{
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		return GetEntProp( iResource, Prop_Send, "m_nMannVsMachineMaxWaveCount" );
	}
	
	return -1;
}

stock bool TF2_IsWave666()
{
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		if(GetEntProp( iResource, Prop_Send, "m_nMvMEventPopfileType" ) == 1)
			return true;
	}
	
	return false;	
}

stock void TF2_GetMvMMissionName(char[] name, int size)
{
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		GetEntPropString( iResource, Prop_Send, "m_iszMvMPopfileName", name, size );
		ReplaceString(name, size, "scripts/population/", "");
		ReplaceString(name, size, ".pop", "");
		return;
	}
	
	strcopy(name, size, "");
	return;
}

stock int GetTeamHumanClientCount(int team)
{
	int counter = 0;
	for(int i = 1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			counter++;
		}
	}
	
	return counter;
}

stock int TF2_GetMvMCreditsCollected(MvMStatsType statstype, int creditstype = MvMCredits_Acquired)
{
	int ent = FindEntityByClassname(-1, "tf_mann_vs_machine_stats");
	if(!IsValidEntity(ent))
		return -1;

	switch(statstype)
	{
		case MvMStats_CurrentWave:
		{
			return GetEntProp(ent, Prop_Send, "m_currentWaveStats", _, creditstype);
		}
		case MvMStats_PreviousWave:
		{
			return GetEntProp(ent, Prop_Send, "m_previousWaveStats", _, creditstype);
		}
		case MvMStats_RunningTotal:
		{
			return GetEntProp(ent, Prop_Send, "m_runningTotalWaveStats", _, creditstype);
		}
		default:
		{
			return -1;
		}
	}
}

// IsMvM code by FlaminSarge
stock bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}