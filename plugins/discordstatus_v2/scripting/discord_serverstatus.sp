#include <sourcemod>
#include <sdktools>
#include <ripext>
#include <steamworks>
#include <discordWebhookAPI>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <left4dhooks>
#tryinclude <sourcetvmanager>
#tryinclude <calladmin>
#tryinclude <steampawn>
#tryinclude <smlib/server>
#tryinclude <sourcebanspp>
#tryinclude <sourcecomms>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.1.9"

bool g_started; // Has the server started?
bool g_hasip;
bool g_hasfullyjoined[MAXPLAYERS + 1];
#if defined _l4dh_included
bool g_hasconfigs; // This is only used in L4D for now
#endif
#if defined _stvmngr_included
bool g_sourcetvmanager = false; // Is the SourceTV manager extension installed?
#endif
#if defined __steampawn_included
bool g_steampawn = false; // Is SteamPawn plugin installed?
#endif
char g_ipaddr[128];
float g_delay;
float g_seed_cooldown;
float g_demorequest_cooldown[MAXPLAYERS + 1];
EngineVersion g_engine;
ConVar c_dns;
ConVar c_delay;
ConVar c_remove1;
ConVar c_remove2;

#define NULL_PLAYER view_as<CPlayer>(0)

methodmap CPlayer
{
	public CPlayer(int index)
	{
		return view_as<CPlayer>(index);
	}

	public static CPlayer GetPlayerByIndex(int index)
	{
		if (index > 0 && index < MaxClients && IsClientInGame(index))
		{
			return CPlayer(index);
		}

		return NULL_PLAYER;
	}

	public bool IsAllowedToRequestDemos()
	{
		return GetGameTime() > g_demorequest_cooldown[this.index];
	}

	public void OnDemoRequested(float cooldown)
	{
		g_demorequest_cooldown[this.index] = GetGameTime() + cooldown;
	}

	public void Reset()
	{
		g_demorequest_cooldown[this.index] = 0.0;
	}

	property int index
	{
		public get() { return view_as<int>(this); }
	}
}

#include "serverstatus/config.sp"
#include "serverstatus/utils.sp"
#include "serverstatus/messages.sp"
#include "serverstatus/left4dead.sp"
#include "serverstatus/teamfortress2.sp"
#include "serverstatus/sourcetv.sp"
#include "serverstatus/calladmin.sp"
#include "serverstatus/sourcebans.sp"

