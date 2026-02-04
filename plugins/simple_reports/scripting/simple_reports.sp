#include <sourcemod>
#include <adminmenu>
#undef REQUIRE_EXTENSIONS
#include <discordWebhookAPI>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Simple Player Reports",
	author = "caxanga334",
	description = "A simple plugin for reporting players.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

// translation strings for the report reasons
static char s_ReportReasonTL[][] = {
	"RR_Cheating",
	"RR_Griefing",
	"RR_BadBehavior",
	"RR_CommsAbuse",
	"RR_BadSpray",
	"RR_Other",
};

int g_ReportTarget[MAXPLAYERS + 1]; // selected report client
float g_ReportCooldown[MAXPLAYERS + 1]; // cooldown between reports
char g_mapname[128];
char g_logfile[PLATFORM_MAX_PATH];
char g_hostname[256];
bool g_RipExtLoaded = false;

ConVar cvar_discord_webhookurl;
ConVar cvar_discord_mention;
ConVar cvar_report_cooldown;

methodmap ReportClient
{
	public ReportClient(int client)
	{
		return view_as<ReportClient>(client);
	}

	property int index
	{
		public get() { return view_as<int>(this); }
	}

	public void Reset()
	{
		g_ReportTarget[this.index] = 0;
		g_ReportCooldown[this.index] = 0.0;
	}

	public void OnReportTargetSelected(int target)
	{
		g_ReportTarget[this.index] = GetClientSerial(target);
	}

	public void SendReportReasonMenu()
	{
		Menu menu = new Menu(MenuHandler_SelectReportReason, MENU_ACTIONS_ALL);

		for (int i = 0; i < sizeof(s_ReportReasonTL); i++)
		{
			char info[8];
			FormatEx(info, sizeof(info), "%i", i);
			menu.AddItem(info, s_ReportReasonTL[i]);
		}

		menu.Display(this.index, 60);
	}

	public void OnPlayerReported(int reason)
	{
		int target = GetClientFromSerial(g_ReportTarget[this.index]);

		if (target > 0)
		{
			LogReport(this.index, target, reason);
			SendReportToDiscord(this.index, target, reason);
			PrintToChat(this.index, "%t", "Msg_ReportSent", target);
			NotifyIngameAdmins(this.index, target, reason);
			g_ReportCooldown[this.index] = GetGameTime() + cvar_report_cooldown.FloatValue;
		}
		else
		{
			PrintToChat(this.index, "%t", "Player no longer available");
		}
	}

	public bool IsReportInCooldown()
	{
		return GetGameTime() < g_ReportCooldown[this.index];
	}
}

public void OnPluginStart()
{
	RegAdminCmd("sm_reportplayer", Command_OpenReportMenu, 0, "Opens the player reporting menu.");

	LoadTranslations("simple_reports.phrases");
	LoadTranslations("common.phrases");

	BuildPath(Path_SM, g_logfile, sizeof(g_logfile), "logs/player_reports.log");
	char time[128];
	FormatTime(time, sizeof(time), "%Y-%m-%d %H:%M:%S");
	LogToFileEx(g_logfile, "%s: Player reports log file started.", time);

	cvar_discord_webhookurl = CreateConVar("sm_simplereports_discord_webhook_url", "", "Url of a discord webhook to send reports to.", FCVAR_PROTECTED);
	cvar_discord_mention = CreateConVar("sm_simplereports_discord_mention", "", "Optional mention in the discord message.", FCVAR_NONE);
	cvar_report_cooldown = CreateConVar("sm_simplereports_cooldown", "60.0", "Cooldown in seconds between reports sent by the same user.", FCVAR_NONE);

	AutoExecConfig(true);
}

public void OnAllPluginsLoaded()
{
	g_RipExtLoaded = LibraryExists("ripext");
}

Action Command_OpenReportMenu(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	char authid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_Engine, authid, sizeof(authid)))
	{
		ReplyToCommand(client, "%t", "Error_NoAuth");
		return Plugin_Handled;
	}

	if (GetClientCount(true) == 1)
	{
		return Plugin_Handled;
	}

	Menu menu = new Menu(MenuHandler_SelectTargetMenu, MENU_ACTIONS_ALL);
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS);
	menu.Display(client, 60);

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	ReportClient rc = ReportClient(client);
	rc.Reset();
}

public void OnMapStart()
{
	char buffer[128];
	char map[128];

	GetCurrentMap(buffer, sizeof(buffer));

	if (GetMapDisplayName(buffer, map, sizeof(map)))
	{
		strcopy(g_mapname, sizeof(g_mapname), map);
	}
	else
	{
		strcopy(g_mapname, sizeof(g_mapname), buffer);
	}

	ConVar hostname = FindConVar("hostname");

	if (hostname != null)
	{
		hostname.GetString(g_hostname, sizeof(g_hostname));
	}
}

