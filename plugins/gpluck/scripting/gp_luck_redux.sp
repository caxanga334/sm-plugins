#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <multicolors>
#include <tf2utils>

#define LUCK_MAX_EFFECT_NAME_LENGTH 64
#define LUCK_RANDOM_NAME_ARRAY_SIZE 48

enum struct eLuckData
{
	int id; // Active Effect ID
	float starttime; // Effect start time
	float duration; // Effect duration
	float timer; // Timer for effects
	float subtimer; // Subtimer for effects
	float cooldown; // Roll usage cooldown
	float vec[3]; // Data vector
	int state; // State for FSM
}
eLuckData g_LuckData[MAXPLAYERS+1];

enum
{
	LUCK_EFFECT_INVALID = -1, // -1: Invalid Effect
	LUCK_EFFECT_NONE = 0, // 0: No Effect
	LUCK_EFFECT_TFCOND, // 1: TF2 Condition
	LUCK_EFFECT_RANDOM_NAME, // 2: Renames the player to a random name
	LUCK_EFFECT_WEAPON_DELETER, // 3: Deletes a random weapon
	LUCK_EFFECT_HEALTH, // 4: Big Health Bonus
	LUCK_EFFECT_SOULSPHERE, // 5: Ultimate DooM's Soul Sphere
	LUCK_EFFECT_OILDRUM_RAIN, // 6: Rain of HL2 trademarked exploding barrels
	LUCK_EFFECT_CHAR_ATTRIBUTE, // 7: Character attribute
	LUCK_EFFECT_WEAPON_ATTRIBUTE, // 8: Weapon Attribute
	LUCK_EFFECT_RANDOM_IMPULSE, // 9: Random Imulse
	LUCK_EFFECT_LAG, // 10: Lag
	LUCK_EFFECT_FORCE_MOVE, // 11: Force move forwards
	LUCK_EFFECT_FORCE_ATTACK, // 12: Force attack
	LUCK_EFFECT_XY_SHIFT, // 13: XY coordinates shift
	LUCK_EFFECT_MAX // Max Effect count
};

ArrayList g_RandomNames1;
ArrayList g_RandomNames2;

methodmap LuckClient
{
	public LuckClient(int index) { return view_as<LuckClient>(index); }
	property int index 
	{
		public get()	{ return view_as<int>(this); }
	}
	property int Effect
	{
		public get()    { return g_LuckData[this.index].id; }
		public set(int value)    { g_LuckData[this.index].id = value; }
	}
	property float StartTime
	{
		public get()    { return g_LuckData[this.index].starttime; }
		public set(float value)    { g_LuckData[this.index].starttime = value; }
	}
	property float Duration
	{
		public get()    { return g_LuckData[this.index].duration; }
		public set(float value)    { g_LuckData[this.index].duration = value; }
	}
	property float Cooldown
	{
		public get()    { return g_LuckData[this.index].cooldown; }
		public set(float value)    { g_LuckData[this.index].cooldown = value; }
	}
	property float Timer
	{
		public get()    { return g_LuckData[this.index].timer; }
		public set(float value)    { g_LuckData[this.index].timer = value; }
	}
	property float SubTimer
	{
		public get()    { return g_LuckData[this.index].subtimer; }
		public set(float value)    { g_LuckData[this.index].subtimer = value; }
	}
	property int State
	{
		public get()    { return g_LuckData[this.index].state; }
		public set(int value)    { g_LuckData[this.index].state = value; }
	}
	public void Reset() // Resets client data
	{
		g_LuckData[this.index].id = LUCK_EFFECT_INVALID;
		g_LuckData[this.index].starttime = 0.0;
		g_LuckData[this.index].duration = 0.0;
		g_LuckData[this.index].cooldown = 0.0;
		g_LuckData[this.index].timer = 0.0;
		g_LuckData[this.index].subtimer = 0.0;
		g_LuckData[this.index].vec[0] = 0.0;
		g_LuckData[this.index].vec[1] = 0.0;
		g_LuckData[this.index].vec[2] = 0.0;
	}
	public bool CanRoll()
	{
		return g_LuckData[this.index].cooldown <= GetGameTime();
	}
	public void Roll()
	{
		RollLuckEffectOnClient(this.index);
	}
	public float GetRemainingCooldownTime()
	{
		return g_LuckData[this.index].cooldown - GetGameTime();
	}
	public void End()
	{
		g_LuckData[this.index].id = LUCK_EFFECT_INVALID;
		g_LuckData[this.index].duration = 0.0;
		g_LuckData[this.index].timer = 0.0;        
	}
	public bool IsEffectActive()
	{
		return g_LuckData[this.index].id > LUCK_EFFECT_NONE && g_LuckData[this.index].id < LUCK_EFFECT_MAX;
	}
	public bool ShouldEffectEnd()
	{
		return g_LuckData[this.index].starttime + g_LuckData[this.index].duration <= GetGameTime();
	}
	public bool IsTimerUp()
	{
		return g_LuckData[this.index].timer <= GetGameTime();
	}
	public bool IsSubTimerUp()
	{
		return g_LuckData[this.index].subtimer <= GetGameTime();
	}
	public void SetDataVector(float vec[3])
	{
		g_LuckData[this.index].vec[0] = vec[0];
		g_LuckData[this.index].vec[1] = vec[1];
		g_LuckData[this.index].vec[2] = vec[2];
	}
	public void GetDataVector(float vec[3])
	{
		vec[0] = g_LuckData[this.index].vec[0];
		vec[1] = g_LuckData[this.index].vec[1];
		vec[2] = g_LuckData[this.index].vec[2];
	}
}

