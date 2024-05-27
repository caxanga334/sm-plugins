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

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"

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
char g_primarywebhook[WEBHOOK_URL_MAX_SIZE];
char g_adminwebhook[WEBHOOK_URL_MAX_SIZE];
float g_delay;
EngineVersion g_engine;
ConVar c_webhook_primary_url;
ConVar c_webhook_admin;
ConVar c_delay;
ConVar c_remove1;
ConVar c_remove2;
ConVar c_dns;
ConVar c_announcestart;
ConVar c_announceIP;
#if defined _calladmin_included
ConVar c_calladmin_mention;
#endif

#include "serverstatus/utils.sp"
#include "serverstatus/messages.sp"
#include "serverstatus/left4dead.sp"
#include "serverstatus/teamfortress2.sp"
#include "serverstatus/sourcetv.sp"
#include "serverstatus/calladmin.sp"

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

	if (g_engine == Engine_TF2)
	{
		HookEvent("mvm_begin_wave", EV_TF2_OnMvMWaveStart);
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("plugin.serverstatus");

	AutoExecConfig_CreateConVar("sm_serverstatus_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	c_webhook_primary_url = AutoExecConfig_CreateConVar("sm_serverstatus_webhook_primary_url", "", "Primary webhook URL.", FCVAR_PROTECTED);
	c_webhook_admin = AutoExecConfig_CreateConVar("sm_serverstatus_webhook_admin_url", "", "Webhook for admin messages.", FCVAR_PROTECTED);
	c_delay = AutoExecConfig_CreateConVar("sm_serverstatus_delay", "20.0", "Delay between webhook messages to prevent spam.", FCVAR_NONE, true, 1.0, false);
	c_remove1 = AutoExecConfig_CreateConVar("sm_serverstatus_remove", "", "Remove this part from servername", FCVAR_NONE);
	c_remove2 = AutoExecConfig_CreateConVar("sm_serverstatus_remove2", "", "Remove this part from servername", FCVAR_NONE);
	c_dns = AutoExecConfig_CreateConVar("sm_serverstatus_dns", "", "Send the server IP as a domain name (eg: tf2.example.com) instead", FCVAR_NONE);
	c_announcestart = AutoExecConfig_CreateConVar("sm_serverstatus_alert_start", "1", "Sends a message when the server starts", FCVAR_NONE, true, 0.0, true, 1.0);
	c_announceIP = AutoExecConfig_CreateConVar("sm_serverstatus_show_server_ip", "1", "Shows the server IP address on the server start message?", FCVAR_NONE, true, 0.0, true, 1.0);
#if defined _calladmin_included
	c_calladmin_mention = AutoExecConfig_CreateConVar("gp_discord_calladmin_mention", "@here", "Role to mention when sending CallAdmin messages. \nTo mention a specific role, use <@&ROLE_ID_HERE>", FCVAR_NONE);
#endif

	c_webhook_primary_url.AddChangeHook(OnPrimaryURLChanged);
	c_webhook_admin.AddChangeHook(OnAdminURLChanged);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	g_started = false;
#if defined _l4dh_included
	g_hasconfigs = false;
#endif
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

	c_webhook_primary_url.GetString(g_primarywebhook, sizeof(g_primarywebhook));
	c_webhook_admin.GetString(g_adminwebhook, sizeof(g_adminwebhook));
}

public void OnMapStart()
{
	g_delay = 0.0;
#if defined _l4dh_included
	g_delay_l4d_gamemode = 0.0;
	g_delay_l4d_generic = 0.0;
#endif

#if defined __steampawn_included
	if (!g_hasip)
	{
		CreateTimer(30.0, Timer_SDR_BuildIP, _, TIMER_FLAG_NO_MAPCHANGE);
	}
#else
	g_hasip = BuildServerIPAddr(g_ipaddr, sizeof(g_ipaddr));

	if (g_hasip && !g_started && c_announcestart.BoolValue)
	{
		g_started = true;
		CreateTimer(15.0, Timer_OnServerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
#endif
}

public void OnClientPutInServer(int client)
{
	g_hasfullyjoined[client] = true;

	if (g_delay <= GetGameTime() && !IsFakeClient(client))
	{
		g_delay = GetGameTime() + c_delay.FloatValue;
		CreateTimer(1.0, Timer_OnClientJoin, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientDisconnect(int client)
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

	if (g_hasip && !g_started && c_announcestart.BoolValue)
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

void OnPrimaryURLChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_primarywebhook, sizeof(g_primarywebhook));
}

void OnAdminURLChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_adminwebhook, sizeof(g_adminwebhook));
}