int MenuHandler_SelectTargetMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
	case MenuAction_Display:
	{
		Panel panel = view_as<Panel>(param2);
		char title[64];
		FormatEx(title, sizeof(title), "%T", "ReportMenu_PlayersTitle", param1);
		panel.SetTitle(title);
		return 0;
	}
	case MenuAction_End:
	{
		delete menu;
		return 0;
	}
	case MenuAction_Select:
	{
		char info[16];

		if (menu.GetItem(param2, info, sizeof(info)))
		{
			int userid = StringToInt(info);
			int target = GetClientOfUserId(userid);

			if (target > 0)
			{
				if (CheckCommandAccess(target, "sm_playerreports_admin", ADMFLAG_KICK))
				{
					PrintToChat(param1, "%t", "Unable to target");
				}
				else
				{
					ReportClient rc = ReportClient(param1);
					rc.OnReportTargetSelected(target);
					rc.SendReportReasonMenu();
				}
			}
			else
			{
				PrintToChat(param1, "%t", "Player no longer available");
			}
		}

		return 0;
	}
	}

	return 0;
}

int MenuHandler_SelectReportReason(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
	case MenuAction_Display:
	{
		Panel panel = view_as<Panel>(param2);
		char title[64];
		FormatEx(title, sizeof(title), "%T", "ReportMenu_ReasonsTitle", param1);
		panel.SetTitle(title);
		return 0;
	}
	case MenuAction_End:
	{
		delete menu;
		return 0;
	}
	case MenuAction_DisplayItem:
	{
		char display[32];
		
		if (menu.GetItem(param2, "", 0, _, display, sizeof(display)))
		{
			char tl[64];
			FormatEx(tl, sizeof(tl), "%T", display, param1);
			return RedrawMenuItem(tl);
		}

		return 0;
	}
	case MenuAction_Select:
	{
		char info[8];

		if (menu.GetItem(param2, info, sizeof(info)))
		{
			int reasonindex = StringToInt(info);
			ReportClient rc = ReportClient(param1);
			rc.OnPlayerReported(reasonindex);
		}

		return 0;
	}
	}

	return 0;
}

void LogReport(int caller, int target, int reason)
{
	char time[128];
	FormatTime(time, sizeof(time), "%Y-%m-%d %H:%M:%S");

	char strreason[128];
	FormatEx(strreason, sizeof(strreason), "%T", s_ReportReasonTL[reason], LANG_SERVER);

	LogToFileEx(g_logfile, "%s: %L reported %L for \"%s\"!", time, caller, target, strreason);
}

void SendReportToDiscord(int caller, int target, int reason)
{
	if (!g_RipExtLoaded)
	{
		return;
	}

	char url[1024];
	cvar_discord_webhookurl.GetString(url, sizeof(url));

	if (strlen(url) < 10)
	{
		return;
	}

	char mention[64];
	cvar_discord_mention.GetString(mention, sizeof(mention));
	Webhook webhook = new Webhook(mention);
	
	Embed embed1 = new Embed("Player Report", "A player was reported on the server!");
	embed1.SetTimeStampNow();
	embed1.SetColor(15548997);
	EmbedAuthor author = new EmbedAuthor(g_hostname);
	embed1.SetAuthor(author);
	delete author;
	
	EmbedField fmap = new EmbedField("Map", g_mapname, false);
	embed1.AddField(fmap);

	char buffer[256];
	char authid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(caller, AuthId_Engine, authid, sizeof(authid)))
	{
		strcopy(authid, sizeof(authid), "NO_STEAM_AUTH");
	}

	FormatEx(buffer, sizeof(buffer), "%N (%s)", caller, authid);
	EmbedField fcaller = new EmbedField("Caller", buffer, false);
	embed1.AddField(fcaller);

	if (!GetClientAuthId(target, AuthId_Engine, authid, sizeof(authid)))
	{
		strcopy(authid, sizeof(authid), "NO_STEAM_AUTH");
	}

	FormatEx(buffer, sizeof(buffer), "%N (%s)", target, authid);
	EmbedField ftarget = new EmbedField("Target", buffer, false);
	embed1.AddField(ftarget);

	char tl[128];
	FormatEx(tl, sizeof(tl), "%T", s_ReportReasonTL[reason], LANG_SERVER);
	FormatEx(buffer, sizeof(buffer), "%s", tl);

	EmbedField freason = new EmbedField("Reason", buffer, false);
	embed1.AddField(freason);

	webhook.AddEmbed(embed1);
	webhook.Execute(url, Webhook_HTTP_Callback);
	delete webhook;
}

void Webhook_HTTP_Callback(HTTPResponse response, any value, const char[] error)
{
	if (response.Status != HTTPStatus_OK)
	{
		LogError("Failed to send player report message to discord! Error: %s", error);
	}
}

void NotifyIngameAdmins(int caller, int target, int reason)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))
		{
			PrintToChat(client, "%t", "Msg_Admin_Reported", caller, target, s_ReportReasonTL[reason]);
		}
	}
}