char g_logpath[PLATFORM_MAX_PATH];

#include "luck/configs.sp"
#include "luck/attributes.sp"
#include "luck/functions.sp"
#include "luck/effects.sp"
#include "luck/gameevents.sp"
#include "luck/gametrace.sp"

public Plugin myinfo =
{
	name = "[GP] Luck Rolls Module",
	author = "caxanga334",
	description = "Gamers ala Pro Luck Rolls Module",
	version = "2.1.0",
	url = "https://github.com/caxanga334/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugins only supports Team Fortress 2.");
		return APLRes_SilentFailure;
	}

	if (late)
	{
		strcopy(error, err_max, "Late loading is currently not supported!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

// Called when the plugin starts
public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");

	// Register Commands
	RegConsoleCmd("sm_luck", ConCmd_Luck, "Roll a luck effect");
	RegConsoleCmd("sm_roll", ConCmd_Luck, "Roll a luck effect");
	RegConsoleCmd("sm_rtd", ConCmd_Luck, "Roll a luck effect");
	RegAdminCmd("sm_luck_force", ConCmd_ForceEffect, ADMFLAG_CHEATS, "Forces a luck effect on a client");

	// Game Events
	HookEvent("player_death", E_PlayerDeath, EventHookMode_Post);

	InitAttributes();

	BuildPath(Path_SM, g_logpath, sizeof(g_logpath), "logs/luck.log");
	
	g_RandomNames1 = new ArrayList(ByteCountToCells(LUCK_RANDOM_NAME_ARRAY_SIZE));
	g_RandomNames2 = new ArrayList(ByteCountToCells(LUCK_RANDOM_NAME_ARRAY_SIZE));

	Config_LoadRandomNames();
}

// Called when the map starts
public void OnMapStart()
{
	PrecacheModel("models/props_c17/oildrum001_explosive.mdl", true);
}
 
// Called when a client is entering the game
public void OnClientPutInServer(int client)
{
	LuckClient lc = LuckClient(client);
	lc.Reset();
}

// Luck roll command callback
public Action ConCmd_Luck(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "This command can only be used in-game or in-chat for listen servers.");
		return Plugin_Handled;
	}

	if(IsFakeClient(client))
		return Plugin_Handled;

	if(TF2_GetClientTeam(client) == TFTeam_Blue && IsMannVsMachine())
	{
		CReplyToCommand(client, "{orange}Your team cannot use this command.");
		return Plugin_Handled;
	}

	LuckClient lc = LuckClient(client);

	if(!lc.CanRoll())
	{
		CReplyToCommand(client, "{cyan}Luck roll is currently in cooldown, please wait{green} %0.6f {cyan}second(s).", lc.GetRemainingCooldownTime());
		return Plugin_Handled;
	}

	lc.Roll();
	lc.Cooldown = GetGameTime() + Math_GetRandomFloat(60.0, 180.0);

	return Plugin_Handled;
}

