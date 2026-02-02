#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "[NMRiH] Admin Tools",
    author = "caxanga334",
    description = "Provides some utility admin command for NMRiH.",
    version = "1.0.0",
    url = "https://github.com/caxanga334/sm-plugins"
};


public void OnPluginStart()
{
    RegAdminCmd("sm_nmrih_respawn_dead", Command_RespawnDeadPlayer, ADMFLAG_CHEATS, "Respawns all dead players.");
}

Action Command_RespawnDeadPlayer(int client, int args)
{
    char code[256];
    FormatEx(code, sizeof(code), "GameState.RespawnDeadPlayers()");
    SetVariantString(code);
    AcceptEntityInput(0, "RunScriptCode", 0, 0);

    LogMessage("%L respawned all dead players.");
    ShowActivity2(client, "[SM] ", "Respawned all dead players!");

    return Plugin_Handled;
}