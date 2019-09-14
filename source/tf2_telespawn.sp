#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <caxanga334>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===
bool g_bTeleEnabled[MAXPLAYERS+1];
bool g_bSpawnOnTele[MAXPLAYERS+1];

ArrayList adt_telered;
ArrayList adt_teleblu;

ConVar cv_spawnuber;

public Plugin myinfo = {
	name = "[TF2] Spawn on Teleporter",
	author = "caxanga334",
	description = "Allows players to spawn on teleporter like MvM robots.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion = GetEngineVersion();
	if( EngineVersion != Engine_TF2 )
	{
		LogError("This plugin is for Team Fortress 2 only.");
		return APLRes_Failure;
	}
	else
		return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("tf2_telespawn.phrases");
	
	cv_spawnuber = CreateConVar( "sm_telespawn_uber", "5.0", "How many seconds of ubercharge to apply when players spawn on a teleporter. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 30.0);
	
	adt_teleblu = new ArrayList(1);
	adt_telered = new ArrayList(1);

	RegConsoleCmd( "sm_spawntele", Cmd_SpawnTele, "Enable/Disable spawn teleporter" );
	RegConsoleCmd( "sm_spawnmode", Cmd_SpawnMode, "Toggles spawn mode between spawn point and teleporter" );
	
	AddCommandListener( Listener_Build, "build" );
	
	HookEvent( "player_spawn", E_PlayerSpawn );
	HookEvent( "player_builtobject", E_BuildObject, EventHookMode_Pre );
	
	AutoExecConfig(true, "plugin.telespawn");
}

public void OnMapStart()
{
	PrecacheSound(")mvm/mvm_tele_deliver.wav");
	adt_teleblu.Clear();
	adt_telered.Clear();
}

public void OnClientPutInServer(int client)
{
	ResetClientData(client);
}

public void OnClientDisconnect(int client)
{
	ResetClientData(client);
}

/****************************************************
					COMMANDS
*****************************************************/
public Action Cmd_SpawnTele( int client, int nArgs )
{
	if( !IsValidClient(client) )
		return Plugin_Handled;
		
	if( TF2_GetPlayerClass(client) == TFClass_Engineer )
	{
		if( !g_bTeleEnabled[client] )
		{
			g_bTeleEnabled[client] = true;
			ReplyToCommand(client, "%t", "Tele Enabled");
		}
		else
		{
			g_bTeleEnabled[client] = false;
			ReplyToCommand(client, "%t", "Tele Disabled");			
		}
	}
	
	return Plugin_Handled;
}

public Action Cmd_SpawnMode( int client, int nArgs )
{
	if( !IsValidClient(client) )
		return Plugin_Handled;
		
	if( !g_bSpawnOnTele[client] )
	{
		g_bSpawnOnTele[client] = true;
		ReplyToCommand(client, "%t", "Spawn Tele");
	}
	else
	{
		g_bSpawnOnTele[client] = false;
		ReplyToCommand(client, "%t", "Spawn Normal");
	}
	
	return Plugin_Handled;
}

/****************************************************
					LISTENER
*****************************************************/

public Action Listener_Build(int client, const char[] command, int argc)
{
	if( !g_bTeleEnabled[client] )
		return Plugin_Continue;
		
	if( IsFakeClient(client) )
		return Plugin_Continue;
	
	char strArg1[8], strArg2[8];
	GetCmdArg(1, strArg1, sizeof(strArg1));
	GetCmdArg(2, strArg2, sizeof(strArg2));
	
	TFObjectType objType = view_as<TFObjectType>(StringToInt(strArg1));
	TFObjectMode objMode = view_as<TFObjectMode>(StringToInt(strArg2));
	
	if( g_bTeleEnabled[client] )
	{
		if( objType == TFObject_Teleporter && objMode == TFObjectMode_Entrance )
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/****************************************************
					EVENTS
*****************************************************/

public Action E_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
}

public Action E_BuildObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int index = event.GetInt("index");
	if( !IsFakeClient(client) && g_bTeleEnabled[client] )
	{
		CreateTimer(0.1, Timer_BuildObject, index);
		
	}
}

/****************************************************
					TIMERS
*****************************************************/

public Action Timer_BuildObject(Handle timer, any index)
{
	char classname[32];
	
	if( IsValidEdict(index) )
	{
		GetEdictClassname(index, classname, sizeof(classname))
		
		else if( strcmp(classname, "obj_teleporter", false) == 0 )
		{
			int iBuilder = GetEntPropEnt( index, Prop_Send, "m_hBuilder" );
			if( TF2_GetObjectMode(index) == TFObjectMode_Entrance && g_bTeleEnabled[iBuilder] )
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
			else
			{
				DispatchKeyValue(index, "defaultupgrade", "2");
				SetEntProp(index, Prop_Data, "m_iMaxHealth", 300);
				SetVariantInt(300);
				AcceptEntityInput(index, "SetHealth");
				CreateTimer(0.1, Timer_OnTeleporterFinished, index, TIMER_REPEAT);
			}
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_OnTeleporterFinished(Handle timer, any index)
{
	if( !IsValidEntity(index) )
		return Plugin_Stop;
		
	float flProgress = GetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed");
	
	if( flProgress >= 1.0 )
	{
		SetEntProp(index, Prop_Data, "m_iMaxHealth", 300);
		SetVariantInt(300);
		AcceptEntityInput(index, "SetHealth");
		HookSingleEntityOutput(index, "OnDestroyed", OnDestroyedTeleporter, true);
		
		if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
			adt_teleblu.Push(EntIndexToEntRef(index))
		else if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Red) )
			adt_telered.Push(EntIndexToEntRef(index))
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/****************************************************
					FUNCTIONS
*****************************************************/
/* bool IsMvM()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
} */

void ResetClientData(int client)
{
	g_bTeleEnabled[client] = false;
	g_bSpawnOnTele[client] = false;
}

void OnDestroyedTeleporter(const char[] output, int caller, int activator, float delay)
{
	int ref = EntIndexToEntRef(caller);
	int index;
	
	index = adt_telered.FindValue(ref);
	if( index == -1 )
		index = adt_teleblu.FindValue(ref);
	else
		adt_telered.Erase(index)
		
	if( index == -1 )
		LogError("OnDestroyed called but teleporter was not found inside arrays");
	else
		adt_teleblu.Erase(index)
}