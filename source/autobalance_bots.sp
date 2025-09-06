#include <sourcemod>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

bool g_bIsTF2;

public Plugin myinfo =
{
    name = "Auto Balance Bots",
    author = "caxanga334",
    description = "Enables the built-in auto balance for bots.",
    version = "1.1.0",
    url = "https://github.com/caxanga334/sm-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion ev = GetEngineVersion();

    if (ev == Engine_TF2)
    {
        g_bIsTF2 = true;
    }
    else
    {
        g_bIsTF2 = false;
    }

    return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
    {
        SDKHook(client, SDKHook_CanBeAutobalanced, CanBeAutoBalanced);
    }
}

bool CanBeAutoBalanced(int client, bool origRet)
{
#if defined _tf2_stocks_included
    if (g_bIsTF2)
    {
        // re-create some CTFPlayer::CanBeAutoBalanced checks
        // https://github.com/ValveSoftware/source-sdk-2013/blob/68c8b82fdcb41b8ad5abde9fe1f0654254217b8e/src/game/server/tf/tf_player.cpp#L19789

        if (TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) || TF2_IsPlayerInCondition(client, TFCond_HalloweenKart))
        {
            return false;
        }
    }
#endif


    return true;
}