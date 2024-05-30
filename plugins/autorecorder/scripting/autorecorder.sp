#include <sourcemod>

// #define REQUIRE_EXTENSIONS // defined by default in SM 1.12
#include <sourcetvmanager>

EngineVersion g_Engine;

#include <autorecorder/logic.sp>
#include <autorecorder/console.sp>

#define PLUGIN_VERSION "1.3.0"

public Plugin myinfo =
{
    name = "Automated Demo Recording",
    author = "shqke, caxanga334",
    description = "Plugin takes control over demo recording process allowing to record only useful footage",
    version = PLUGIN_VERSION,
    url = "https://github.com/caxanga334/sm-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int maxlen)
{
    g_Engine = GetEngineVersion();
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("sm_autorecorder_version", PLUGIN_VERSION, "Auto Recorder plugin version.", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);

    Logic_Init();
    Console_Init();

    AutoExecConfig(true, "plugin.autorecorder");
}

public void OnAllPluginsLoaded()
{
    if (!LibraryExists("sourcetvmanager"))
    {
        SetFailState("SourceTV Manager not loaded!");
    }
}

public void OnLibraryRemoved(const char[] name)
{
    switch (g_Engine)
    {
        case Engine_Left4Dead, Engine_Left4Dead2:
        {
            if (strcmp(name, "sourcetvsupport") == 0 && SourceTV_IsRecording()) {
                SourceTV_StopRecording();
            }
        }
    }
}