// Force effect command
public Action ConCmd_ForceEffect(int client, int args)
{
	/*
	if(!client)
	{
		ReplyToCommand(client, "This command can only be used in-game or in-chat for listen servers.");
		return Plugin_Handled;
	}
	*/

	if(args < 1)
	{
		ReplyToCommand(client, "Usage: sm_luck_force <target> [ID]");
		return Plugin_Handled;        
	}

	char arg1[MAX_NAME_LENGTH], arg2[4];
	int iarg2;
	GetCmdArg(1, arg1, sizeof(arg1));

	/**
		* target_name - stores the noun identifying the target(s)
		* target_list - array to store clients
		* target_count - variable to store number of clients
		* tn_is_ml - stores whether the noun must be translated
		*/
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(args == 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		iarg2 = StringToInt(arg2);
		if(!IsValidLuckEffect(iarg2))
		{
			ReplyToCommand(client, "Invalid luck effect %i", iarg2);
			return Plugin_Handled;
		}
	}
	else
	{
		iarg2 = 0;
	}

	char effectname[32];
	GetEffectName(iarg2, effectname, sizeof(effectname));

	for (int i = 0; i < target_count; i++)
	{
		if(!iarg2)
		{
			RollLuckEffectOnClient(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" forced a random luck effect on \"%L\"", client, target_list[i]);
		}
		else
		{
			ActivateEffect(target_list[i], iarg2);
			LogAction(client, target_list[i], "\"%L\" forced the luck effect \"%s\" on \"%L\"", client, effectname, target_list[i]);
		}
	}

	if(iarg2)
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "Forced the luck effect \"%s\" on %t", effectname, target_name);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "Forced the luck effect \"%s\" on %s", effectname, target_name);
		}
	}
	else
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "Forced a random luck effect on %t", target_name);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "Forced a random luck effect on %s", target_name);
		}
	}

	return Plugin_Handled;
}

/**
 * Rolls a random luck effect on the given client
 *
 * @param client        The client to roll
 * @return     no return
 */
void RollLuckEffectOnClient(int client)
{
	int effect = Math_GetRandomInt(LUCK_EFFECT_NONE+1, LUCK_EFFECT_MAX-1);
	char name[64];
	GetEffectName(effect, name, sizeof(name));
	LogToFile(g_logpath, "Client \"%L\" rolled luck effect \"%s\".", client, name);
	ActivateEffect(client, effect);
}

/**
 * Activates a luck effect
 *
 * @param client    Client index
 * @param effect    Luck effect ID
 * @return     no return
 */
void ActivateEffect(int client, const int effect)
{
	LuckClient lc = LuckClient(client);
	float gametime = GetGameTime();

	switch(effect)
	{
		case LUCK_EFFECT_TFCOND:
		{
			ApplyTFCondEffect(client);
		}
		case LUCK_EFFECT_RANDOM_NAME:
		{
			ApplyRandomNameEffect(client);
		}
		case LUCK_EFFECT_WEAPON_DELETER:
		{
			ApplyWeaponDeleterEffect(client);
		}
		case LUCK_EFFECT_HEALTH:
		{
			ApplyHealthBonusEffect(client);
		}
		case LUCK_EFFECT_SOULSPHERE:
		{
			ApplySoulSphereEffect(client);
		}
		case LUCK_EFFECT_OILDRUM_RAIN:
		{
			lc.Effect = LUCK_EFFECT_OILDRUM_RAIN;
			lc.StartTime = gametime;
			lc.Duration = Math_GetRandomFloat(30.0, 60.0);
			lc.Timer = gametime + 1.5;
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"Oil Drum Rain\"{cyan}.", client);
		}
		case LUCK_EFFECT_CHAR_ATTRIBUTE:
		{
			ApplyCharAttribEffect(client);
		}
		case LUCK_EFFECT_WEAPON_ATTRIBUTE:
		{
			ApplyWeaponAttribEffect(client);
		}
		case LUCK_EFFECT_RANDOM_IMPULSE:
		{
			lc.Effect = LUCK_EFFECT_RANDOM_IMPULSE;
			lc.StartTime = gametime;
			lc.Duration = Math_GetRandomFloat(30.0, 60.0);
			lc.Timer = gametime + 1.5;
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"Random Impulse\"{cyan}.", client);
		}
		case LUCK_EFFECT_LAG:
		{
			lc.Effect = LUCK_EFFECT_LAG;
			lc.StartTime = gametime;
			lc.Duration = Math_GetRandomFloat(30.0, 60.0);
			lc.Timer = gametime + 1.0;
			lc.SubTimer = gametime + Math_GetRandomFloat(0.10, 0.75);
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"Lag\"{cyan}.", client);
		}
		case LUCK_EFFECT_FORCE_MOVE:
		{
			lc.Effect = LUCK_EFFECT_FORCE_MOVE;
			lc.StartTime = gametime;
			lc.Duration = Math_GetRandomFloat(30.0, 60.0);
			lc.Timer = gametime + Math_GetRandomFloat(5.0, 10.0);
			lc.State = Math_GetRandomInt(0,3);
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"Force Move\"{cyan}.", client);
		}
		case LUCK_EFFECT_FORCE_ATTACK:
		{
			lc.Effect = LUCK_EFFECT_FORCE_ATTACK;
			lc.StartTime = gametime;
			lc.Duration = Math_GetRandomFloat(30.0, 60.0);
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"Force Attack\"{cyan}.", client);
		}
		case LUCK_EFFECT_XY_SHIFT:
		{
			ApplyCoordinateShiftEffect(client);
			CPrintToChatAll("{green}[LUCK] {cyan}%N rolled {gold}\"XY Shift\"{cyan}.", client);
		}
		default: ThrowError("Invalid luck effect ID: %i", effect);
	}
}