public Plugin myinfo =
{
	name = "[ANY] Discord Server Status",
	author = "caxanga334",
	description = "Sends the server status to discord via a webhook",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_engine = GetEngineVersion();
	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("plugin.serverstatus");

	AutoExecConfig_CreateConVar("sm_serverstatus_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	c_dns = AutoExecConfig_CreateConVar("sm_serverstatus_dns", "", "Send the server IP as a domain name (eg: tf2.example.com) instead", FCVAR_NONE);
	c_delay = AutoExecConfig_CreateConVar("sm_serverstatus_delay", "10.0", "Delay between webhook messages to prevent spam.", FCVAR_NONE, true, 1.0, false);
	c_remove1 = AutoExecConfig_CreateConVar("sm_serverstatus_remove", "", "Remove this part from servername", FCVAR_NONE);
	c_remove2 = AutoExecConfig_CreateConVar("sm_serverstatus_remove2", "", "Remove this part from servername", FCVAR_NONE);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	RegAdminCmd("sm_seed", ConCmd_Seed, 0, "Sends a seed request for this server.");
	RegAdminCmd("sm_demorequest", ConCmd_DemoRequest, 0, "Sends a SourceTV demo request notification.");
	RegAdminCmd("sm_demo", ConCmd_DemoRequest, 0, "Sends a SourceTV demo request notification.");
	RegAdminCmd("sm_dr", ConCmd_DemoRequest, 0, "Sends a SourceTV demo request notification.");

	g_started = false;
#if defined _l4dh_included
	g_hasconfigs = false;
#endif

	if (g_engine == Engine_TF2)
	{
		HookEvent("mvm_begin_wave", EV_TF2_OnMvMWaveStart);
	}

	if (g_engine == Engine_Left4Dead || g_engine == Engine_Left4Dead2)
	{
		AddCommandListener(L4D_OnCallVote, "callvote");
	}

	Config_Load();
}

public void OnAllPluginsLoaded()
{
#if defined _stvmngr_included
	// Note: OnLibraryAdded/Removed is not called for extensions
	g_sourcetvmanager = LibraryExists("sourcetvmanager");
#endif
}

public void OnLibraryAdded(const char[] name)
{
#if defined __steampawn_included
	if (strcmp(name, "steampawn") == 0)
	{
		g_steampawn = true;
	}
#endif
}

public void OnLibraryRemoved(const char[] name)
{
#if defined __steampawn_included
	if (strcmp(name, "steamspawn") == 0)
	{
		g_steampawn = false;
	}
#endif
}

public void OnConfigsExecuted()
{
#if defined _l4dh_included
	g_hasconfigs = true;
#endif
}

public void OnMapStart()
{
	g_delay = 0.0;
	g_seed_cooldown = 0.0;
#if defined _l4dh_included
	g_delay_l4d_gamemode = 0.0;
	g_delay_l4d_generic = 0.0;
#endif

	if (!cfg_ServerStart.enabled)
	{
		return;
	}

#if defined __steampawn_included
	if (!g_hasip)
	{
		CreateTimer(30.0, Timer_SDR_BuildIP, _, TIMER_FLAG_NO_MAPCHANGE);
	}
#else
	g_hasip = BuildServerIPAddr(g_ipaddr, sizeof(g_ipaddr));

	if (g_hasip && !g_started)
	{
		g_started = true;
		CreateTimer(15.0, Timer_OnServerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
#endif
}

public void OnClientPutInServer(int client)
{
	if (cfg_JoinLeave.enabled)
	{
		g_hasfullyjoined[client] = true;

		if (g_delay <= GetGameTime() && !IsFakeClient(client))
		{
			g_delay = GetGameTime() + c_delay.FloatValue;
			CreateTimer(1.0, Timer_OnClientJoin, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CPlayer player = CPlayer(client);
	player.Reset();
}

public void OnClientDisconnect(int client)
{
	if (cfg_JoinLeave.enabled)
	{
		if (g_hasfullyjoined[client] && !IsFakeClient(client))
		{
			g_hasfullyjoined[client] = false;
			if(g_delay <= GetGameTime())
			{
				g_delay = GetGameTime() + c_delay.FloatValue;
				CreateTimer(1.0, Timer_OnClientLeave, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

Action ConCmd_Seed(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "This command is only available in-game!");
		return Plugin_Handled;
	}

	if (!cfg_Seed.enabled)
	{
		ReplyToCommand(client, "Seed is disabled on this server.");
		return Plugin_Handled;
	}

	float now = GetGameTime();

	if (g_seed_cooldown > now)
	{
		ReplyToCommand(client, "A seed request was sent recently, please wait %i seconds.", RoundToCeil(g_seed_cooldown - now));
		return Plugin_Handled;
	}

	if (!g_hasip)
	{
		g_hasip = BuildServerIPAddr(g_ipaddr, sizeof(g_ipaddr));
	}

	g_seed_cooldown = now + cfg_Seed.cooldown;
	LogMessage("%L sent a seed request.", client);
	SendMessage_OnSeedRequest(client);
	return Plugin_Handled;
}

Action ConCmd_DemoRequest(int client, int args)
{
#if !defined _stvmngr_included
	return Plugin_Handled;
#else
	if (!cfg_DemoRequests.enabled)
	{
		ReplyToCommand(client, "This server has disabled demo requests.");
		return Plugin_Handled;
	}

	if (!g_sourcetvmanager)
	{
		if (client == 0)
		{
			// Command was executed by console, warn server ops that they didn't install the extension
			LogError("SourceTV Manager not loaded!");
		}

		return Plugin_Handled;
	}

	if (!SourceTV_IsActive() || !SourceTV_IsRecording())
	{
		ReplyToCommand(client, "SourceTV is not available.");
		return Plugin_Handled;
	}

	if (client == 0)
	{
		SendMessage_OnDemoRequest(client);
		return Plugin_Handled;
	}

	CPlayer player = CPlayer(client);

	if (!player.IsAllowedToRequestDemos())
	{
		ReplyToCommand(client, "Please wait before requesting demos again.");
		return Plugin_Handled;
	}

	player.OnDemoRequested(cfg_DemoRequests.cooldown);
	SendMessage_OnDemoRequest(client);

	if (cfg_DemoRequests.hasaccessurl)
	{
		ReplyToCommand(client, "Demo request received. Access it at %s", cfg_DemoRequests.accessurl);
	}

	return Plugin_Handled;
#endif
}

public Action Timer_OnClientJoin(Handle timer, any data)
{
	SendMessage_OnClientJoin(GetClientFromSerial(data));
	return Plugin_Stop;
}

public Action Timer_OnClientLeave(Handle timer)
{
	SendMessage_OnClientLeave();
	return Plugin_Stop;
}

public Action Timer_OnServerStart(Handle timer)
{
	SendMessage_OnServerStart();
	return Plugin_Stop;
}

#if defined __steampawn_included
// A delay is needed to get the SDR IP
public Action Timer_SDR_BuildIP(Handle timer)
{
	g_hasip = BuildServerIPAddr(g_ipaddr, sizeof(g_ipaddr));

	if (g_hasip && !g_started)
	{
		g_started = true;
		CreateTimer(15.0, Timer_OnServerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}
#endif

public void OnWebHookExecuted(HTTPResponse response, any value, const char[] error)
{
	if (response.Status != HTTPStatus_OK)
	{
		LogError("Failed to send webhook message! Status: %i Error: %s", view_as<int>(response.Status), error);
		return;
	}
}
