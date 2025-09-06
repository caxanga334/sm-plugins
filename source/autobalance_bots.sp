#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "Auto Balance Bots",
    author = "caxanga334",
    description = "Enables the built-in auto balance for bots.",
    version = "1.0.0",
    url = "https://github.com/caxanga334/sm-plugins"
};

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
    {
        SDKHook(client, SDKHook_CanBeAutobalanced, CanBeAutoBalanced);
    }
}

bool CanBeAutoBalanced(int client, bool origRet)
{
    return true;
}