// Called via RequestFrame when the player_death event is fired.
void OnClientDeath(int userid)
{
	int client = GetClientOfUserId(userid);

	if(client)
	{
		LuckClient lc = LuckClient(client);
		lc.End(); // Cancel active effect
	}
}

// OnPlayerRunCmd
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsClientInGame(client))
		return Plugin_Continue;

	if(IsFakeClient(client))
		return Plugin_Continue;

	if(GetClientTeam(client) < view_as<int>(TFTeam_Red))
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	LuckClient lc = LuckClient(client);

	if(lc.IsEffectActive())
	{
		if(lc.ShouldEffectEnd())
		{
			lc.End();
			return Plugin_Continue;
		}

		switch(lc.Effect)
		{
			case LUCK_EFFECT_OILDRUM_RAIN:
			{
				if(lc.IsTimerUp())
				{
					ApplyOilDrumRainEffect(client);
					lc.Timer = GetGameTime() + 1.5;
				}
			}
			case LUCK_EFFECT_RANDOM_IMPULSE:
			{
				if(lc.IsTimerUp())
				{
					ApplyRandomImpulseEffect(client);
					lc.Timer = GetGameTime() + 1.5;
				}
			}
			case LUCK_EFFECT_LAG:
			{
				if(lc.IsSubTimerUp())
				{
					float vec[3];
					GetClientAbsOrigin(client, vec);
					lc.SetDataVector(vec);
					lc.SubTimer = GetGameTime() + 99999.0; // Don't set the position again until main timer is UP!
				}

				if(lc.IsTimerUp())
				{
					float vec[3];
					lc.GetDataVector(vec);
					ApplyLagEffect(client, vec);
					lc.Timer = GetGameTime() + 1.0;
					lc.SubTimer = GetGameTime() + Math_GetRandomFloat(0.10, 0.75);
				}
			}
			case LUCK_EFFECT_FORCE_MOVE:
			{
				if(lc.IsTimerUp())
				{
					lc.Timer = GetGameTime() + Math_GetRandomFloat(5.0, 10.0);
					lc.State = Math_GetRandomInt(0,3);
				}

				switch(lc.State)
				{
					case 0: { MoveForward(vel); }
					case 1: { MoveBackwards(vel); }
					case 2: { MoveLeft(vel); }
					case 3: { MoveRight(vel); }
				}

				return Plugin_Changed;
			}
			case LUCK_EFFECT_FORCE_ATTACK:
			{
				buttons |= IN_ATTACK;

				if(Math_RandomChance(5)) { buttons |= IN_ATTACK2; }
				if(Math_RandomChance(5)) { buttons |= IN_ATTACK3; }

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}