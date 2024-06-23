#include <sourcemod>
#include <left4dhooks>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#tryinclude <sourcebanspp>

#undef REQUIRE_EXTENSIONS
#tryinclude <sourcetvmanager>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Auto Moderator",
	author = "caxanga334",
	description = "A very basic auto moderator for Left 4 Dead 2 servers.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
};

#if defined _stvmngr_included
bool g_sourcetvmanager;
#endif

#if defined _sourcebanspp_included
bool g_sourcebans;
#endif

#include "l4d_automod/logger.sp"
#include "l4d_automod/config.sp"
#include "l4d_automod/data.sp"
#include "l4d_automod/action.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}

	strcopy(error, err_max, "This plugins is for Left 4 Dead/ 2 only!");
	return APLRes_Failure;
}

public void OnLibraryAdded(const char[] name)
{
#if defined _sourcebanspp_included
	if (strcmp(name, "sourcebans++") == 0)
	{
		g_sourcebans = true;
	}
#endif
}

public void OnLibraryRemoved(const char[] name)
{
#if defined _sourcebanspp_included
	if (strcmp(name, "sourcebans++") == 0)
	{
		g_sourcebans = false;
	}
#endif
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	LoadTranslations("l4d_automod.phrases.txt");

	HookEvent("player_hurt_concise", EV_PlayerHurt, EventHookMode_Post);

	Config_Init();
}

public void OnAllPluginsLoaded()
{
#if defined _stvmngr_included
	g_sourcetvmanager = LibraryExists("sourcetvmanager");
#endif
}

public void OnClientPutInServer(int client)
{
	Player player = Player(client);
	player.Reset();
}

public void OnMapStart()
{
	Logger_BuildFilePath();
	Config_Load();
}

void EV_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	Player victim = Player(GetClientOfUserId(event.GetInt("userid")));
	Player attacker = Player(event.GetInt("attackerentid"));

	if (!victim.IsValid() || attacker.IsValid())
	{
		// both victim and attacker must be a player entity and must be in-game
		return;
	}

	if (g_cfg.ff_ignore_bots && IsFakeClient(victim.index))
	{
		// ignore bots enabled
		return;
	}

	// We only care about survivors
	if (L4D_GetClientTeam(victim.index) != L4DTeam_Survivor)
	{
		return;
	}

	// Not friendly fire
	if (GetClientTeam(victim.index) != GetClientTeam(attacker.index))
	{
		return;
	}

	int dmgtype = event.GetInt("type");

	if (g_cfg.ff_ignore_fire && (dmgtype & DMG_BURN) != 0)
	{
		// ignoring fire (burn) damage
		return;
	}

	int damage = event.GetInt("dmg_health");

	if (damage <= 0)
	{
		return;
	}

	attacker.OnFriendlyFireDamage(damage);
	Action_OnFriendlyFire(attacker, victim);
}