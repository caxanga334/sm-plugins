#include <sourcemod>
#include <clientprefs>
#include <left4dhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Admin Stealth",
	author = "caxanga334",
	description = "Allows admins to hide.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
};

Cookie g_cookieFLEnabled = null; // fake latency enabled?
Cookie g_cookieFLMin = null; // fake latency min
Cookie g_cookieFLMax = null; // fake latency max

enum struct AdminSettings
{
	int cachedlatency;
	bool fakelatency;
	int maxlatency;
	int minlatency;
	float latencytimer;

	void Reset()
	{
		this.cachedlatency = 0;
		this.fakelatency = false;
		this.maxlatency = 0;
		this.minlatency = 0;
		this.latencytimer = 0.0;
	}
}

AdminSettings g_settings[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_cookieFLEnabled = RegClientCookie("L4D2ADMSTHFLB", "L4D2 Admin Stealth fake latency enabled.", CookieAccess_Protected);
	g_cookieFLMin = RegClientCookie("L4D2ADMSTHFLMIN", "L4D2 Admin Stealth fake latency min.", CookieAccess_Protected);
	g_cookieFLMax = RegClientCookie("L4D2ADMSTHFLMAX", "L4D2 Admin Stealth fake latency max.", CookieAccess_Protected);

	RegAdminCmd("sm_toggle_fake_latency", CMD_ToggleFakeLatency, ADMFLAG_ROOT, "Toggles fake scoreboard latency.");
	RegAdminCmd("sm_set_minmax_fake_latency", CMD_SetMinMax, ADMFLAG_ROOT, "Sets your fake scoreboard latency min and max random value.");
}

public void OnClientDisconnect(int client)
{
	g_settings[client].Reset();
}

public void OnClientPutInServer(int client)
{
	g_settings[client].Reset();
}

public void OnClientCookiesCached(int client)
{
	char buffer[16];

	g_cookieFLEnabled.Get(client, buffer, sizeof(buffer));
	g_settings[client].fakelatency = StringToInt(buffer) != 0;
	g_cookieFLMin.Get(client, buffer, sizeof(buffer));
	g_settings[client].minlatency = StringToInt(buffer);
	g_cookieFLMax.Get(client, buffer, sizeof(buffer));
	g_settings[client].maxlatency = StringToInt(buffer);
	g_settings[client].latencytimer = 0.0;

	if (g_settings[client].minlatency <= 0 || g_settings[client].maxlatency <= 0)
	{
		g_settings[client].minlatency = GetRandomInt(30, 35);
		g_settings[client].maxlatency = GetRandomInt(36, 40);
		
		FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].minlatency);
		g_cookieFLMin.Set(client, buffer);
		FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].maxlatency);
		g_cookieFLMax.Set(client, buffer);
	}

	g_settings[client].cachedlatency = GetRandomInt(g_settings[client].minlatency, g_settings[client].maxlatency);
	LogMessage("Loaded Admin Stealth settings for client %L", client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_settings[client].fakelatency)
	{
		if (g_settings[client].latencytimer <= GetGameTime())
		{
			g_settings[client].latencytimer = GetGameTime() + GetRandomFloat(0.5, 9.0);
			g_settings[client].cachedlatency = GetRandomInt(g_settings[client].minlatency, g_settings[client].maxlatency);
		}

		L4D_SetPlayerResourceData(client, L4DResource_Ping, view_as<any>(g_settings[client].cachedlatency));
	}
}

Action CMD_ToggleFakeLatency(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	g_settings[client].fakelatency = !g_settings[client].fakelatency;

	if (g_settings[client].fakelatency)
	{
		g_cookieFLEnabled.Set(client, "1");
		g_settings[client].latencytimer = 0.0;
		ReplyToCommand(client, "[SM] Fake latency enabled!");
	}
	else
	{
		g_cookieFLEnabled.Set(client, "0");
		ReplyToCommand(client, "[SM] Fake latency disabled!");
	}

	if (g_settings[client].minlatency == 0)
	{
		g_settings[client].minlatency = GetRandomInt(30, 35);
		g_settings[client].maxlatency = GetRandomInt(36, 40);
		
		char buffer[8];
		FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].minlatency);
		g_cookieFLMin.Set(client, buffer);
		FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].maxlatency);
		g_cookieFLMax.Set(client, buffer);
	}

	g_settings[client].cachedlatency = GetRandomInt(g_settings[client].minlatency, g_settings[client].maxlatency);

	return Plugin_Handled;
}

Action CMD_SetMinMax(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_set_fake_latency_bounds <min> <max>");
		return Plugin_Handled;
	}

	int min = GetCmdArgInt(1);
	int max = GetCmdArgInt(2);

	if (min <= 0 || max <= 0)
	{
		ReplyToCommand(client, "[SM] Error: min and max must be greater than zero! Got %i / %i", min, max);
		return Plugin_Handled;
	}

	if (max < min || min > max)
	{
		ReplyToCommand(client, "[SM] Error: invalid values! Got %i / %i", min, max);
		return Plugin_Handled;
	}

	g_settings[client].minlatency = min;
	g_settings[client].maxlatency = max;
	
	char buffer[8];
	FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].minlatency);
	g_cookieFLMin.Set(client, buffer);
	FormatEx(buffer, sizeof(buffer), "%i", g_settings[client].maxlatency);
	g_cookieFLMax.Set(client, buffer);

	ReplyToCommand(client, "[SM] New Min: %i / New Max: %i", min, max);

	return Plugin_Handled;
}