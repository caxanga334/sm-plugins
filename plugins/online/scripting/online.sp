#include <sourcemod>
#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

// variables
char g_strCfgPath[PLATFORM_MAX_PATH];
ArrayList g_strSteamID;
ArrayList g_strRole;

public Plugin myinfo = {
	name = "Online Staff",
	author = "caxanga334",
	description = "Lists online staff members.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_online", command_online, "Lists online staff members");

	InitArrays();
	LoadKVFile();
}

public void OnMapStart()
{
	ResetArrays();
	LoadKVFile();
}

public Action command_online(int client, int args)
{
	int iStaff = 0, x;
	char buffer[255], buffer2[255];
	
	ReplyToCommand(client, "Online Staff Members:");
	for(int i = 1;i < MaxClients;i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsClientAuthorized(i) && !IsFakeClient(i))
		{
			GetClientAuthId(i, AuthId_Steam2, buffer, sizeof(buffer));
			x = g_strSteamID.FindString(buffer);
			if(x != -1)
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