#include <sourcemod>
#include <clientprefs>
#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

// variables
char g_strCfgPath[PLATFORM_MAX_PATH];
ArrayList g_strSteamID;
ArrayList g_strRole;
bool g_bHidden[MAXPLAYERS + 1];
Handle g_hHiddenCookie;

public Plugin myinfo = {
	name = "Online Staff",
	author = "caxanga334",
	description = "Lists online staff members.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
}

public void OnPluginStart()
{
	g_hHiddenCookie = RegClientCookie("online_staff_hidden", "Online Staff Hidden Status", CookieAccess_Private);

	RegConsoleCmd("sm_online", command_online, "Lists online staff members");
	RegAdminCmd("sm_online_reload", command_reload, ADMFLAG_ROOT, "Reloads the staff list");

	InitArrays();
	LoadKVFile();
}

public void OnMapStart()
{
	ResetArrays();
	LoadKVFile();
}

public void OnClientPutInServer(int client)
{
	char buffer[4], buffer2[255];
	int iBool, x;
	
	if( AreClientCookiesCached(client) && IsClientAuthorized(client) )
	{
		GetClientAuthId(client, AuthId_Steam2, buffer2, sizeof(buffer2));
		x = g_strSteamID.FindString(buffer2);
		if(x != -1) // Don't load hidden status for non-staff
		{
			GetClientCookie(client, g_hHiddenCookie, buffer, sizeof(buffer));
			iBool = StringToInt(buffer);
			switch( iBool )
			{
				case 0: g_bHidden[client] = false;
				case 1: g_bHidden[client] = true;
				default: LogError("iBool value was out of bounds! ( %i )", iBool);
			}
			PrintToConsole(client, "[Staff List] Hidden status loaded from cookie. ( %s )", g_bHidden[client] ? "Enabled" : "Disabled");
		}
	}
}

public Action command_reload(int client, int args)
{
	ResetArrays();
	LoadKVFile();
	ReplyToCommand(client, "Staff List reload: OK");
	return Plugin_Handled;
}

public Action command_online(int client, int args)
{
	int iStaff = 0, x;
	char buffer[255], buffer2[255];
	
	if(args == 1 && IsClientInGame(client))
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		if(StrEqual(buffer, "hide", false))
		{
			GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
			x = g_strSteamID.FindString(buffer);
			if(x != -1) // don't toggle for non-staff
			{
				g_bHidden[client] = !g_bHidden[client];
				ReplyToCommand(client, "[Staff List] Hidden mode is %s.", g_bHidden[client] ? "enabled" : "disabled");
				buffer2 = g_bHidden[client] ? "1" : "0";
				SetClientCookie(client, g_hHiddenCookie, buffer2);
				return Plugin_Handled;
			}
		}
	}
	
	ReplyToCommand(client, "Online Staff Members:");
	for(int i = 1;i < MaxClients;i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsClientAuthorized(i) && !IsFakeClient(i))
		{
			GetClientAuthId(i, AuthId_Steam2, buffer, sizeof(buffer));
			x = g_strSteamID.FindString(buffer);
			if(x != -1 && !g_bHidden[i])
			{
				iStaff++;
				g_strSteamID.GetString(x, buffer, sizeof(buffer));
				g_strRole.GetString(x, buffer2, sizeof(buffer2));
				GetClientName(i, buffer, sizeof(buffer));
				ReplyToCommand(client, "%s - %s", buffer, buffer2);
			}
		}
	}
	
	if(iStaff == 0) { ReplyToCommand(client, "None"); }
	
	return Plugin_Handled;
}

void InitArrays()
{
	g_strSteamID = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_strRole = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
}

void ResetArrays()
{
	g_strSteamID.Clear();
	g_strRole.Clear();
}

void LoadKVFile()
{
	BuildPath(Path_SM, g_strCfgPath, sizeof(g_strCfgPath), "configs/online_stafflist.cfg");
	if(!FileExists(g_strCfgPath)) { SetFailState("Config file \"%s\" not found!", g_strCfgPath); }
	
	KeyValues kv = new KeyValues("StaffList");
	kv.ImportFromFile(g_strCfgPath);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
	}
	
	char buffer[255];
	
	do
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		g_strSteamID.PushString(buffer);
		kv.GetString("role", buffer, sizeof(buffer), "Admin");
		g_strRole.PushString(buffer);
		
	} while( kv.GotoNextKey() );
	
	delete kv;
}