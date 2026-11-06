#include <sourcemod>
#include <mapchooser>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
    name = "MvM End Mission Map Vote",
    author = "caxanga334",
    description = "Triggers a map vote when an MvM mission ends.",
    version = "1.0.0",
    url = "https://github.com/caxanga334/sm-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (FindSendPropInfo("CTFGameRulesProxy", "m_bPlayingMannVsMachine") < 0)
    {
        strcopy(error, err_max, "This plugin is for Team Fortress 2 only!");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}


public void OnPluginStart()
{
    HookEvent("mvm_mission_complete", OnMissionCompleteEvent, EventHookMode_PostNoCopy);
}

void OnMissionCompleteEvent(Event event, const char[] name, bool dontBroadcast)
{
    if (CanMapChooserStartVote())
    {
        LogMessage("Received \"mvm_mission_complete\" game event. Starting map vote.");
        InitiateMapChooserVote(MapChange_Instant);
    }
}