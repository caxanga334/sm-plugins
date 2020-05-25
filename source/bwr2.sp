#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <tf2attributes>
#include <multicolors>
//#tryinclude <bwr2>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>

#define REQUIRE_PLUGIN
#include <adminmenu>

#undef REQUIRE_PLUGIN

#define SVTAGSIZE 256

#pragma semicolon					1

#define PLUGIN_VERSION				"1.6.6"//
#define PLUGIN_TAG					"BWR2"

//#define PLUGIN_UPDATE_URL			""

#define ERROR_NONE					0		// PrintToServer only
#define ERROR_LOG					(1<<0)	// use LogToFile
#define ERROR_BREAKF				(1<<1)	// use ThrowError
#define ERROR_BREAKN				(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP				(1<<3)	// use SetFailState
#define ERROR_NOPRINT				(1<<4)	// don't use PrintToServer

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"
#define SENTRYBUSTER_SND_INTRO		")mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define SENTRYBUSTER_SND_LOOP		"mvm/sentrybuster/mvm_sentrybuster_loop.wav"
#define SENTRYBUSTER_SND_SPIN		")mvm/sentrybuster/mvm_sentrybuster_spin.wav"
#define SENTRYBUSTER_SND_EXPLODE	")mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define GIANTROBOT_SND_DEPLOYING	"mvm/mvm_deploy_giant.wav"
#define SMALLROBOT_SND_DEPLOYING	"mvm/mvm_deploy_small.wav"
#define BOMB_SND_STAGEALERT			"mvm/mvm_warning.wav"

//spy laugh
#define SPYLAUGH1					"vo/mvm/norm/spy_mvm_laughshort02.mp3"
#define SPYLAUGH2					"vo/mvm/norm/spy_mvm_laughshort03.mp3"
#define SPYLAUGH3					"vo/mvm/norm/spy_mvm_laughshort05.mp3"

#define TF_DMG_AFTERBURN                    DMG_PREVENT_PHYSICS_FORCE | DMG_BURN


#define SENTRYBUSTER_DISTANCE		320.0 //original value 410.0 changed because particle wasn't matching up
#define SENTRYBUSTER_DAMAGE			10000
// old sentry buster dmg 99999
#define SENTRYBUSTER_CLASSVARIANT	99

#define TF_MVM_MAX_PLAYERS			10
#define TF_MVM_MAX_DEFENDERS		6

#define SPAWNTYPE_NORMAL			0
#define SPAWNTYPE_LOWER				1
#define SPAWNTYPE_GIANT				2
#define SPAWNTYPE_SNIPER			3
#define SPAWNTYPE_SPY				4
#define SPAWNTYPE_MAX				5

#define FLGIANTSCALE				1.75
#define FLSMALLGIANTSCALE			1.2

//The joincooldown bool
//new bool:JoinTeamCoolDown = true;
new Float:flNextChangeTeamBlu;
new BtouchedUpgradestation[MAXPLAYERS];
new bool:IsAttackClass[MAXPLAYERS];
new bool:CanAirSpawn[MAXPLAYERS];
new IsRobotLocked[MAXPLAYERS];

//Sentrybusterpickingbools
new bool:g_CanDispatchSentryBuster = false;
new bool:bEnableBuster;
new Handle:sm_tf2bwr_buster;
/////////GATEBOT
new bool:IsGateBotPlayer[MAXPLAYERS];
new bool:BvisIncluded;
////////////////////////////
////BOMB////////////////////
///////////////////////////
new bool:BombHidden[2069];
new bool:BombHasBeenDeployed;
//new bool:BuffTimerCreated;
new bool:CanTeleportBomb;
//new Handle:g_hBombHud;
new BombStage[MAXPLAYERS]; //update for multiple bombs
new Float:LastGateCapture;
new bool:IsMannhattan;
new bool:IsSmallMap;
new bool:MapDisallowParachute;
new bool:CanTeleportBomb1;
new bool:CanTeleportBomb2;
new bool:CanTeleportBomb3;
new String:BombName1[255];
new String:BombName2[255];
new String:BombName3[255];
new Bomb1;
new Bomb2;
new Bomb3;
new nGateCapture;
//new bool://SecondBombEnable;
/////////////////////////////////////////////
//////////TELEPORTER/////////////////////////


//////DEBUG/////
new bool:DebugGeneral = false;

///////////////

//new bool:bEngiCanBuildSecondTele[MAXPLAYERS];
#define TF_OBJECT_TELEPORTER	1
#define TF_TELEPORTER_ENTR		0
//new bool:AnnouncerQuiet;
new bool:GateStunEnabled;
new bool:teleportersound;
//new g_iMaxEntities;
#define TELEPORTER_SPAWN		")mvm/mvm_tele_deliver.wav"
new bool:BombPickup;
new Carrier;
new Float:flAnnounceDeploy;
/////////////////////////////////////////
//////////TELEPORTER/////////////////////
///////////////////////////////////////
new Handle:hAdminMenu = INVALID_HANDLE;
//////////////////
///SENTRY VISION//
//////////////////

new Handle:cvarOutlineEnable;
new Handle:cvarSentryVision;
///////////////////////////////////////
//////BOSS SYSTEM/////////////////////
////////////////////////////////////
#define TF2BWR_CONFIG 		"configs/tf2bwr/waveconfig.cfg"
new Handle:kvKey = INVALID_HANDLE;
new bool:BossEnabled;
new Float:fNextBossTime;
new String:BossList[255];
new Float:flBossWaitTime;
///////////////////////////////////////
//////BOSS SYSTEM/////////////////////
////////////////////////////////////
//fix bools
new bool:IsDecoy;
new bool:IsntStock[MAXPLAYERS]; //used just for giant blackbox soldier for sndfix
new Handle:g_hCustomTags;
new Handle: sv_tags;
new bool:g_bIgnoreNextTagChange = false;
//IsSpawnedSpawnroom[2069];

new CaseClamping = -1;//

//666 mode wip
new bool:Is666Mode;

#if !defined _tf2itemsinfo_included
new TF2ItemSlot = 8;
#endif

enum
{
	Spawn_Normal,
	Spawn_Lower,
	Spawn_Sniper,
	Spawn_Spy,
	Spawn_Giant,
	Spawn_Invasion,
	Spawn_Standard,
	Spawn_Bwr
};
enum
{
	BotSkill_Easy,
	BotSkill_Normal,
	BotSkill_Hard,
	BotSkill_Expert
};

enum RobotMode
{
	Robot_Stock,
	Robot_Normal,
	Robot_BigNormal,
	Robot_Giant,
	Robot_SentryBuster,
	Robot_Small,
	Robot_None
};
enum Effects
{
	Effect_None,
	Effect_AlwaysCrits,
	Effect_FullCharge,
	Effect_HoldFireUntilFullReload,
	Effect_Invisible,
	Effect_AlwaysInvisible,
	Effect_TeleportToHint,
	Effect_UseBossHealthBar,
	Effect_UseBossHealthBar_Effect_AlwaysCrits,
	Effect_AutoDisguise,
	Effect_AlwaysMiniCrits,
	Effect_TeamHealthRegen,

};
new TFClassType:iRobotClass[MAXPLAYERS];
new RobotMode:iRobotMode[MAXPLAYERS];
new Effects:iEffect[MAXPLAYERS];
new iRobotVariant[MAXPLAYERS];
new iSelectedVariant[MAXPLAYERS];
new bool:bInRespawn[MAXPLAYERS];
new bool:bFreezed[MAXPLAYERS];
new Float:flNextChangeTeam[MAXPLAYERS];
new Handle:hTimer_SentryBuster_Beep[MAXPLAYERS+1];
new bool:bSkipSpawnEventMsg[MAXPLAYERS+1];
new bool:bSkipInvAppEvent[MAXPLAYERS+1];
new bool:bStripItems[MAXPLAYERS+1];
//bomb handles
new Handle:g_hDeployTimer;
//new Handle:g_hBombBossHud;
new Handle:g_hbombs1[MAXPLAYERS];
new Handle:g_hbombs2[MAXPLAYERS];
new Handle:g_hbombs3[MAXPLAYERS];

new iDeployingBomb;
//new iDeployingAnim[][2] = {{120,2},{49,49},{163,149},{100,100},{82,82},{89,89},{96,93}};
new iFilterEnt[2];
new iLaserModel = -1;
new Float:flLastSentryBuster;
new Float:flLastAnnounce;

#if defined _tf2spawnitem_included
new bool:bUseTF2SI = false;
#endif

new Handle:hSDKEquipWearable = INVALID_HANDLE;
new Handle:hSDKRemoveWearable = INVALID_HANDLE;

new Handle:sm_tf2bwr_version1;
new Handle:sm_tf2bwr_logs;
new Handle:sm_tf2bwr_flag;
new Handle:sm_tf2bwr_freeze;
new Handle:sm_tf2bwr_respawn_red;
new Handle:sm_tf2bwr_respawn_blue;
new Handle:sm_tf2bwr_randomizer;
new Handle:sm_tf2bwr_autojoin;
#if defined _updater_included
new Handle:sm_tf2bwr_autoupdate;
#endif
new Handle:sm_tf2bwr_max_defenders;
new Handle:sm_tf2bwr_min_defenders;
new Handle:sm_tf2bwr_min_defenders4giants;
new Handle:sm_tf2bwr_restrict_ready;
new Handle:sm_tf2bwr_notifications;
new Handle:sm_tf2bwr_myloadouts;
new Handle:sm_tf2bwr_sentrybuster_debug;
new Handle:sm_tf2bwr_engineers;
new Handle:sm_tf2bwr_red_spawnprotection; // RED Spawn Protection
new Handle:sm_tf2bwr_red_spawnprotection_time; // How many seconds of protection
new Handle:sm_tf2bwr_redsp_attack_type; // Type of attack bonus
new Handle:sm_tf2bwr_redsp_defense_type; // Type of defense bonus
new bool:bREDSpawnProtection;
new Float:iREDSpawnProtectionTime;
new iREDSPAttackType;
new iREDSPDefenseType;
new bool:bUseLogs;
new bool:bFlagPickup;
new bool:bSpawnFreeze;
new iRespawnTimeRED;
new iRespawnTimeBLU;
new bool:bRandomizer;
new bool:bAutoJoin;
#if defined _updater_included
new bool:bAutoUpdate = true;
#endif
new iMaxDefenders;
new iMinDefenders;
new iMinDefenders4Giants;
new bool:bRestrictReady;
new bool:bNotifications;
new bool:bMyLoadouts;
new bool:bSentryBusterDebug;
new nMaxEngineers;
new iCurrentWave;
new iTotalWave;
new iEventPopFileType;
new bool:bWaveNumGiants = false;
new bool:bCanSpyTeleport;

public Plugin:myinfo = 
{
	name = "[TF2] Be With Robots 2",
	author = "Benoist3012,TehPlayer14,Anonymous Player", 
	description = "Allows players to play as robot on MvM mode.",
	version = PLUGIN_VERSION,
	url = "https://www.gamersalapro.com"
	//Old BWR2 Benoist3012
	//Original(Leonardo)
}

public OnPluginStart()
{
	//LoadTranslations("bwr.phrases.txt");

	g_hCustomTags = CreateArray(SVTAGSIZE);
	sv_tags = FindConVar("sv_tags");

	MyAddServerTag("BWR2");

	sm_tf2bwr_version1 = CreateConVar( "sm_tf2bwr_version1", PLUGIN_VERSION, "TF2 Be With Robots 2 version", FCVAR_NOTIFY|FCVAR_REPLICATED ); //|FCVAR_NOTIFY
	SetConVarString( sm_tf2bwr_version1, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2bwr_version1, OnConVarChanged_PluginVersion );
			
	CreateConVar("bwr2_version", PLUGIN_VERSION, "Be With Robots 2 plugin version. DO NOT CHANGE", FCVAR_NOTIFY|FCVAR_REPLICATED);		
	
	cvarOutlineEnable = CreateConVar("sm_tf2bwr_bulding_outline_enable", "1", "Outline Bulding?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	cvarSentryVision = CreateConVar("sm_tf2bwr_bulding_outline", "1", "Add up the number, Sentry:1,Dispenser:2,Teleporter:4");
	
	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	if( !StrEqual( strGameDir, "tf", false ) )
		Error( ERROR_BREAKP|ERROR_LOG, _, "THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!" );
	
	sm_tf2bwr_logs = CreateConVar( "sm_tf2bwr_logs", "0", "Enable debug logs on console?", FCVAR_NONE, true, 0.0, true, 1.0 ); //"1" disabled logs cos reasons
	HookConVarChange( sm_tf2bwr_logs, OnConVarChanged );
	
	sm_tf2bwr_flag = CreateConVar( "sm_tf2bwr_flag", "1", "Allow flag pick up by humans.", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_flag, OnConVarChanged );
	
	sm_tf2bwr_freeze = CreateConVar( "sm_tf2bwr_freeze", "1", "Disable movement for robohumans between rounds.", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_freeze, OnConVarChanged );
	
	sm_tf2bwr_respawn_red = CreateConVar( "sm_tf2bwr_respawn_red", "20", "Respawn fix for RED team. Set -1 to disable it.", FCVAR_NONE, true, -1.0 );
	HookConVarChange( sm_tf2bwr_respawn_red, OnConVarChanged );
	
	sm_tf2bwr_respawn_blue = CreateConVar( "sm_tf2bwr_respawn_blue", "3", "Respawn fix for BLU team. Set -1 to disable it.", FCVAR_NONE, true, -1.0 );
	HookConVarChange( sm_tf2bwr_respawn_blue, OnConVarChanged ); //broken
	
	sm_tf2bwr_randomizer = CreateConVar( "sm_tf2bwr_randomizer", "1", "Picking random class variants.", FCVAR_NONE );
	HookConVarChange( sm_tf2bwr_randomizer, OnConVarChanged );
	
	sm_tf2bwr_autojoin = CreateConVar( "sm_tf2bwr_autojoin", "1", "Handle autojoin command, trow player in RED or BLU team.", FCVAR_NONE );
	HookConVarChange( sm_tf2bwr_autojoin, OnConVarChanged );
	
#if defined _updater_included
	sm_tf2bwr_autoupdate = CreateConVar( "sm_tf2bwr_autoupdate", "1", "If Updater plugin installed, autoupdate plugin.", FCVAR_NONE );
	HookConVarChange( sm_tf2bwr_autoupdate, OnConVarChanged );
#endif
	
	sm_tf2bwr_max_defenders = CreateConVar( "sm_tf2bwr_max_defenders", "7", "Limit of RED team players. All other players will be thrown as BLU team. Set 0 to disable.", FCVAR_NONE, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_max_defenders, OnConVarChanged );
	
	sm_tf2bwr_min_defenders = CreateConVar( "sm_tf2bwr_min_defenders", "4", "Minimum number of defenders required to join BLU team. Set 0 to disable.", FCVAR_NONE, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_min_defenders, OnConVarChanged );
	
	sm_tf2bwr_min_defenders4giants = CreateConVar( "sm_tf2bwr_min_defenders4giants", "6", "Minimum number of defenders required to allow BLU team select giant robots. Set 0 to disable.", FCVAR_NONE, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_min_defenders4giants, OnConVarChanged );
	
	sm_tf2bwr_restrict_ready = CreateConVar( "sm_tf2bwr_restrict_ready", "1", "Block BLU team Ready status command.", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_restrict_ready, OnConVarChanged );
	
	sm_tf2bwr_notifications = CreateConVar( "sm_tf2bwr_notifications", "1", "Show/hide chat notifications.", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_notifications, OnConVarChanged );
	
	sm_tf2bwr_myloadouts = CreateConVar( "sm_tf2bwr_myloadouts", "0", "Allow human robots to select My Loadout variants.", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_myloadouts, OnConVarChanged );
	
	sm_tf2bwr_sentrybuster_debug = CreateConVar( "sm_tf2bwr_sentrybuster_debug", "0", "Beams: red - too far, yellow - didn't hit anything, green - valid target, blue - barrier/wall", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_sentrybuster_debug, OnConVarChanged );
	
	sm_tf2bwr_engineers = CreateConVar( "sm_tf2bwr_engineers", "2", "Allow/disallow engineers", FCVAR_NONE, true, -1.0, true, 10.0 ); //changed to 2 engineers
	HookConVarChange( sm_tf2bwr_engineers, OnConVarChanged );
	
	sm_tf2bwr_buster = CreateConVar( "sm_tf2bwr_buster", "1", "Enable or disable buster", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_buster, OnConVarChanged );
	
	sm_tf2bwr_red_spawnprotection = CreateConVar( "sm_tf2bwr_red_spawnprotection", "1", "Enable or disable spawn protection for RED team", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_red_spawnprotection, OnConVarChanged );
	
	sm_tf2bwr_red_spawnprotection_time = CreateConVar( "sm_tf2bwr_red_spawnprotection_time", "10.0", "How many seconds of spawn protection is given to RED players.", FCVAR_NONE, true, 1.0, true, 60.0 );
	HookConVarChange( sm_tf2bwr_red_spawnprotection_time, OnConVarChanged );
	
	sm_tf2bwr_redsp_attack_type = CreateConVar( "sm_tf2bwr_redsp_attack_type", "0", "RED spawn protection attack boost type, 0 for crits, 1 for minicrits", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_redsp_attack_type, OnConVarChanged );
	
	sm_tf2bwr_redsp_defense_type = CreateConVar( "sm_tf2bwr_redsp_defense_type", "0", "RED spawn protection defense boost type, 0 for uber, 1 for battalion's backup effect", FCVAR_NONE, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_redsp_defense_type, OnConVarChanged );
	
	AutoExecConfig(true, "be_with_robots");
	
	AddNormalSoundHook( NormalSoundHook );
	
	AddCommandListener( CommandListener_Drop , "dropitem" );
	AddCommandListener( CommandListener_Build , "build" );
	AddCommandListener( Command_JoinTeam, "jointeam" );
	AddCommandListener( Command_JoinTeam, "autoteam" );
	AddCommandListener( Command_JoinClass, "joinclass" );
	AddCommandListener( Command_JoinClass, "join_class" );
	AddCommandListener( Command_Taunt, "taunt" );
	AddCommandListener( Command_Taunt, "+taunt" );
	AddCommandListener( Command_Action, "+use_action_slot_item" );
	AddCommandListener( Command_Action, "+use_action_slot_item_server" );
	AddCommandListener( Command_BuyBack, "td_buyback" );
	AddCommandListener( Command_Kick, "kickid" );
	AddCommandListener( Command_Suicide, "kill" );
	AddCommandListener( Command_Suicide, "explode" );
	AddCommandListener( Command_Vote, "callvote" );
	AddCommandListener( Command_Ready, "tournament_player_readystate" );
	//AddCommandListener( Command_ChangeRoboClass, "changeclass" ); broken
	AddCommandListener( Command_Listener );
	
	if (sv_tags != INVALID_HANDLE)
	{
		HookConVarChange(sv_tags, OnSVTagsChange); //tags hook
	}
	decl String:strCmdDescr[128];
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display robot menu", PLUGIN_TAG );
	RegConsoleCmd( "sm_robotmenu", Command_ChangeClassMenu, strCmdDescr );

	//RegConsoleCmd( "sm_tauntc", Cmd_Taunt );
	RegConsoleCmd( "sm_robomenu", Command_ChangeClassMenu, strCmdDescr );
	RegConsoleCmd( "sm_rc", Command_ChangeClassMenu, strCmdDescr );
	RegConsoleCmd( "sm_roboclass", Command_ChangeClassMenu, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display help message", PLUGIN_TAG );
	RegConsoleCmd( "sm_robothelp", Command_ShowHelpMessage, strCmdDescr );
	RegConsoleCmd( "sm_robohelp", Command_ShowHelpMessage, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Join BLU team", PLUGIN_TAG );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_joinblue", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_joinblu", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_bwr", Command_JoinTeamBlue, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Join RED team", PLUGIN_TAG );
	RegConsoleCmd( "sm_joinred", Command_JoinTeamRed, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display player list", PLUGIN_TAG );
	RegConsoleCmd( "sm_bwr_players", Command_ShowPlayerList, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Move player to spectators", PLUGIN_TAG );
	RegAdminCmd( "sm_bwr_kick", Command_MoveToSpec, ADMFLAG_KICK, strCmdDescr );
	RegAdminCmd("sm_bwr_force", Command_ForceVariant, ADMFLAG_ROOT, "Force a specific robot variant");
	
	AddTempEntHook( "PlayerAnimEvent", TEHook_PlayerAnimEvent );
//	AddTempEntHook( "TFParticleEffect", TEHook_Particle );
	AddTempEntHook( "TFExplosion", TEHook_TFExplosion );
	
	HookEvent("teamplay_win_panel", Event_DefaultWinPanel, EventHookMode_Pre); //Pannel
	HookEvent( "player_team", OnPlayerChangeTeam );
	//HookEvent( "object_destroyed", OnObjectDestroyed, EventHookMode_Pre );
	HookEvent( "player_changeclass", OnPlayerChangeClass );
	HookEvent( "player_death", OnPlayerDeath );
	HookEvent( "player_death", OnPlayerDeathPre, EventHookMode_Pre ); // cash
	HookEvent( "player_spawn", OnPlayerSpawnPre, EventHookMode_Pre );
	HookEvent( "player_spawn", OnPlayerSpawn );
	HookEvent( "post_inventory_application", OnPostInventoryApplication );
	HookEvent( "teamplay_round_win", OnRoundWinPre, EventHookMode_Pre );
	HookEvent( "teamplay_round_start", OnRoundStartPre, EventHookMode_Pre );
	HookEvent("teamplay_flag_event", EventHook_FlagStuff);
	HookEvent("teamplay_flag_event", EventHook_FlagStuff2);
	HookEntityOutput("item_teamflag", "OnReturn", OnBombReset);
	HookEntityOutput("item_teamflag", "OnPickupTeam2", OnBombPickup);
	HookEntityOutput("team_control_point", "OnCapTeam2", OnGateCapture);
	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Pre);
	//HookEvent("player_builtobject", EventHook_tele);

	//g_iMaxEntities = GetMaxEntities();
	
	/////BOSS SYSTEM
	HookEvent("mvm_begin_wave", WaveStart);
	HookEvent("mvm_wave_complete", WaveEnd);
	
	// Extra Hooks
	HookEvent("mvm_wave_failed", WaveFailed);
	HookEvent("mvm_mission_complete", MVMVictory);
	

	decl String:strFilePath[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, strFilePath, sizeof(strFilePath), "gamedata/tf2items.randomizer.txt" );
	if( FileExists( strFilePath ) )
	{
		new Handle:hGameConf = LoadGameConfigFile( "tf2items.randomizer" );
		if( hGameConf != INVALID_HANDLE )
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable" );
			PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
			hSDKEquipWearable = EndPrepSDKCall();
			if( hSDKEquipWearable == INVALID_HANDLE )
			{
				// Old gamedata
				StartPrepSDKCall(SDKCall_Player);
				PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "EquipWearable" );
				PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
				hSDKEquipWearable = EndPrepSDKCall();
			}
			
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "CTFPlayer::RemoveWearable" );
			PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
			hSDKRemoveWearable = EndPrepSDKCall();
			if( hSDKRemoveWearable == INVALID_HANDLE )
			{
				// Old gamedata
				StartPrepSDKCall(SDKCall_Player);
				PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "RemoveWearable" );
				PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
				hSDKRemoveWearable = EndPrepSDKCall();
			}
			
			CloseHandle( hGameConf );
		}
	}
	
	iDeployingBomb = -1;
	
	for( new i = 0; i < MAXPLAYERS; i++ )
	{
		ResetData( i, true );
		if( IsValidClient( i ) )
		{
			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamage );
//			if( !IsFakeClient( i ) && GetClientTeam( i ) == _:TFTeam_Blue && IsPlayerAlive( i ) )
//				TF2_RespawnPlayer( i );
		}
	}

	//CreateTimer( 10.0, Timer_AutoBalance, 0, TIMER_REPEAT );
	
#if defined _tf2spawnitem_included
	bUseTF2SI = LibraryExists( "tf2spawnitem" );
#endif

	ServerCommand("sm_cvar host_thread_mode 2");

	CreateTimer(901.0, Timer_Announce, _, TIMER_REPEAT);
	CreateTimer(105.0, Timer_Announce2, _, TIMER_REPEAT);
}
public OnSVTagsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (g_bIgnoreNextTagChange)
	{
		// we fired this callback, no need to reapply tags
		return;
	}
	
	// reapply each custom tag
	new cnt = GetArraySize(g_hCustomTags);
	for (new i = 0; i < cnt; i++)
	{
		decl String:tag[SVTAGSIZE];
		GetArrayString(g_hCustomTags, i, tag, sizeof(tag));
		MyAddServerTag(tag);
	}
}

public Action:Timer_Announce(Handle:hTimer)
{
	PrintToChatAll("[BWR 2] Official group: http://steamcommunity.com/groups/TF2BWRR");
}
public Action:Timer_Announce2(Handle:hTimer)
{
	PrintToChatAll("You're playing %s Version %s",PLUGIN_TAG, PLUGIN_VERSION);
	PrintToChatAll("To play as a robot type !joinblu");
	PrintToChatAll("To see important commands use !robohelp");
}
public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidRobot(i) )
		{
			if( GetTeamPlayerCount( _:TFTeam_Red ) >= TF_MVM_MAX_DEFENDERS )
				Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( i ) );
			else
			{
				Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( i ) );
				if( IsPlayerAlive(i) && bFreezed[i] )
				{
					SetEntityFlags( i, GetEntityFlags(i) & ~FL_ATCONTROLS );
					TF2_RegeneratePlayer( i );
				}
			}
		}
}

public OnLibraryAdded( const String:strLibrary[] )
{
#if defined _updater_included
	if( StrEqual( strLibrary, "updater", false ) && bAutoUpdate )
		Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
#if defined _tf2spawnitem_included
	if( StrEqual( strLibrary, "tf2spawnitem", false ) )
		bUseTF2SI = true;
#endif
}

public OnConfigsExecuted()
{
	bUseLogs = GetConVarBool( sm_tf2bwr_logs );
	bFlagPickup = GetConVarBool( sm_tf2bwr_flag );
	bSpawnFreeze = GetConVarBool( sm_tf2bwr_freeze );
	iRespawnTimeRED = GetConVarInt( sm_tf2bwr_respawn_red );
	iRespawnTimeBLU = GetConVarInt( sm_tf2bwr_respawn_blue );
	bAutoJoin = GetConVarBool( sm_tf2bwr_autojoin );
	bRandomizer = GetConVarBool( sm_tf2bwr_randomizer );
	bEnableBuster = GetConVarBool( sm_tf2bwr_buster );
	bREDSpawnProtection = GetConVarBool ( sm_tf2bwr_red_spawnprotection );
	iREDSpawnProtectionTime = GetConVarFloat ( sm_tf2bwr_red_spawnprotection_time );
	iREDSPAttackType = GetConVarInt( sm_tf2bwr_redsp_attack_type );
	iREDSPDefenseType = GetConVarInt( sm_tf2bwr_redsp_defense_type );
	
#if defined _updater_included
	bAutoUpdate = GetConVarBool( sm_tf2bwr_autoupdate );
	if( LibraryExists("updater") )
	{
		if( bAutoUpdate )
			Updater_AddPlugin( PLUGIN_UPDATE_URL );
		else
			Updater_RemovePlugin();
	}
#endif
	iMaxDefenders = GetConVarInt( sm_tf2bwr_max_defenders );
	iMinDefenders = GetConVarInt( sm_tf2bwr_min_defenders );
	iMinDefenders4Giants = GetConVarInt( sm_tf2bwr_min_defenders4giants );
	bRestrictReady = GetConVarBool( sm_tf2bwr_restrict_ready );
	bNotifications = GetConVarBool( sm_tf2bwr_notifications );
	bMyLoadouts = GetConVarBool( sm_tf2bwr_myloadouts );
	bSentryBusterDebug = GetConVarBool( sm_tf2bwr_sentrybuster_debug );
	nMaxEngineers = GetConVarBool( sm_tf2bwr_engineers );
}
public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public OnMapStart()
{
	//CreateExtraSpawnAreas();
	Is666Mode = false;
	IsMannhattan = false;
	IsDecoy = false;
	IsSmallMap = false;
	MapDisallowParachute = false;
	if( IsMvM( true ) )
	{
		//ServerCommand("sm plugins unload betherobot");
		//ServerCommand("sv_tags %s", PLUGIN_VERSION);
		//ServerCommand("sm_rcon sv_tags %s", PLUGIN_TAG);

		new iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "item_teamflag") ) != -1 )
		{
			SDKHook( iEnt, SDKHook_StartTouch, OnFlagTouch );
			SDKHook( iEnt, SDKHook_Touch, OnFlagTouch );
//			SDKHook( iEnt, SDKHook_EndTouch, OnFlagEndTouch );
		}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_respawnroom") ) != -1 )
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
				SDKHook( iEnt, SDKHook_Touch, OnSpawnStartTouch );
			//SDKHook( iEnt, SDKHook_StartTouch, OnSpawnStartTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnSpawnEndTouch );
		}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_capturezone") ) != -1 )
			if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SDKHook( iEnt, SDKHook_Touch, OnCapZoneTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnCapZoneEndTouch );
			}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "trigger_timer_door") ) != -1 )
		{
			if ( IsMannhattan == true ) // fix for community maps
			{
			SDKHook( iEnt, SDKHook_Touch, OnTriggerGateTouch );
			SDKHook( iEnt, SDKHook_StartTouch, OnTriggerGateTouch );
			}
		}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_upgradestation") ) != -1 )
		{
			SDKHook( iEnt, SDKHook_StartTouch, OnTriggerUpgradestationtouch );
		}
		iLaserModel = PrecacheModel("materials/sprites/laserbeam.vmt");
		
		//flLastSentryBuster = 0.0;
		flLastAnnounce = 0.0;
		
		teleportersound = true;
		
		decl String:strAnnounceLine[PLATFORM_MAX_PATH];
		for( new a = 1; a <= 7; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts0%i.mp3", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
		for( new a = 1; a <= 4; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_spy_spawn0%i.mp3", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
		for( new a = 8; a <= 9; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts0%i.mp3", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
		for( new a = 10; a <= 11; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts%i.mp3", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
		//////////////Teleporter
		for(new a = 1; a <= 5; a++)
		{
			Format(strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_eng_tele_activated0%i.mp3", a);
			PrecacheSnd(strAnnounceLine, _, true );
		}
		for(new a = 2; a <= 3; a++)
		{
			Format(strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_engbot_arrive0%i.mp3", a);
			PrecacheSnd(strAnnounceLine, _, true );
		}
		/////////////////STEP unused
		//for(new a = 1; a <= 18; a++)
		//{
		//	Format( strAnnounceLine, sizeof( strAnnounceLine ), "mvm/player/footsteps/robostep_%s%i.wav", ( a < 10 ? "0" : "" ), a );
		//	PrecacheSound(strAnnounceLine);
		//}
		//for(new a = 1; a <= 18; a++)
		//{
		//	Format( strAnnounceLine, sizeof( strAnnounceLine ), "mvm/giant_common/giant_common_step_%s%i.wav", ( a < 10 ? "0" : "" ), a );
		//	PrecacheSound(strAnnounceLine);
		//} unused
		for(new a = 1; a <= 12; a++)
		{
			Format( strAnnounceLine, sizeof( strAnnounceLine ), "vo/mvm_wave_lose%s%i.mp3", ( a < 10 ? "0" : "" ), a );
			PrecacheSound(strAnnounceLine);
		}
		////////GLOW
		//for(new a = 0; a < 2069; a++)
		//{
		//	WasCarried[a] = false;
		//	ObjGlow[a] = -1;
		//	ObjTimer[a] = INVALID_HANDLE;
		//}
		//CreateTimer(3.0, Particle_Teleporter);
		decl String:file[128];
		BuildPath(Path_SM, file, sizeof(file), TF2BWR_CONFIG);
		kvKey = CreateKeyValues("tf2bwr");
		if(!FileToKeyValues(kvKey, file)) 
		{
			SetFailState("Could not load file %s.", file);
		}
		decl String:map[38];
		GetCurrentMap(map,sizeof(map));
		if (StrEqual(map, "mvm_mannhattan"))
		{
			IsMannhattan = true;
		}
		if (StrEqual(map, "mvm_decoy"))
		{
			IsDecoy = true;
		}
/* 		if (StrEqual(map, "mvm_ghost_town"))
		{
			Is666Mode = true;
		}
		if (StrEqual(map, "mvm_decay_rc1"))
		{
			Is666Mode = true;
		} */
		if (StrEqual(map, "mvm_2fort_b1_3"))
		{
			IsSmallMap = true;
		}
		if (StrEqual(map, "mvm_darkcells"))
		{
			IsSmallMap = true;
			MapDisallowParachute = true;
		}
		ReleaseSpawntimefixblu();
		
	}
}
stock ReleaseSpawntimefixblu()
{
	new TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	new Float:RespawnTimeBlueValue = 0.1;
	SetVariantFloat(RespawnTimeBlueValue);
	AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
}
public OnMapEnd()
{
	if( IsMvM( true ) )
	{
		BossEnabled = false;
		CloseHandle(kvKey);
	}
	for(new a = 0; a < 2069; a++)
	{
		//WasCarried[a] = false;
		//if(ObjGlow[a] != -1)
		//	if(IsValidEntity(ObjGlow[a]))
		//		AcceptEntityInput(ObjGlow[a],"Kill");
		//if(ObjTimer[a] != INVALID_HANDLE)
		//	CloseHandle(ObjTimer[a]);
		//ObjGlow[a] = -1;
		//ObjTimer[a] = INVALID_HANDLE;
	}
	for (new i = 1; i <= MaxClients; i++)
		BtouchedUpgradestation[i] = false;
}

stock StopAllBlueBuilding()
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
	{
		new team = GetEntProp(ent, Prop_Data, "m_iTeamNum");
		if(team == _:TFTeam_Blue)
			stopBuilding(ent);
	}
	while ((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)
	{
		new team = GetEntProp(ent, Prop_Data, "m_iTeamNum");
		if(team == _:TFTeam_Blue)
			stopBuilding(ent);
	}
}

stock stopBuilding(ent)
{
	//DispatchKeyValue(ent, "defaultupgrade", "2");
	AcceptEntityInput(ent,"Disable");
	//SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
	CreateTimer( 22.0, Timer_startBuilding, ent );
}

public Action:Timer_startBuilding( Handle:hTimer, any:ent )
{
	GateStunEnabled = false;
	//AcceptEntityInput(ent,"Enable");
	//DispatchKeyValue(ent, "defaultupgrade", "2");
	SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
	new String:strClassname[64];
	GetEdictClassname( ent, strClassname, sizeof(strClassname) ); 
	if( StrEqual( strClassname, "obj_dispenser", false ) )
		SetEntProp(ent, Prop_Send, "m_iState", 0);
	return Plugin_Continue;
}
//
stock GiveSpawnProtection(i, Float:time)
{
	TF2_AddCondition(i, TFCond_UberchargedHidden, time);
	TF2_AddCondition(i, TFCond_UberchargeFading, time);
	new TFClassType:iClass = TF2_GetPlayerClass( i );
	if( iClass != TFClass_Heavy )
		TF2_AddCondition(i, TFCond_Ubercharged, time);
}

public OnGameFrame()
{
	if( !IsMvM() )
		return;
	
	new i, iFlag = -1, nTeamNum;
	while( ( iFlag = FindEntityByClassname( iFlag, "item_teamflag" ) ) != -1 )
	{
		i = GetEntPropEnt( iFlag, Prop_Send, "m_hOwnerEntity" );
		if( IsValidClient(i) && ( !bFlagPickup || GetClientTeam(i) != _:TFTeam_Blue ) )
			AcceptEntityInput( iFlag, "ForceReset" );
	}
	new iEFlags;
	for( i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i) )
		{
			if(!IsGateBotPlayer[i] && nGateCapture != 2 && IsMannhattan)
			{
				new hat = -1;
				while((hat=FindEntityByClassname(hat, "tf_wearable"))!=INVALID_ENT_REFERENCE)
				{
					new Owner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
					if (IsValidClient(Owner) && GetClientTeam(Owner) == _:TFTeam_Blue)
					{
						if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1057 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1063 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1062 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1065 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1058 ||GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1059 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1061 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1064 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1060 ) //missing 1060 heavy fixed
							IsGateBotPlayer[Owner] = true;
						else
							IsGateBotPlayer[Owner] = false;
					}
				}	
			}
			//if(iDeployingBomb == i)
			//	SetEntPropFloat(i, Prop_Data, "m_flCycle", -1.2);
			
			nTeamNum = GetClientTeam(i);
			
			iFlag = GetEntPropEnt( i, Prop_Send, "m_hItem" );
			if( !IsValidEdict( iFlag ) )
				iFlag = 0;
			
			//if( IsFakeClient(i) )
			//	continue;
			
			// blue/yellow eyes
			//SetEntProp( i, Prop_Send, "m_nBotSkill", BotSkill_Easy );
			//SetEntProp( i, Prop_Send, "m_bIsMiniBoss", _:false );
			if( nTeamNum == _:TFTeam_Blue )
			{
				if( iRobotMode[i] == Robot_Giant || iRobotMode[i] == Robot_SentryBuster ) // || iRobotMode[i] == Robot_BigNormal )
				{
					SetEntProp( i, Prop_Send, "m_bIsMiniBoss", _:true );
				}
				//if( GameRules_GetRoundState() == RoundState_BetweenRounds )
				//{
				//	GiveSpawnProtection(i);
				//}
					
				//else if( iRobotMode[i] == Robot_Stock )
				//	SetEntProp( i, Prop_Send, "m_nBotSkill", BotSkill_Expert );
			}
			if( nTeamNum != _:TFTeam_Blue )
			{
				if( iFlag )
					AcceptEntityInput( iFlag, "ForceDrop" );
				continue;
			}
			else if( iFlag && ( !bFlagPickup || iRobotMode[i] == Robot_SentryBuster ) )
				AcceptEntityInput( iFlag, "ForceDrop" );
			
			SetEntProp( i, Prop_Send, "m_bIsReadyToHighFive", 0 );
			if(IsValidRobot(i) && bInRespawn[i])
			{
				GiveSpawnProtection(i, 0.255);
				//TF2_AddCondition(i, TFCond_UberchargedHidden, 1.4);
				//TF2_AddCondition(i, TFCond_UberchargeFading, 1.4);
			}
/*		if(bool:GetEntProp(i, Prop_Send, "m_bGlowEnabled") == true && IsValidRobot(i))
			if(IsValidRobot(i) && iRobotMode[i] != Robot_Giant && !TF2_IsPlayerInCondition( i, TFCond_UberchargedHidden )) //i == Carrier
			{
				new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
				if(BombStage[i] == 0)
				{
					if (g_hbombs1[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs1[i]);
						g_hbombs1[i] = INVALID_HANDLE;
					}
					if (g_hbombs2[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs2[i]);
						g_hbombs2[i] = INVALID_HANDLE;
					}
					if (g_hbombs3[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs3[i]);
						g_hbombs3[i] = INVALID_HANDLE;
					}
				}
				if(BombStage[i] == 1)
				{
					if (g_hbombs2[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs2[i]);
						g_hbombs2[i] = INVALID_HANDLE;
					}
					if (g_hbombs3[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs3[i]);
						g_hbombs3[i] = INVALID_HANDLE;
					}
					new Float:CurrentTime = GetGameTime();
					new Float:NextTime = CurrentTime+15.0;
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
					g_hbombs2[i] = CreateTimer(20.0, Timer_bombst2, i);
					g_hbombs3[i] = CreateTimer(35.0, Timer_bombst3, i);
				}
				if(BombStage[i] == 2)
				{
					if (g_hbombs3[i] != INVALID_HANDLE)
					{
						CloseHandle(g_hbombs3[i]);
						g_hbombs3[i] = INVALID_HANDLE;
					}
					new Float:CurrentTime = GetGameTime();
					new Float:NextTime = CurrentTime+15.0;
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
					g_hbombs3[i] = CreateTimer(35.0, Timer_bombst3, i);
				}
			}
			*/
			//if( iEffect[i] == Effect_AlwaysCrits )
				//TF2_AddCondition( i, TFCond_CritOnFlagCapture, 0.125 ); //old CritOnKill
			else if( iEffect[i] == Effect_HoldFireUntilFullReload )
			{
				IsntStock[i] = true;
				
//				new weaponBLACKBOX = GetPlayerWeaponSlot(i, 0);
//				if(GetEntProp(weaponBLACKBOX, Prop_Send, "m_iClip1") == 3)
//				if(GetEntProp(weaponBLACKBOX, Prop_Send, "m_iClip1") < 3)//3 && !CreatedRelodTimer[i])
//					SetEntPropFloat(weaponBLACKBOX, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.3);
					
				//New Blocking soon
			}
			else if( iEffect[i] == Effect_AlwaysInvisible )
				SetEntPropFloat( i, Prop_Send, "m_flCloakMeter", 100.0 );
			else if( iEffect[i] == Effect_UseBossHealthBar || iEffect[i] == Effect_UseBossHealthBar_Effect_AlwaysCrits )
			{
				SetEntProp(i, Prop_Send, "m_bUseBossHealthBar", true);
				fNextBossTime = GetEngineTime();
/* 				if(iEffect[i] == Effect_UseBossHealthBar_Effect_AlwaysCrits)
					iEffect[i] = Effect_AlwaysCrits;
				else
					iEffect[i] = Effect_None; */
			}
			iEFlags = GetEntityFlags(i);
			if( iDeployingBomb == i || bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds ) //
			{
				SetEntPropFloat( i, Prop_Send, "m_flMaxspeed", 1.0 );
				iEFlags |= FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
				bFreezed[i] = true;
			}
			else if( bFreezed[i] )
			{
				iEFlags &= ~FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
//				iHealth = GetClientHealth( i );
//				TF2_RegeneratePlayer( i );
//				SetEntityHealth( i, iHealth );
				bFreezed[i] = false;
			}
		}
}

public Action:Timer_RemoveStun( Handle:hTimer)
{
	GateStunEnabled = false;
	/*for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
		{
			TF2_RemoveCondition(i, TFCond_Dazed);
			TF2_RemoveCondition(i, TFCond_MVMBotRadiowave);
		}
	}*/
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
		{
			if(!IsPlayerAlive(i))
				TF2_RespawnPlayer(i);
			BlockRespawnclients(true);
		}
	}
	new i = -1;
	while ((i = FindEntityByClassname(i, "trigger_multiple")) != -1)
	{
		if(IsValidEntity(i))
		{
			decl String:strName[50];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "gate2_door_alarm") == 0)
			{
				if(nGateCapture == 1)
					AcceptEntityInput( i, "Enable" );
				if(nGateCapture == 2)
					AcceptEntityInput( i, "Disable" );
				break;
			}
		}
	}
}

public OnClientPutInServer( iClient )
{
	ResetData( iClient, true );
	if( IsValidClient( iClient ) )
		SDKHook( iClient, SDKHook_OnTakeDamage, OnTakeDamage );
}
public OnClientDisconnect( iClient )
{
	BtouchedUpgradestation[iClient] = false;
	IsRobotLocked[iClient] = false;
	ResetData( iClient, true );
	DestroyBuildings( iClient );
	FixSounds( iClient );
}
stock Entity_GetClassName(entity, String:buffer[], size)
{
	if(IsValidEntity(entity))
	{
		GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);
	
		if (buffer[0] == '\0') 	
		{
			return false;
		}
	
		return true;
	}
	return false;
}

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	new String:sEnt[255];
	Entity_GetClassName(iEntity,sEnt,sizeof(sEnt));
	if( StrEqual( strClassname, "obj_sentrygun", false ) || StrEqual( strClassname, "obj_dispenser", false ) || StrEqual( strClassname, "obj_teleporter", false ) )
		SDKHook( iEntity, SDKHook_OnTakeDamage, OnBuildingTakeDamage );
	else if( StrEqual( strClassname, "item_teamflag", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
		SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
//		SDKHook( iEntity, SDKHook_EndTouch, OnFlagEndTouch );
	}
	else if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		//if( GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		//{
			//if(!IsSpawnedSpawnroom[iEntity])
			//{
			//SDKHook( iEntity, SDKHook_StartTouch, OnSpawnStartTouch );
			SDKHook( iEntity, SDKHook_Touch, OnSpawnStartTouch );
			SDKHook( iEntity, SDKHook_EndTouch, OnSpawnEndTouch );
			//}
		//}
	}
	else if( StrEqual( strClassname, "func_capturezone", false ))
	{
		SDKHook( iEntity, SDKHook_Touch, OnCapZoneTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnCapZoneEndTouch );
	}
	else if( StrEqual( strClassname, "trigger_timer_door", false ) && IsMannhattan == true )
	{
		SDKHook( iEntity, SDKHook_Touch, OnTriggerGateTouch );
		SDKHook( iEntity, SDKHook_StartTouch, OnTriggerGateTouch );
	}
	/*else if( StrEqual( strClassname, "trigger_multiple", false ) )
	{
		decl String:Name[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", Name, sizeof(Name));
		if(strcmp(Name, "gate1_door_alarm") == 0)
		{
			//SDKHook( iEntity, SDKHook_Touch, OnTriggerAlarmTouch );
			SDKHook( iEntity, SDKHook_StartTouch, OnTriggerAlarmTouch );
		}
		if(strcmp(Name, "gate2_door_alarm") == 0)
		{
			//SDKHook( iEntity, SDKHook_Touch, OnTriggerAlarmTouch );
			SDKHook( iEntity, SDKHook_StartTouch, OnTriggerAlarmTouch );
		}
	}*/
	if( StrEqual( strClassname, "obj_sentrygun", false ) )
	{
		//SDKHook( iEntity, SDKHook_OnTakeDamage, OnSentryTakeDamage ); not needed anymore
		//PrintToChatAll("UPGRADE SET");
		CreateTimer( 0.6, Timer_SetInstantLevel3, iEntity ); //0.6
	}
//	if( StrEqual( strClassname, "obj_dispenser", false ) )
//	{
//		if( StrEqual( strClassname, "obj_dispenser", false ) )
//			CreateTimer( 0.6, Timer_SetInstantLevel3, iEntity );
//	}
	//if( StrEqual( strClassname, "entity_revive_marker", false ) )
	if (StrEqual(sEnt, "entity_revive_marker"))
	{
		if( StrEqual( strClassname, "entity_revive_marker", false ) )
			CreateTimer(0.1, FindReviveMaker, iEntity);
	}
	new Shield = -1;
	if(StrEqual( strClassname, "entity_medigun_shield", false ) ) 
	{
		if(IsValidEntity(Shield))
		{
			new i = GetEntPropEnt( Shield, Prop_Send, "m_hOwnerEntity" );
			if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue  )
			{
				SetVariantInt(1);
				AcceptEntityInput(Shield, "Skin" );
			}
		}
	}
/*	if (StrEqual(sEnt, "info_particle_system"))
	{
		CreateTimer(0.3, SayParticleStrng, iEntity);
	}*/
	//PrintToChatAll("Classname is: %s", strClassname);
}

stock bool:IsThereAnyRedEngineer()
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if(TF2_GetPlayerClass( i ) == TFClass_Engineer && GetClientTeam(i) == _:TFTeam_Red )
//		PrintToChatAll("Found engineer");
		return true;
	}
	return false;
}
stock bool:IsThereAnyRedSentry()
{
	new iSentry = -1;
	while( ( iSentry = FindEntityByClassname( iSentry, "obj_sentrygun" ) ) != -1 )
	{
		//PrintToChatAll("Looped a sentry.");
		if( GetEntProp( iSentry, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Red)
			return true;
	}
	return false;
}

/////////////////////////////////////////
/////////REMOVE ENTITY REVIVE MAKER/////
////////////////////////////////////////
public Action:FindReviveMaker(Handle:Timer, any:iEntity)
{
//	new ReviveMakers = -1;
//	if((ReviveMakers = FindEntityByClassname(ReviveMakers,"entity_revive_marker")) != -1)
	if(IsValidEdict(iEntity))
	{
		decl String:strClassname[256];
		GetEdictClassname( iEntity, strClassname, sizeof(strClassname) );
		if( !StrEqual( strClassname, "entity_revive_marker", false ) )
			return Plugin_Stop;
		new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwner");
		if(GetClientTeam(client) == _:TFTeam_Blue)
		{
			AcceptEntityInput(iEntity,"Kill");
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Continue;
	}
}
public Action:Command_JoinTeam( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	decl String:strTeam[16];
	if( nArgs > 0 )
		GetCmdArg( 1, strTeam, sizeof(strTeam) );
	
	new TFTeam:iTeam = TFTeam_Unassigned;
	if( StrEqual( strTeam, "red", false ) )
		iTeam = TFTeam_Red;
	else if( StrEqual( strTeam, "blue", false ) )
		iTeam = TFTeam_Blue;
	else if( StrEqual( strTeam, "spectate", false ) || StrEqual( strTeam, "spectator", false ) )
		iTeam = TFTeam_Spectator;
	else if( !StrEqual( strCommand, "autoteam", false ) )
		return Plugin_Continue;
	
	new Float:flCalmDown = flNextChangeTeam[iClient] - GetGameTime();
	if( flCalmDown > 0.0 && iTeam > TFTeam_Spectator )
	{
		CPrintToChat( iClient, "{red}* Please wait for{yellow} %0.1f {red}seconds before joining team.", flCalmDown );
		return Plugin_Handled;
	}
	
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bACanJoinRED = CheckCommandAccess( iClient, "tf2bwr_joinred", 0, true );
	new bool:bACanJoinBLU = CheckCommandAccess( iClient, "tf2bwr_joinblue", 0, true );
	new bool:bCanJoinRED = ( iMaxDefenders <= 0 || iNumDefenders < iMaxDefenders ) && bACanJoinRED;
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders >= iMinDefenders );//iNumDefenders >= iMinDefenders
	new bool:bCanJoinBLU = ( bEnoughRED && ( iMaxDefenders <= 0 || iNumHumanRobots < ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) ) ) && bACanJoinBLU;
	
	if( iTeam == TFTeam_Red && !bACanJoinRED )
		PrintToChat( iClient, "* You don't have persmission to join RED team." );
	else if( iTeam == TFTeam_Blue && !bACanJoinBLU )
		PrintToChat( iClient, "* You don't have persmission to join BLU team." );
	
	if( iTeam == TFTeam_Unassigned || StrEqual( strCommand, "autoteam", false ) || StrEqual( strTeam, "auto", false ) )
	{
		if( !bAutoJoin )
			iTeam = TFTeam_Red;
		else
		{
			if( bCanJoinBLU && bCanJoinRED )
			{
				if( ( GetURandomInt() % 2 ) == 0 )
					iTeam = TFTeam_Blue;
				else
					iTeam = TFTeam_Red;
			}
			else if( !bCanJoinBLU && bCanJoinRED )
				iTeam = TFTeam_Red;
			else if( bCanJoinBLU && !bCanJoinRED )
				iTeam = TFTeam_Blue;
			else //if( !bCanJoinBLU && !bCanJoinRED )
				iTeam = TFTeam_Spectator;
		}
	}
	if( iTeam == TFTeam_Spectator )
	{
		CreateTimer( 0.0, Timer_TurnSpec, GetClientUserId( iClient ) );
		return Plugin_Handled;
	}
	else if( iTeam == TFTeam_Blue ) // !joinblu
	{
		if( TFTeam:GetClientTeam( iClient ) == TFTeam_Blue )
			return Plugin_Handled;
		//if(BtouchedUpgradestation[iClient])
		//{
		//	PrintToChat( iClient, "You've used upgrade station! You can't join robots!" );
		//	return Plugin_Handled;
		//}
/* 		if(IsRobotLocked[iClient])
		{
			CPrintToChat( iClient, "{fullblue}[BWR2] {yellow}You are locked and cannot join {blue}BLU{yellow}." );
			return Plugin_Handled;
		} */
		if(GetGameTime() - flNextChangeTeamBlu < 0.1)
		{
			CPrintToChat( iClient, "{fullblue}[BWR2] {red} Join BLU is currently in cooldown, please wait." );
			return Plugin_Handled;
		}
		if (CheckCommandAccess(iClient, "bwr_admin",  ADMFLAG_ROOT))
		{
			CreateTimer( 0.3, Timer_TurnRobot, GetClientUserId( iClient ) );
			LogAction(iClient, -1, "[BWR2] %L Joined BLU team (admin)", iClient );
			return Plugin_Stop;
		}
		if(GetClientTeam(iClient) == _:TFTeam_Spectator)
		{
			CPrintToChatAll("{yellow}[BWR2] {cyan}You must join {red}RED{cyan} before you can join BLU.", iClient);
			return Plugin_Handled;
		}
		if(GameRules_GetRoundState() == RoundState_RoundRunning && iTotalWave >= 2)
		{
			CPrintToChat( iClient, "{fullblue}[BWR2] {darkorange} You can't join {blue}BLU{darkorange} while the wave is in progress." );
			EmitSoundToClient( iClient, "vo/heavy_no02.mp3", iClient, SNDCHAN_VOICE , SNDLEVEL_NORMAL , SND_NOFLAGS , SNDVOL_NORMAL , SNDPITCH_NORMAL );
			return Plugin_Handled;
		}
		if( !bCanJoinBLU )
		{
			if( !bEnoughRED )
			{
				CPrintToChat( iClient, "{orange}Not enough {red}RED {orange}team players to join {blue}BLU {orange}team." );
				EmitSoundToClient( iClient, "vo/heavy_no02.mp3", iClient, SNDCHAN_VOICE , SNDLEVEL_NORMAL , SND_NOFLAGS , SNDVOL_NORMAL , SNDPITCH_NORMAL );
				return Plugin_Handled;
			}
			else
			{
				if (CheckCommandAccess(iClient, "bwr_premium",  ADMFLAG_CUSTOM1))
				{
					PrintToChat( iClient, "[BWR2] Welcome back!" );
					// They have the "bwr_premium" override or the generic admin flag if no override exist
					for( new i = 1; i <= MaxClients; i++ )
						if( IsValidClient(i) && !IsFakeClient(i) &&  GetClientTeam(i) == _:TFTeam_Blue && !CheckCommandAccess(i, "bwr_premium",  ADMFLAG_CUSTOM1))
						{
							FakeClientCommand(i, "jointeam spectate" );
							PrintToChat(i, "[BWR2] You were kicked from blue because premium member joined!" );
							PrintToChat(i, "[BWR2] Get premium to get immunity and join in anytime!" );
							CreateTimer( 0.1, Timerjoinblupremium, iClient );					
							return Plugin_Stop;
						}
				}
				else
				{
					CPrintToChat( iClient, "{yellow}There's no free slots in {blue}BLU {yellow}team." );
					return Plugin_Handled;
				}
			}
		}
		//if( !JoinTeamCoolDown )
		//{
		//	PrintToChat( iClient, "[BWR 2] You can't join robots now" );
		//	return Plugin_Handled;
		//}
//		StripWeapon( iClient );
//		CreateTimer( 0.1, Timer_Stripweapon, GetClientUserId( iClient ) );
		CreateTimer( 0.3, Timer_TurnRobot, GetClientUserId( iClient ) );
		LogAction(iClient, -1, "[BWR2] %L Joined BLU team", iClient );
		CPrintToChatAll("{yellow}[BWR2] {cyan}%N {white} joined BLU team.", iClient);
		return Plugin_Handled;
	}
	else if( iTeam == TFTeam_Red )
	{
		if( TFTeam:GetClientTeam( iClient ) == TFTeam_Red )
			return Plugin_Handled;
		if( !bCanJoinRED )
		{
			PrintToChat( iClient, "There's no free slots in RED team." );
			return Plugin_Handled;
		}
		LogAction(iClient, -1, "[BWR2] %L Joined RED team", iClient );
		CPrintToChatAll("{yellow}[BWR2] {cyan}%N {white} joined RED team.", iClient);		
		CreateTimer( 5.0, Timer_TurnHuman, GetClientUserId( iClient ) );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action:Timerjoinblupremium(Handle:timer, any:client)
{
	FakeClientCommand(client, "jointeam blue" );
	LogAction(client, -1, "[BWR2] %L Used premium access to join BLU", client);
}
public Action:RemoveSpawnProtection(Handle:timer, any:client)
{
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_UberchargedHidden);//
	TF2_RemoveCondition(client, TFCond_Ubercharged);
}
stock KillPlayer2(client)
{
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_UberchargedHidden);//
	TF2_RemoveCondition(client, TFCond_Ubercharged);
	SDKHooks_TakeDamage(client, 0, 0, 99999.0, DMG_GENERIC|DMG_PREVENT_PHYSICS_FORCE);
	if(IsPlayerAlive(client))
		ForcePlayerSuicide( client );
	if(!IsPlayerAlive(client) && !GateStunEnabled)
		CreateTimer( 2.5, RespawnPlayer2, client );
}
public Action:RespawnPlayer2(Handle:timer, any:Ent)
{
	if(!IsPlayerAlive(Ent))
		TF2_RespawnPlayer(Ent);	
}
public Action:Command_JoinClass( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	if( IsPlayerAlive(iClient) && !bInRespawn[iClient] )
		KillPlayer2(iClient);
	
	decl String:strClass[16];
	if( nArgs > 0 )
		GetCmdArg( 1, strClass, sizeof(strClass) );
		
	if( strlen(strClass) <= 0 )
		return Plugin_Handled;
	
	
	if( GameRules_GetRoundState() != RoundState_BetweenRounds )
	{
		ShowClassMenu( iClient );
		if( !StrEqual( strClass, "sniper", false ) )
			return Plugin_Handled;
	}
	
	ResetData( iClient );

	if( StrEqual( strClass, "auto", false ) || StrEqual( strClass, "engineer", false ) && !CanPlayEngineer(iClient) )
	{
		decl String:strClasses[9][16] = { "scout","sniper","soldier","demoman","medic","heavyweapons","pyro","spy","engineer" };
		FakeClientCommand( iClient, "%s %s", strCommand, strClasses[GetRandomInt(0,7)] );
		return Plugin_Handled;
	}
	
	if( StrEqual( strClass, "scout", false ) )
		iRobotClass[iClient] = TFClass_Scout;
	else if( StrEqual( strClass, "sniper", false ) )
		iRobotClass[iClient] = TFClass_Sniper;
	else if( StrEqual( strClass, "soldier", false ) )
		iRobotClass[iClient] = TFClass_Soldier;
	else if( StrEqual( strClass, "demoman", false ) )
		iRobotClass[iClient] = TFClass_DemoMan;
	else if( StrEqual( strClass, "medic", false ) )
		iRobotClass[iClient] = TFClass_Medic;
	else if( StrEqual( strClass, "heavyweapons", false ) )
		iRobotClass[iClient] = TFClass_Heavy;
	else if( StrEqual( strClass, "pyro", false ) )
		iRobotClass[iClient] = TFClass_Pyro;
	else if( StrEqual( strClass, "spy", false ) )
		iRobotClass[iClient] = TFClass_Spy;
	else if( StrEqual( strClass, "engineer", false ) )
		iRobotClass[iClient] = TFClass_Engineer;
	if( iRobotClass[iClient] != TFClass_Unknown )
		SetClassVariant( iClient, iRobotClass[iClient], bRandomizer ? PickRandomClassVariant( iRobotClass[iClient] ) : 0 );
	
	return Plugin_Continue;
}


public Action:Command_Taunt( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || !( GetEntityFlags(iClient) & FL_ONGROUND ) || TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) )
		return Plugin_Continue;
	
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		SentryBuster_Explode( iClient );
		return Plugin_Continue;
	}
	else if( iRobotMode[iClient] == Robot_Giant ) // || iRobotMode[iClient] == Robot_BigNormal )
	{
		new TFClassType:iClass = TF2_GetPlayerClass( iClient );
		if( iClass == TFClass_DemoMan || iClass == TFClass_Heavy || iClass == TFClass_Pyro || iClass == TFClass_Scout || iClass == TFClass_Soldier )
		{
			// No animations for taunting 'boss' models
			return Plugin_Handled;
		}
	}
	
	new iWeapon = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
	if( !IsValidEntity(iWeapon) )
	return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action:Command_Action( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	return Plugin_Handled;
}
public Action:Command_BuyBack( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	return Plugin_Handled;
}
public Action:Command_Kick( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || iClient != 0 )
		return Plugin_Continue;
	
	decl String:strTarget[8];
	GetCmdArg( 1, strTarget, sizeof(strTarget) );
	
	new iTarget = GetClientOfUserId( StringToInt( strTarget ) );
	if( !IsValidRobot( iTarget ) || GameRules_GetRoundState() != RoundState_BetweenRounds )
		return Plugin_Continue;
	
	return Plugin_Handled;
}
public Action:Command_Suicide( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster )
		return Plugin_Continue;
	
	FakeClientCommand( iClient, "taunt" );
	return Plugin_Handled;
}
public Action:Command_Vote( iClient, const String:strCommand[], nArgs )
{
	if( nArgs != 2 || !IsMvM() )
		return Plugin_Continue;
	
	decl String:strIssue[16];
	GetCmdArg( 1, strIssue, sizeof(strIssue) );
	if( !StrEqual( strIssue, "kick", false ) )
		return Plugin_Continue;
	
	decl String:strTarget[256];
	GetCmdArg( 2, strTarget, sizeof(strTarget) );
	
	new iUserID = 0;
	new iSpacePos = FindCharInString( strTarget, ' ' );
	if( iSpacePos > -1 )
	{
		decl String:strUserID[12];
		strcopy( strUserID, ( iSpacePos+1 < sizeof(strUserID) ? iSpacePos+1 : sizeof(strUserID) ), strTarget );
		iUserID = StringToInt( strUserID );
	}
	else
		iUserID = StringToInt( strTarget );
	
	new iTarget = GetClientOfUserId( iUserID );
	if( IsValidRobot(iTarget,false) && IsFakeClient(iTarget) )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action:Command_ChangeRoboClass( iClient, const String:strCommand[], nArgs )
{
	if( GetClientTeam(iClient) == _:TFTeam_Blue && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		ShowClassMenu( iClient );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Command_Ready( iClient, const String:strCommand[], nArgs )
{
	if( IsMvM() && bRestrictReady && GetClientTeam(iClient) == _:TFTeam_Blue )
	{
		if( bNotifications )
			CPrintToChat( iClient, "{fullred}* {blue}BLU{fullred} team can't start the game." );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action:Command_Listener( iClient, const String:strCmdName[], nArgs )
{
	/*
	decl String:strCommand[512];
	GetCmdArgString( strCommand, sizeof(strCommand) );
	PrintToServer( "%L :  %s %s", iClient, strCmdName, strCommand );
	*/
	return Plugin_Continue;
}
public Action:Command_ChangeClassMenu( iClient, nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) || GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Continue;
	if( iRobotMode[iClient] == Robot_SentryBuster )
		return Plugin_Handled;
	if( !bRandomizer && ( bInRespawn[iClient] || !IsPlayerAlive(iClient) ) && GameRules_GetRoundState() == RoundState_BetweenRounds )
		ShowClassMenu( iClient, TF2_GetPlayerClass( iClient ) );
	else
		ShowClassMenu( iClient );
	return Plugin_Handled;
}
stock UpdatePlayerHitbox(const client, const Float:fScale)
{
		static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

		decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;

		ScaleVector(vecScaledPlayerMin, fScale);
		ScaleVector(vecScaledPlayerMax, fScale);

		SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
		SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}
public Action:Command_ShowHelpMessage( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) )
		return Plugin_Continue;
	
	ReplyToCommand( iClient, "\x03:: \x04TF2 Be With Robots 2\x03 plugin ver.%s", PLUGIN_VERSION );
	ReplyToCommand( iClient, "\x03:: \x01You can play as BLU team on this server." );
	ReplyToCommand( iClient, "\x03:: \x01Type \x03jointeam blue\x01 in console or \x03/joinblue\x01 in chat." );
	ReplyToCommand( iClient, "\x03:: \x01Type \x03/robomenu\x01 to change robot class/variant." );
	
	return Plugin_Handled;
}
public Action:Command_JoinTeamBlue( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	

	if( GetTeamPlayerCount( _:TFTeam_Blue ) > (TF_MVM_MAX_PLAYERS - iMaxDefenders) && !IsFakeClient(iClient))
	{
		FakeClientCommand( iClient, "jointeam red" );
		return Plugin_Handled;
	}
	
	FakeClientCommand( iClient, "jointeam blue" );
	
	//LogAction(iClient, -1, "[BWR2] %L Joined BLU team", iClient);
	
	return Plugin_Handled;
}
public Action:Command_JoinTeamRed( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
		
	bInRespawn[iClient] = false;
	FakeClientCommand( iClient, "jointeam red" );
	//LogAction(iClient, -1, "[BWR2] %L Joined RED team", iClient);
	return Plugin_Handled;
}
public Action:Command_ShowPlayerList( iClient, nArgs )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	new bool:bChat = iClient > 0 && GetCmdReplySource() == SM_REPLY_TO_CHAT;
	
	new String:strPlayerList[3][250], iPlayerCount[3], iIndex;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			iIndex = GetClientTeam(i) - 1;
			if( iIndex < 0 || iIndex > 2 )
				iIndex = 0;
			iPlayerCount[iIndex]++;
			Format( strPlayerList[iIndex], sizeof(strPlayerList[]), "%s%s%s%N%s", strPlayerList[iIndex], strlen(strPlayerList[iIndex]) ? ", " : "", bChat ? "\x03" : "", i, bChat ? "\x01" : "" );
		}
	
	ReplyToCommand( iClient, "%s%d%s players in RED team: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[1], bChat ? "\x01" : "", strPlayerList[1] );
	ReplyToCommand( iClient, "%s%d%s players in BLU team: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[2], bChat ? "\x01" : "", strPlayerList[2] );
	ReplyToCommand( iClient, "%s%d%s other players: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[0], bChat ? "\x01" : "", strPlayerList[0] );
	
	return Plugin_Handled;
}
public Action:Command_MoveToSpec( iClient, nArgs )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: sm_bwr_kick <target>" );
		return Plugin_Handled;
	}
	
	decl String:strTargets[64];
	GetCmdArg( 1, strTargets, sizeof(strTargets) );
	
	new nTargets, iTargets[MAXPLAYERS+1], String:strTargetName[MAX_NAME_LENGTH], bool:tn_is_ml;
	if( ( nTargets = ProcessTargetString( strTargets, iClient, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), tn_is_ml ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	new iTeam;
	for( new i = 0; i < nTargets; i++ )
		if( ( iTeam = GetClientTeam( iTargets[i] ) ) > _:TFTeam_Spectator )
		{
			flNextChangeTeam[ iTargets[i] ] = 0.0;
			FakeClientCommand( iTargets[i], "jointeam spectate" );
			ShowActivity2( iClient, "[SM] ", "Kicked %N from %s team to spectators.", iTargets[i], iTeam == _:TFTeam_Red ? "RED" : "BLU" );
			flNextChangeTeam[ iTargets[i] ] = GetGameTime() + 30.0;
			bInRespawn[i] = false;//rocketjump fix
		}
	
	return Plugin_Handled;
}

public Action:Command_ForceVariant( iClient, nArgs )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	if( nArgs < 3 )
	{
		ReplyToCommand( iClient, "Usage: sm_bwr_force <target> <class> <variant id>" );
		return Plugin_Handled;
	}
	
 	decl String:strTargets[64];
	GetCmdArg( 1, strTargets, sizeof(strTargets) );
	
	new nTargets, iTargets[MAXPLAYERS+1], String:strTargetName[MAX_NAME_LENGTH], bool:tn_is_ml;
	if( ( nTargets = ProcessTargetString( strTargets, iClient, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), tn_is_ml ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	 
/* 	new String:arg1[64];
	GetCmdArgString(arg1, sizeof(arg1));
	 
	new target = FindTarget(iClient, arg1, true, false);
	if (target == -1) 
	{
		return Plugin_Handled;
	}  */

	
	char arg2[16];
	GetCmdArg(2 , arg2, sizeof(arg2));
	
	char arg3[4];
	GetCmdArg( 3, arg3, sizeof(arg3) );
	new i;
	for(i = 0; i < nTargets; i++ )
	{
		if( GetClientTeam( iTargets[i] ) >= _:TFTeam_Blue )
		{
			if( StrEqual(arg2, "scout", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Scout, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "soldier", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Soldier, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "pyro", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Pyro, StringToInt(arg3) );
			}	
			else if( StrEqual(arg2, "demoman", false) )
			{
				SetClassVariant( iTargets[i], TFClass_DemoMan, StringToInt(arg3) );
			}	
			else if( StrEqual(arg2, "heavy", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Heavy, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "engineer", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Engineer, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "medic", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Medic, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "sniper", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Sniper, StringToInt(arg3) );
			}
			else if( StrEqual(arg2, "spy", false) )
			{
				SetClassVariant( iTargets[i], TFClass_Spy, StringToInt(arg3) );
			}
			else
			{
				ReplyToCommand(iClient, "[BWR2]: Invalid Arguments");
			}
		}
		else
		{
			ReplyToCommand(iClient, "[BWR2]: This command can only be used on BLU players");
			return Plugin_Handled;			
		}
	}
	
	new String:argtarget[64];
	GetCmdArg(1 ,argtarget, sizeof(argtarget));

	new target = FindTarget(iClient, argtarget, true, false);
	
	LogAction(iClient, iTargets[i], "[BWR2] %L forced a robot variant (class: %s | variant: %s) on %L", iClient, arg2, arg3, target);
	if (CheckCommandAccess(iClient, "bwr_admin",  ADMFLAG_ROOT))
	{
		ShowActivity2(iClient, "[BWR2] ", "%N forced a robot variant (class: %s | variant: %s) on %N", iClient, arg2, arg3, target);
	}
	else
	{
		CPrintToChatAll("{yellow}[BWR2]{magenta} %N {cyan}forced a robot variant (class: {magenta}%s{cyan} | variant: {magenta}%s{cyan}) on {magenta}%N", iClient, arg2, arg3, target);
	}
	
	return Plugin_Handled;
}

public Action:TEHook_Particle(const String:te_name[], const Players[], numClients, Float:delay)
{
//	PrintToServer( "%d", TE_ReadNum( "m_iParticleSystemIndex" ) );
//	PrintToServer( "%i", TE_ReadNum( "m_iParticleSystemIndex" ) );
//	PrintToServer( "%s: %d %d %d", te_name, TE_ReadNum( "m_iPlayerIndex" ), TE_ReadNum( "m_iEvent" ), TE_ReadNum( "m_nData" ) );
	return Plugin_Continue;
}

public Action:TEHook_PlayerAnimEvent(const String:te_name[], const Players[], numClients, Float:delay)
{
//	PrintToServer( "%s: %d %d %d", te_name, TE_ReadNum( "m_iPlayerIndex" ), TE_ReadNum( "m_iEvent" ), TE_ReadNum( "m_nData" ) );
	return Plugin_Continue;
}
public Action:TEHook_TFExplosion(const String:te_name[], const Players[], numClients, Float:delay)
{
//	PrintToServer( "%s: %d %d %d %d %d", te_name, TE_ReadNum( "entindex" ), TE_ReadNum( "m_nDefID" ), TE_ReadNum( "m_nSound" ), TE_ReadNum( "m_iWeaponID" ), TE_ReadNum( "m_iCustomParticleIndex" ) );
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:flVelocity[3], Float:flAngles[3], &iWeapon )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) )
		return Plugin_Continue;

	//new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	
	if( bInRespawn[iClient] && GameRules_GetRoundState() == RoundState_RoundRunning)
	{

		if( iButtons & IN_ATTACK )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK2 )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	}

/* 	if( bInRespawn[iClient] && iClass == TFClass_Scout && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		//iButtons &= ~IN_ATTACK;
		iButtons &= ~IN_ATTACK2;
		return Plugin_Changed;
	}
	
	if( bInRespawn[iClient] && iClass == TFClass_Pyro && GameRules_GetRoundState() == RoundState_RoundRunning)
	{

		if( iButtons & IN_ATTACK )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK2 )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	}
	if( bInRespawn[iClient] && iClass == TFClass_Sniper && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		if( iButtons & IN_ATTACK )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK2 )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	} */
	//if( bInRespawn[iClient] && iClass == TFClass_Engineer )
	//{
	//	iButtons &= ~IN_ATTACK;
	//	return Plugin_Changed;
	//}
	if( bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds /*&& bInRespawn[iClient]*/ )
	{
		if( iButtons & IN_JUMP )
		{
			iButtons &= ~IN_JUMP;
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK2 )
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		if (iButtons & IN_FORWARD && TF2_IsPlayerInCondition( iClient, TFCond_HalloweenKartNoTurn )) 
		{
			iButtons &= ~IN_FORWARD;
		}
		
	}
	else if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		if( iButtons & IN_ATTACK && !bInRespawn[iClient] )
		{
			FakeClientCommand( iClient, "taunt" );
			iButtons &= ~IN_ATTACK;
			return Plugin_Changed;
		}
		if( iButtons & IN_JUMP ) //else
		{
			iButtons &= ~IN_JUMP;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_TurnSpec( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	if( !IsFakeClient(iClient) )
	{
		DestroyBuildings( iClient );
		FixSounds( iClient );
		
		SetVariantString( "" );
		AcceptEntityInput( iClient, "SetCustomModel" );
		SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
		UpdatePlayerHitbox(iClient, 1.0);
		SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	}
	
	ChangeClientTeam( iClient, _:TFTeam_Spectator );
	
	ResetData( iClient );
	
	LogMessage("[BWR2] Player %L was moved to spectator.", iClient);
	
	return Plugin_Stop;
}
public Action:Timer_TurnHuman( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	
	if( !IsFakeClient(iClient) )
	{
		ResetData( iClient );
		DestroyBuildings( iClient );
		FixSounds( iClient );
		
		SetVariantString( "" );
		AcceptEntityInput( iClient, "SetCustomModel" );
		SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
		UpdatePlayerHitbox(iClient, 1.0);
		SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	}
	
	new i, iTargets[MAXPLAYERS+1], nTargets, bool:bOverlimits = GetTeamPlayerCount( _:TFTeam_Red ) >= TF_MVM_MAX_DEFENDERS;
	if( bOverlimits ) for( i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red )
			iTargets[nTargets++] = i;
	
	nTargets -= TF_MVM_MAX_DEFENDERS - 1;
	
	for( i = 0; i < nTargets; i++ ) if( iTargets[i] ) SetEntProp( iTargets[i], Prop_Send, "m_iTeamNum", _:TFTeam_Blue );
	ChangeClientTeam( iClient, _:TFTeam_Red );
	for( i = 0; i < nTargets; i++ ) if( iTargets[i] ) SetEntProp( iTargets[i], Prop_Send, "m_iTeamNum", _:TFTeam_Red );
	
	if( GetEntProp( iClient, Prop_Send, "m_iDesiredPlayerClass" ) == _:TFClass_Unknown )
		ShowClassPanel( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_TurnRobot( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	if( !IsFakeClient(iClient) )
	{
		ResetData( iClient );
		DestroyBuildings( iClient );
		FixSounds( iClient );
		StripCharacterAttributes(iClient);
		SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	}
	
	if( bRandomizer )
		PickRandomRobot( iClient );
	
	new iEntFlags = GetEntityFlags( iClient );
	SetEntityFlags( iClient, iEntFlags|FL_FAKECLIENT );
	ChangeClientTeam( iClient, _:TFTeam_Blue );
	SetEntityFlags( iClient, iEntFlags&~FL_FAKECLIENT );
	
	if( GetEntProp( iClient, Prop_Send, "m_iDesiredPlayerClass" ) == _:TFClass_Unknown )
		ShowClassPanel( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_Respawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Stop;
	
	if( !IsPlayerAlive( iClient ) && GameRules_GetRoundState() == RoundState_RoundRunning )
		TF2_RespawnPlayer( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_SentryBuster_Explode( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster )
		return Plugin_Stop;
	
	new Float:flExplosionPos[3];
	GetClientAbsOrigin( iClient, flExplosionPos );
	
	if( bSentryBusterDebug || GameRules_GetRoundState() != RoundState_BetweenRounds )
	{
		new i;
		for( i = 1; i <= MaxClients; i++ )
			if( i != iClient && IsValidClient(i) && IsPlayerAlive(i) ) //&& GetClientTeam(i) == _:TFTeam_Red )
				if( CanSeeTarget( iClient, i, SENTRYBUSTER_DISTANCE ) )
					DealDamage( i, SENTRYBUSTER_DAMAGE, iClient, TF_CUSTOM_PUMPKIN_BOMB );
		
		new String:strObjects[5][] = { "obj_sentrygun","obj_dispenser","obj_teleporter","obj_teleporter_entrance","obj_teleporter_exit" };
		for( new o = 0; o < sizeof(strObjects); o++ )
		{
			i = -1;
			while( ( i = FindEntityByClassname( i, strObjects[o] ) ) != -1 )
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue && !GetEntProp( i, Prop_Send, "m_bCarried" ) && !GetEntProp( i, Prop_Send, "m_bPlacing" ) )
					if( CanSeeTarget( iClient, i, SENTRYBUSTER_DISTANCE ) )
						DealDamage( i, SENTRYBUSTER_DAMAGE, iClient );
		}
	}
	
	CreateParticle( flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5 );
	CreateParticle( flExplosionPos, "explosionTrail_seeds_mvm", 5.5 );	//fluidSmokeExpl_ring_mvm  explosionTrail_seeds_mvm
	
	ForcePlayerSuicide( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_SentryBuster_Beep( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster || TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) )
	{
		if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
			KillTimer( hTimer_SentryBuster_Beep[iClient] );
		hTimer_SentryBuster_Beep[iClient] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	PrecacheSnd( SENTRYBUSTER_SND_INTRO );
	EmitSoundToAll( SENTRYBUSTER_SND_INTRO, iClient, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE );
	return Plugin_Handled;
}
public Action:Timer_OnPlayerSpawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) )
		return Plugin_Stop;
		
	decl String:strAnnounceLine[PLATFORM_MAX_PATH];
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	
	if(iRobotMode[iClient] != Robot_Giant && iClass == TFClass_Pyro && IsValidRobot(iClient))
	{
		//TF2Attrib_RemoveByName(iClient, "deflection size multiplier");
		//TF2Attrib_RemoveByName(iClient, "flame life bonus");
	}
	if(iRobotMode[iClient] == Robot_Giant && IsValidRobot(iClient))
	{
		///TF2Attrib_SetByName(iClient, "deflection size multiplier", 1.01);
		//TF2Attrib_SetByName(iClient, "bombinomicon effect on death", 1.0);
	}
	else
	{
		TF2Attrib_RemoveByName(iClient, "bombinomicon effect on death");
	}
	if(iRobotMode[iClient] == Robot_Giant && iClass == TFClass_Pyro && IsValidRobot(iClient))
	{
		///TF2Attrib_SetByName(iClient, "deflection size multiplier", 1.01);
		TF2Attrib_SetByName(iClient, "flame life bonus", 1.4);
	}
	
	//TF2Attrib_SetByName(iClient, "crit mod disabled", 1.0); broken
	
	if(Is666Mode)
	{
//		if(GetRandomInt(0,9) > 8)// for extra effect
//		{
//		}
		if(iRobotVariant[iClient] != -1)
			TF2_AddCondition(iClient, TFCond_CritOnKill, TFCondDuration_Infinite); //for all classes
		if(iClass == TFClass_Engineer)
			TF2_AddCondition(iClient, TFCond_Buffed, TFCondDuration_Infinite); //minicrits for sentry main engi defense 
	}
	GiveSpawnProtection(iClient, 3.0);
	//TF2_AddCondition(iClient, TFCond_UberchargedHidden, 3.0);
	//TF2_AddCondition(iClient, TFCond_UberchargeFading, 3.0);
	if( iClass == TFClass_DemoMan )
		TF2Attrib_SetByName(iClient, "mult charge turn control", 100.0);
	if( iClass == TFClass_Spy && GameRules_GetRoundState() == RoundState_RoundRunning )//spytele and enforcerban
	{
		//TF2_AddCondition(iClient, TFCond_Disguised, -1.0);
		CreateTimer( 2.7, Timer_TeleportSpy, iClient);
		TF2_AddCondition( iClient, TFCond_Cloaked, -1.0 );
		//TF2_DisguisePlayer( iClient, TFTeam_Red, TFClassType:GetRandomInt(1,9) );
	}
	if( CanAirSpawn[iClient] == true && GameRules_GetRoundState() == RoundState_RoundRunning && MapDisallowParachute == false )//Parachute Spawn Tele
	{
		CreateTimer( 1.2, Timer_TeleParachute, iClient);
		CreateTimer( 1.4, Timer_ForceParachute, iClient);
	}
	
	//	if(iRobotVariant[iClient] == -1)
	//	{
	//		new Revolver = GetPlayerWeaponSlot( iClient, 0 );
	//		if(GetEntProp(Revolver, Prop_Send, "m_iItemDefinitionIndex") == 460)//460 enforcer id
	//			TF2_RemoveCondition(iClient, TFCond_CritOnKill);
	//	}
	TF2_RemoveCondition(iClient, TFCond_UberchargedHidden);//security check for bomb upgrades
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		TF2_AddCondition(iClient, TFCond_PreventDeath, TFCondDuration_Infinite);
		PrecacheSnd( SENTRYBUSTER_SND_LOOP );
		EmitSoundToAll( SENTRYBUSTER_SND_LOOP, iClient, SNDCHAN_STATIC, SNDLEVEL_TRAIN );
		if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
			KillTimer( hTimer_SentryBuster_Beep[iClient] );
		hTimer_SentryBuster_Beep[iClient] = CreateTimer( 5.0, Timer_SentryBuster_Beep, GetClientUserId(iClient), TIMER_REPEAT );
		TriggerTimer( hTimer_SentryBuster_Beep[iClient] );
		//flLastSentryBuster = GetGameTime+35.0();
		
		for(new i = 1; i <= MaxClients; i++)//engineer speach red
		{
			if(IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Red && iClass == TFClass_Engineer)
			{
				SetVariantString("randomnum:75");
				AcceptEntityInput(i, "AddContext");

				SetVariantString("IsMvMDefender:1");
				AcceptEntityInput(i, "AddContext");
				SetVariantString("TLK_MVM_SENTRY_BUSTER");
				AcceptEntityInput(i, "SpeakResponseConcept");
				AcceptEntityInput(i, "ClearContext");
			}
		}
		g_CanDispatchSentryBuster = false;
		if( ( flLastAnnounce + 10.0 ) < GetEngineTime() && GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			if( ( flLastSentryBuster + 60.0 ) > GetEngineTime() ) switch( GetRandomInt(0,1) )
			{
				case 1: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts02.mp3" );
				default: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts03.mp3" );
			}
			else switch( GetRandomInt(0,4) )
			{
				case 4: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts07.mp3" );
				case 3: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts06.mp3" );
				case 2: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts05.mp3" );
				case 1: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts04.mp3" );
				default: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts01.mp3" );
			}
			//flLastSentryBuster = GetEngineTime();
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
	}
	else if( iRobotMode[iClient] == Robot_Giant ) // || iRobotMode[iClient] == Robot_BigNormal )
	{
		if( iClass == TFClass_Scout )
		{
			PrecacheSnd( GIANTSCOUT_SND_LOOP );
			EmitSoundToAll( GIANTSCOUT_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Soldier )
		{
			PrecacheSnd( GIANTSOLDIER_SND_LOOP );
			EmitSoundToAll( GIANTSOLDIER_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_DemoMan )
		{
			PrecacheSnd( GIANTDEMOMAN_SND_LOOP );
			EmitSoundToAll( GIANTDEMOMAN_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Heavy )
		{
			PrecacheSnd( GIANTHEAVY_SND_LOOP );
			EmitSoundToAll( GIANTHEAVY_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Pyro )
		{
			PrecacheSnd( GIANTPYRO_SND_LOOP );
			EmitSoundToAll( GIANTPYRO_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
	}
	
	if( ( flLastAnnounce + 10.0 ) < GetEngineTime() && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		if( iClass == TFClass_Engineer && iEffect[iClient] != Effect_TeleportToHint)
		{
			if( GetNumEngineers( iClient ) > 1 )
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_engbot_another01.mp3" );
			else
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_engbot_arrive01.mp3" );
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
		else if( iClass == TFClass_Spy )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_spy_spawn0%d.mp3", GetRandomInt(1,4) );
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
	}
	
	if( iEffect[iClient] == Effect_FullCharge )
	{
		if( iClass == TFClass_Medic )
		{
			new iWeapon = GetPlayerWeaponSlot( iClient, 1 );
			if( IsValidEdict( iWeapon ) )
				SetEntPropFloat( iWeapon, Prop_Send, "m_flChargeLevel", 1.0 );
		}
		else if( iClass == TFClass_Soldier )
			SetEntPropFloat( iClient, Prop_Send, "m_flRageMeter", 100.0 );
	}
	if( iClass == TFClass_Soldier && iRobotMode[iClient] == Robot_Giant )
		SetEntPropFloat( iClient, Prop_Send, "m_flRageMeter", 100.0 );
	else if( iClass == TFClass_Spy && ( iEffect[iClient] == Effect_Invisible || iEffect[iClient] == Effect_AlwaysInvisible ) )
	{
		TF2_AddCondition( iClient, TFCond_Cloaked, -1.0 );
		new Handle:hTargets = CreateArray(), TFClassType:iTargetClass;
		for( new i = 1; i <= MaxClients; i++ )
			if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red )
			{
				iTargetClass = TF2_GetPlayerClass(i);
				if( iTargetClass != TFClass_Unknown )
					PushArrayCell( hTargets, i );
			}
		if( GetArraySize(hTargets) > 0 )
		{
			new iTarget = GetArrayCell( hTargets, GetRandomInt(0,GetArraySize(hTargets)-1) );
			TF2_DisguisePlayer( iClient, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget );
		}
		else
			TF2_DisguisePlayer( iClient, TFTeam_Red, TFClassType:GetRandomInt(1,9) );
		CloseHandle( hTargets );
	}
	else if( iClass == TFClass_Spy && iEffect[iClient] == Effect_AutoDisguise )
	{
		new Handle:hTargets = CreateArray(), TFClassType:iTargetClass;
		for( new i = 1; i <= MaxClients; i++ )
			if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red )
			{
				iTargetClass = TF2_GetPlayerClass(i);
				if( iTargetClass != TFClass_Unknown )
					PushArrayCell( hTargets, i );
			}
		if( GetArraySize(hTargets) > 0 )
		{
			new iTarget = GetArrayCell( hTargets, GetRandomInt(0,GetArraySize(hTargets)-1) );
			TF2_DisguisePlayer( iClient, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget );
		}
		else
			TF2_DisguisePlayer( iClient, TFTeam_Red, TFClassType:GetRandomInt(1,9) );
		CloseHandle( hTargets );
	}
	if( iEffect[iClient] == Effect_AlwaysCrits )
	{
		TF2_AddCondition( iClient, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
	}
	if( iEffect[iClient] == Effect_UseBossHealthBar_Effect_AlwaysCrits )
	{
		TF2_AddCondition( iClient, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
	}
	if( iEffect[iClient] == Effect_AlwaysMiniCrits )
	{
		TF2_AddCondition( iClient, TFCond_Buffed, TFCondDuration_Infinite);
	}
	if( iEffect[iClient] == Effect_TeamHealthRegen )
	{
		TF2_AddCondition( iClient, TFCond_RadiusHealOnDamage, TFCondDuration_Infinite);
	}
	
	// Robot Spawn Points
	new iEnt = -1, Float:vecOrigin[3], Float:vecAngles[3];
	new iRandomSpawn = -1;
	if( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal || iRobotMode[iClient] == Robot_SentryBuster )
		iEnt = FindRandomSpawnPoint( Spawn_Giant );
	else if( iRobotMode[iClient] == Robot_Normal || iRobotMode[iClient] == Robot_Stock )
	{
		if( iClass == TFClass_Sniper )
		{
			iEnt = FindRandomSpawnPoint( Spawn_Sniper );
		}
		else if( iClass == TFClass_Spy )
		{
			iEnt = FindRandomSpawnPoint( Spawn_Spy );
		}
		else if( GetRandomInt(0,1) )
		{
			iRandomSpawn = GetRandomInt(0,3);
			if ( iRandomSpawn == 0)
			{
				iEnt = FindRandomSpawnPoint( Spawn_Bwr );
				//PrintToChatAll("DEBUG: iRandomSpawn value is %d and we spawned at Spawn_Bwr", iRandomSpawn);
			}
			if ( iRandomSpawn == 1)
			{
				iEnt = FindRandomSpawnPoint( Spawn_Invasion );
				//PrintToChatAll("DEBUG: iRandomSpawn value is %d and we spawned at Spawn_Invasion", iRandomSpawn);
			}
			if ( iRandomSpawn == 2)
			{
				iEnt = FindRandomSpawnPoint( Spawn_Lower );
				//PrintToChatAll("DEBUG: iRandomSpawn value is %d and we spawned at Spawn_Lower", iRandomSpawn);
			}	
			if ( iRandomSpawn == 3)
			{
				iEnt = FindRandomSpawnPoint( Spawn_Standard );
				//PrintToChatAll("DEBUG: iRandomSpawn value is %d and we spawned at Spawn_Standard", iRandomSpawn);
			}
			//PrintToChatAll("DEBUG: iRandomSpawn value is %d", iRandomSpawn);
		}
	}
	if( iEnt <= MaxClients || !IsValidEntity( iEnt ) )
		iEnt = FindRandomSpawnPoint( Spawn_Normal );
	if( iEnt > MaxClients && IsValidEntity( iEnt ) && !IsMannhattan )
	{
		GetEntPropVector( iEnt, Prop_Send, "m_vecOrigin", vecOrigin );
		GetEntPropVector( iEnt, Prop_Data, "m_angRotation", vecAngles );
		TeleportEntity( iClient, vecOrigin, vecAngles, NULL_VECTOR );
	}
	new TFClassType:class = TF2_GetPlayerClass(iClient);
	//CanTeleportBomb = true;
	if(!IsMannhattan && CanTeleportBomb && GameRules_GetRoundState() == RoundState_RoundRunning && class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Medic)
	{
			new iflagr = -1;
			new Float:Position[3];
			while ((iflagr = FindEntityByClassname(iflagr, "item_teamflag")) != -1)
			{
			if(IsValidEdict(iflagr)) //&& bool:GetEntProp( iflagr, Prop_Data, "m_bDisabled" ) == false)
			{
				//PrintToChatAll("bomb %i", iflagr);
				GetClientAbsOrigin(iClient, Position);
				TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
				//CanTeleportBomb1 = false;//Prevent for 2 teleport
				////SecondBombEnable = true;// This bool will become false if the first intel is taken.
				//break;
			}
			}
		//if(!//SecondBombEnable)
		//{
		//	new iflagr = -1;
		//	new Float:Position[3];
		//	iflagr = FindEntityByClassname(iflagr, "item_teamflag");
		//	GetClientAbsOrigin(iClient, Position);
		//	TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
		//}
		//else
		//{
		//	new Float:Position[3];
		//	GetClientAbsOrigin(iClient, Position);
		//	TeleportEntity(Bomb2, Position, NULL_VECTOR, NULL_VECTOR);
		//}
	}
// disabling this due to error spam.
/* 	if(IsMannhattan && GameRules_GetRoundState() == RoundState_RoundRunning && class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Medic && !IsGateBotPlayer[iClient] && ((LastGateCapture + 19.9) < GetEngineTime()))
	{
		new iflagr = -1;
		if(CanTeleportBomb1)
		{
			iflagr = Bomb1;
			//PrintToChatAll("[TF2BWR] Bomb1 Can be Teleported!");
		}
		if(CanTeleportBomb2)
		{
			iflagr = Bomb2;
			//PrintToChatAll("[TF2BWR] Bomb2 Can be Teleported!");
		}
		if(CanTeleportBomb3)
		{
			iflagr = Bomb3;
			//PrintToChatAll("[TF2BWR] Bomb3 Can be Teleported!");
		}
		new Float:Position[3];
		GetClientAbsOrigin(iClient, Position);
		TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
	} */
	if( iEffect[iClient] == Effect_TeleportToHint )
	{
		TeleportRobotToHint(iClient);
	}
	
	//SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));
	//if(iRobotMode[iClient] != Robot_SentryBuster)
	//{
	//	new Primary = GetPlayerWeaponSlot(iClient, 0);
	//	if(IsValidEntity(Primary))
	//		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", Primary);
		//
	//}
	
	if(iRobotMode[iClient] == Robot_SentryBuster && IsGateBotPlayer[iClient])
		IsGateBotPlayer[iClient] = false;//security check
	else if(((LastGateCapture + 19.9) < GetEngineTime()) && !GateStunEnabled)
			SpawnRobot(iClient);
	CreateTimer(1.0, Timer_BuildingSmash, iClient, TIMER_REPEAT);
	
	return Plugin_Stop;
}
stock PlayAnimationV3(client, char[] anim)
{
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	if( iClass == TFClass_Spy || Is666Mode || iClass == TFClass_Engineer)
		return;
	new String:modelname[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
	//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, vecAngles);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	vecAngles[0] = 0.0;
	HideBomb(client);

	//flag player item_teamflag attachment
	int animationentity = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(animationentity))
	{
		DispatchKeyValueVector(animationentity, "origin", vecOrigin);
		//DispatchKeyValueVector(animationentity, "angles", vecAngles);
		DispatchKeyValue(animationentity, "model", modelname);
		DispatchKeyValue(animationentity, "targetname", "bwrdeployaniment");
		DispatchKeyValue(animationentity, "defaultanim", anim);
		
		SetEntProp(animationentity, Prop_Send, "m_nSkin", 1);
		if(TF2_IsPlayerInCondition( client, TFCond_Ubercharged ))
			SetEntProp(animationentity, Prop_Send, "m_nSkin", 3);
		//SetEntProp(animationentity, Prop_Send, "m_bGlowEnabled", 1); will crash 
		DispatchSpawn(animationentity);
		if( iClass == TFClass_Medic )
		{
			CreateTimer( 0.4, Timer_ResetAnimSpeed, animationentity );
			SetEntPropFloat(animationentity, Prop_Data, "m_flPlaybackRate", 1.9);
		}

		ChangeView(animationentity);
		SetEntPropEnt(animationentity, Prop_Send, "m_hOwnerEntity", client);
		
		//SetEntProp(animationentity, Prop_Send, "m_bGlowEnabled", 1); will crash 
			
		new Float:PlayerScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
		SetEntPropFloat(animationentity, Prop_Send, "m_flModelScale", PlayerScale);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(animationentity, "AddOutput");
		
		new bombanimation = CreateEntityByName("prop_dynamic_override");
		if(IsValidEntity(bombanimation))
		{
			SetVariantString("!activator");
			AcceptEntityInput(bombanimation, "SetParent", animationentity, bombanimation, 0);
			DispatchKeyValue(bombanimation, "model", "models/props_td/atom_bomb.mdl");
			SetVariantString("Flag");
			AcceptEntityInput(bombanimation, "SetParentAttachment", bombanimation , bombanimation, 0);
			
			DispatchSpawn(bombanimation);
			//CreateTimer( 0.7, Timer_SetGlow, animationentity ); no glow because nobody cares
		}
	}
}


public Action:Timer_ResetAnimSpeed( Handle:hTimer, any:ent )
{
	SetEntPropFloat(ent, Prop_Data, "m_flPlaybackRate", 1.0);
}

/*public Action:Timer_SetGlow( Handle:hTimer, any:ent )
{
	SetEntProp(ent, Prop_Send, "m_bGlowEnabled", 1);
}
*/
/*stock BlueGlowProp(entity,client)
{
	int Bomb = GetEntPropEnt( client, Prop_Send, "m_hItem" );
	PrecacheModel("models/empty.mdl");
	if(IsValidEntity(Bomb))
	{
		//SetEntityModel(Bomb,"models/empty.mdl");//Hide bomb flag model from glow and hide his particle effect
		new String:Name[255];
		GetEntPropString(Bomb, Prop_Data, "m_iName", Name, 255);//Every bomb got a name
		SetVariantString(Name);
		AcceptEntityInput(entity,"SetParent");
	}
}
*/

stock HideBomb(client)
{
	PrecacheModel("models/empyt.mdl");
	new iFlag = -1;
	while( ( iFlag = FindEntityByClassname( iFlag, "item_teamflag" ) ) != -1 )
	{
		new i = GetEntPropEnt( iFlag, Prop_Send, "m_hOwnerEntity" );
		if( i == client )
		{
			SetEntityModel(iFlag, "models/empyt.mdl");
			BombHidden[iFlag] = true;
			SetEntityRenderMode(iFlag, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iFlag, 255, 255, 255, 0);
			SetEntProp(iFlag, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
}

stock ChangeView(Entity) //makes ent look at the hatch
{
	new i = -1;	//look at hatch
	while ((i = FindEntityByClassname(i, "func_breakable")) != -1)
	{
	if(IsValidEntity(i))
	{
		decl String:strName[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "cap_hatch_glasswindow") == 0)
		{
			LookAtTarget(Entity, i, true);
			break;
		}
	} 
	}
}

public Action:Timer_OnPlayerChangeTeam( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) )
		return Plugin_Stop;
	
	//CheckTeamBalance( false, iClient );
	
	return Plugin_Stop;
}
public Action:Timer_OnPlayerDeath( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );

	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) || IsPlayerAlive(iClient) )
		return Plugin_Stop;
	
	FixSounds( iClient );
	
	if( IsValidRobot(iClient) )
	{
		TF2Attrib_RemoveByName(iClient, "health regen");
		//if( iDeployingBomb > 0 )
		//{
		//	iDeployingBomb = -1;
		if (g_hDeployTimer != INVALID_HANDLE)
		{
			CloseHandle(g_hDeployTimer);
			g_hDeployTimer = INVALID_HANDLE;
		}
			
		//}
//		if( iRobotMode[iClient] == Robot_Giant )// && GameRules_GetRoundState() == RoundState_RoundRunning ) // || GameRules_GetRoundState() == RoundState_RoundRunning ) //if( iRobotMode[iClient] != Robot_Stock && iRobotMode[iClient] != Robot_Normal )
//
//		{
//			PrecacheSnd( SENTRYBUSTER_SND_EXPLODE );
//			EmitSoundToAll( SENTRYBUSTER_SND_EXPLODE, iClient, SNDCHAN_STATIC, 125 );
//		}
	}
	IsntStock[iClient] = false;
	//decl Float:ClientOrigin[3];
	//GetClientAbsOrigin(iClient, ClientOrigin);
	//if( iRobotMode[iClient] == Robot_Giant && iRobotMode[iClient] != Robot_SentryBuster && GameRules_GetRoundState() == RoundState_RoundRunning )
	//	GIBGIANT(iClient, ClientOrigin); disabled bugged
	
	
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Stop;
	
	//if( CheckTeamBalance( false, iClient ) )
		//return Plugin_Stop;
	
	new iTeamNum = GetClientTeam(iClient);
	if( iTeamNum == _:TFTeam_Blue )
	{
		if( bRandomizer )//&& iRobotVariant[iClient] > -1
			PickRandomRobot( iClient );//this executes on death
		
		if(!GateStunEnabled)
		{
			//PrintToChatAll("called setrepsawntime");
			//new TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
			//SetVariantFloat(float(iRespawnTimeBLU));
			//AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
			CreateTimer( float(iRespawnTimeBLU), Timer_Respawn, GetClientUserId(iClient) );
		}
	}
	else if( iTeamNum == _:TFTeam_Red && iRespawnTimeRED >= 0 )
		CreateTimer( float(iRespawnTimeRED), Timer_Respawn, GetClientUserId(iClient) );
	
	return Plugin_Stop;
}
//
stock GIBGIANT(Client, Float:ClientOrigin[3])//
{
					decl Ent;
 
					//Initialize:
					Ent = CreateEntityByName("tf_ragdoll");
 
					//Write:
					SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
					SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", Client); 
					SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR);
					SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
					SetEntProp(Ent, Prop_Send, "m_bGib", 1);
 
					//Send:
					DispatchSpawn(Ent);

					//Remove Body:
					CreateTimer(0.1, RemoveBody, Client);
					CreateTimer(8.0, RemoveGibs, Ent);
}
public Action:RemoveBody(Handle:Timer, any:Client)
{

	//Declare:
	decl BodyRagdoll;

	//Initialize:
	BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");

	//Remove:
	if(IsValidEdict(BodyRagdoll)) RemoveEdict(BodyRagdoll);
}
//Remove Gibs:
public Action:RemoveGibs(Handle:Timer, any:Ent)
{

	//Validate:
	if(IsValidEntity(Ent))
	{

		//Declare:
		decl String:Classname[64];

		//Initialize:
		GetEdictClassname(Ent, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "tf_ragdoll", false))
		{

			//Delete:
			RemoveEdict(Ent);
		}
	}
}
//

public Action:Timer_DeployingBomb( Handle:hTimer, any:iUserID )
{
	if( iDeployingBomb > -1 )
		return Plugin_Stop;
	
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || !( GetEntityFlags(iClient) & FL_ONGROUND ) )
	{
		iDeployingBomb = -1;
		return Plugin_Stop;
	}
	
	GameRules_SetProp( "m_bPlayingMannVsMachine", 0 );
	CreateTimer( 0.1, Timer_SetMannVsMachines );
	
	return Plugin_Stop;
}
public Action:Timer_SetMannVsMachines( Handle:hTimer, any:data )
{
GameRules_SetProp( "m_bPlayingMannVsMachine", 1 );
iDeployingBomb = -1;
//	FinishDeploying();
//	return Plugin_Stop;
}

/*
public Action:Timer_AutoBalance( Handle:hTimer, any:iAutoBalance )
{
	if( !IsMvM() )
		return Plugin_Handled;
	
	PrintToServer( "Timer_AutoBalance( %d )", iAutoBalance );
	
	if( iAutoBalance )
	{
		CheckTeamBalance( true );
		return Plugin_Stop;
	}
	
	//new iBalanceReason = CheckTeamBalance();
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders > iMinDefenders );  //removed >=
	new bool:bTooManyRED = ( iNumDefenders > iMaxDefenders );
	new bool:bTooManyBLU = ( iNumHumanRobots > ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) );
	if( CheckTeamBalance() && ( !bEnoughRED && iNumHumanRobots > 0 || bTooManyRED && iNumDefenders > 0 || bTooManyBLU && iNumHumanRobots > 0 ) )
	{
		if( bNotifications )
			PrintToChatAll( "Teams will be auto-balanced." );
		//CreateTimer( 5.0, Timer_AutoBalance, 1 );
	}
	return Plugin_Handled;
}
*/

public Action:Timer_SetRobotModel( Handle:hTimer, any:iClient )
{
	if( !IsMvM() )
		return Plugin_Stop;
	
	if( !IsValidRobot( iClient ) )
		return Plugin_Stop;
	
	if( !IsPlayerAlive( iClient ) )
		return Plugin_Handled;
	
//	if( TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) || TF2_IsPlayerInCondition( iClient, TFCond_Dazed) )
//		return Plugin_Handled;
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		if( IsSmallMap == true )
		{
			SetRobotModel( iClient, "models/bots/demo/bot_sentry_buster.mdl" );
			SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", FLSMALLGIANTSCALE );
			UpdatePlayerHitbox(iClient, FLSMALLGIANTSCALE);
		}
		else
		{
			SetRobotModel( iClient, "models/bots/demo/bot_sentry_buster.mdl" );
			SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", FLGIANTSCALE );
			UpdatePlayerHitbox(iClient, FLGIANTSCALE);
		}
	}
	else
	{
		new String:strModel[PLATFORM_MAX_PATH];
		switch( iClass )
		{
			case TFClass_Scout: strcopy( strModel, sizeof(strModel), "scout" );
			case TFClass_Sniper: strcopy( strModel, sizeof(strModel), "sniper" );
			case TFClass_Soldier: strcopy( strModel, sizeof(strModel), "soldier" );
			case TFClass_DemoMan: strcopy( strModel, sizeof(strModel), "demo" );
			case TFClass_Medic: strcopy( strModel, sizeof(strModel), "medic" );
			case TFClass_Heavy: strcopy( strModel, sizeof(strModel), "heavy" );
			case TFClass_Pyro: strcopy( strModel, sizeof(strModel), "pyro" );
			case TFClass_Spy: strcopy( strModel, sizeof(strModel), "spy" );
			case TFClass_Engineer: strcopy( strModel, sizeof(strModel), "engineer" );
		}
		
		if( strlen(strModel) > 0 )
		{
			if( iRobotMode[iClient] == Robot_Giant )
			{
				if( IsSmallMap == true )
				{
					if( iClass == TFClass_DemoMan || iClass == TFClass_Heavy || iClass == TFClass_Pyro || iClass == TFClass_Scout || iClass == TFClass_Soldier )
						Format( strModel, sizeof( strModel ), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel );
					else
						Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
					SetRobotModel( iClient, strModel );
					SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", FLSMALLGIANTSCALE );
					UpdatePlayerHitbox(iClient, FLSMALLGIANTSCALE); 
				}
				else
				{
					if( iClass == TFClass_DemoMan || iClass == TFClass_Heavy || iClass == TFClass_Pyro || iClass == TFClass_Scout || iClass == TFClass_Soldier )
						Format( strModel, sizeof( strModel ), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel );
					else
						Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
					SetRobotModel( iClient, strModel );
					SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", FLGIANTSCALE );
					UpdatePlayerHitbox(iClient, FLGIANTSCALE); 
				}
			}
			else
			{
				Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
				SetRobotModel( iClient, strModel );
				if( iRobotMode[iClient] == Robot_BigNormal )
				{
					if( IsSmallMap == true )
					{
						if(iClass == TFClass_Scout)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Soldier)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Pyro)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_DemoMan)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Heavy)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Engineer)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Medic)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Sniper)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
						if(iClass == TFClass_Spy)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.1 );
							UpdatePlayerHitbox(iClient, 1.1);
						}
					}
					else
					{
						if(iClass == TFClass_Scout)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_Soldier)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_Pyro)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_DemoMan)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.3 );
							UpdatePlayerHitbox(iClient, 1.3);
						}
						if(iClass == TFClass_Heavy)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.5 );
							UpdatePlayerHitbox(iClient, 1.5);
						}
						if(iClass == TFClass_Engineer)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_Medic)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_Sniper)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
						if(iClass == TFClass_Spy)
						{
							SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.4 );
							UpdatePlayerHitbox(iClient, 1.4);
						}
					}
				}
				if( iRobotMode[iClient] == Robot_Small )
				{
					if(iClass == TFClass_Scout)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Soldier)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Pyro)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_DemoMan)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Heavy)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Engineer)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Medic)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Sniper)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
					if(iClass == TFClass_Spy)
					{
						SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
						UpdatePlayerHitbox(iClient, 0.65);
					}
				}
			}
		}
	}
	//SetEntProp( iClient, Prop_Send, "m_nSkin", 1);

	return Plugin_Stop;
}
public Action:Timer_DeleteParticle( Handle:hTimer, any:iEntRef )
{
	new iParticle = EntRefToEntIndex( iEntRef );
	if( IsValidEntity(iParticle) )
	{
		decl String:strClassname[256];
		GetEdictClassname( iParticle, strClassname, sizeof(strClassname) );
		if( StrEqual( strClassname, "info_particle_system", false ) )
			AcceptEntityInput( iParticle, "Kill" );
	}
}

public OnPlayerChangeTeam( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast ) //not you
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	if( GetEventInt( hEvent, "team" ) <= _:TFTeam_Spectator )
		return;
	
	if( GetEventInt( hEvent, "team" ) == _:TFTeam_Blue )
		flNextChangeTeamBlu = GetGameTime() + 3.0;
	
	flNextChangeTeam[iClient] = GetGameTime() + 3.0;
	
	CreateTimer( 0.0, Timer_OnPlayerChangeTeam, GetEventInt( hEvent, "userid" ) );

}

public OnPlayerChangeClass( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	DestroyBuildings( iClient );
}

public OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	
	if(IsFakeClient(iClient))
		IsGateBotPlayer[iClient] = false;
	
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
		
	if (g_hbombs1[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hbombs1[iClient]);
		g_hbombs1[iClient] = INVALID_HANDLE;
	}
	if (g_hbombs2[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hbombs2[iClient]);
		g_hbombs2[iClient] = INVALID_HANDLE;
	}
	if (g_hbombs3[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hbombs3[iClient]);
		g_hbombs3[iClient] = INVALID_HANDLE;
	}
	if (g_hDeployTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hDeployTimer);
		g_hDeployTimer = INVALID_HANDLE;
	}
	new Float:flModelScale = GetEntPropFloat(iClient, Prop_Send, "m_flModelScale");
	if(flModelScale > 1.0)//since robots with scale higher than 1 do gib always
		if(iRobotMode[iClient] != Robot_SentryBuster && GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			//PrintToChatAll("trigger");
			decl Float:ClientOrigin[3];
			GetClientAbsOrigin(iClient, ClientOrigin);
			GIBGIANT(iClient, ClientOrigin); //
		}
	//else if( iRobotMode[iClient] == Robot_BigNormal && iRobotMode[iClient] != Robot_SentryBuster && GameRules_GetRoundState() == RoundState_RoundRunning)
	//{
	//	PrintToChatAll("trigger");
	//	decl Float:ClientOrigin[3];
	//	GetClientAbsOrigin(iClient, ClientOrigin);
	//	GIBGIANT(iClient, ClientOrigin); //
	//}
	//CreateTimer(0.1, RemoveBody, iClient);
	
	CreateTimer( 0.0, Timer_OnPlayerDeath, GetEventInt( hEvent, "userid" ) );
}
public Action:OnPlayerSpawnPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast ) //not u crashing
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	bSkipInvAppEvent[iClient] = false;
	
	if( GetClientTeam(iClient) != _:TFTeam_Red ) // rocketjump fix
	{
		bInRespawn[iClient] = false;
	}
	
	// RED Spawn Protection
	if( GetClientTeam(iClient) ==  _:TFTeam_Red && bREDSpawnProtection )
	{
		if( iREDSPAttackType == 0 )
		{
			TF2_AddCondition( iClient, TFCond_CritCanteen, iREDSpawnProtectionTime);
		}
		else if( iREDSPAttackType == 1 )
		{
			TF2_AddCondition( iClient, TFCond_Buffed, iREDSpawnProtectionTime);
		}
		
		if( iREDSPDefenseType == 0 )
		{
			TF2_AddCondition( iClient, TFCond_UberchargedCanteen, iREDSpawnProtectionTime);
		}
		else if( iREDSPDefenseType == 1 )
		{
			TF2_AddCondition( iClient, TFCond_DefenseBuffed, iREDSpawnProtectionTime);
		}
		//CPrintToChatAll("{yellow}[DEBUG] {springgreen}Giving RED spawn protection!");
		//TF2_AddCondition( iClient, TFCond_UberchargedCanteen, iREDSpawnProtectionTime);
		//TF2_AddCondition( iClient, TFCond_CritCanteen, iREDSpawnProtectionTime);
		TF2_AddCondition( iClient, TFCond_SpeedBuffAlly, iREDSpawnProtectionTime);
	}
	
	if( GetClientTeam(iClient) != _:TFTeam_Blue )
		return Plugin_Continue;
	new bool:bCanPlayEngineer = CanPlayEngineer(iClient);
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if( iClass < TFClass_Scout || iClass > TFClass_Engineer || iClass > TFClass_Spy && !bCanPlayEngineer )
	{
		iClass = TFClassType:GetRandomInt(1,(bCanPlayEngineer?9:8));
		TF2_SetPlayerClass( iClient, iClass, _, true );
		TF2_RegeneratePlayer( iClient );
	}
	CreateTimer( 0.1, Timer_SetRobotModel, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
//	if( GameRules_GetRoundState() == RoundState_BetweenRounds && !bInRespawn[iClient] && GetClientTeam(iClient) == _:TFTeam_Blue )
//		CreateExtraSpawnAreas(iClient);
//	new iTeamNum = GetClientTeam(iClient);
//	if( iTeamNum == _:TFTeam_Blue )
//	{
//		TF2Attrib_SetByName(iClient, "cancel falling damage", 1.0);
//	}

	return Plugin_Continue;
}
//public Action:Timer_MarkGatebotsBot( Handle:Timer, any:client )//
//{

//}
public OnPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast ) //spy tele
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	//if(IsFakeClient(iClient) && IsMannhattan)
		//CreateTimer( 0.01, Timer_MarkGatebotsBot, iClient );
	new iTeamNum = GetClientTeam(iClient);
	SetEntityRenderColor(iClient, 255, 255, 255, 255);
	if(IsMvM() && !IsValidRobot(iClient) && !GateStunEnabled && IsFakeClient(iClient))
	{
			SpawnRobot(iClient);
	}
	if(!IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient))
	{
		return;
	}
	FixSounds( iClient );
	
	new bool:bPrintMsg = bNotifications && !bSkipSpawnEventMsg[iClient];
	if( !bSkipSpawnEventMsg[iClient] )
		bSkipSpawnEventMsg[iClient] = true;
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	

	if( iTeamNum == _:TFTeam_Blue )
	{
		decl String:strVariant[128];
		if( iRobotVariant[iClient] == -1 )
			PrintToChat( iClient, "\x01You're spawned as \x03Your Spy\x01");	//PrintToChat( iClient, "\x01You're spawned as \x03You are\x01", strVariant );
		else if( iRobotVariant[iClient] == -1 && IsGateBotPlayer[iClient])
			PrintToChat( iClient, "\x01You're spawned as \x03Your GateBot Spyx\01" );	//PrintToChat( iClient, "\x01You're spawned as \x03You are\x01", strVariant );
		else if( GetRobotVariantName( iClass, iRobotVariant[iClient], strVariant, sizeof(strVariant) ) && !IsGateBotPlayer[iClient])
			CPrintToChat( iClient, "{yellow}You're spawned as {blue}%s", strVariant );
		else if( GetRobotVariantName( iClass, iRobotVariant[iClient], strVariant, sizeof(strVariant) ) && IsGateBotPlayer[iClient] && iRobotMode[iClient] != Robot_SentryBuster )
			PrintToChat( iClient, "\x01You're spawned as \x03GateBot %s\x01", strVariant );
		else if( GetRobotVariantName( iClass, iRobotVariant[iClient], strVariant, sizeof(strVariant) ) && iRobotMode[iClient] == Robot_SentryBuster)
			CPrintToChat( iClient, "{yellow}You're spawned as {blue}%s", strVariant );
		if( bPrintMsg )
			PrintToChat( iClient, "\x01Type \x03/robomenu\x01 to change variant of your roboclass." );
	}
	else if( iTeamNum == _:TFTeam_Red )
	{
		//TF2Attrib_RemoveByName(iClient, "deflection size multiplier");
		TF2Attrib_RemoveByName(iClient, "flame life bonus");
		TF2Attrib_RemoveByName(iClient, "mult charge turn control");
		if( bPrintMsg )
			PrintToChat( iClient, "\x01You can play as BLU team. Type \x03/robohelp\x01 for details." );
		return;
	}
	else
		return;
	
	if( iClass == TFClass_Unknown )
		return;
	
	CreateTimer( 0.1, Timer_OnPlayerSpawn, GetClientUserId(iClient) );
	
	if( iRobotMode[iClient] == Robot_SentryBuster )
		CPrintToChat( iClient, "{orange}Sentry Buster:{yellow} Press {red}Taunt {yellow}button to detonate." );

	// Spawn Messages
	if( iClass == TFClass_Engineer || iClass == TFClass_Spy )
		CPrintToChat( iClient, "{orange}[BWR]{yellow}: You've spawned as a {blue}Support Class{yellow}. You cannot pick up the bomb." );
	if( iClass == TFClass_Medic && IsAttackClass[iClient] == false )
		CPrintToChat( iClient, "{orange}[BWR]{yellow}: You've spawned as a {blue}Support Class{yellow}. You cannot pick up the bomb." );
	if( iClass == TFClass_Sniper && IsAttackClass[iClient] == false )
		CPrintToChat( iClient, "{orange}[BWR]{yellow}: You've spawned as a {blue}Support Class{yellow}. You cannot pick up the bomb." );
}
public Action:Timer_TeleportSpy( Handle:Timer, any:client )//spytele
{
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	if( iClass == TFClass_Spy && IsPlayerAlive(client) )
		//CreateTimer(12.0, Timer_RoboSpyTauntRedPlayers, client, TIMER_REPEAT);
		CreateTimer(7.0, Timer_RoboSpyTauntRedPlayers, client);
	if( iClass == TFClass_Spy && TF2_IsPlayerInCondition( client, TFCond_Cloaked ) && bCanSpyTeleport == true )
	{
	
		//new iEnt = FindRandomSpawnSpyPoint(iEnt);
		new i6 = FindNearestSpyHint();
		new Float:SpyHintPos[3];
		GetEntPropVector(i6, Prop_Send, "m_vecOrigin", SpyHintPos);
		SpyHintPos[2]+=13;
		TeleportEntity(client, SpyHintPos, NULL_VECTOR, NULL_VECTOR);
		if(iClass == TFClass_Spy)
		{
			TeleportEntity(client, SpyHintPos, NULL_VECTOR, NULL_VECTOR);
			//GiveSpawnProtection(i, 1.4);
			CreateTimer( 0.1, RemoveSpawnProtection, client );
			//TF2_AddCondition(client, TFCond_UberchargedHidden, 0.75);
			//TF2_AddCondition(client, TFCond_UberchargeFading, 0.75);
			//if(IsMannhattan || IsDecoy)
			//	CreateTimer( 0.2, Timer_Checkstuck, client);
		}
	}
}
FindNearestSpyHint()
{
	new Float:pVec[3];
	new Float:nVec[3];
	new found = -1;
	new Float:MAX_DIST = 10000.0;
	new Float:found_dist = MAX_DIST;
	new Float:aux_dist;
	new i5 = -1;
	while((i5 = FindEntityByClassname(i5, "info_target")) != -1)
	{
		if(IsValidEntity(i5))
		{
			decl String:strName[50];
			GetEntPropString(i5, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bwr_spy_spawnpoint") == 0)
			{
				GetEntPropVector(i5, Prop_Send, "m_vecOrigin", nVec);
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						GetClientEyePosition(i, pVec);
						aux_dist = GetVectorDistance(pVec, nVec, false);
						if(aux_dist < found_dist && aux_dist > 2000) // to not spawn in the line of fire
						{
							found = i5;
							found_dist = aux_dist;
						}
					}
				}
			}
		}
	}
	return found;
}
public Action:Timer_Checkstuck( Handle:Timer, any:client )//spytele
{
	if(CheckIfPlayerIsStuck(client))
	{
		new Float:Stuckpos[3];
		GetClientAbsOrigin(client, Stuckpos);
		if(IsMannhattan)
			Stuckpos[0]+=-45;
		if(IsDecoy)
			Stuckpos[1]+=45;
		TeleportEntity(client, Stuckpos, NULL_VECTOR, NULL_VECTOR);
	}	
}
public Action:Timer_TeleParachute( Handle:Timer, any:client )//Parachute Tele
{
	//new TFClassType:iClass = TF2_GetPlayerClass(client);
	if( CanAirSpawn[client] == true )
	{
	
		//new iEnt = FindRandomSpawnSpyPoint(iEnt);
		new i6 = FindNearestParachuteHint();
		new Float:ParachuteHintPos[3];
		GetEntPropVector(i6, Prop_Send, "m_vecOrigin", ParachuteHintPos);
		ParachuteHintPos[2]+=13;
		TeleportEntity(client, ParachuteHintPos, NULL_VECTOR, NULL_VECTOR);
		if( CanAirSpawn[client] == true )
		{
			TeleportEntity(client, ParachuteHintPos, NULL_VECTOR, NULL_VECTOR);
			CreateTimer( 0.1, RemoveSpawnProtection, client );
		}
	}
}
public Action:Timer_ForceParachute( Handle:Timer, any:client )//Parachute Tele
{
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	if( iClass == TFClass_Soldier )
	{
		TF2_AddCondition(client, TFCond:TFCond_Parachute, TFCondDuration_Infinite);
		TF2_AddCondition(client, TFCond:TFCond_BlastJumping, 30.0);
		TF2_AddCondition(client, TFCond:TFCond_UberchargedCanteen, 4.0);
	}
	else
	{
		TF2_AddCondition(client, TFCond:TFCond_Parachute, TFCondDuration_Infinite);
		TF2_AddCondition(client, TFCond:TFCond_UberchargedCanteen, 4.0);
	}
}
FindNearestParachuteHint() // Parachute Hint Entity
{
	new Float:pVec[3];
	new Float:nVec[3];
	new found = -1;
	new Float:MAX_DIST = 14000.0;
	new Float:found_dist = MAX_DIST;
	new Float:aux_dist;
	new i5 = -1;
	//new iClient = GetClientOfUserId( iClient );
	while((i5 = FindEntityByClassname(i5, "info_target")) != -1)
	{
		if(IsValidEntity(i5))
		{
			decl String:strName[50];
			GetEntPropString(i5, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bwr_parachute_spawn") == 0)
			{
				GetEntPropVector(i5, Prop_Send, "m_vecOrigin", nVec);
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Red)
					{
						GetClientEyePosition(i, pVec);
						aux_dist = GetVectorDistance(pVec, nVec, false);
						if(aux_dist < found_dist && aux_dist > 2000) // to not spawn in the line of fire
						{
							found = i5;
							found_dist = aux_dist;
						}
					}
				}
			}
		}
	}
	return found;
}
stock bool:CheckIfPlayerIsStuck(iClient)//spytele
{
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(iClient, vecMin);
	GetClientMaxs(iClient, vecMax);
	GetClientAbsOrigin(iClient, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
	return TR_DidHit();	// head in wall ?
}


public bool:TraceEntityFilterSolid(entity, contentsMask) //spytele
{
	return entity > 1;
}

/* stock FindRandomSpawnSpyPoint( iType )//spytele
{
	new Handle:hSpawnPoint = CreateArray();
	new iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "info_target") ) != -1 )
	{
		if(IsValidEntity(iEnt))
		{
			decl String:strName[50];
			GetEntPropString(iEnt, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bwr_spy_spawnpoint") == 0)
			{
				PushArrayCell( hSpawnPoint, iEnt );
			}
		}
	}
	if( GetArraySize(hSpawnPoint) > 0 )
	{
		return GetArrayCell( hSpawnPoint, GetRandomInt(0,GetArraySize(hSpawnPoint)-1) );
		CloseHandle( hSpawnPoint );
	}
	CloseHandle( hSpawnPoint );
	
	return -1;
} */

/*
public Action:TF2Items_OnGiveNamedItem( iClient, String:strClassname[], iItemDefID, &Handle:hItem )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	if( !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	new TFClassType:iClass = TF2_GetPlayerClass( iClient );
	new TF2ItemSlot:iSlot = TF2II_GetItemSlot( iItemDefID, iClass );
	
	if( iSlot == TF2ItemSlot_Action || iSlot == TF2ItemSlot_Misc )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
*/
public OnPostInventoryApplication( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	if( !IsMvM() )
		return;
	
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) )
		return;

	if( bSkipInvAppEvent[iClient] )
	{
		bSkipInvAppEvent[iClient] = false;
		return;
	}
	//if( !bInRespawn[iClient] && IsPlayerAlive(iClient) && GameRules_GetRoundState() == RoundState_BetweenRounds && GetClientTeam(iClient) == _:TFTeam_Blue )
	//{
	//	CreateExtraSpawnAreas(iClient);
	//}
	if( GetClientTeam(iClient) != _:TFTeam_Blue )
	{
		if( bStripItems[iClient] )
			StripItems( iClient );
		bStripItems[iClient] = false;
		
		bSkipInvAppEvent[iClient] = true;
		TF2_RegeneratePlayer( iClient );
		return;
	}
	new String:weaponAttribs[256];
	StripItems( iClient );
	new TFClassType:iClass = TF2_GetPlayerClass( iClient );
	switch( iClass ) // robot variants
	{
		case TFClass_Scout:
		{	
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30153, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30154, 100, 5, weaponAttribs, true );//roam vision 
				
			// Scout Variants
			if( iRobotVariant[iClient] == 0 ) // Standard Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1"); // unlimited quantity hidden - inf ammo?
				SpawnWeapon( iClient, "tf_weapon_scattergun", 13, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 1 ) // Batsaber Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 11.0 ; 5 ; 1.35 ; 125 ; -45");
				SpawnWeapon( iClient, "tf_weapon_bat", 30667, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 2 ) // Fish Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "218 ; 1 ; 1 ; 0.4 ; 396 ; 0.8 ; 140 ; 25 ; 16 ; 30 ; 182 ; 8");
				SpawnWeapon( iClient, "tf_weapon_bat_fish", 221, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 3 ) // Armored Combat Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 475 ; 60 ; 0.3 ; 62 ; 0.9 ; 64 ; 0.7 ; 66 ; 0.5 ; 54 ; 0.65 ; 252 ; 1.4 ; 5 ; 1.60");
				SpawnWeapon( iClient, "tf_weapon_scattergun", 13, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 4 ) // Sword Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 275 ; 16 ; 5");
				SpawnWeapon( iClient, "tf_weapon_bat", 452, 100, 5, weaponAttribs, false ); // Three-Rune Blade
			}
			if( iRobotVariant[iClient] == 5 ) // Minor League Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1 ; 140 ; 15"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 6 ) // Hyper League Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.25 ; 140 ; 15"); // 75% Faster Ball Recharge
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 7 ) // Bonk Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_lunchbox_drink", 46, 100, 5, weaponAttribs, false ); // BONK!
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_bat", 0, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 8 ) // Wrap Assassin
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.60 ; 149 ; 6 ; 522 ; 1 ; 366 ; 1"); // 40% faster ball recharge, bleed for 6 seconds, damage causes airblast, stun airborne enemies for 3 seconds
				SpawnWeapon( iClient, "tf_weapon_bat_giftwrap", 648, 100, 5, weaponAttribs, false ); // Wrap Assassin
			}
			if( iRobotVariant[iClient] == 9 ) // Jump Sandman
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.50 ; 326 ; 2 ; 140 ; 15"); // 50% Faster Ball Recharge
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 10 ) // Force-A-Nature Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 318 ; 1.6 ; 518 ; 1.5 ; 1 ; 1.35");
				SpawnWeapon( iClient, "tf_weapon_scattergun", 45, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 11 ) // Scout MK II
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 75 ; 326 ; 1.25 ; 107 ; 1.15 ; 45 ;  1.25 ; 96 ; 1.5 ; 2 ; 1.65 ; 5 ; 0.5 ; 348 ; 1.5 ; 324 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_scattergun", 13, 100, 5, weaponAttribs, false );
			}
			// GIANT SCOUT BEGIN HERE
			if( iRobotVariant[iClient] == 12 ) // Giant Scout (Standard)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 1475 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5"); // inf ammo?
				SpawnWeapon( iClient, "tf_weapon_scattergun", 13, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 13 ) // Giant Super Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 1075 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5 ; 107 ; 2.0"); // Nerf: move speed 100% -> 15%
				SpawnWeapon( iClient, "tf_weapon_bat_fish", 221, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 14 ) // Force-a-Nature Super Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 1075 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5 ; 107 ; 1.1 ; 45 ; 2 ; 6 ; 0.5 ; 318 ; 1.7 ; 518 ; 6 ; 1 ; 0.35 ; 106 ; 0.4");
				SpawnWeapon( iClient, "tf_weapon_scattergun", 45, 100, 5, weaponAttribs, false );
			}
			if( iRobotVariant[iClient] == 15 ) // Giant Jumping Sandman
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 1090 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5 ; 2 ; 2 ; 278 ; 0.1 ; 326 ; 2"); // inf ammo?
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 16 ) // Major League Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 1490 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5 ; 278 ; 0.1"); // inf ammo?
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 17 ) // Armored Sandman Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 2890 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5 ; 278 ; 0.05"); // inf ammo?
				SpawnWeapon( iClient, "tf_weapon_bat_wood", 44, 100, 5, weaponAttribs, false ); // The Sandman
			}
			if( iRobotVariant[iClient] == 18 ) // Giant BONK Scout
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 1 ; 140 ; 975 ; 252 ; 0.7 ; 329 ; 0.7 ; 330 ; 5"); // Nerf: 900 HP
				SpawnWeapon( iClient, "tf_weapon_scattergun", 13, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.70");
				SpawnWeapon( iClient, "tf_weapon_lunchbox_drink", 46, 100, 5, weaponAttribs, false ); // Nerf: original 45% recharge speed, now 10%
			}
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 63");
			//	SpawnWeapon( iClient, "tf_wearable", 1057, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_Soldier: // Soldier Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30157, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30158, 100, 5, weaponAttribs, true );//roam vision 
				
			if( iRobotVariant[iClient] == 0 ) //normal soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 1 ) //Extended Buff Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 129, 100, 5, weaponAttribs, false ); // Buff Banner
			}
			else if( iRobotVariant[iClient] == 2 ) //Extended Backup Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 226, 100, 5, weaponAttribs, false ); // Battalions Backup
			}
			else if( iRobotVariant[iClient] == 3 ) //Extended Conch Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 354, 100, 5, weaponAttribs, false ); // Concheror Banner
			}
			else if( iRobotVariant[iClient] == 4 ) //Push Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 522 ; 1 ; 1 ; 0.45 ; 6 ; 0.001 ; 440 ; -2 ; 318 ; 1.5 ; 100 ; 1.2 ; 411 ; 2");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 414, 100, 5, weaponAttribs, false ); // The Liberty Launcher
			}
			else if( iRobotVariant[iClient] == 5 ) //Black Box Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 1 ; 0.33 ; 6 ; 0.001 ; 318 ; 0.9 ; 99 ; 1.25 ; 411 ; 2 ; 16 ; 60");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 228, 100, 5, weaponAttribs, false ); // The Black Box
			}
			else if( iRobotVariant[iClient] == 6 ) // Science Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_particle_cannon", 441, 100, 5, weaponAttribs, false ); // The Cow Mangler 5000
			}
			else if( iRobotVariant[iClient] == 7 ) // Air Force Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 318 ; 0.5 ; 181 ; 1 ; 140 ; 550 ; 275 ; 1 ; 16 ; 10");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher_airstrike", 1104, 100, 5, weaponAttribs, false ); // The Air Strike
				Format(weaponAttribs, sizeof(weaponAttribs), "326 ; 4.5");
				SpawnWeapon( iClient, "tf_weapon_parachute", 1101, 100, 5, weaponAttribs, false ); // The B.A.S.E. Jumper
				CanAirSpawn[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 8 ) // Mini Rocket Spammer
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 150 ; 440 ; 12 ; 6 ; 0.5 ; 411 ; 2");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 9 ) // Stun Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 488 ; 4");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 10 ) // Direct Hit Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher_directhit", 127, 100, 5, weaponAttribs, false ); // DH
			}
			else if( iRobotVariant[iClient] == 11 ) // Bizon Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 1.15");
				SpawnWeapon( iClient, "tf_weapon_raygun", 442, 100, 5, weaponAttribs, false ); // The Righteous Bison
			}
			else if( iRobotVariant[iClient] == 12 ) // Market Gardener
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "57 ; 4");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 237, 100, 5, weaponAttribs, false ); // Rocket Jumper
				Format(weaponAttribs, sizeof(weaponAttribs), "275 ; 1");
				SpawnWeapon( iClient, "tf_weapon_parachute", 1101, 100, 5, weaponAttribs, false ); // The B.A.S.E. Jumper
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shovel", 416, 100, 5, weaponAttribs, false ); // The Market Gardener
				CanAirSpawn[iClient] = true;
			}
			// Giant Soldiers Variants
			else if( iRobotVariant[iClient] == 13 ) // Giant Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 14 ) // Rocket Spammer
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 7800 ; 252 ; 0.7 ; 329 ; 0.3 ; 330 ; 3 ; 405 ; 0.1 ; 6 ; 0.3 ; 440 ; 36 ; 318 ; 0.6 ; 411 ; 2");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}	
			else if( iRobotVariant[iClient] == 15 ) // Giant Charged Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 318 ; 0.2 ; 6 ; 2.0 ; 103 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 513, 100, 5, weaponAttribs, false ); // The Original
			}
			else if( iRobotVariant[iClient] == 16 ) // Giant Rapid Fire Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 318 ; -0.8 ; 6 ; 0.5 ; 103 ; 0.65");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 17 ) // Giant Buff Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 129, 100, 5, weaponAttribs, false ); // Buff Banner
			}
			else if( iRobotVariant[iClient] == 18 ) // Giant Backup Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 226, 100, 5, weaponAttribs, false ); // Battalions Backup
			}
			else if( iRobotVariant[iClient] == 19 ) // Giant Conch Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
				Format(weaponAttribs, sizeof(weaponAttribs), "319 ; 9.0");
				SpawnWeapon( iClient, "tf_weapon_buff_item", 354, 100, 5, weaponAttribs, false ); // Concheror Banner
			}
			else if( iRobotVariant[iClient] == 20 ) // Giant Black Box Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3800 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 1 ; 0.45 ; 6 ; 0.001 ; 318 ; 1.6 ; 99 ; 1.25 ; 411 ; 4 ; 16 ; 1000 ; 103 ; 0.9");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 228, 100, 5, weaponAttribs, false ); // The Black Box
			}
			else if( iRobotVariant[iClient] == 21 ) // Giant Burst Fire Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 4000 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 2 ; 2.0 ; 318 ; 0.4 ; 6 ; 0.2 ; 440 ; 5 ; 103 ; 0.9");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 22 ) // Giant Blast Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 1 ; 0.75 ; 522 ; 1 ; 6 ; 0.25 ; 440 ; 5 ; 318 ; 0.2 ; 100 ; 1.2 ; 411 ; 4 ; 405 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 414, 100, 5, weaponAttribs, false ); // The Liberty Launcher
			}
			else if( iRobotVariant[iClient] == 23 ) // Giant Direct Hit Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher_directhit", 127, 100, 5, weaponAttribs, false ); // DH
			}
			else if( iRobotVariant[iClient] == 24 ) // Giant Science Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 3600 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3");
				SpawnWeapon( iClient, "tf_weapon_particle_cannon", 441, 100, 5, weaponAttribs, false ); // The Cow Mangler 5000
			}
			else if( iRobotVariant[iClient] == 25 ) // Giant Shotgun Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.75 ; 140 ; 4800 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 335 ; 3.0 ; 318 ; 0.4 ; 6 ; 0.75 ; 45 ; 1.8 ; 2 ; 1.6 ; 106 ; 0.6");
				SpawnWeapon( iClient, "tf_weapon_shotgun_soldier", 10, 100, 5, weaponAttribs, false ); // Solly Shotgun
			}	
			else if( iRobotVariant[iClient] == 26 ) // Giant Australium Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 140 ; 7000 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 150 ; 1 ; 2 ; 2.5 ; 542 ; 1");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 205, 100, 5, weaponAttribs, false ); // RL
			}		
			else if( iRobotVariant[iClient] == 27 ) // Giant Rocket-Barrage Soldier
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.4 ; 140 ; 3220 ; 252 ; 0.4 ; 329 ; 0.4 ; 330 ; 3 ; 59 ; 0.0 ; 181 ; 2 ; 4 ; 10.0 ; 318 ; 0.5 ; 1 ; 0.15 ; 104 ; 0.35 ; 411 ; 4 ; 31 ; 5");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 730, 100, 5, weaponAttribs, false ); // RL
			}
			else if( iRobotVariant[iClient] == 101 )// Major Crits
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "330 ; 3 ; 2 ; 5 ; 103 ; 1 ; 99 ; 2 ; 522 ; 1 ; 318 ; 3 ; 6 ; 2 ; 411 ; 1 ; 521 ; 1 ; 107 ; 0.4 ; 329 ; 0.4 ; 252 ; 0.4 ; 405 ; 0.1 ; 140 ; 39800");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 228, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 100 )// Sergeant Crits
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "330 ; 3 ; 2 ; 1.5 ; 140 ; 59800 ; 107 ; 0.3 ; 252 ; 0.4 ; 329 ; 0.4 ; 6 ; 0.2 ; 318 ; 0.6 ; 440 ; 7.0 ; 103 ; 1.3 ; 57 ; 250.0 ; 478 ; 0.1 ; 405 ; 0.1 ; 330 ; 3.0");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false);
			}
			else if( iRobotVariant[iClient] == 102 )// Celestial Rocket Spammer
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.25 ; 140 ; 48800 ; 252 ; 0.7 ; 329 ; 0.4 ; 330 ; 3 ; 440 ; 76 ; 6 ; 0.1 ; 318 ; 0.2 ; 411 ; 5 ; 99 ; 2.0 ; 103 ; 1.25 ; 180 ; 5000 ; 57 ; 10 ; 478 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher", 18, 100, 5, weaponAttribs, false );
			}
		}
		case TFClass_Pyro: // Pyro Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30151, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30152, 100, 5, weaponAttribs, true );//roam vision 
				
			if( iRobotVariant[iClient] == 0 ) // Normal Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 21, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 1 ) // Flare Gun Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_flaregun", 39, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 2 ) // Pyro Pusher
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 2 ; 1 ; 6 ; 0.75 ; 318 ; 1.25 ; 103 ; 0.35");
				SpawnWeapon( iClient, "tf_weapon_flaregun", 740, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 3 ) // Fast Scorch Shot
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 2 ; 1 ; 6 ; 0.75 ; 318 ; 1.25 ; 103 ; 1.3");
				SpawnWeapon( iClient, "tf_weapon_flaregun", 740, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 4 ) // Shotgun Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 4 ; 2 ; 2 ; 1.15 ; 31 ; 10 ; 318 ; 0.5 ; 6 ; 0.8");
				SpawnWeapon( iClient, "tf_weapon_shotgun_pyro", 12, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 5 ) // Moonraker
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.45 ; 140 ; 75 ; 107 ; 1.25");
				SpawnWeapon( iClient, "tf_weapon_fireaxe", 2, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 6 ) // Moonman
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "280 ; 13 ; 318 ; -1 ; 6 ; 0.3 ; 1004 ; 4");
				SpawnWeapon( iClient, "tf_weapon_flaregun_revenge", 595, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 7 ) // Phlog Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 594, 100, 5, weaponAttribs, false ); // The Phlogistinator
			}
			else if( iRobotVariant[iClient] == 8 ) // Dragun's Fury Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 2 ; 1.75 ; 140 ; 50");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher_fireball", 1178, 100, 5, weaponAttribs, false ); // Dragon's Fury
			}
			else if( iRobotVariant[iClient] == 9 ) // Gas Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 21, 100, 5, weaponAttribs, false ); // Default Flamethrower
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 875 ; 1 ; 874 ; 0.2");
				SpawnWeapon( iClient, "tf_weapon_jar_gas", 1180, 100, 5, weaponAttribs, false ); // The Gas Passer
			}
			else if( iRobotVariant[iClient] == 10 ) // Hot Hand Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.45 ; 107 ; 1.10 ; 140 ; 225");
				SpawnWeapon( iClient, "tf_weapon_slap", 1181, 100, 5, weaponAttribs, false ); // The butt slapper
			}
			else if( iRobotVariant[iClient] == 11 ) // Long Range Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 844 ; 5000.0 ; 862 ; 1.0");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 21, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 12 ) // Elite Shotgun Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 2 ; 1.30 ; 5 ; 0.50 ; 45 ; 1.6 ; 107 ; 1.15");
				SpawnWeapon( iClient, "tf_weapon_shotgun_pyro", 12, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 13 ) // Combo Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 1.15");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 21, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 795 ; 2.0");
				SpawnWeapon( iClient, "tf_weapon_fireaxe", 38, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 14 ) // Thermal Thruster Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 325 ; 107 ; 1.35");
				SpawnWeapon( iClient, "tf_weapon_rocketlauncher_fireball", 1178, 100, 5, weaponAttribs, false ); // Dragon's Fury
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 871 ; 1 ; 872 ; 1 ; 874 ; 0.85 ; 275 ; 1");
				SpawnWeapon( iClient, "tf_weapon_rocketpack", 1179, 100, 5, weaponAttribs, false );
			}
			// Giant Pyros
			else if( iRobotVariant[iClient] == 15 ) // Giant Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 330 ; 6 ; 140 ; 2825");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 21, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 16 ) // Giant Flare Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 330 ; 6 ; 140 ; 2825 ; 6 ; 0.3");
				SpawnWeapon( iClient, "tf_weapon_flaregun", 351, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 17 ) // Giant Flare Pyro (Scorch Shot)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.35 ; 252 ; 0.6 ; 329 ; 0.6 ; 330 ; 6 ; 140 ; 2825 ; 6 ; 0.2 ; 522 ; 1");
				SpawnWeapon( iClient, "tf_weapon_flaregun", 740, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 18 ) // Giant Airblast Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 330 ; 6 ; 140 ; 2825 ; 2 ; 0.05 ; 6 ; 1 ; 255 ; 5");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 215, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 19 ) // Giant Napalm Pyro
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 0.4 ; 252 ; 0.6 ; 329 ; 0.6 ; 330 ; 6 ; 140 ; 2825 ; 73 ; 10 ; 71 ; 2.5 ; 1 ; 0.25 ; 356 ; 1");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 30474, 100, 5, weaponAttribs, false );
			}
			// BOSSES
			else if( iRobotVariant[iClient] == 100 )// Chief Pyro (Boss System)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 54825 ; 107 ; 0.4 ; 252 ; 0.3 ; 329 ; 0.3 ; 2 ; 5 ; 255 ; 2 ; 57 ; 500 ; 478 ; 0.1 ; 405 ; 0.1 ; 330 ; 6");
				SpawnWeapon( iClient, "tf_weapon_flamethrower", 208, 100, 5, weaponAttribs, false );
			}
			//Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
			//SpawnWeapon( iClient, "tf_weapon_fireaxe", 2, 100, 5, weaponAttribs, false );
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1058, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_DemoMan: // Demo Variants
		{
			CanAirSpawn[iClient] = false;
			if( iRobotVariant[iClient] != SENTRYBUSTER_CLASSVARIANT )
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
				SpawnWeapon( iClient, "tf_wearable", 30143, 100, 5, weaponAttribs, true );
				if(!IsGateBotPlayer[iClient])
					SpawnWeapon( iClient, "tf_wearable", 30144, 100, 5, weaponAttribs, true );//roam vision 
			}
			if( iRobotVariant[iClient] == SENTRYBUSTER_CLASSVARIANT )
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 2325 ; 107 ; 1.4 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 7 ; 402 ; 1 ; 137 ; 0.0 ; 1 ; 0.0");//fixed sentrybuster speed.... again
				SpawnWeapon( iClient, "tf_weapon_stickbomb", 307, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
				SpawnWeapon( iClient, "tf_wearable", 30161, 100, 5, weaponAttribs, true );
			}
			else
			{
				if( iRobotVariant[iClient] == 0 ) // Normal Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_weapon_bottle", 1, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 1 ) // Demoknight
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 131, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 25");
					SpawnWeapon( iClient, "tf_weapon_sword", 132, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 2 ) // Samurai Demo
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "1030 ; 1 ; 302 ; 2 ; 249 ; 3.5 ; 326 ; 2.3 ; 498 ; 1 ; 348 ; 1.15 ; 676 ; 1");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 406, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.5 ; 140 ; 475");
					SpawnWeapon( iClient, "tf_weapon_katana", 357, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 3 ) // Burst Fire Demo
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "318 ; 1.75 ; 6 ; 0.05 ; 3 ; 0.5 ; 411 ; 3");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_weapon_bottle", 1, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 4 ) // Cannon Demo
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.6 ; 99 ; 1.4 ; 96 ; 1.6");
					SpawnWeapon( iClient, "tf_weapon_cannon", 996, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 5 ) // Explosive Melee Demo
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "1030 ; 1 ; 302 ; 2 ; 249 ; 2");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 406, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.20 ; 99 ; 5.0 ; 140 ; 125 ; 797 ; 1");
					SpawnWeapon( iClient, "tf_weapon_stickbomb", 307, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 6 ) // Spammer Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 6 ; 0.2 ; 318 ; 0.25 ; 411 ; 2 ; 103 ; 1.25 ; 1 ; 0.5");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 475 ; 57 ; 2 ; 69 ; 0.25");
					SpawnWeapon( iClient, "tf_weapon_stickbomb", 307, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 7 ) // Precision Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 2 ; 1.80 ; 96 ; 2.0 ; 103 ; 3.0");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 308, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 8 ) // Demopan
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 131, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeaponNoForce( iClient, "saxxy", 264, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 9 ) // Charger Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 202 ; 2 ; 248 ; 4.0 ; 247 ; 1");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 131, 100, 5, weaponAttribs, true );
				}
				else if( iRobotVariant[iClient] == 10 ) // Minefield Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 88 ; 8 ; 97 ; 0.5");
					SpawnWeapon( iClient, "tf_weapon_pipebomblauncher", 20, 100, 5, weaponAttribs, false );
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_weapon_bottle", 1, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 11 ) // Giant Rapid Fire Demoman (Type 1)
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 3125 ; 107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 4 ; 318 ; -0.4 ; 6 ; 0.75");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 12 ) // Giant Rapid Fire Demoman (Type 2)
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 3125 ; 107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 4 ; 6 ; 0.5");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 13 ) // Giant Demoknight
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
					SpawnWeapon( iClient, "tf_wearable", 405, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 3150 ; 107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 4");
					SpawnWeapon( iClient, "tf_wearable_demoshield", 131, 100, 5, weaponAttribs, true );
					Format(weaponAttribs, sizeof(weaponAttribs), "31 ; 3");
					SpawnWeapon( iClient, "tf_weapon_sword", 132, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 14 ) // Giant Burst Fire Demo
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 3125 ; 107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 4 ; 318 ; 0.65 ; 6 ; 0.1 ; 440 ; 7 ; 411 ; 5 ; 103 ; 1.1");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 19, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 15 ) // Giant Cannon Demoman
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 3725 ; 107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 4 ; 2 ; 3.5 ; 99 ; 2.5 ; 96 ; 2.6 ; 521 ; 1");
					SpawnWeapon( iClient, "tf_weapon_cannon", 996, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 100 ) //Major Bomber (Boss System)
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 39825 ; 107 ; 0.32 ; 252 ; 0.7 ; 329 ; 0.3 ; 3 ; 3 ; 103 ; 1.5 ; 478 ; 0.1 ; 405 ; 0.1 ; 330 ; 4");
					SpawnWeapon( iClient, "tf_weapon_grenadelauncher", 206, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 101 ) //Chief Tavish (Boss System)
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 54850 ; 107 ; 0.4 ; 252 ; 0.3 ; 329 ; 0.3 ; 57 ; 500 ; 478 ; 0.1 ; 405 ; 0.1 ; 330 ; 4");
					SpawnWeapon( iClient, "tf_weapon_sword", 132, 100, 5, weaponAttribs, false );
				}
				else if( iRobotVariant[iClient] == 102 ) //Sir NukeSalot (Boss System)
				{
					Format(weaponAttribs, sizeof(weaponAttribs), "330 ; 4 ; 466 ; 0 ; 521 ; 1 ; 2 ; 7 ; 6 ; 2 ; 318 ; 1.8 ; 522 ; 1 ; 99 ; 1.2 ; 3 ; 0.5 ; 411 ; 5 ; 103 ; 0.8 ; 107 ; 0.35 ; 329 ; 0.4 ; 140 ; 49825");
					SpawnWeapon( iClient, "tf_weapon_cannon", 996, 100, 5, weaponAttribs, false );
				}
			}
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1061, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_Heavy: // Heavy Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30147, 100, 5, weaponAttribs, true );
			///if(!IsGateBotPlayer[iClient]) heavy has all times the roam vision hats checked
			SpawnWeapon( iClient, "tf_wearable", 30148, 100, 5, weaponAttribs, true );//roam vision 
			if( iRobotVariant[iClient] == 0 ) // Normal Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_minigun", 15, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 1 ) // Steel Gauntlet
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 600");
				SpawnWeapon( iClient, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 2 ) // Fast Puncher
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 107 ; 1.3 ; 396 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_fists", 43, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 3 ) // Heavyweight Champ
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_fists", 43, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 4 ) // Heavy Mittens
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 125 ; -240 ; 107 ; 1.3");
				SpawnWeapon( iClient, "tf_weapon_fists", 656, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 5 ) // Steel Gauntlet Pusher
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 600 ; 2 ; 1.5 ; 522 ; 1");
				SpawnWeapon( iClient, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 6 ) // Heavy Shotgun
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 318 ; 0.1 ; 6 ; 2.5 ; 45 ; 3 ; 2 ; 0.33");
				SpawnWeapon( iClient, "tf_weapon_shotgun_hwg", 11, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 7 )// Giant Deflector Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 323 ; 2");
				SpawnWeapon( iClient, "tf_weapon_minigun", 850, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 8 ) // Giant Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2");
				SpawnWeapon( iClient, "tf_weapon_minigun", 15, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 9 ) // Giant Shotgun Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 318 ; 0.1 ; 6 ; 2.5 ; 45 ; 10 ; 1 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_shotgun_hwg", 11, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 10 ) // Giant Heavy (Brass Beast)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2");
				SpawnWeapon( iClient, "tf_weapon_minigun", 312, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 11 ) // Giant Heavy (Natascha)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2");
				SpawnWeapon( iClient, "tf_weapon_minigun", 41, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 12 )// Giant deflector heavy heal on kill
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 2 ; 1.2 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 323 ; 2 ; 180 ; 5000");
				SpawnWeapon( iClient, "tf_weapon_minigun", 850, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 13 ) // Giant Mafia Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 106 ; 0.5 ; 797 ; 1");
				SpawnWeapon( iClient, "tf_weapon_minigun", 424, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 14 ) // Giant Armored Heavy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4700 ; 107 ; 0.4 ; 2 ; 1.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 330 ; 2 ; 60 ; 0.1 ; 64 ; 0.4 ; 66 ; 0.25 ; 206 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_minigun", 298, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 100 )
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 59700 ; 107 ; 0.4 ; 57 ; 250 ; 6 ; 0.6 ; 2 ; 5 ; 252 ; 0.3 ; 330 ; 2 ; 405 ; 0.1 ; 478 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
			}
			Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
			if( iRobotVariant[iClient] == 0 || 11 > iRobotVariant[iClient] >= 6 || iRobotVariant[iClient] == 0)
				SpawnWeapon( iClient, "tf_weapon_fists", 5, 100, 5, weaponAttribs, false );
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1060, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_Medic: // Medic Variants
		{
			CanAirSpawn[iClient] = false;
			IsAttackClass[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30149, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30150, 100, 5, weaponAttribs, true );//roam vision 
			
			if( iRobotVariant[iClient] == 0 ) //Uber Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "8 ; 5");
				SpawnWeapon( iClient, "tf_weapon_medigun", 29, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 1 ) //Uber Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "8 ; 5");
				SpawnWeapon( iClient, "tf_weapon_medigun", 29, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 2 ) //Quick Uber Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "8 ; 0.1 ; 10 ; 5 ; 314 ; -3");
				SpawnWeapon( iClient, "tf_weapon_medigun", 29, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 3 ) //Quick-Fix Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "307 ; 1");
				SpawnWeapon( iClient, "tf_weapon_medigun", 411, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 4 ) //Big Heal Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "8 ; 10 ; 10 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_medigun", 411, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 5 ) //Vaccinator Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "10 ; 3.5");
				SpawnWeapon( iClient, "tf_weapon_medigun", 998, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 6 ) //Shield Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "499 ; 2 ; 319 ; 2 ; 190 ; 8");
				SpawnWeapon( iClient, "tf_weapon_medigun", 411, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 7 ) //Kritzkrieg Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "10 ; 2.5 ; 314 ; 6");
				SpawnWeapon( iClient, "tf_weapon_medigun", 35, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 8 ) //Crossbow Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 318 ; 0.5 ; 6 ; 0.4 ; 4 ; 5.0 ; 1 ; 0.4 ; 140 ; 450");
				SpawnWeapon( iClient, "tf_weapon_crossbow", 305, 100, 5, weaponAttribs, false );
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 9 ) //Battle Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 1 ; 0.9 ; 16 ; 4 ; 6 ; 0.85");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "5 ; 1.3 ; 140 ; 40 ; 64 ; 0.75");
				SpawnWeapon( iClient, "tf_weapon_bonesaw", 8, 100, 5, weaponAttribs, false );
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 10 ) //Ubersaw Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "8 ; 5 ; 140 ; 100");
				SpawnWeapon( iClient, "tf_weapon_medigun", 29, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "17 ; 100 ; 218 ; 1 ; 179 ; 1");
				SpawnWeapon( iClient, "tf_weapon_bonesaw", 37, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 11 ) //Giant Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4350 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 8 ; 200 ; 9 ; 0.05 ; 69 ; 0.01");
				SpawnWeapon( iClient, "tf_weapon_medigun", 411, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 12 ) //Giant Uber Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4350 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 314 ; 8");
				SpawnWeapon( iClient, "tf_weapon_medigun", 29, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 13 ) //Giant Shield Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4350 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 499 ; 2 ; 319 ; 5");
				SpawnWeapon( iClient, "tf_weapon_medigun", 411, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 14 ) //Giant Kritzkrieg Medic
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_syringegun_medic", 17, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 4350 ; 107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 10 ; 5 ; 314 ; 12");
				SpawnWeapon( iClient, "tf_weapon_medigun", 35, 100, 5, weaponAttribs, false );
			}
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1059, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_Sniper: // Sniper Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30155, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30156, 100, 5, weaponAttribs, true );//roam vision 
				
			if( iRobotVariant[iClient] == 0 ) // Normal Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 14, 100, 5, weaponAttribs, false ); // Stock Sniper Rifle
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
			}
			else if( iRobotVariant[iClient] == 1 ) // Razorback Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 14, 100, 5, weaponAttribs, false ); // Stock Sniper Rifle
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_wearable", 57, 100, 5, weaponAttribs, true ); // The Razorback
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
			}
			else if( iRobotVariant[iClient] == 2 ) // Sydney Sleeper Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 230, 100, 5, weaponAttribs, false ); // Sydney Sleeper Sniper Rifle
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_wearable", 231, 100, 5, weaponAttribs, true ); // Darwin's Danger Shield
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
			}
			else if( iRobotVariant[iClient] == 3 ) // Bowman
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0"); // Inf Ammo
				SpawnWeapon( iClient, "tf_weapon_compound_bow", 56, 100, 5, weaponAttribs, false ); // The Huntsman
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 4 ) // Jarater Master
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.20"); // 80% faster recharge
				SpawnWeapon( iClient, "tf_weapon_jar", 58, 100, 5, weaponAttribs, false ); // Jarate
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 232, 100, 5, weaponAttribs, false ); // The Bushwacka
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 5 ) // Jarater Master (Slow Down)
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "278 ; 0.40 ; 313 ; 1.70"); // 60% faster recharge, -70% movement speed on targets
				SpawnWeapon( iClient, "tf_weapon_jar", 58, 100, 5, weaponAttribs, false ); // Jarate
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 6 ) // AWP Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 2 ; 1.35"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 851, 100, 5, weaponAttribs, false ); // The AWPer Hand
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_wearable", 57, 100, 5, weaponAttribs, true ); // The Razorback
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
			}
			else if( iRobotVariant[iClient] == 7 ) // Armor Piercing Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 2 ; 1.55 ; 797 ; 1 ; 90 ; 1.75"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 526, 100, 5, weaponAttribs, false ); // The Machina
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_wearable", 57, 100, 5, weaponAttribs, true ); // The Razorback
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
			}
			else if( iRobotVariant[iClient] == 8 ) // SMG Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 4 ; 2.0 ; 2 ; 1.75 ; 6 ; 0.65 ; 318 ; 0.50 ; 31 ; 9"); // 
				SpawnWeapon( iClient, "tf_weapon_smg", 16, 100, 5, weaponAttribs, false ); // SMG
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 9 ) // Assault Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 14, 100, 5, weaponAttribs, false ); // Stock Sniper Rifle
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_parachute", 1101, 100, 5, weaponAttribs, false ); // The B.A.S.E. Jumper
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
				CanAirSpawn[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 10 ) // Assault AWP Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 2 ; 1.35"); // Inf Ammo, Block Intel
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 851, 100, 5, weaponAttribs, false ); // The AWPer Hand
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_parachute", 1101, 100, 5, weaponAttribs, false ); // The B.A.S.E. Jumper
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // Anti-bug
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
				CanAirSpawn[iClient] = true;
			}
			else if( iRobotVariant[iClient] == 11 ) // Mini Critter Sniper
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "400 ; 1 ; 32 ; 1 ; 110 ; 8 ; 218 ; 1 ; 318 ; 0.75 ; 1 ; 0.30 ; 5 ; 0.60 ; 91 ; 0.0 ; 305 ; 1");
				SpawnWeapon( iClient, "tf_weapon_sniperrifle", 14, 100, 5, weaponAttribs, false ); // Stock Sniper Rifle
				Format(weaponAttribs, sizeof(weaponAttribs), "67 ; 1.10 ; 64 ; 0.25");
				SpawnWeapon( iClient, "tf_weapon_jar", 58, 100, 5, weaponAttribs, false ); // Piss
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_club", 3, 100, 5, weaponAttribs, false ); // Stock Kukri
				IsAttackClass[iClient] = false;
				CanAirSpawn[iClient] = true;
			}
		}
		case TFClass_Spy: // Spies Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30159, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30160, 100, 5, weaponAttribs, true );//roam vision
				
			if( iRobotVariant[iClient] == 0 ) // Normal Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 24, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_knife", 4, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 60, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 1 ) // Gentle Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 375 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 61, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "292 ; 24 ; 426 ; 0 ; 433 ; 0.9");
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_knife", 4, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 60, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 2 ) // Assassin Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 140 ; 75 ; 107 ; 1.35 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 24, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "396 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_knife", 638, 100, 5, weaponAttribs, false ); // The Sharp Dresser
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 59, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 3 ) // Dead Ringer Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 24, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX			
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_knife", 4, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "83 ; 0.1");
				SpawnWeapon( iClient, "tf_weapon_invis", 59, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 4 ) // Gunslinger Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 26 ; 175 ; 2 ; 1.45 ; 362 ; 1 ; 106 ; 0.2 ; 97 ; 0.25 ; 6 ; 0.7 ; 266 ; 1 ; 400 ; 1 ; 182 ; 3");
				SpawnWeapon( iClient, "tf_weapon_revolver", 161, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX			
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 947, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 5 ) // Ninja Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1 ; 400 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "396 ; 0.7 ; 107 ; 1.20");
				SpawnWeapon( iClient, "tf_weapon_knife", 356, 100, 5, weaponAttribs, false ); // Conniver's Kunai
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 59, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 6 ) // Silent Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 24, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "156 ; 1"); // Silent Killer, diguise on backstab
				SpawnWeapon( iClient, "tf_weapon_knife", 4, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "160 ; 1"); // Silent Uncloak
				SpawnWeapon( iClient, "tf_weapon_invis", 59, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 7 ) // Saboteur Spy
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0 ; 400 ; 1 ; 1 ; 0.3 ; 140 ; 125");
				SpawnWeapon( iClient, "tf_weapon_revolver", 24, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "428 ; 4.0 ; 426 ; 0.2 ; 427 ; 15"); // Sapper
				SpawnWeapon( iClient, "tf_weapon_builder", 933, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "5 ; 2.5"); // Slower attack speed
				SpawnWeapon( iClient, "tf_weapon_knife", 4, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_invis", 947, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 8 ) // Dr. Ambasicle
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "390 ; 3.0 ; 400 ; 1");
				SpawnWeapon( iClient, "tf_weapon_revolver", 61, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_builder", 735, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_knife", 649, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_pda_spy", 27, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_invis", 59, 100, 5, weaponAttribs, false );
			}
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1064, 100, 5, weaponAttribs, true );
			//}
		}
		case TFClass_Engineer: // Engineer Variants
		{
			CanAirSpawn[iClient] = false;
			Format(weaponAttribs, sizeof(weaponAttribs), "692 ; 1");
			SpawnWeapon( iClient, "tf_wearable", 30145, 100, 5, weaponAttribs, true );
			if(!IsGateBotPlayer[iClient])
				SpawnWeapon( iClient, "tf_wearable", 30146, 100, 5, weaponAttribs, true );//roam vision
			if( iRobotVariant[iClient] == 0 )
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 175 ; 353 ; 1"); // 286 building health bonus removed
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 1 )
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 375 ; 353 ; 1");
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 2 ) // Battle Engineer: Faster Sentry Build Speed, Upgraded Sentry
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 250 ; 353 ; 1 ; 287 ; 1.15 ; 286 ; 2 ; 343 ; 1.6 ; 344 ; 1.35 ; 351 ; 1 ; 464 ; 1.8");
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 3 ) // Fast Build Engineer: Wrench builds stuff faster, boost on tele speed
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 275 ; 353 ; 1 ; 465 ; 1.4 ; 92 ; 2.0");
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 4 ) // Fast Teleporter Engineer: Builds teleporter faster, build 20% faster
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 375 ; 353 ; 1 ; 465 ; 2.5 ; 92 ; 1.2");
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); // DUMMY TO FIX
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 5 ) // PDQ Engineer
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 50 ; 353 ; 1 ; 92 ; 3.0 ; 6 ; 0.6 ; 95 ; 0.50 ; 1 ; 0.25 ; 92 ; 3.0 ; 286 ; 0.5");
				SpawnWeapon( iClient, "tf_weapon_wrench", 329, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_mechanical_arm", 528, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			else if( iRobotVariant[iClient] == 6 ) // Circuit City Engineer
			{
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_shotgun_primary", 9, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1");
				SpawnWeapon( iClient, "tf_weapon_mechanical_arm", 528, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "140 ; 375 ; 353 ; 1");
				SpawnWeapon( iClient, "tf_weapon_wrench", 7, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_build", 25, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_pda_engineer_destroy", 26, 100, 5, weaponAttribs, false );
				Format(weaponAttribs, sizeof(weaponAttribs), "172 ; 1"); 
				SpawnWeapon( iClient, "tf_weapon_builder", 28, 100, 5, weaponAttribs, false );
			}
			//if(IsGateBotPlayer[iClient])
			//{
			//	Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
			//	SpawnWeapon( iClient, "tf_wearable", 1065, 100, 5, weaponAttribs, true );
			//}
		}
	}
	
	if( iRobotVariant[iClient] <= -1 )
	{
		bSkipInvAppEvent[iClient] = true;
		TF2_RegeneratePlayer( iClient );
	}
	else
		bStripItems[iClient] = true;
	
	FixTPose( iClient );
	if(IsGateBotPlayer[iClient])
	{
		CreateTimer(0.1,Timer_GateBotHat,iClient);
		//PrintToChatAll("reached pre class ");
	}
}
public Action:Timer_GateBotHat(Handle:timer,any:iClient)
{
	new TFClassType:iClass = TF2_GetPlayerClass( iClient );
	new String:weaponAttribs[256];
//	PrintToChatAll("reached post class ");
//	if(IsGateBotPlayer[iClient])
//	{
	if(!BvisIncluded)
		Format(weaponAttribs, sizeof(weaponAttribs), "134 ; 64");
	else
		Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
	switch(iClass)
	{
		case TFClass_Scout:
		{
			//PrintToChatAll("reached post32 class ");
			SpawnWeapon( iClient, "tf_wearable", 1057, 100, 5, weaponAttribs, true );
			//PrintToChatAll("reached post3 class ");
		}
		case TFClass_Soldier:
		{
			SpawnWeapon( iClient, "tf_wearable", 1063, 100, 5, weaponAttribs, true );
		}
		case TFClass_Sniper:
		{
			SpawnWeapon( iClient, "tf_wearable", 1062, 100, 5, weaponAttribs, true );
		}
		case TFClass_Engineer:
		{
			SpawnWeapon( iClient, "tf_wearable", 1065, 100, 5, weaponAttribs, true );
		}
		case TFClass_Pyro:
		{
				SpawnWeapon( iClient, "tf_wearable", 1058, 100, 5, weaponAttribs, true );
		}
		case TFClass_Medic:
		{
				SpawnWeapon( iClient, "tf_wearable", 1059, 100, 5, weaponAttribs, true );
		}
		case TFClass_DemoMan:
		{
			SpawnWeapon( iClient, "tf_wearable", 1061, 100, 5, weaponAttribs, true );
		}
		case TFClass_Spy:
		{
			SpawnWeapon( iClient, "tf_wearable", 1064, 100, 5, weaponAttribs, true );
		}
		case TFClass_Heavy:
		{
			SpawnWeapon( iClient, "tf_wearable", 1060, 100, 5, weaponAttribs, true );
		}
	}
//	}
}
/////////////////////////////////////////////
//////TELEPORTER ADDED BY BENOIST3012///////
///////////////////////////////////////////
/*public Action:CheckTeleporter(Handle:Timer)
{
	if(IsMvM())
	{
		new TeleporterExit = -1;
		if((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1 && GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
		{
			new OwnerTeleporter = GetEntPropEnt(TeleporterExit,Prop_Send,"m_hBuilder");
			new String:modelname[128];
			GetEntPropString(TeleporterExit, Prop_Data, "m_ModelName", modelname, 128);
			if(StrContains(modelname, "light") != -1 && IsValidRobot(OwnerTeleporter))
			{
				if(!AnnouncerQuiet)
				{	
					new soundswitch;
					soundswitch = GetRandomInt(1, 5);
					decl String:soundteleporteractivate[PLATFORM_MAX_PATH];
					Format( soundteleporteractivate, sizeof(soundteleporteractivate), "vo/announcer_mvm_eng_tele_activated0%i.mp3", soundswitch);
					EmitSoundToAll(soundteleporteractivate);
					AnnouncerQuiet = true;
				}
			}
			else
			{
				teleportercheck = false;
				RobotTeleporter = -1;
			}
		}
		else
		{
			AnnouncerQuiet = false;
			if(teleportercheck)
			{
				teleportercheck = false;
				RobotTeleporter = -1;
			}
		}
	}
}*/
public Action:CommandListener_Drop(client, const String:command[], argc)
{
	return Plugin_Handled;
}

/*public Action:Particle_Teleporter(Handle:Timer)
{
	if(IsMvM())
	{
		CreateTimer(3.0, Particle_Teleporter);
		new TeleporterExit = -1;
		while((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1)
		{
			if(GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
			{
				new OwnerTeleporter = GetEntPropEnt(TeleporterExit,Prop_Send,"m_hBuilder");
				new String:modelname[128];
				GetEntPropString(TeleporterExit, Prop_Data, "m_ModelName", modelname, 128);
				if(StrContains(modelname, "light") != -1 && IsValidRobot(OwnerTeleporter)) 
				{
					new Float:position[3];
					GetEntPropVector(TeleporterExit,Prop_Send, "m_vecOrigin",position);
					new attach = CreateEntityByName("trigger_push");
					CreateTimer(3.0, DeleteTrigger, attach);
					TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR); //telestuff
					//new Float:TeleOffsetR = GetRandomFloat(-150.0, 150.0);
					AttachParticleTeleporter(attach,"teleporter_mvm_bot_persist");
				}
			}
		}
	}
}*/

SpawnRobot(client)
{
	new Float:position[3];
	new RobotTeleporter = GetRandomTeleporterBlu();
//	if(bool:GetEntProp(RobotTeleporter, Prop_Send, "m_bIsSapped") == true || bool:GetEntProp(RobotTeleporter, Prop_Send, "m_bDisabled") == true)
//		return;
	
	if(GetClientTeam(client) != _:TFTeam_Blue)
	{
		return;
	}
	if(RobotTeleporter != -1)
	{
		GetEntPropVector(RobotTeleporter,Prop_Send, "m_vecOrigin",position);
	}
	else
	{
		return;
	}
	new TFClassType:iClass = TF2_GetPlayerClass( client );
	if( iClass != TFClass_Heavy )
		TF2_AddCondition(client, TFCond:TFCond_Ubercharged, 5.0);
	TF2_AddCondition(client, TFCond:TFCond_UberchargedCanteen, 5.0);
	TF2_AddCondition(client, TFCond:TFCond_UberchargeFading, 5.0);
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	//Get robot height and match height for them to make bots less confused
	//Player standing 83
	//Teleporter 95
	new Float:flModelScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	if(flModelScale == 1.0)
		position[2] += 16;// reference size +1
	if(flModelScale == 1.5)
		position[2] += 23;
	if(flModelScale == 1.75)
		position[2] += 26;
	if(flModelScale > 1.75)
		position[2] += 50;
		
	if(flModelScale < 1.75 && flModelScale != 1.5 && flModelScale != 1.0)
		position[2] += 50;
	//
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	if(teleportersound)
	{
		PrecacheSnd(TELEPORTER_SPAWN); //deliver
		teleportersound = false;
		CreateTimer(0.3, Tele_Sound);
		EmitSoundToAll( TELEPORTER_SPAWN, RobotTeleporter, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
	}
	if(!IsMannhattan && CanTeleportBomb && GameRules_GetRoundState() == RoundState_RoundRunning && class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Medic && !IsFakeClient(client))
	{
		//new iflagr = -1;
	//	new Float:Position[3];
		//iflagr = FindEntityByClassname(iflagr, "item_teamflag");
		//GetClientAbsOrigin(client, Position);
		//TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
	}
	if(IsMannhattan && GameRules_GetRoundState() == RoundState_RoundRunning && class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Medic && ((LastGateCapture + 19.9) < GetEngineTime()) && !IsGateBotPlayer[client] && !IsFakeClient(client))// && nGateCapture != 2
	{
		new iflagr = -1;
		if(CanTeleportBomb1)
		{
			iflagr = Bomb1;
		}
		if(CanTeleportBomb2)
		{
			iflagr = Bomb2;
		}
		if(CanTeleportBomb3)
		{
			iflagr = Bomb3;
		}
		new Float:Position[3];
		GetClientAbsOrigin(client, Position);
		TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
	}
	CreateTimer(0.15, Timer_RemoveUberHidden, client);
}
public Action:Timer_RemoveUberHidden(Handle:timer, client)
{
	TF2_RemoveCondition(client, TFCond_UberchargedHidden);
}
GetRandomTeleporterBlu()
{
	new Handle:hSpawnPoint = CreateArray();
	new String:modelname[128], iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "obj_teleporter") ) != -1 )
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue && bool:GetEntProp( iEnt, Prop_Send, "m_bHasSapper" ) == false)
		{
			//PrintToServer("Passed check teamnum and sapper");
			GetEntPropString(iEnt, Prop_Data, "m_ModelName", modelname, 128);
			if(StrContains(modelname, "light") != -1)
			{
				//PrintToServer("Passed check model");
				PushArrayCell( hSpawnPoint, iEnt );
				//new teleowner = GetEntPropEnt(iEnt,Prop_Send,"m_hBuilder");
				//bEngiCanBuildSecondTele[teleowner] = true;
			}
		}
	if( GetArraySize(hSpawnPoint) > 0 )
		return GetArrayCell( hSpawnPoint, GetRandomInt(0,GetArraySize(hSpawnPoint)-1) );
	CloseHandle( hSpawnPoint );
	return -1;
}
public Action:Tele_Sound(Handle:timer)
{
	teleportersound = true;
}
public Action:DeleteTrigger(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "trigger_push", false)) AcceptEntityInput(Ent, "Kill");
	return;
}
stock AttachParticleTeleporter(entity, String:particleType[], Float:offset[]={0.0,0.0,0.0})//, bool:attach=true) //teleport particle + No Beam when disabled
{
	if(!GateStunEnabled)
	{
	new particle=CreateEntityByName("info_particle_system");

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	new Float:TeleOffsetR = GetRandomFloat(-150.0, 150.0);
	position[0]+=TeleOffsetR;
	position[1]+=TeleOffsetR;
	position[2]+=offset[2];
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
//	if(attach)
//	{
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
//	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
//	CreateTimer(0.1, DeleteParticle, particle);
//	return particle;
	}
}
public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}
/////////////////////////////////////////////
//////END TELEPORTER///////////////////////
///////////////////////////////////////////
//////////////////////////////////////
/////////////////////////////////////
////////////////////////////////////////////
////TELEPORTTOHINT ADDED BY BENOIST3012////
///////////////////////////////////////////
TeleportRobotToHint(client)
{
	new Float:Pos[3];
	iEffect[client] = Effect_None;
	new TeleportPoint = GetNestNextToTheBomb();
	if(TeleportPoint != -1)
	{
		GetEntPropVector(TeleportPoint, Prop_Send, "m_vecOrigin", Pos);
		new attach = CreateEntityByName("trigger_push");
		CreateTimer(10.0, DeleteTrigger, attach);
		TeleportEntity(attach, Pos, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(client, Pos, NULL_VECTOR, NULL_VECTOR);//
		TF2_RemoveCondition(client, TFCond_Ubercharged);//fix
		TE_Particle("teleported_blue", Pos, _, _, attach, 1,0);
		TE_Particle("teleported_mvm_bot", Pos, _, _, attach, 1,0);
		new soundswitch;
		soundswitch = GetRandomInt(2, 3);
		decl String:soundteleporttohint[PLATFORM_MAX_PATH];
		Format( soundteleporttohint, sizeof(soundteleporttohint), "vo/announcer_mvm_engbot_arrive0%i.mp3", soundswitch);
		EmitSoundToAll(soundteleporttohint);
	}
	
}
GetNestNextToTheBomb()
{
	new Handle:hSpawnPoint = CreateArray();
	new Float:pVec[3];
	new Float:nVec[3];
	new found = -1;
	new Float:MAX_DIST = 10000.0;
	new Float:found_dist = MAX_DIST;
	new Float:aux_dist;
	new i5 = -1;
	while((i5 = FindEntityByClassname(i5, "bot_hint_engineer_nest")) != -1)
	{
		if(IsValidEntity(i5))
		{
			GetEntPropVector(i5, Prop_Send, "m_vecOrigin", nVec);
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Red)
				{
					GetClientEyePosition(i, pVec);
					aux_dist = GetVectorDistance(pVec, nVec, false);
					if(aux_dist < found_dist && aux_dist > 2000) // to not spawn in the line of fire
					{
						found = i5;
						found_dist = aux_dist;
					}
				}
			}
		}
	}
	CloseHandle( hSpawnPoint );
	if ( BombPickup == true )
	{
		GetRandomInt(0,1);
	}
	if ( Carrier )
	{
		GetRandomInt(0,1);
	}
	return found;
/* 	new Float:Pos1[3];
	new Float:Pos2[3];
	new Float:Pos3[3];
	new Float:Pos4[3];
	new Float:Pos5[3];
	new Float:Pos6[3];
	new Float:Pos7[3];
	new Float:Pos8[3];
	new Float:Pos9[3];
	new Float:Pos10[3];
	new Float:Pos11[3];
	new Float:Pos12[3];
	new Float:Pos13[3];
	new Float:Pos14[3];
	new Float:BombPos[3];
	new Float:Dist1 = 500.0;
	new Float:Dist2 = 800.0;
	new Float:Dist3 = 1200.0;
	new Float:Dist4 = 1600.0;
	new Float:Dist5 = 2000.0;
	new Float:Dist6 = 2400.0;
	new Float:Dist7 = 2800.0;
	new Float:Dist8 = 3400.0;
	new Float:Dist9 = 3800.0;
	new Float:Dist10 = 4200.0;
	new Float:Dist11 = 4600.0;
	new Float:Dist12 = 5200.0;
	new Float:Dist13 = 5600.0;
	new Float:Dist14 = 6000.0;
	new Handle:hSpawnPoint = CreateArray();
	new iEnt = -1;
	new Bomb = -1;
	if(BombPickup)
	{
		Bomb = Carrier;
		GetEntPropVector(Bomb, Prop_Send, "m_vecOrigin", BombPos);
	}
	else
	{
		while( (Bomb = FindEntityByClassname( Bomb, "item_teamflag") ) != -1)
			GetEntPropVector(Bomb, Prop_Send, "m_vecOrigin", BombPos);
	}
	while( ( iEnt = FindEntityByClassname( iEnt, "bot_hint_engineer_nest") ) != -1 )
		PushArrayCell( hSpawnPoint, iEnt );
	if( GetArraySize(hSpawnPoint) > 0 )
	{
		//new MaxNest = GetArraySize(hSpawnPoint)-1;
		new n;
		//for(n = 1; n<=MaxNest; n++)
		//{
		n = GetRandomInt(1,14);
		//PrintToChatAll("DEBUG: n value is %d", n);
		new Nest = GetArrayCell( hSpawnPoint, n);
		if(n == 1)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos1);
			Dist1 = GetVectorDistance(Pos1, BombPos);
		}
		if(n == 2)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos2);
			Dist2 = GetVectorDistance(Pos2, BombPos);
		}
		if(n == 3)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos3);
			Dist3 = GetVectorDistance(Pos3, BombPos);
		}
		if(n == 4)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos4);
			Dist4 = GetVectorDistance(Pos4, BombPos);
		}
		if(n == 5)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos5);
			Dist5 = GetVectorDistance(Pos5, BombPos);
		}
		if(n == 6)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos6);
			Dist6 = GetVectorDistance(Pos6, BombPos);
		}
		if(n == 7)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos7);
			Dist7 = GetVectorDistance(Pos7, BombPos);
		}
		if(n == 8)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos8);
			Dist8 = GetVectorDistance(Pos8, BombPos);
		}
		if(n == 9)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos9);
			Dist9 = GetVectorDistance(Pos9, BombPos);
		}
		if(n == 10)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos10);
			Dist10 = GetVectorDistance(Pos10, BombPos);
		}
		if(n == 11)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos11);
			Dist11 = GetVectorDistance(Pos11, BombPos);
		}
		if(n == 12)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos12);
			Dist12 = GetVectorDistance(Pos12, BombPos);
		}
		if(n == 13)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos13);
			Dist13 = GetVectorDistance(Pos13, BombPos);
		}
		if(n == 14)
		{
			GetEntPropVector(Nest, Prop_Send, "m_vecOrigin", Pos14);
			Dist14 = GetVectorDistance(Pos14, BombPos);
		}
		//}
		if(Dist1 < Dist2 && Dist1 < Dist3 && Dist1 < Dist4 && Dist1 < Dist5 && Dist1 < Dist6 && Dist1 < Dist7 && Dist1 < Dist8 && Dist1 < Dist9 && Dist1 < Dist10 && Dist1 < Dist11 && Dist1 < Dist12 && Dist1 < Dist13 && Dist1 < Dist14)
			return GetArrayCell( hSpawnPoint, 1);
		if(Dist2 < Dist1 && Dist2 < Dist3 && Dist2 < Dist4 && Dist2 < Dist5 && Dist2 < Dist6 && Dist2 < Dist7 && Dist2 < Dist8 && Dist2 < Dist9 && Dist2 < Dist10 && Dist2 < Dist11 && Dist2 < Dist12 && Dist2 < Dist13 && Dist2 < Dist14)
			return GetArrayCell( hSpawnPoint, 2);
		if(Dist3 < Dist2 && Dist3 < Dist1 && Dist3 < Dist4 && Dist3 < Dist5 && Dist3 < Dist6 && Dist3 < Dist7 && Dist3 < Dist8 && Dist3 < Dist9 && Dist3 < Dist10 && Dist3 < Dist11 && Dist3 < Dist12 && Dist3 < Dist13 && Dist3 < Dist14)
			return GetArrayCell( hSpawnPoint, 3);
		if(Dist4 < Dist2 && Dist4 < Dist3 && Dist4 < Dist1 && Dist4 < Dist5 && Dist4 < Dist6 && Dist4 < Dist7 && Dist4 < Dist8 && Dist4 < Dist9 && Dist4 < Dist10 && Dist4 < Dist11 && Dist4 < Dist12 && Dist4 < Dist13 && Dist4 < Dist14)
			return GetArrayCell( hSpawnPoint, 4);
		if(Dist5 < Dist2 && Dist5 < Dist3 && Dist5 < Dist4 && Dist5 < Dist1 && Dist5 < Dist6 && Dist5 < Dist7 && Dist5 < Dist8 && Dist5 < Dist9 && Dist5 < Dist10 && Dist5 < Dist11 && Dist5 < Dist12 && Dist5 < Dist13 && Dist5 < Dist14)
			return GetArrayCell( hSpawnPoint, 5);
		if(Dist6 < Dist2 && Dist6 < Dist3 && Dist6 < Dist4 && Dist6 < Dist5 && Dist6 < Dist1 && Dist6 < Dist7 && Dist6 < Dist8 && Dist6 < Dist9 && Dist6 < Dist10 && Dist6 < Dist11 && Dist6 < Dist12 && Dist6 < Dist13 && Dist6 < Dist14)
			return GetArrayCell( hSpawnPoint, 6);
		if(Dist7 < Dist2 && Dist7 < Dist3 && Dist7 < Dist4 && Dist7 < Dist5 && Dist7 < Dist6 && Dist7 < Dist1 && Dist7 < Dist8 && Dist7 < Dist9 && Dist7 < Dist10 && Dist7 < Dist11 && Dist7 < Dist12 && Dist7 < Dist13 && Dist7 < Dist14)
			return GetArrayCell( hSpawnPoint, 7);
		if(Dist8 < Dist2 && Dist8 < Dist3 && Dist8 < Dist4 && Dist8 < Dist5 && Dist8 < Dist6 && Dist8 < Dist7 && Dist8 < Dist1 && Dist8 < Dist9 && Dist8 < Dist10 && Dist8 < Dist11 && Dist8 < Dist12 && Dist8 < Dist13 && Dist8 < Dist14)
			return GetArrayCell( hSpawnPoint, 8);
		if(Dist9 < Dist2 && Dist9 < Dist3 && Dist9 < Dist4 && Dist9 < Dist5 && Dist9 < Dist6 && Dist9 < Dist7 && Dist9 < Dist8 && Dist9 < Dist1 && Dist9 < Dist10 && Dist9 < Dist11 && Dist9 < Dist12 && Dist9 < Dist13 && Dist9 < Dist14)
			return GetArrayCell( hSpawnPoint, 9);
		if(Dist10 < Dist2 && Dist10 < Dist3 && Dist10 < Dist4 && Dist10 < Dist5 && Dist10 < Dist6 && Dist10 < Dist7 && Dist10 < Dist8 && Dist10 < Dist9 && Dist10 < Dist1 && Dist10 < Dist11 && Dist10 < Dist12 && Dist10 < Dist13 && Dist10 < Dist14)
			return GetArrayCell( hSpawnPoint, 10);
		if(Dist11 < Dist2 && Dist11 < Dist3 && Dist11 < Dist4 && Dist11 < Dist5 && Dist11 < Dist6 && Dist11 < Dist7 && Dist11 < Dist8 && Dist11 < Dist9 && Dist11 < Dist10 && Dist11 < Dist1 && Dist11 < Dist12 && Dist11 < Dist13 && Dist11 < Dist14)
			return GetArrayCell( hSpawnPoint, 11);
		if(Dist12 < Dist2 && Dist12 < Dist3 && Dist12 < Dist4 && Dist12 < Dist5 && Dist12 < Dist6 && Dist12 < Dist7 && Dist12 < Dist8 && Dist12 < Dist9 && Dist12 < Dist10 && Dist12 < Dist11 && Dist12 < Dist1 && Dist12 < Dist13 && Dist12 < Dist14)
			return GetArrayCell( hSpawnPoint, 12);
		if(Dist13 < Dist2 && Dist13 < Dist3 && Dist13 < Dist4 && Dist13 < Dist5 && Dist13 < Dist6 && Dist13 < Dist7 && Dist13 < Dist8 && Dist13 < Dist9 && Dist13 < Dist10 && Dist13 < Dist11 && Dist13 < Dist12 && Dist13 < Dist1 && Dist13 < Dist14)
			return GetArrayCell( hSpawnPoint, 13);
		if(Dist14 < Dist2 && Dist14 < Dist3 && Dist14 < Dist4 && Dist14 < Dist5 && Dist14 < Dist6 && Dist14 < Dist7 && Dist14 < Dist8 && Dist14 < Dist9 && Dist14 < Dist10 && Dist14 < Dist11 && Dist14 < Dist12 && Dist14 < Dist13 && Dist14 < Dist1)
			return GetArrayCell( hSpawnPoint, 14);
	}
	CloseHandle( hSpawnPoint );
	return -1; */
}
stock TE_Particle(String:Name[], Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR,entindex=-1,attachtype=-1,attachpoint=-1,bool:resetParticles=true,customcolors = 0,Float:color1[3] = NULL_VECTOR,Float:color2[3] = NULL_VECTOR,controlpoint = -1,controlpointattachment = -1,Float:controlpointoffset[3] = NULL_VECTOR)
{
	//PrintToServer( "%d", TE_ReadNum( "m_iParticleSystemIndex" ) );
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    new Float:delay=3.0;
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    
    if(customcolors)
    {
        TE_WriteNum("m_bCustomColors", customcolors);
        TE_WriteVector("m_CustomColors.m_vecColor1", color1);
        if(customcolors == 2)
        {
            TE_WriteVector("m_CustomColors.m_vecColor2", color2);
        }
    }
    if(controlpoint != -1)
    {
        TE_WriteNum("m_bControlPoint1", controlpoint);
        if(controlpointattachment != -1)
        {
            TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
        }
    }
    
    TE_SendToAll(delay);
}
//////////////////////////////////////
/////////////////////////////////////
////////////////////////////////////////
/////////////BOMB TELEPORT/////////////
///////////////////////////////////////
public OnBombReset(const String:output[], caller, activator, Float:delay)
{
	if(IsMvM())
	{
		CanTeleportBomb = true;
	}
	if(IsMvM() && IsMannhattan)
	{
		decl String:BombName[255];
		GetEntPropString(caller, Prop_Data, "m_iName", BombName, sizeof(BombName));
		if(StrEqual(BombName,BombName1))
			CanTeleportBomb1 = true;
		if(StrEqual(BombName,BombName2))
			CanTeleportBomb2 = true;
		if(StrEqual(BombName,BombName3))
			CanTeleportBomb3 = true;
	}
}
public OnBombPickup(const String:output[], caller, activator, Float:delay)
{
	decl String:BombName[255];
	GetEntPropString(caller, Prop_Data, "m_iName", BombName, sizeof(BombName));
	if(IsMvM() && IsMannhattan )
	{
		if(StrEqual(BombName,BombName1))
			CanTeleportBomb1 = false;
		if(StrEqual(BombName,BombName2))
			CanTeleportBomb2 = false;
		if(StrEqual(BombName,BombName3))
			CanTeleportBomb3 = false;
	}
	//if(StrEqual(BombName,BombName1))
		//SecondBombEnable = false;
}
public OnGateCapture(const String:output[], caller, activator, Float:delay)
{
	if(IsMannhattan)
	{
		CreateTimer(21.9, Timer_RemoveStun); 
		new TeleporterExit = -1;
		while((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1)
		{
			if(GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
			{
				//SDKHooks_TakeDamage(TeleporterExit, 0, 0, 500.0, DMG_CRUSH);
				AcceptEntityInput( TeleporterExit, "removehealth 10000" );
			}
		}
		StunRobots();
		LastGateCapture = GetEngineTime();
		nGateCapture += 1;
		//StopAllBlueBuilding();
		GateStunEnabled = true;
		BlockRespawnclients(false);
		if(nGateCapture == 1)
		{
			CanTeleportBomb2 = true;
			
//			PrintToChatAll("[TFBWR] Gate 1 Captured!");
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
			{
				if (g_hbombs1[i] != INVALID_HANDLE)
				{
					CloseHandle(g_hbombs1[i]);
					g_hbombs1[i] = INVALID_HANDLE;
				}
				if (g_hbombs2[i] != INVALID_HANDLE)
				{
					CloseHandle(g_hbombs2[i]);
					g_hbombs2[i] = INVALID_HANDLE;
				}
				if (g_hbombs3[i] != INVALID_HANDLE)
				{
					CloseHandle(g_hbombs3[i]);
					g_hbombs3[i] = INVALID_HANDLE;
				}
			}
		}
		if(nGateCapture == 2)
		{
			CanTeleportBomb3 = true;
//			PrintToChatAll("[TFBWR] Gate 2 Captured!");
			for (new i = 1; i <= MaxClients; i++)
			{
			if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
			{
				new hat = -1;
				while((hat=FindEntityByClassname(hat, "tf_wearable"))!=INVALID_ENT_REFERENCE)
				{
					if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == i)
					{																																																																																																																																																							
						if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1057 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1063 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1062 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1065 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1058 ||GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1059 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1061 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1064 || GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == 1060)
						{																																																																																																																																																							
//							TF2_RemoveWearable(i, hat);
							AcceptEntityInput(hat, "Kill");
//							PrintToChatAll("Found hat");
						}
					}
				}
				SetEntProp(i, Prop_Send, "m_iTeamNum", 0);
				IsGateBotPlayer[i] = false;
				CreateTimer(0.13,ResetTeam, i);//prevent the crash
//				CreateTimer(0.1,Timer_TurnOffGateBotHat,i);
			}
			}
			new i3 = -1;
			while ((i3 = FindEntityByClassname(i3, "trigger_multiple")) != -1)
			{
				if(IsValidEntity(i3))
				{
				decl String:strName[50];
				GetEntPropString(i3, Prop_Data, "m_iName", strName, sizeof(strName));
				if(strcmp(strName, "gate2_door_alarm") == 0)
				{
					AcceptEntityInput(i3, "Disable");
					break;
				}
				}
			}
		}
	}
}
stock BlockRespawnclients(bool:unlock)
{	
	new TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	new Float:RespawnTimeBlueValue = 12.5;
	SetVariantFloat(RespawnTimeBlueValue);
	AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
	//PrintToChatAll("locked respawn attempt");
	if(unlock)
	{
		RespawnTimeBlueValue = 0.1;
		SetVariantFloat(RespawnTimeBlueValue);
		AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
	}
}
stock bool:IsGiantOrBigNormal(client)
{
	new Float:flModelScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	if(flModelScale > 1.0 && iRobotMode[client] != Robot_SentryBuster)
		return true;
	return false;
}
stock StunRobots()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i) && IsPlayerAlive(i))
			if(iRobotMode[i] != Robot_SentryBuster && iRobotMode[i] != Robot_Giant && iRobotMode[i] != Robot_BigNormal)// added bignormal robots to not be stunned fixed it again
			{
				TF2_AddCondition(i, TFCond_MVMBotRadiowave, 22.0);
				TF2_StunPlayer(i, 22.0, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, _);
				AttachParticleHead(i, "bot_radio_waves", 21.9);
			}
}
public Action:ResetTeam(Handle:timer,any:iclient)
{
	new entflags = GetEntityFlags(iclient);

	SetEntityFlags(iclient, entflags | FL_FAKECLIENT);
	SetEntProp(iclient, Prop_Send, "m_iTeamNum", 3);
	SetEntProp(iclient, Prop_Send, "m_nSkin", 2);
	SetEntityFlags(iclient, entflags);
}
/////////////////////////////////////////////////////
/////////////BOSS SYSTEM ADDED BY BENOIST3012///////
////////////////////////////////////////////////////
public Action:WaveStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Trigger wave s");
/* 	if(!IsMannhattan)
	{
		new ienti = -1; //hologram
		while ((ienti = FindEntityByClassname(ienti, "logic_relay")) != -1)
		{
		if(IsValidEntity(ienti))
		{
			decl String:strName[50];
			GetEntPropString(ienti, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "wave_finished_relay") == 0)
			{
				AcceptEntityInput(ienti, "Trigger");
				break;
			}
			else if(strcmp(strName, "bombpath_wavefinished") == 0)   
			{
				AcceptEntityInput(ienti, "Trigger");
				break;
			}
		} 
		}
	} */
	if(!teleportersound)
		teleportersound = true;//fix
	BombHasBeenDeployed = false;
	
	g_CanDispatchSentryBuster = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i) && IsPlayerAlive(i))
			if(TF2_GetPlayerClass( i ) == TFClass_Soldier || TF2_GetPlayerClass( i ) == TFClass_Medic)
				CreateTimer(0.2, Timer_SetBannerCharge, i);  //restores banner on wave start
	}
	
	if(IsMannhattan)
		Removegatebot();
	if(GateStunEnabled)
		GateStunEnabled = false;
	new BombCounter = 1;
	new iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "item_teamflag") ) != -1 )
	{
		if(BombCounter == 1)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", BombName1, sizeof(BombName1));
			//PrintToChatAll("[TFBWR] BombName: %s", BombName1);
			Bomb1 = iEnt;
		}
		if(BombCounter == 2)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", BombName2, sizeof(BombName2));
			//PrintToChatAll("[TFBWR] BombName: %s", BombName2);
			Bomb2 = iEnt;
		}
		if(BombCounter == 3)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", BombName3, sizeof(BombName3));
			//PrintToChatAll("[TFBWR] BombName: %s", BombName3);
			Bomb3 = iEnt;
		}
		BombCounter+=1;
	}
	nGateCapture = 0;
	iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "team_control_point") ) != -1 )
	{
		if((GetEntProp(iEnt,Prop_Send,"m_iTeamNum") == 3))
		{
			nGateCapture +=1;
			//PrintToChatAll("[TFBWR] GateCaptureCaptured: %i",nGateCapture);
		}
	}
	//SecondBombEnable = false;
	CanTeleportBomb = true;
	CanTeleportBomb1 = true;
	CanTeleportBomb2 = false;
	CanTeleportBomb3 = false;
	BossEnabled = false;
	new waveIndex = GetEventInt(event, "wave_index");
	waveIndex += 1;
	//PrintToChatAll("[TF2BWR] Wave %i Begin", waveIndex);
	LoadTF2bwrConfigs(waveIndex);
	///BOMB TELEPORT
//	CreateTimer(3.0, Teleport_Bomb);//Prevent bug when a popfile change the intel

	flLastSentryBuster = GetGameTime()+20.0;//initial delay 20s
	
	CountWaveNumber(); // check wave numbers
	CheckGiantAvailability(); // check giants
	IsHalloweenMission(); // Dynamic wave 666 mode
	SpyTeleportAvailable(); // Check if the map supports spy teleport
	

	new bool:bGiants = false;
	if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
	{
		bGiants = true;
	}

	if(bWaveNumGiants == false && bGiants == true)
	{
		CPrintToChatAll("{fullblue}[BWR2]{yellow} Giant Robots are disabled for this wave!");
	}
	if(bWaveNumGiants == true && bGiants == true)
	{
		CPrintToChatAll("{fullblue}[BWR2]{yellow} Giant Robots are enabled for this wave!");
	}
	
	new bool:bWaveStartDebug = false; // set true for debug
	if(bWaveStartDebug == true)
	{
		CPrintToChatAll("{fullred}Alert!{orange} Debug messages are enabled.");
		CPrintToChatAll("{orange}[BWR2]{yellow} Current Wave Number: %d | Total Wave Number: %d | Event PopFile Type: %d", iCurrentWave, iTotalWave, iEventPopFileType);
		CPrintToChatAll("{orange}[BWR2]{cyan} [BOSS SYSTEM]{yellow} Wave Index: %d", waveIndex);
		if(Is666Mode == true)
		{
			CPrintToChatAll("{orange}[BWR2]{yellow} Wave 666 Mode Enabled");
		}
		if(bWaveNumGiants == true)
		{
			CPrintToChatAll("{orange}[BWR2]{yellow} Wave: Giants Enabled");
		}
		if(bWaveNumGiants == false)
		{
			CPrintToChatAll("{orange}[BWR2]{yellow} Wave: Giants Disabled");
		}
	}
	
	// alerts players about spy teleport
	if(bCanSpyTeleport == false)
	{
		CPrintToChatAll("{orange}[BWR2]{fullred} Warning! {cyan}Spy teleport is not avaiable for this map.");
	}
	
}
public Action:Timer_SetBannerCharge( Handle:hTimer, client)
{
	if(IsPlayerAlive(client))
	{
		if(TF2_GetPlayerClass( client ) == TFClass_Medic)
		{
			new Medigun = GetPlayerWeaponSlot( client, 1 );
			if( IsValidEdict( Medigun  ) && Medigun != -1 )
				SetEntPropFloat( Medigun, Prop_Send, "m_flChargeLevel", 1.0 );
		}
		if(TF2_GetPlayerClass( client ) == TFClass_Soldier)
			SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 );
	}
}

public Action:Teleport_Bomb(Handle:timer)
{
	new RandomRobotHuman = GetRandomPlayer(3);
	if(RandomRobotHuman != -1)
	{
		if(CanTeleportBomb || CanTeleportBomb1)
		{
			new iflagr = -1;
			new Float:Position[3];
			while ((iflagr = FindEntityByClassname(iflagr, "logic_relay")) != -1)
			{
			if(IsValidEntity(iflagr) && bool:GetEntProp( iflagr, Prop_Data, "m_bDisabled" ) == false)
			{
				GetClientAbsOrigin(RandomRobotHuman, Position);
				TeleportEntity(iflagr, Position, NULL_VECTOR, NULL_VECTOR);
				CanTeleportBomb1 = false;//Prevent for 2 teleport
				//SecondBombEnable = true;// This bool will become false if the first intel is taken.
				break;
			}
			}
			
			//iflagr = FindEntityByClassname(iflagr, "item_teamflag");
		}
	}
}
public Action:WaveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//CPrintToChatAll("{fullred}[DEBUG]: {orange}Event: mvm_wave_complete");
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == _:TFTeam_Red && !IsFakeClient(i) && IsRobotLocked[i])
			{
				IsRobotLocked[i] = false;
				CPrintToChat( i, "{fullblue}[BWR2]{yellow} You have been unlocked from joining {blue}BLU{yellow}." );
			}
		}
	}
	if(IsMannhattan)
	{
		new i = -1;
		while ((i = FindEntityByClassname(i, "logic_relay")) != -1)
		{
			if(IsValidEntity(i))
			{
				decl String:strName[50];
				GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
				if(strcmp(strName, "holograms_3way_relay") == 0)
				{
					AcceptEntityInput(i, "Trigger");
					break;
				}
			} 
		}
	}
	g_CanDispatchSentryBuster = false;
	CanTeleportBomb = false;
	CanTeleportBomb1 = false;
	CanTeleportBomb2 = false;
	CanTeleportBomb3 = false;
	nGateCapture = 0;
	new iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "team_control_point") ) != -1 )
	{
		if((GetEntProp(iEnt,Prop_Send,"m_iTeamNum") == 3))
		{
			nGateCapture +=1;
		}
	}
	BossEnabled = false;
	
	CountWaveNumber(); // check wave numbers
	CheckGiantAvailability(); // check giants
	//CPrintToChatAll("{fullblue}[BWR2]{yellow} Current Wave Number: %d | Total Wave Number: %d", iCurrentWave, iTotalWave);
}
// wave failed
public Action:WaveFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	//CPrintToChatAll("{fullred}[DEBUG]: {orange}Event: mvm_wave_failed");
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
			{	
				IsRobotLocked[i] = true;
				CPrintToChat( i, "{fullblue}[BWR2]{yellow} You have been locked from joining {blue}BLU{yellow}." );
				CPrintToChat( i, "{fullblue}[BWR2]{yellow} Win a single wave on {red}RED{yellow} to join {blue}BLU {yellow}again." );
			}
		}
	}
	flNextChangeTeamBlu = GetGameTime() + 30.0;
	
	
	CountWaveNumber(); // check wave numbers
	CheckGiantAvailability(); // check giants
	IsHalloweenMission();
	//CPrintToChatAll("{fullblue}[BWR2]{yellow} Current Wave Number: %d | Total Wave Number: %d", iCurrentWave, iTotalWave);
}
public Action:MVMVictory(Handle:event, const String:name[], bool:dontBroadcast)
{
	//CPrintToChatAll("{fullred}[DEBUG]: {orange}Event: mvm_mission_complete");
	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsFakeClient(i) && IsRobotLocked[i] && IsClientConnected(i) && IsClientInGame(i))
		{
			IsRobotLocked[i] = false;
			CPrintToChat( i, "{fullblue}[BWR2]{yellow} You have been unlocked from joining {blue}BLU{yellow}." );
			if(GetClientTeam(i) == _:TFTeam_Blue && !IsFakeClient(i))
			{
				ClientCommand(i, "sm_joinred"); // forces players on BLU to join RED
			}
		}
	}
}
public LoadTF2bwrConfigs(CurrentWave)
{
	new String:cvar[32];
	Format(cvar, sizeof(cvar), "tf_mvm_popfile");
	new String:responseBuffer[4096];
	ServerCommandEx(responseBuffer, sizeof(responseBuffer), "%s", cvar);
	decl String:pop[8];
	decl String:buffer[255];
	decl String:jumpkey[255];
	KvGoBack(kvKey);
	//PrintToChatAll("[TF2BWR][Boss System] Load Config");
	KvJumpToKey(kvKey, "popfile");
	//PrintToChatAll("[TF2BWR][Boss System] Detect Popfile");
	new i;
	for(i = 1; i<=200; i++)
	{
		Format(pop, sizeof(pop),"pop%i",i);
		KvGetString(kvKey, pop, buffer, sizeof(buffer),"");
		//PrintToChatAll("[TF2BWR][Boss System] pop%i", i);
		if(!StrEqual(buffer,""))
		{
			if(StrContains(responseBuffer,buffer) != -1)
			{
				Format(jumpkey, sizeof(jumpkey),buffer);
				break;
			}
		}
		else
		{
			return;
		}
	}
	//PrintToChatAll("[TF2BWR][Boss System] Current Popfile Selected: %s", jumpkey);
	KvGoBack(kvKey);
	if(KvJumpToKey(kvKey, jumpkey, true))
	{
		new String:map[32];
		GetCurrentMap(map,sizeof(map));
		//PrintToChatAll("[TF2BWR][Boss System] jumpkey: %s || map: %s", jumpkey, map);
		if(!StrEqual(jumpkey, map))
		{
			if(KvJumpToKey(kvKey, "Boss", true))
			{
				//PrintToChatAll("[TF2BWR][Boss System] Boss Key");
				new String:wave[32];
				new String:bosswavetime[32];
				Format(wave, sizeof(wave),"wave%i",CurrentWave);
				new numwave=KvGetNum(kvKey, wave, 0);
				new String:BossListWave[255];
				Format(BossListWave, sizeof(BossListWave),"BossListWave%i",CurrentWave);
				Format(bosswavetime, sizeof(bosswavetime),"Bosswavetime%i",CurrentWave);
				KvGetString(kvKey, BossListWave, BossList, sizeof(BossList),"");
				flBossWaitTime = KvGetFloat(kvKey,bosswavetime,0.0);
				if(!StrEqual(BossList,""))
				{
					//PrintToChatAll("[TF2BWR][Boss System] BossList: %s", BossList);
				}
				else
				{
					Format(BossList, sizeof(BossList),"EveryBoss");
				}
				//PrintToChatAll("[TF2BWR][Boss System] Cfg wave%i", CurrentWave);
				//PrintToChatAll("[TF2BWR][Boss System] Boss active? %i , if it's 0 disable it's 1 enabled", numwave);
				if(numwave == 1)
				{
					KvGoBack(kvKey);
					BossEnabled = true;
					fNextBossTime == 0.0;
					CPrintToChatAll("{yellow}[BWR] {orange}Bosses are enable for this wave!");
					return;
				}
				else
				{
					KvGoBack(kvKey);
					BossEnabled = false;
					CPrintToChatAll("{yellow}[BWR] {orange}Bosses are disabled for this wave!");
					return;
				}
			}
		}
		else
		{
			PrintToChatAll("[Tf2bwr] The base popfile is not allowed to have boss remove it in the config file");
			KvGoBack(kvKey);
			return;
		}
	}
}
//////////////////////////////////////////////
/////////ADMIN MENU ADDED BY BENOIST3012/////
////////////////////////////////////////////
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
	#if defined _tf2spawnitem_included
	if( StrEqual( strLibrary, "tf2spawnitem", false ) )
		bUseTF2SI = false;
	#endif
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
 
	AddToTopMenu(hAdminMenu, "sm_robotbossmenu", TopMenuObject_Item, AdminMenu_AddMoney, player_commands, "sm_robotbossmenu", ADMFLAG_CUSTOM2);
}
public AdminMenu_AddMoney(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	new Handle:hPlayerSelectMenu;
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "(BWR2) Boss menu");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		hPlayerSelectMenu = CreateMenu(Menu_PlayerSelect);
		SetMenuTitle(hPlayerSelectMenu, "Select Target(Only Player In Blue!)");
		
		new maxClients = GetMaxClients();
		for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			else if (IsFakeClient(i))
			{
				continue;
			}
			if (GetClientTeam(i) != _:TFTeam_Blue)
			{
				continue;
			}
			new String:infostr[128];
			Format(infostr, sizeof(infostr), "%N", i);
			new String:indexstr[32];
			IntToString(i, indexstr, sizeof(indexstr)); 
			
			AddMenuItem(hPlayerSelectMenu,indexstr,infostr);
		}
		SetMenuExitButton(hPlayerSelectMenu, true);
		DisplayMenu(hPlayerSelectMenu, param, MENU_TIME_FOREVER);
	}
}
public Menu_PlayerSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:target[32];
		GetMenuItem(menu, GetMenuItemCount(menu)-1, target, sizeof(target));
		new client = StringToInt(target);
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new Handle:hBossSelectMenu = CreateMenu(Menu_BossSelect);
		SetMenuTitle(hBossSelectMenu, "Select Boss for the player:%N", client);
		
		AddMenuItem(hBossSelectMenu, "//BossList//", "//BossList//"); //Don't remove this
		AddMenuItem(hBossSelectMenu, "SergeantCrits", "SergeantCrits");
		AddMenuItem(hBossSelectMenu, "MajorCrits", "MajorCrits");
		AddMenuItem(hBossSelectMenu, "SirNukesalot", "SirNukesalot");
		AddMenuItem(hBossSelectMenu, "ChiefTavish", "ChiefTavish");
		AddMenuItem(hBossSelectMenu, "ChiefPyro", "ChiefPyro");
		AddMenuItem(hBossSelectMenu, "CaptainPunch", "CaptainPunch");
		AddMenuItem(hBossSelectMenu, "MajorBomber", "MajorBomber");
		AddMenuItem(hBossSelectMenu, "RocketSpammer", "RocketSpammer");
		
		AddMenuItem(hBossSelectMenu, info, "", ITEMDRAW_IGNORE);
		
		SetMenuExitButton(hBossSelectMenu, true);
		DisplayMenu(hBossSelectMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Menu_BossSelect(Handle:menu, MenuAction:action, param1, param2)
{
	new String:Bossstr[32];
	GetMenuItem(menu, param2, Bossstr, sizeof(Bossstr));
	new String:target[32];
	GetMenuItem(menu, GetMenuItemCount(menu)-1, target, sizeof(target));
	new client = StringToInt(target);
	if( GetClientTeam(client) == _:TFTeam_Blue )
	{
		if(StrEqual(Bossstr,"MajorCrits"))
			SetClassVariant( client, TFClass_Soldier, 101 );
		else if(StrEqual(Bossstr,"SirNukesalot"))
			SetClassVariant( client, TFClass_DemoMan, 102 );
		else if(StrEqual(Bossstr,"ChiefTavish"))
			SetClassVariant( client, TFClass_DemoMan, 101 );
		else if(StrEqual(Bossstr,"ChiefPyro"))
			SetClassVariant( client, TFClass_Pyro, 100 );
		else if(StrEqual(Bossstr,"CaptainPunch"))
			SetClassVariant( client, TFClass_Heavy, 100 );
		else if(StrEqual(Bossstr,"MajorBomber"))
			SetClassVariant( client, TFClass_DemoMan, 100 );
		else if(StrEqual(Bossstr,"SergeantCrits"))
			SetClassVariant( client, TFClass_Soldier, 100 );
		else if(StrEqual(Bossstr,"RocketSpammer"))
			SetClassVariant( client, TFClass_Soldier, 102 );
	}
}
//////////////////////////////////////////////////////////
//////////////BOSS SYSTEM END////////////////////////////
////////////////////////////////////////////////////////
public Action:OnRoundWinPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	//CPrintToChatAll("{fullred}[DEBUG]: {orange}Event: teamplay_round_win");
	if(BombHasBeenDeployed)
	{
		new soundswitch = GetRandomInt(1, 12);
		decl String:strAnnounceLine[255];
		if(soundswitch > 9)
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_wave_lose%i.mp3", soundswitch );
		if(soundswitch < 10)
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_wave_lose0%i.mp3", soundswitch );
		EmitSoundToAll( strAnnounceLine );
		//GameRules_SetProp( "m_bPlayingMannVsMachine", 1 );
		
	}
	for (new i = 1; i <= MaxClients; i++)
		BtouchedUpgradestation[i] = false;
	return Plugin_Continue;
}

public Action:OnRoundStartPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	if( IsMvM()	)
	{
		new bool:bGiants = iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red );
		for( new iClient = 1; iClient <= MaxClients; iClient++ )
//			if( IsValidRobot( iClient ) && !CheckTeamBalance( false, iClient ) && ( iRobotVariant[iClient] >= 0 || !bMyLoadouts ) && ( bRandomizer || !bGiants && ( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal ) ) )
			if( IsValidRobot( iClient ) && ( iRobotVariant[iClient] >= 0 || !bMyLoadouts ) && ( bRandomizer || !bGiants && ( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal ) ) )
				PickRandomRobot( iClient );
	}
	return Plugin_Continue;
}

public Action:OnSpawnStartTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidRobot(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue)
		return Plugin_Continue;
	//if(!bInRespawn[iOther])
	//{
	//PrintToChatAll("enabled bool repsawn");
	bInRespawn[iOther] = true;
	//}
	return Plugin_Continue;
}

public Action:Timer_RoboSpyTauntRedPlayers( Handle:hTimer, any:client )
{
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	if( iClass != TFClass_Spy || GameRules_GetRoundState() != RoundState_RoundRunning || !IsPlayerAlive(client) )
		return Plugin_Stop;
		
	//play snort
	
	new SPYSNDSW = -1;
	SPYSNDSW = GetRandomInt(1,6);
	switch(SPYSNDSW)
	{
		case 1:
		{
			PrecacheSnd( SPYLAUGH1 );
			EmitSoundToAll( SPYLAUGH1, client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		case 2:
		{
			PrecacheSnd( SPYLAUGH2 );
			EmitSoundToAll( SPYLAUGH2, client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		case 3:
		{
			PrecacheSnd( SPYLAUGH3 );
			EmitSoundToAll( SPYLAUGH3, client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		case 4:
		{
			PrecacheSnd( "vo/mvm/norm/spy_mvm_revenge01.mp3" );
			EmitSoundToAll( "vo/mvm/norm/spy_mvm_revenge01.mp3", client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		case 5:
		{
			PrecacheSnd( "vo/mvm/norm/spy_mvm_revenge02.mp3" );
			EmitSoundToAll( "vo/mvm/norm/spy_mvm_revenge02.mp3", client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		case 6:
		{
			PrecacheSnd( "vo/mvm/norm/spy_mvm_revenge03.mp3" );
			EmitSoundToAll( "vo/mvm/norm/spy_mvm_revenge03.mp3", client, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
	}
	return Plugin_Continue;
}

public Action:OnSpawnEndTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidRobot(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue )
		return Plugin_Continue;
	
	//CreateTimer(0.01, Timer_CheckinSpawn, iOther);
	bInRespawn[iOther] = false;
	if(TF2_IsPlayerInCondition( iOther, TFCond_Taunting ) && GameRules_GetRoundState() == RoundState_BetweenRounds)
		KillPlayer2(iOther);
	return Plugin_Continue;
}
public Action:Timer_CheckinSpawn(Handle:timer, client)
{

	bInRespawn[client] = false;
}
public Action:OnCapZoneTouch( iEntity, iOther )
{
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Stop;
	
	static Float:flLastSndPlay[MAXPLAYERS];

	if( iDeployingBomb >= 0 )
		return Plugin_Continue;
	
	if(
		!IsMvM()
		|| GameRules_GetRoundState() != RoundState_RoundRunning
		|| !IsValidClient(iOther)
		|| IsFakeClient(iOther)
		|| iRobotMode[iOther] == Robot_SentryBuster
		|| !( GetEntityFlags(iOther) & FL_ONGROUND )
		|| !IsValidEdict( GetEntPropEnt( iOther, Prop_Send, "m_hItem" ) )
	)
		return Plugin_Continue;
		
	//if(BombHasBeenDeployed)
	//	return Plugin_Stop;
		
	//if( ( flLastSndPlay[iOther] + 2.0 ) <= GetGameTime() )
	//{
	SetEntPropFloat( iOther, Prop_Send, "m_flMaxspeed", 0.1 );
	
	if( iRobotMode[iOther] == Robot_Giant ) //|| iRobotMode[iOther] == Robot_BigNormal )
	{
		PrecacheSnd( GIANTROBOT_SND_DEPLOYING );
		EmitSoundToAll( GIANTROBOT_SND_DEPLOYING, iOther, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
	}
	else
	{
		PrecacheSnd( SMALLROBOT_SND_DEPLOYING );
		EmitSoundToAll( SMALLROBOT_SND_DEPLOYING, iOther, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
	}
	
	SetVariantInt(1);
	AcceptEntityInput(iOther, "SetForcedTauntCam");
	flLastSndPlay[iOther] = GetGameTime();
	new i = -1;	
	while ((i = FindEntityByClassname(i, "func_breakable")) != -1)
	{
	if(IsValidEntity(i))
	{
		decl String:strName[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "cap_hatch_glasswindow") == 0)
		{
			LookAtTarget(iOther, i, false);
			break;
		}
	} 
	}
	//TF2_StunPlayer(iOther, 2.1, 0.0, TF_STUNFLAGS_LOSERSTATE, _);
	
	//PlayDeployAnimationPrimary(iOther); //deploy not always playing
	
	RemoveWearables(iOther, true);

	CreateTimer(2.7, Timer_CheckIfFailedToDeploy, iOther);
	CreateTimer( 0.05, Timer_DeployAnim, iOther );
	CreateTimer( 0.1, Timer_BlockTurning, iOther ); 
	
	//}
	
	g_hDeployTimer = CreateTimer(2.1, Timer_DeployTimer, iOther);
	CreateTimer(2.0, Timer_TLKDEPLOYED, iOther);
	if(IsValidRobot(iOther) && iRobotMode[iOther] != Robot_Giant)
	{
	new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
	if(BombStage[iOther] == 0)
	{
		if (g_hbombs1[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs1[iOther]);
			g_hbombs1[iOther] = INVALID_HANDLE;
		}
		if (g_hbombs2[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs2[iOther]);
			g_hbombs2[iOther] = INVALID_HANDLE;
		}
		if (g_hbombs3[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs3[iOther]);
			g_hbombs3[iOther] = INVALID_HANDLE;
		}
		new Float:CurrentTime = GetGameTime();
		new Float:NextTime = CurrentTime+5.2;
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
		g_hbombs1[iOther] = CreateTimer(5.2, Timer_bombst1, iOther);
		g_hbombs2[iOther] = CreateTimer(20.0, Timer_bombst2, iOther);
		g_hbombs3[iOther] = CreateTimer(35.0, Timer_bombst3, iOther);
	}
	if(BombStage[iOther] == 1)
	{
		if (g_hbombs2[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs2[iOther]);
			g_hbombs2[iOther] = INVALID_HANDLE;
		}
		if (g_hbombs3[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs3[iOther]);
			g_hbombs3[iOther] = INVALID_HANDLE;
		}
		new Float:CurrentTime = GetGameTime();
		new Float:NextTime = CurrentTime+15.0;
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
		g_hbombs2[iOther] = CreateTimer(20.0, Timer_bombst2, iOther);
		g_hbombs3[iOther] = CreateTimer(35.0, Timer_bombst3, iOther);
	}
	if(BombStage[iOther] == 2)
	{
		if (g_hbombs3[iOther] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs3[iOther]);
			g_hbombs3[iOther] = INVALID_HANDLE;
		}
		new Float:CurrentTime = GetGameTime();
		new Float:NextTime = CurrentTime+15.0;
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
		g_hbombs3[iOther] = CreateTimer(35.0, Timer_bombst3, iOther);
	}
	}
	iDeployingBomb = iOther;
//	CreateTimer( 1.8, Timer_DeployingBomb, GetClientUserId(iOther) );  // old code 
	if( (flAnnounceDeploy + 2.5) < GetEngineTime())
	{
		decl String:strAnnounceLine[255];
		new random = GetRandomInt(1,4);
		switch(random)
		{
			case 1:
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts08.mp3");
			case 2:
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts09.mp3");
			case 3:
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts10.mp3");
			case 4:
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_bomb_alerts11.mp3");
		}
		EmitSoundToAll( strAnnounceLine );
		flAnnounceDeploy = GetEngineTime();
	}
	
	return Plugin_Continue;
}
public Action:Timer_CheckIfFailedToDeploy( Handle:hTimer, any:iOther )
{
	if(GateStunEnabled && !BombHasBeenDeployed)
		ForcePlayerSuicide( iOther );
}
//stock StopDeployAnim(client)
//{
	//SetAnimation(client, "run_primary", 1, 1);	
//}

public Action:Timer_DeployAnim( Handle:hTimer, any:iOther )
{
	PlayAnimationV3(iOther, "primary_deploybomb");
	TF2_RemoveCondition(iOther, TFCond_Taunting);
	//new iClass = _:TF2_GetPlayerClass(iOther);
	//if( iClass >= 1 && iClass < 9 )
	//	TF2_PlayAnimation( iOther, 21, iDeployingAnim[iClass-1][_:(iRobotMode[iOther]==Robot_Giant)] );
	//SetAnimation(iOther, "primary_deploybomb", 1, 1);
	
}
public Action:Timer_BlockTurning( Handle:hTimer, any:iOther )
{
	//TF2_StunPlayer(iOther, 2.2, 0.0, TF_STUNFLAGS_LOSERSTATE, _);
	TF2_AddCondition(iOther, TFCond_HalloweenKartNoTurn, 2.1);
}
public Action:OnCapZoneEndTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || iOther != iDeployingBomb )
		return Plugin_Continue;
		
	//if( iOther > 33 && iOther < 0 )
	//	return Plugin_Handled;
	StopDeployEnt(iOther);
	StopSnd( iOther, _, SMALLROBOT_SND_DEPLOYING );
	StopSnd( iOther, _, GIANTROBOT_SND_DEPLOYING );
	//StopDeployAnim(iOther);
	
	ShowWearables(iOther);
	
	TF2_RemoveCondition(iOther, TFCond_Dazed);
	TF2_RemoveCondition(iOther, TFCond_HalloweenKartNoTurn);

	iDeployingBomb = -1;

	if (g_hDeployTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hDeployTimer);
        g_hDeployTimer = INVALID_HANDLE;
    }
	
	return Plugin_Continue;
}
stock ShowHiddenBombs()
{
	new iFlag = -1;
	while( ( iFlag = FindEntityByClassname( iFlag, "item_teamflag" ) ) != -1 )
	{
		if( BombHidden[iFlag] )
		{
			SetEntityModel(iFlag, "models/props_td/atom_bomb.mdl");
			SetEntProp(iFlag, Prop_Send, "m_bGlowEnabled", 1);
			SetEntityRenderColor(iFlag, 255, 255, 255, 255);
			BombHidden[iFlag] = false;
		}
	}
}

stock StopDeployEnt(client)
{
	PrecacheModel("models/props_td/atom_bomb.mdl");
//	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	new i2 = -1;	
	while((i2 = FindEntityByClassname(i2, "item_teamflag")) != -1)
	{
	if(IsValidEntity(i2))
	{
		new iOwner2 = GetEntPropEnt( i2, Prop_Send, "m_hOwnerEntity" );
		if(client == iOwner2)
		{
			SetEntityModel(i2, "models/props_td/atom_bomb.mdl");
			SetEntProp(i2, Prop_Send, "m_bGlowEnabled", 1);
			SetEntityRenderColor(i2, 255, 255, 255, 255);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			break;
		}
	} 
	}
	KillDeployAnimation3();

	SetEntityRenderColor(client, 255, 255, 255, 255);
}
stock KillDeployAnimation3()
{
	//PrintToChatAll("reached killdeploy code!");
	new i = -1;	
	while ((i = FindEntityByClassname(i, "prop_dynamic")) != -1)
	{
	if(IsValidEntity(i))
	{
		//PrintToChatAll("its valid!");
		decl String:strName[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		//new iOwner = GetEntPropEnt( i, Prop_Send, "m_hOwnerEntity" );
		if(strcmp(strName, "bwrdeployaniment") == 0 )//&& iOwner == client)
		{
		//if(iOwner == client)
			//PrintToChatAll("kill attempt!");
			AcceptEntityInput(i,"KillHierarchy");
			break;
		}
	} 
	}
}

public Action:OnTriggerUpgradestationtouch( iEntity, iOther )
{
	if( !IsMvM() )
		return Plugin_Continue;
	// Causing crashes?
	// if(IsValidClient(iOther) && IsClientInGame(iOther) && IsPlayerAlive(iOther))
	// {
		// BtouchedUpgradestation[iOther] = true;
	// }
	// if( GetClientTeam(iOther) == _:TFTeam_Blue && IsPlayerAlive(iOther) && !IsFakeClient(iOther) )
	// {
		// ForcePlayerSuicide(iOther);
	// }

	return Plugin_Continue;
}

public Action:OnTriggerGateTouch( iEntity, iOther )
{
	if( !IsMvM() )
		return Plugin_Continue;
	if(IsValidClient(iOther) && IsClientInGame(iOther) && IsPlayerAlive(iOther) && IsMannhattan == true)
	{
		if( GetClientTeam(iOther) != _:TFTeam_Blue || !IsGateBotPlayer[iOther] || iRobotMode[iOther] == Robot_SentryBuster || TF2_IsPlayerInCondition( iOther, TFCond_Disguised ) )
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:OnTriggerAlarmTouch( iEntity, iOther )
{
	if( !IsMvM() )
		return Plugin_Continue;
		
	//PrintToChatAll("tounched alarm!");
	if(IsValidClient(iOther) && IsClientInGame(iOther) && IsPlayerAlive(iOther))
	{
		//if( GetClientTeam(iOther) != _:TFTeam_Blue || !IsGateBotPlayer[iOther] )//|| iRobotMode[iOther] == Robot_SentryBuster )
		if( GetClientTeam(iOther) != _:TFTeam_Blue || !IsGateBotPlayer[iOther] || iRobotMode[iOther] == Robot_SentryBuster || TF2_IsPlayerInCondition( iOther, TFCond_Disguised ) )// 
			return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action:OnFlagTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || IsFakeClient(iOther) )
		return Plugin_Continue;
		
	if( GetClientTeam(iOther) != _:TFTeam_Blue || !bFlagPickup || TF2_GetPlayerClass(iOther) == TFClass_Engineer || iRobotMode[iOther] == Robot_SentryBuster || IsGateBotPlayer[iOther])
		return Plugin_Handled;

	return Plugin_Continue; 
}

stock SentryPushonDmg(attacker, attacked)
{
	new Ent = attacker;
	new i = attacked;
	new Float:flPos1[3];
	GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", flPos1 );

	new Float:flPos2[3];
	GetClientAbsOrigin(i, flPos2);
			
	new Float:Vec[3];
	new Float:AngBuff[3];
	MakeVectorFromPoints(flPos1, flPos2, Vec);
	GetVectorAngles(Vec, AngBuff);
	AngBuff[0] -= 30.0; 
	GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(Vec, Vec);
	ScaleVector(Vec, 2020.0);   
	Vec[2] += 250.0;
	TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
}
stock bool:IsAttackerSentry(iInflictor)
{
	new String:iAttackerObject[128];
	GetEdictClassname(iInflictor, iAttackerObject, sizeof(iAttackerObject));
	if (StrEqual(iAttackerObject, "obj_sentrygun"))
	{
		if(GetEntProp(iInflictor, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
		{
			//PrintToChatAll("chkd sentry");
			return true;
		}
	}
	return false;
}
stock bool:IsAIBuster(client)
{
	if(!IsFakeClient(client))
		return false;
	
	new String:modelname[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
	if(StrContains(modelname, "sentry_buster") == -1)
		return false;
	return true;
}
stock bool:IsGiantRobot(client)
{
	if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
		return true;
	return false;
}

public Action:OnTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
{
	if( !IsMvM() || !IsValidClient(iVictim) || !IsValidClient(iAttacker) )
		return Plugin_Continue;
	
	//PrintToChatAll( "%f", flDamage);	
	//PrintToChatAll( "%i %i", iDamageBits, iDamageCustom );	
	//PrintToChatAll( "Damage: %0.2f (%d) (%d)", flDamage, iDamageBits, iDamageCustom );
	
	if(GameRules_GetRoundState() == RoundState_RoundRunning && iAttacker != iVictim && IsAIBuster(iAttacker) && IsGiantRobot(iVictim) && GetClientTeam(iVictim) == _:TFTeam_Blue)
	{
		flDamage = 900.0;//sentry buster fix
		return Plugin_Changed;
	}
	
	if(GameRules_GetRoundState() == RoundState_BetweenRounds && iAttacker != iVictim)
	{
		flDamage = 0.0;
		return Plugin_Changed;
	}
	if( (iDamageBits != TF_DMG_AFTERBURN) && !IsAttackerSentry(iInflictor))
	{
		//if( GetClientTeam(iVictim) == _:TFTeam_Red && iRobotMode[iAttacker] == Robot_SentryBuster && !TF2_IsPlayerInCondition( iAttacker, TFCond_Taunting ))
		//{
		//	flDamage = 0.0;
		//	return Plugin_Changed;
		//}
		if( GetClientTeam(iVictim) == _:TFTeam_Blue && iRobotMode[iVictim] == Robot_SentryBuster )
		{
			if( TF2_IsPlayerInCondition( iVictim, TFCond_Taunting ) )
			{
				flDamage = 0.0;
				return Plugin_Changed;
			}
			else if( flDamage * ( iDamageBits & DMG_CRIT ? 3.0 : 1.0 ) >= float( GetClientHealth(iVictim) ) )
			{
				if( GetEntityFlags(iVictim) & FL_ONGROUND )
					FakeClientCommand( iVictim, "taunt" );
				else
					SentryBuster_Explode( iVictim );
				flDamage = 0.0;
				return Plugin_Changed;
			}
		}
		if( GetClientTeam(iVictim) == _:TFTeam_Red && bInRespawn[iAttacker] && iAttacker != iVictim )
		{
			flDamage = 0.0;
			return Plugin_Changed;
		}
	
		if( GetClientTeam(iVictim) == _:TFTeam_Red && bInRespawn[iAttacker])//&& TF2_IsPlayerInCondition( iAttacker, TFCond_UberchargedHidden ) )
		{
			flDamage = 0.0;
			return Plugin_Changed;
		}
		//new TFClassType:class = TF2_GetPlayerClass(iAttacker);
	}
	return Plugin_Continue;
}
public Action:OnBuildingTakeDamage( iBuilding, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
{
	if (!IsValidEntity( iBuilding ) || !IsValidClient( iAttacker ))
		return Plugin_Continue;
		
	
//	if( bInRespawn[iAttacker] ) //&& IsValidEntity( iBuilding )
//	{
//		flDamage = 0.0;
//		if( bNotifications )
//			PrintToChat( iAttacker, "You can't hit enemies from spawn zone." );
//		return Plugin_Changed;
//	}
	if( GetClientTeam(iAttacker) == _:TFTeam_Blue && bInRespawn[iAttacker] && !IsAttackerSentry(iInflictor) ) // && IsValidEntity( iBuilding ) )
	{
		flDamage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
stock bool:IsValidMvMRobot( iClient )
{
	if( !IsValidClient(iClient) ) return false;
	if( GetClientTeam(iClient) != _:TFTeam_Blue ) return false;
	return true;
}

public Action:NormalSoundHook( iClients[64], &iNumClients, String:strSound[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags )
{
	//if( StrContains( strSound, "vo/mvm_", false ) != -1 ) PrintToServer( "%s %d %f %d %d %d", strSound, iChannel, flVolume, iLevel, iPitch, iFlags );
	if( !IsMvM() || !IsValidRobot(iEntity) )
		return Plugin_Continue;
	
	new TFClassType:iClass = TF2_GetPlayerClass( iEntity );
	
	//if( iClass == TFClass_Medic )
	//	PrintToChatAll( "Missing sound: %s", strSound );

	if( StrContains( strSound, "announcer", false ) != -1 )
		return Plugin_Continue;
	//if( StrContains( strSound, "demo_charge_windup", false ) != -1 )
	//	ReplaceString( strSound, sizeof( strSound ), "demo_charge_windup", "mvm/giant_soldier/giant_soldier_" );
	
	if( StrContains( strSound, ")weapons/rocket_", false ) != -1 && ( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal ) )
	{
		if(!IsntStock[iEntity]) //fix for giant blackbox soldier
		{
			ReplaceString( strSound, sizeof( strSound ), ")weapons/", "mvm/giant_soldier/giant_soldier_" );
			PrecacheSnd( strSound );
			EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
			return Plugin_Stop;
		}
	}
	else if( StrContains( strSound, "weapons\\quake_rpg_fire_remastered", false ) != -1 && ( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal ) )
	{
		ReplaceString( strSound, sizeof( strSound ), "weapons\\quake_rpg_fire_remastered", "mvm/giant_soldier/giant_soldier_rocket_shoot" );
		PrecacheSnd( strSound );
		EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
		return Plugin_Stop;
	}
	//if( iClass == TFClass_Medic )
	//	PrintToChatAll( "sound: %s", strSound );
	if( StrContains( strSound, "vo/", false ) != -1)//sentry buster only needed atm sinve mvm fixed voices
	{
		if(iRobotMode[iEntity] == Robot_SentryBuster)
			return Plugin_Stop;
		//if( iClass == TFClass_Medic )
		//{
		//	ReplaceString( strSound, sizeof( strSound ), "vo/", "vo/mvm/norm/medic_mvm_Go01.mp3", false );
			//sound: 
			//PrintToChatAll( "sound: %s", strSound );
		//}
		if( TF2_IsPlayerInCondition( iEntity, TFCond_Disguised ) || Is666Mode)
		{
			//PrintToChatAll( "client disguised!");
			if( StrContains( strSound, "norm/", false ) != -1)
			{
				ReplaceString( strSound, sizeof( strSound ), "vo/mvm/norm/", "vo/", false );
				ReplaceString( strSound, sizeof( strSound ), "_mvm", "", false );
			}
			if( StrContains( strSound, "mght/", false ) != -1)
			{
				ReplaceString( strSound, sizeof( strSound ), "vo/mvm/mght/", "vo/", false );
				ReplaceString( strSound, sizeof( strSound ), "_mvm_m", "", false );
			//	PrintToChatAll( "sound: %s", strSound );
				
			}
			//EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
			//PrintToChatAll( "sound: %s", strSound );
			return Plugin_Changed;
		}
		else
		{
		if(
			StrContains( strSound, "vo/mvm/", false ) != -1
			|| StrContains( strSound, "/demoman_", false ) == -1
			&& StrContains( strSound, "/engineer_", false ) == -1
			&& StrContains( strSound, "/heavy_", false ) == -1
			&& StrContains( strSound, "/medic_", false ) == -1
			&& StrContains( strSound, "/pyro_", false ) == -1
			&& StrContains( strSound, "/scout_", false ) == -1
			&& StrContains( strSound, "/sniper_", false ) == -1
			&& StrContains( strSound, "/soldier_", false ) == -1
			&& StrContains( strSound, "/spy_", false ) == -1
			&& StrContains( strSound, "/engineer_", false ) == -1
		)
			return Plugin_Continue;
		if( iRobotMode[iEntity] == Robot_Giant) // || iRobotMode[iEntity] == Robot_BigNormal ) && iClass != TFClass_Medic
		{
			switch( iClass )
			{
				case TFClass_Scout:		ReplaceString( strSound, sizeof(strSound), "scout_", "scout_mvm_m_", false );
				case TFClass_Sniper:	ReplaceString( strSound, sizeof(strSound), "sniper_", "sniper_mvm_", false );
				case TFClass_Soldier:	ReplaceString( strSound, sizeof(strSound), "soldier_", "soldier_mvm_m_", false );
				case TFClass_DemoMan:	ReplaceString( strSound, sizeof(strSound), "demoman_", "demoman_mvm_m_", false );
				case TFClass_Medic:		ReplaceString( strSound, sizeof(strSound), "medic_", "medic_mvm_", false );
				case TFClass_Heavy:		ReplaceString( strSound, sizeof(strSound), "heavy_", "heavy_mvm_m_", false );
				case TFClass_Pyro:		ReplaceString( strSound, sizeof(strSound), "pyro_", "pyro_mvm_m_", false );
				case TFClass_Spy:		ReplaceString( strSound, sizeof(strSound), "spy_", "spy_mvm_", false );
				case TFClass_Engineer:	ReplaceString( strSound, sizeof(strSound), "engineer_", "engineer_mvm_", false );
				default:				return Plugin_Continue;
			}
		}
		else
		{
			switch( iClass )
			{
				case TFClass_Scout:		ReplaceString( strSound, sizeof(strSound), "scout_", "scout_mvm_", false );
				case TFClass_Sniper:	ReplaceString( strSound, sizeof(strSound), "sniper_", "sniper_mvm_", false );
				case TFClass_Soldier:	ReplaceString( strSound, sizeof(strSound), "soldier_", "soldier_mvm_", false );
				case TFClass_DemoMan:	ReplaceString( strSound, sizeof(strSound), "demoman_", "demoman_mvm_", false );
				case TFClass_Medic:		ReplaceString( strSound, sizeof(strSound), "medic_", "medic_mvm_", false );
				case TFClass_Heavy:		ReplaceString( strSound, sizeof(strSound), "heavy_", "heavy_mvm_", false );
				case TFClass_Pyro:		ReplaceString( strSound, sizeof(strSound), "pyro_", "pyro_mvm_", false );
				case TFClass_Spy:		ReplaceString( strSound, sizeof(strSound), "spy_", "spy_mvm_", false );
				case TFClass_Engineer:	ReplaceString( strSound, sizeof(strSound), "engineer_", "engineer_mvm_", false );
				default:				return Plugin_Continue;
			}
		}
		if( StrContains( strSound, "_mvm_m_", false ) > -1 )
			ReplaceString( strSound, sizeof( strSound ), "vo/", "vo/mvm/mght/", false );
		else
			ReplaceString( strSound, sizeof( strSound ), "vo/", "vo/mvm/norm/", false );
		ReplaceString( strSound, sizeof( strSound ), ".wav", ".mp3", false );
		
		decl String:strSoundCheck[PLATFORM_MAX_PATH];
		Format( strSoundCheck, sizeof(strSoundCheck), "sound/%s", strSound );
		if( !FileExists(strSoundCheck,true) )
		{
			//PrintToServer( "Missing sound: %s", strSound );
			return Plugin_Stop;
		}
		
		return Plugin_Changed; // check this 
		}
	}
//here was code
	
	return Plugin_Continue;
}

public Menu_Classes( Handle:hMenu, MenuAction:nAction, iClient, nMenuItem ) //here goes healthbarfix
{
	if( nAction == MenuAction_Select ) 
	{
		decl String:strSelection[32];
		GetMenuItem( hMenu, nMenuItem, strSelection, sizeof(strSelection) );
		
		if( bRandomizer )
		{
			if( StrEqual( strSelection, "random_attack", false ) )
			{
				new TFClassType:iClass[5] = {TFClass_Scout,TFClass_Soldier,TFClass_DemoMan,TFClass_Heavy,TFClass_Pyro};
				iRobotClass[iClient] = iClass[GetRandomInt(0,sizeof(iClass)-1)];
				SetClassVariant( iClient, iRobotClass[iClient], -2 );
			}
			else if( StrEqual( strSelection, "random_support", false ) )
			{
				new TFClassType:iClass[4] = {TFClass_Sniper,TFClass_Medic,TFClass_Spy,TFClass_Engineer};
				iRobotClass[iClient] = iClass[GetRandomInt(0,sizeof(iClass)-(CanPlayEngineer(iClient)?1:2))];
				SetClassVariant( iClient, iRobotClass[iClient], -3 );
			}
			else
			{
				iRobotClass[iClient] = TFClassType:GetRandomInt(1,(CanPlayEngineer(iClient)?9:8));
				SetClassVariant( iClient, iRobotClass[iClient], PickRandomClassVariant( iRobotClass[iClient] ) );
			}
		}
		else
			ShowClassMenu( iClient, TFClassType:StringToInt( strSelection ) );
	}
	else if( nAction == MenuAction_Cancel ) 
	{
		if( nMenuItem == MenuCancel_ExitBack )
			ShowClassMenu( iClient );
	}
	else if( nAction == MenuAction_End )
		CloseHandle( hMenu );
}
public Menu_ClassVariants( Handle:hMenu, MenuAction:nAction, iClient, nMenuItem )
{
	if( nAction == MenuAction_Select ) 
	{
		decl String:strSelection[32];
		GetMenuItem( hMenu, nMenuItem, strSelection, sizeof(strSelection) );
		
		decl String:strBuffer[2][32];
		ExplodeString( strSelection, "_", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]) );
		
		if( StrEqual( strBuffer[0], "scout", false ) )
			iRobotClass[iClient] = TFClass_Scout;
		else if( StrEqual( strBuffer[0], "sniper", false ) )
			iRobotClass[iClient] = TFClass_Sniper;
		else if( StrEqual( strBuffer[0], "soldier", false ) )
			iRobotClass[iClient] = TFClass_Soldier;
		else if( StrEqual( strBuffer[0], "demo", false ) )
			iRobotClass[iClient] = TFClass_DemoMan;
		else if( StrEqual( strBuffer[0], "medic", false ) )
			iRobotClass[iClient] = TFClass_Medic;
		else if( StrEqual( strBuffer[0], "heavy", false ) )
			iRobotClass[iClient] = TFClass_Heavy;
		else if( StrEqual( strBuffer[0], "pyro", false ) )
			iRobotClass[iClient] = TFClass_Pyro;
		else if( StrEqual( strBuffer[0], "spy", false ) )
			iRobotClass[iClient] = TFClass_Spy;
		else if( StrEqual( strBuffer[0], "engineer", false ) )
			iRobotClass[iClient] = TFClass_Engineer;
		else
		{
			ShowClassMenu( iClient );
			return;
		}
		new bool:bGiants = false, iVariant = StringToInt(strBuffer[1]);
		if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
			bGiants = true;
		if(
			!bMyLoadouts 
			&&
			iVariant == -1
			||
			iVariant > -1
			&&
			(
				bRandomizer
				||
				iRobotClass[iClient] == TFClass_Engineer
				&&
				!CanPlayEngineer(iClient)
				||
				!bGiants
				&&
				(
					iRobotMode[iClient] == Robot_BigNormal
					||
					iRobotMode[iClient] == Robot_Giant
				)
			)
			||
			iRobotClass[iClient] == TFClass_DemoMan
			&&
			iVariant == SENTRYBUSTER_CLASSVARIANT
			&&
			!CheckCommandAccess( iClient, "tf2bwr_sentrybuster", 0, true )
		)
			iVariant = PickRandomClassVariant( iRobotClass[iClient] );
		SetClassVariant( iClient, iRobotClass[iClient], iVariant );
	}
	else if( nAction == MenuAction_Cancel ) 
	{
		if( nMenuItem == MenuCancel_ExitBack )
			ShowClassMenu( iClient );
	}
	else if( nAction == MenuAction_End )
		CloseHandle( hMenu );
}

stock PrecacheMdl( const String:strModel[PLATFORM_MAX_PATH], bool:bPreload = false )
{
	if( FileExists( strModel, true ) || FileExists( strModel, false ) )
		if( !IsModelPrecached( strModel ) )
			return PrecacheModel( strModel, bPreload );
	return -1;
}
stock PrecacheSnd( const String:strSample[PLATFORM_MAX_PATH], bool:bPreload = false, bool:bForceCache = false )
{
	decl String:strSound[PLATFORM_MAX_PATH];
	strcopy( strSound, sizeof(strSound), strSample );
	if( strSound[0] == ')' || strSound[0] == '^' || strSound[0] == ']' )
		strcopy( strSound, sizeof(strSound), strSound[1] );
	Format( strSound, sizeof(strSound), "sound/%s", strSound );
	if( FileExists( strSound, true ) || FileExists( strSound, false ) )
	{
		if( bForceCache || !IsSoundPrecached( strSample ) )
			return PrecacheSound( strSample, bPreload );
	}
	else if( strSound[0] != ')' && strSound[0] != '^' && strSound[0] != ']' )
		PrintToServer( "Missing sound file: %s", strSample );
	return -1;
}
stock EmitSoundToClients( const String:strSample[PLATFORM_MAX_PATH] )
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			EmitSoundToClient( i, strSample );
}
stock StopSnd( iClient, iChannel = SNDCHAN_AUTO, const String:strSample[PLATFORM_MAX_PATH] )
{
	if( !IsValidEntity(iClient) )
		return;
	StopSound( iClient, iChannel, strSample );
}

stock FinishDeploying()
{
	GameRules_SetProp( "m_bPlayingMannVsMachine", 1 );
	
	iDeployingBomb = -1;
}


stock CheckTeamBalance( bool:bAutoBalance = false, iClient = 0 )
{
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bCanJoinRED = ( iMaxDefenders <= 0 || iNumDefenders < iMaxDefenders );
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders >= iMinDefenders );
	new bool:bCanJoinBLU = ( bEnoughRED && ( iMaxDefenders <= 0 || iNumHumanRobots < ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) ) );
	
	/*
	PrintToServer( "iNumDefenders: %d", iNumDefenders );
	PrintToServer( "iNumHumanRobots: %d", iNumHumanRobots );
	PrintToServer( "bCanJoinRED: %d", bCanJoinRED );
	PrintToServer( "bEnoughRED: %d", bEnoughRED );
	PrintToServer( "bCanJoinBLU: %d", bCanJoinBLU );
	*/
	
	if( !bEnoughRED )
	{
		for( new i = 0; i < ( bAutoBalance ? iMinDefenders - iNumDefenders : 1 ); i++ )
		{
			if( bAutoBalance )
				iClient = PickRandomPlayer( TFTeam_Blue );
			if( iClient && TFTeam:GetClientTeam(iClient) == TFTeam_Blue )
			{
				if( bCanJoinRED )
					Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( iClient ) );
				else
					Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
				PrintToChat( iClient, "You are moved to the other team for game balance" );
			}
		}
		return 1;
	}
	else if( iMaxDefenders > 0 )
	{
		new bool:bOverlimit = ( iNumHumanRobots > ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) );
		if( bOverlimit )
		{
			for( new i = 0; i < ( bAutoBalance ? iNumHumanRobots - ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) : 1 ); i++ )
			{
				if( bAutoBalance )
					iClient = PickRandomPlayer( TFTeam_Blue );
				if( iClient && TFTeam:GetClientTeam(iClient) != TFTeam_Blue )
				{
					if( bCanJoinRED )
						Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( iClient ) );
					else
						Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
					PrintToChat( iClient, "You are moved to the other team for game balance" );
				}
			}
			return 2;
		}
		bOverlimit = ( iNumDefenders > iMaxDefenders );
		if( bOverlimit )
		{
			for( new i = 0; i < ( bAutoBalance ? iNumDefenders - iMaxDefenders : 1 ); i++ )
			{
				if( bAutoBalance )
					iClient = PickRandomPlayer( TFTeam_Red );
				if( iClient && TFTeam:GetClientTeam(iClient) == TFTeam_Red )
				{
					if( bCanJoinBLU )
						Timer_TurnRobot( INVALID_HANDLE, GetClientUserId( iClient ) );
					else
						Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
					PrintToChat( iClient, "You are moved to the other team for game balance" );
				}
			}
			return 3;
		}
	}
	
	return 0;
}


stock PickRandomPlayer( TFTeam:iTeam = TFTeam_Unassigned )
{
	new target_list[MaxClients];
	new target_count = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			if( iTeam == TFTeam_Unassigned || TFTeam:GetClientTeam( i ) == iTeam )
				target_list[target_count++] = i;
	return ( target_count ? target_list[GetRandomInt(0,target_count-1)] : 0 );
}
public Action:Timer_stripSentrybuster(Handle:timer, any:client)//fix for gatebot sentrybuster
{
	if(iRobotMode[client] == Robot_SentryBuster)
	{
		new hat = -1;
		while((hat=FindEntityByClassname(hat, "tf_wearable"))!=INVALID_ENT_REFERENCE)
		{
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(hat , Prop_Send, "m_iItemDefinitionIndex") != 30161)// don't remove roamvision 
			{																																																																																																																																																																																																																																																																																																												
				AcceptEntityInput(hat, "Kill");
				IsGateBotPlayer[client] = false;
//				PrintToChatAll("Found hat");	
			}
		}
	}
}
stock PickRandomRobot( iClient, bool:bChangeClass = true ) // select random robot
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return;
	//SetClassVariant( iClient, TFClass_DemoMan, SENTRYBUSTER_CLASSVARIANT );
	//return;
	
	if(g_CanDispatchSentryBuster==true && iRobotMode[iClient] != Robot_SentryBuster && !IsFakeClient(iClient) && flLastSentryBuster < GetGameTime() && GameRules_GetRoundState() == RoundState_RoundRunning)// && GetRandomInt(1,5) > 4) //&& GetRandomInt(0,9) > 8 10%
	{
		flLastSentryBuster = GetGameTime() + 65.0;// disallow next buster for 360s
		g_CanDispatchSentryBuster = false;
		//PrintToChatAll("Sentry Buster dispatched.");

		if(IsMannhattan && nGateCapture != 2)
			CreateTimer(0.3, Timer_stripSentrybuster, iClient);
		
		SetClassVariant( iClient, TFClass_DemoMan, SENTRYBUSTER_CLASSVARIANT ); //buster picking
		//moved engineer speach code to on spawn
		return;
	}
	
	new TFClassType:iClass = iRobotClass[iClient];
	if( !bChangeClass && iClass == TFClass_Unknown )
		iClass = TF2_GetPlayerClass( iClient );
	if( bChangeClass || iClass == TFClass_Unknown )
		if( iSelectedVariant[iClient] == -2 )
		{
			new TFClassType:iValidClass[5] = {TFClass_Scout,TFClass_Soldier,TFClass_DemoMan,TFClass_Heavy,TFClass_Pyro};
			iClass = iValidClass[GetRandomInt(0,sizeof(iValidClass)-1)];
		}
		else if( iSelectedVariant[iClient] == -3 )
		{
			new TFClassType:iValidClass[4] = {TFClass_Sniper,TFClass_Medic,TFClass_Spy,TFClass_Engineer};
			iClass = iValidClass[GetRandomInt(0,sizeof(iValidClass)-(CanPlayEngineer(iClient)?1:2))];
		}
		else
			iClass = TFClassType:GetRandomInt(6,8);
	iRobotClass[iClient] = iClass;
	SetClassVariant( iClient, iRobotClass[iClient], ( iSelectedVariant[iClient] >= -3 && iSelectedVariant[iClient] < -1 ? iSelectedVariant[iClient] : PickRandomClassVariant( iRobotClass[iClient] ) ) );
//	new String:classname[16];
//	TF2_GetNameOfClass(TF2_GetPlayerClass(iClient), classname, sizeof(classname));
//	FakeClientCommand( iClient, "joinclass %s", classname );
}
/*stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavyweapons");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}*/
stock PickRandomClassVariant( TFClassType:iClass = TFClass_Unknown ) // Class Variant Selection
{
	new BossRandom2;
	new bool:bGiants = false;
	if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
	{
		bGiants = true;
	}
	if(!BossEnabled || GameRules_GetRoundState() != RoundState_RoundRunning || ( fNextBossTime + flBossWaitTime ) > GetEngineTime())
	{
		if(bWaveNumGiants == false)
		{
			switch(	iClass ) // giant disabled (by wave number)
			{
				case TFClass_Scout:		return GetRandomInt(0,11);
				case TFClass_Soldier:	return GetRandomInt(0,12);
				case TFClass_DemoMan:	return GetRandomInt(0,10);
				case TFClass_Pyro:		return GetRandomInt(0,14);
				case TFClass_Heavy:		return GetRandomInt(0,6);
			}
		}
		else // allows giants to spawn based on RED player count
		{
			switch(	iClass )
			{											// giants disabled 		// giant enabled
				case TFClass_Scout:		return !bGiants ? GetRandomInt(0,11) : GetRandomInt(0,18);
				case TFClass_Soldier:	return !bGiants ? GetRandomInt(0,12) : GetRandomInt(0,27);
				case TFClass_DemoMan:	return !bGiants ? GetRandomInt(0,10) : GetRandomInt(0,15);
				case TFClass_Pyro:		return !bGiants ? GetRandomInt(0,14) : GetRandomInt(0,19);
				case TFClass_Heavy:		return !bGiants ? GetRandomInt(0,6) : GetRandomInt(0,14);
			}
		}
	}
	if(BossEnabled && GameRules_GetRoundState() == RoundState_RoundRunning && ( fNextBossTime + flBossWaitTime ) < GetEngineTime() && bGiants)
	{
		switch(	iClass )
		{
			case TFClass_Scout:
			{
				if(bWaveNumGiants == false) // giant disabled (by wave number)
				{
					return GetRandomInt(0,11); // giants disabled
				}
				else
				{
					return GetRandomInt(0,18); // giants enabled
				}
			}
			case TFClass_Soldier:
			{
				new BossCase = GetRandomInt(0,10);//NEVER CHANGE THIS
				if(BossCase == 10)
				{
					new Handle:BossRandom = CreateArray();
					if(StrContains(BossList, "SergeantCrits") != -1)
						PushArrayCell(BossRandom, 1);
					if(StrContains(BossList, "MajorCrits") != -1)
						PushArrayCell(BossRandom, 2);	
					if(StrContains(BossList, "RocketSpammer") != -1)
						PushArrayCell(BossRandom, 3);	
					BossRandom2 = GetArrayCell( BossRandom, GetRandomInt(0,GetArraySize(BossRandom)-1) );
					if(BossRandom2 == 0)
						return GetRandomInt(100,102);
					if(BossRandom2 == 1)
						return 100;
					if(BossRandom2 == 2)
						return 101;
					if(BossRandom2 == 3)
						return 102;
					if(StrContains(BossList, "EveryBoss") != -1)
						return GetRandomInt(10,11);
					CloseHandle( BossRandom );
				}
				else
				{
					if(bWaveNumGiants == false) // giant disabled (by wave number)
					{
						return GetRandomInt(0,12); // giants disabled
					}
					else
					{
						return GetRandomInt(0,27); // giants enabled
					}
				}
			}
			case TFClass_DemoMan:
			{
				new BossCase = GetRandomInt(0,5);//NEVER CHANGE THIS
				if(BossCase == 5)
				{
					new Handle:BossRandom = CreateArray();
					if(StrContains(BossList, "MajorBomber") != -1)
						PushArrayCell(BossRandom, 1);
					if(StrContains(BossList, "ChiefTavish") != -1)
						PushArrayCell(BossRandom, 2);
					if(StrContains(BossList, "SirNukesalot") != -1)
						PushArrayCell(BossRandom, 3);

					BossRandom2 = GetArrayCell( BossRandom, GetRandomInt(0,GetArraySize(BossRandom)-1) );
					if(StrContains(BossList, "EveryBoss") != -1)
						return GetRandomInt(100,102);
					if(BossRandom2 == 0)
						return GetRandomInt(0,4);
					if(BossRandom2 == 1)
						return 100;
					if(BossRandom2 == 2)
						return 101;
					if(BossRandom2 == 3)
						return 102;
					CloseHandle( BossRandom );
				}
				else
				{
					if(bWaveNumGiants == false) // giant disabled (by wave number)
					{
						return GetRandomInt(0,10); // giants disabled
					}
					else
					{
						return GetRandomInt(0,15); // giants enabled
					}
				}
			}
			case TFClass_Pyro:
			{
				new BossCase = GetRandomInt(0,6);//NEVER CHANGE THIS
				if(BossCase == 6)
				{
					new Handle:BossRandom = CreateArray();
					if(StrContains(BossList, "ChiefPyro") != -1)
						PushArrayCell(BossRandom, 1);
						
					BossRandom2 = GetArrayCell(BossRandom, GetRandomInt(0,GetArraySize(BossRandom)-1));
					if(StrContains(BossList, "EveryBoss") != -1)
						return 100;
					if(BossRandom2 == 0)
						return GetRandomInt(0,5);
					if(BossRandom2 == 1)
						return 100;
					CloseHandle( BossRandom );
				}
				else
				{
					if(bWaveNumGiants == false) // giant disabled (by wave number)
					{
						return GetRandomInt(0,14); // giants disabled
					}
					else
					{
						return GetRandomInt(0,19); // giants enabled
					}
				}
			}
			case TFClass_Heavy:
			{
				new BossCase = GetRandomInt(0,11);//NEVER CHANGE THIS
				if(BossCase == 11)
				{
					new Handle:BossRandom = CreateArray();
					if(StrContains(BossList, "CaptainPunch") != -1)
						PushArrayCell(BossRandom, 1);
						
					BossRandom2 = GetArrayCell(BossRandom, GetRandomInt(0,GetArraySize(BossRandom)-1));
					if(StrContains(BossList, "EveryBoss") != -1)
						return 100;
					if(BossRandom2 == 0)
						return GetRandomInt(0,10);
					if(BossRandom2 == 1)
						return 100;
					CloseHandle( BossRandom );
				}
				else
				{
					if(bWaveNumGiants == false) // giant disabled (by wave number)
					{
						return GetRandomInt(0,6); // giants disabled
					}
					else
					{
						return GetRandomInt(0,14); // giants enabled
					}
				}
			}
		}
	}
	switch( iClass ) // Select Random Support Variants  // return !bGiants ? GetRandomInt(0,10) : GetRandomInt(0,14); //giant medic is re-enabled again
	{
		case TFClass_Medic:
		{
			if(bWaveNumGiants == false) // giant disabled (by wave number)
			{
				return GetRandomInt(0,10); // giants disabled
			}
			else
			{
				return !bGiants ? GetRandomInt(0,10) : GetRandomInt(0,14); // giants disabled/enabled based on RED player count
			}
		}
		case TFClass_Sniper:	return GetRandomInt(0,11);
		case TFClass_Spy:		return GetRandomInt(0,8);	//0;
		case TFClass_Engineer:	
		{
			new EngiNest = FindEntityByClassname(-1,"bot_hint_engineer_nest");
			if(GameRules_GetRoundState() == RoundState_RoundRunning && EngiNest != -1 && !IsMannhattan)
				return GetRandomInt(0,6); 
			else
				return 0;
		}
	}
	return -1;
}

stock bool:SetClassVariant( iClient, TFClassType:iClass = TFClass_Unknown, iSVariant = -1 ) // set class effects
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return false;
	
	if( iClass == TFClass_Unknown && ( iClass = TF2_GetPlayerClass(iClient) ) == TFClass_Unknown )
		return false;
	
	new bool:bValidVariant = false, iVariant = iSVariant, RobotMode:iMode = Robot_Normal, Effects:iNewEffect = Effect_None;
	if( bMyLoadouts && ( iVariant == -1 || iSVariant == -1 || iSVariant < -3 ) )
	{
		iRobotVariant[iClient] = -1;
		iSelectedVariant[iClient] = -1;
		PrintToChat( iClient, "* Your loadout won't be changed." );
		bValidVariant = true;
	}
	if( !bValidVariant )
	{
		if( iVariant < -1 || !bMyLoadouts && iVariant == -1 ) //dont change iVariant < -1 to -2
			iVariant = PickRandomClassVariant( iClass );
		switch( iClass )
		{
			case TFClass_Scout: // Scout Effects
			{
				if( iVariant >= 0 && iVariant <= 18 ) // valid variants
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant >= 12 ) // always the first giant
						iMode = Robot_Giant;
				}
			}
			case TFClass_Soldier: // Soldier Effects
			{
				if( iVariant >= 0 && iVariant <= 102 )
				{
					bValidVariant = true;

					if( iVariant >= 13 )
						iMode = Robot_Giant;
					if( iVariant >= 1 && iVariant <= 3 ) // soldiers with banners
						iNewEffect = Effect_FullCharge;
					else if( iVariant >= 17 && iVariant <= 19 ) // Giant soldiers with banners
						iNewEffect = Effect_FullCharge;
					else if( iVariant == 15 || iVariant == 21 || iVariant == 26 ) // charged, burst fire, australium
						iNewEffect = Effect_AlwaysCrits;
					if( iVariant == 100 || iVariant == 101 || iVariant == 102 )
					{
						iMode = Robot_Giant;
						iNewEffect = Effect_UseBossHealthBar_Effect_AlwaysCrits;
					}
				}
			}
			case TFClass_DemoMan: // Demo Effects
			{
				if( iVariant >= 0 && iVariant <= 102 )
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant == SENTRYBUSTER_CLASSVARIANT )
						iMode = Robot_SentryBuster;
					else if( iVariant == 2 ) // Samurai Demo
						iMode = Robot_BigNormal;
					else if( iVariant == 6 ) // Spammer Demoman
						iMode = Robot_BigNormal;
					else if( iVariant == 8 ) // Demopan
					{
						iMode = Robot_Stock;
						iNewEffect = Effect_AlwaysCrits;
					}
					else if( iVariant >= 11 && iVariant <= 15 ) // Giants
						iMode = Robot_Giant;
					if( iVariant == 100 || iVariant == 101 || iVariant == 102)//Effect reserved for Boss
					{
						iMode = Robot_Giant;
						iNewEffect = Effect_UseBossHealthBar_Effect_AlwaysCrits;
					}
				}
			}
			case TFClass_Pyro: // Pyro Effects
			{
				if( iVariant >= 0 && iVariant <= 100 )
				{
					bValidVariant = true;
					
					if( iVariant == 2 ) // Pyro Pusher
						iNewEffect = Effect_AlwaysCrits;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant >= 15 ) // Giant Pyros
						iMode = Robot_Giant;
					if( iVariant == 100)//Effect reserved for Boss
					{
						iMode = Robot_Giant;
						iNewEffect = Effect_UseBossHealthBar;
					}
				}
			}
			case TFClass_Heavy: // Heavy Effects
			{
				if( iVariant >= 0 && iVariant <= 100 )
				{
					bValidVariant = true;
					
					if( iVariant == 4 )
						iNewEffect = Effect_AlwaysCrits;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant == 4 )
						iMode = Robot_Small;
					else if( iVariant == 1 || iVariant == 5 )
						iMode = Robot_BigNormal;
					else if( iVariant >= 7 )
						iMode = Robot_Giant;
					if( iVariant == 100)//Effect reserved for Boss
					{
						iMode = Robot_Giant;
						iNewEffect = Effect_UseBossHealthBar;
					}
				}
			}
			case TFClass_Medic: // Medic Effects
			{
				if( iVariant >= 0 )
				{
					bValidVariant = true;
					
					if( iVariant >= -1 && iVariant <= 8)
						iNewEffect = Effect_FullCharge;
					if( iVariant >= 12 ) // begin with giant uber medic
						iNewEffect = Effect_FullCharge;
					if( iVariant == 0 )
						iMode = Robot_Stock;
					if( iVariant == 8 ) // crossbow medic
						iMode = Robot_BigNormal;
					if( iVariant >= 11 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Sniper: // Sniper Effects
			{
				if( iVariant >= 0 )
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					if( iVariant == 6 || iVariant == 10 ) // the awp snipers
						iNewEffect = Effect_AlwaysCrits;
				}
			}
			case TFClass_Spy: // Spy Effects
			{
				if( iVariant > -2 ) //== 0
				{
					bValidVariant = true;
					
					iMode = Robot_Stock;
					if( iVariant == 0 || iVariant == 1 || iVariant == 4  || iVariant == 7 )//added missing spy variant attribute
						iNewEffect = Effect_AlwaysInvisible;
					if( iVariant == 2 || iVariant == 3 || iVariant == 5 || iVariant == 6  || iVariant == 8 )//added missing spy variant attribute
						iNewEffect = Effect_AutoDisguise;
				}
			}
			case TFClass_Engineer: // Engineer Effects
			{
				if( iVariant == 0 )
				{
					bValidVariant = true;
					
					iMode = Robot_Stock;
				}
				if( iVariant == 1 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
				}
				if( iVariant == 2 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
					iMode = Robot_Stock;
				}
				if( iVariant == 3 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
				}
				if( iVariant == 4 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
				}
				if( iVariant == 5 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
				}
				if( iVariant == 6 )
				{
					bValidVariant = true;
					iNewEffect = Effect_TeleportToHint;
				}
			}
		}
	}
	new GateBotCase = GetRandomInt(1,5);
	if(GateBotCase == 5 && IsMannhattan && nGateCapture != 2)
	{
		//CreateTimer(0.2, Timer_stripSentrybuster, iClient);
		IsGateBotPlayer[iClient] = true;
	}
	else
	{
		IsGateBotPlayer[iClient] = false;
	}
	
	
	if( bValidVariant )
	{
		new bool:bAlive = IsPlayerAlive( iClient );
		if( bAlive && !bInRespawn[iClient] && GameRules_GetRoundState() == RoundState_BetweenRounds )
			SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
		if( bAlive && !bInRespawn[iClient] && GameRules_GetRoundState() == RoundState_RoundRunning)
			KillPlayer2(iClient);
			//ForcePlayerSuicide( iClient );
		//else if( !bAlive && iRespawnTimeBLU >= 0 && !GateStunEnabled )
		//	CreateTimer( float(iRespawnTimeBLU), Timer_Respawn, GetClientUserId(iClient) );
		
		iRobotMode[iClient] = iMode;
		iEffect[iClient] = iNewEffect;
		iRobotVariant[iClient] = iVariant;
		iSelectedVariant[iClient] = ( iSVariant < -1 && bRandomizer /*|| iVariant == -1*/ ? iSVariant : iVariant );
		
		if( iClass != TF2_GetPlayerClass(iClient) )
			TF2_SetPlayerClass( iClient, iClass, true );//
		if( bRandomizer )
			iRobotClass[iClient] = iClass;
		
		if( bAlive && bInRespawn[iClient] )
		{
			bSkipSpawnEventMsg[iClient] = true;
			TF2_RespawnPlayer( iClient );
		}
	}
	
	return bValidVariant;
}
public Action:GlowRedSentry( Entity, Client )
{
	if(iRobotMode[Client] != Robot_SentryBuster)
		return Plugin_Handled;
	return Plugin_Continue;
}

stock SentryBuster_Explode( iClient )
{
	if( !IsMvM() || !IsValidRobot(iClient) || iRobotMode[iClient] != Robot_SentryBuster || !IsPlayerAlive(iClient) )
		return;
	
	CreateTimer( 1.98, Timer_SentryBuster_Explode, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE );
	
	SetEntProp( iClient, Prop_Data, "m_takedamage", 0, 1 );
	//SetEntityHealth( iClient, 1 );
	
	StopSnd( iClient, SNDCHAN_STATIC, SENTRYBUSTER_SND_LOOP );
	PrecacheSnd( SENTRYBUSTER_SND_SPIN );
	EmitSoundToAll( SENTRYBUSTER_SND_SPIN, iClient, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN );
}

stock FindRandomSpawnPoint( iType )
{
	new Handle:hSpawnPoint = CreateArray();
	new String:strSpawnName[64], iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "info_player_teamspawn") ) != -1 )
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
			GetEntPropString( iEnt, Prop_Data, "m_iName", strSpawnName, sizeof(strSpawnName) );
			if( StrEqual( strSpawnName, "spawnbot_mission_sniper" ) )
			{
				if( iType == Spawn_Sniper )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_mission_spy" ) )
			{
				if( iType == Spawn_Spy )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( iType == Spawn_Giant && StrEqual( strSpawnName, "spawnbot_giant" ) )
			{
				if( iType == Spawn_Giant )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_lower" ) )
			{
				if( iType == Spawn_Lower )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_invasion" ) )
			{
				if( iType == Spawn_Invasion )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_bwr" ) )
			{
				if( iType == Spawn_Bwr )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot" ) )
			{
				if( iType == Spawn_Standard )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else
			{
				if( iType == Spawn_Normal )
					PushArrayCell( hSpawnPoint, iEnt );
			}
		}
	if( GetArraySize(hSpawnPoint) > 0 )
		return GetArrayCell( hSpawnPoint, GetRandomInt(0,GetArraySize(hSpawnPoint)-1) );
		
	CloseHandle( hSpawnPoint );
	return -1;
}

stock ResetData( iClient, bool:bFullReset = false )
{
	if( iClient < 1 || iClient > MAXPLAYERS )//>= if( iClient < 0 || iClient >= MAXPLAYERS )
		return;
	
	//if(GetClientTeam(i) == _:TFTeam_Red)
	//	bInRespawn[iClient] = false;
	iRobotClass[iClient] = TFClass_Unknown;
	iRobotMode[iClient] = Robot_Normal;
	if( IsValidClient(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Spy )
		if( iRobotVariant[iClient] )
			iEffect[iClient] = Effect_AlwaysInvisible;
		else
			iEffect[iClient] = Effect_Invisible;
	else
		iEffect[iClient] = Effect_None;
	iRobotVariant[iClient] = 0;
	iSelectedVariant[iClient] = 0;
	if( bFullReset )
	{
		bInRespawn[iClient] = false;
		bFreezed[iClient] = false;
		flNextChangeTeam[iClient] = 0.0;
		bSkipSpawnEventMsg[iClient] = false;
		bSkipInvAppEvent[iClient] = false;
		bStripItems[iClient] = false;
	}
	if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
		KillTimer( hTimer_SentryBuster_Beep[iClient] );
	hTimer_SentryBuster_Beep[iClient] = INVALID_HANDLE;
}

stock DestroyBuildings( iClient )
{
	decl String:strObjects[3][] = {"obj_sentrygun","obj_dispenser","obj_teleporter"};
	for( new o = 0; o < sizeof(strObjects); o++ )
	{
		new iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, strObjects[o] ) ) != -1 )
			if( IsValidEdict(iEnt) && GetEntPropEnt( iEnt, Prop_Send, "m_hBuilder" ) == iClient && GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SetEntityHealth( iEnt, 100 );
				SetVariantInt( 1488 );
				AcceptEntityInput( iEnt, "RemoveHealth" );
			}
	}
}

stock StripItems( iClient )
{
	if( !IsValidClient( iClient ) || IsFakeClient( iClient ) || !IsPlayerAlive( iClient ) )
		return;

//	new iWeapon = GetPlayerWeaponSlot( iClient, 0 ); //debug...
//	if( IsValidEdict( iWeapon ) )
//		TF2Attrib_RemoveAll(iWeapon);
//	new iWeapon2 = GetPlayerWeaponSlot( iClient, 1 );
//	if( IsValidEdict( iWeapon2 ) )
//		TF2Attrib_RemoveAll(iWeapon2);
//	new iWeapon3 = GetPlayerWeaponSlot( iClient, 2 );
//	if( IsValidEdict( iWeapon3 ) )
//		TF2Attrib_RemoveAll(iWeapon3);
	
	for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
		TF2_RemoveWeaponSlot( iClient, iSlot );
	
	new iOwner, iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == iClient )
		{
			if( hSDKRemoveWearable != INVALID_HANDLE )
				SDKCall( hSDKRemoveWearable, iClient, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == iClient )
		{
			if(GetEntProp(iEntity , Prop_Send, "m_iItemDefinitionIndex") != 30065)
			{
				if(Is666Mode) 
				{
					if(!IsVoodoSoul(iEntity))
					{
						if( hSDKRemoveWearable != INVALID_HANDLE )
							SDKCall( hSDKRemoveWearable, iClient, iEntity );//
						AcceptEntityInput( iEntity, "Kill" );
						//PrintToChatAll("no zombie cosmetics2");
					}
				}
				else
				{
					if( hSDKRemoveWearable != INVALID_HANDLE )
						SDKCall( hSDKRemoveWearable, iClient, iEntity );
					AcceptEntityInput( iEntity, "Kill" );
					//PrintToChatAll("no zombie cosmetics");
				}
			}
			if(GetEntProp(iEntity , Prop_Send, "m_iItemDefinitionIndex") == 30065 )
			{
				SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEntity, 255, 255, 255, 0);
			}
					
		}
	}
	if( GetClientTeam(iClient) == _:TFTeam_Blue )
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_powerup_bottle" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == iClient )
				AcceptEntityInput( iEntity, "Kill" );
		}
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_usableitem" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == iClient )
				AcceptEntityInput( iEntity, "Kill" );
		}
	}
}
stock bool:IsVoodoSoul(iEntity)
{
	if(GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") > 5616 && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") < 5626 )
		return true;
	return false;
}
stock KillVaccinatorBackpack(iClient)
{
	new iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
	{
		new iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == iClient )
		{
			if(GetEntProp(iEntity , Prop_Send, "m_iItemDefinitionIndex") == 65535)
				AcceptEntityInput( iEntity, "Kill" );
			//else
			//{
			//	new String:strModelPath[PLATFORM_MAX_PATH];
			//	GetEntPropString(iEntity, Prop_Data, "m_ModelName", strModelPath, PLATFORM_MAX_PATH);
			//	PrintToChat(iClient, "Modelpath: %s", strModelPath);  
			//}
		}
	}
}
stock FixTPose( iClient )
{
	new iWeapon = -1;
	
	if( !IsValidClient(iClient) || !IsPlayerAlive(iClient) )
		return iWeapon;
	
	for( new s = 0; s < _:TF2ItemSlot; s++ )
	{
		iWeapon = GetPlayerWeaponSlot( iClient, s );
		if( IsValidEdict( iWeapon ) )
		{
			EquipPlayerWeapon( iClient, iWeapon );
			return iWeapon;
		}
	}
	
	return iWeapon;
}

stock FixSounds( iEntity )
{
	if( iEntity <= 0 || !IsValidEntity(iEntity) )
		return;
	
	StopSnd( iEntity, _, GIANTSCOUT_SND_LOOP );
	StopSnd( iEntity, _, GIANTSOLDIER_SND_LOOP );
	StopSnd( iEntity, _, GIANTPYRO_SND_LOOP );
	StopSnd( iEntity, _, GIANTDEMOMAN_SND_LOOP );
	StopSnd( iEntity, _, GIANTHEAVY_SND_LOOP );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_INTRO );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_LOOP );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_SPIN );
}

stock bool:CanPlayEngineer( iClient )
{
	if( !nMaxEngineers )
		return false;
	if( nMaxEngineers < 0 )
		return true;
//	if( !CheckCommandAccess( iClient, "tf2bwr_engineer", 0, true ) )
//		return false;
	if( GetNumEngineers(iClient) >= nMaxEngineers ) // >
	{
		//PrintToChat( iClient, "* Too many engineers." );
		return false;
	}
	return true;
}

stock bool:CanSeeTarget( iEntity, iOther, Float:flMaxDistance = 0.0 )
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	new Float:vecStart[3];
	new Float:vecStartMaxs[3];
	new Float:vecTarget[3];
	new Float:vecTargetMaxs[3];
	new Float:vecEnd[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecOrigin", vecStart );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs );
	GetEntPropVector( iOther, Prop_Data, "m_vecOrigin", vecTarget );
	GetEntPropVector( iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs );
	
	vecStart[2] += vecStartMaxs[2] / 2.0;
	vecTarget[2] += vecTargetMaxs[2] / 2.0;
	
	if( flMaxDistance > 0.0 )
	{
		new Float:flDistance = GetVectorDistance( vecStart, vecTarget );
		if( flDistance > flMaxDistance )
		{
			BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,0,0,255},0.0,0);
			return false;
		}
	}
	
	iFilterEnt[0] = iEntity;
	iFilterEnt[1] = iOther;
	new Handle:hTrace = TR_TraceRayFilterEx( vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilter );
	if( !TR_DidHit( hTrace ) )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,255,0,255},0.0,0);
		CloseHandle( hTrace );
		return false;
	}
	
	new iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	CloseHandle( hTrace );
	
	if( iHitEnt == iOther || GetVectorDistanceMeter( vecEnd, vecTarget ) <= 1.0 )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{0,255,0,255},0.0,0);
		return true;
	}
	
	BeamEffect(vecStart,vecEnd,6.0,5.0,5.0,{0,0,255,255},0.0,0);
	return false;
}
stock Float:GetVectorDistanceMeter( const Float:vec1[3], const Float:vec2[3], bool:squared = false )
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
public bool:TraceFilter( iEntity, iContentsMask )
{
	if( iEntity == 0 || IsValidEntity(iEntity) && !IsValidEdict(iEntity) )
		return true;
	if( iEntity == iFilterEnt[0] )
		return false;
	if( iEntity == iFilterEnt[1] )
		return true;
	new String:strClassname[64];
	GetEdictClassname( iEntity, strClassname, sizeof(strClassname) ); 
	if( StrEqual( strClassname, "player", false ) || StrContains( strClassname, "obj_", false ) == 0 || StrEqual( strClassname, "tf_ammo_pack", false ) )
		return false;
	//PrintToServer( "%s - block", strClassname );
	return true;
}
stock bool:GetRobotVariantName( TFClassType:iClass, iVariant, String:strBuffer[], iBufferSize )
{ // robot variants names
	strcopy( strBuffer, iBufferSize, "" );
	switch( iClass )
	{
		case TFClass_Scout:
		{
			switch( iVariant ) // Scout Variants - Scout Effects
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Scout" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Scout" );
				case 1: strcopy( strBuffer, iBufferSize, "Batsaber Scout" );
				case 2: strcopy( strBuffer, iBufferSize, "Fish Scout" );
				case 3: strcopy( strBuffer, iBufferSize, "Armored Combat Scout" );
				case 4: strcopy( strBuffer, iBufferSize, "Sword Scout" );
				case 5: strcopy( strBuffer, iBufferSize, "Minor League Scout" );
				case 6: strcopy( strBuffer, iBufferSize, "Hyper League Scout" );
				case 7: strcopy( strBuffer, iBufferSize, "Bonk Scout" );
				case 8: strcopy( strBuffer, iBufferSize, "Wrap Assassin Scout" );
				case 9: strcopy( strBuffer, iBufferSize, "Jumping Sandman" );
				case 10: strcopy( strBuffer, iBufferSize, "Force-A-Nature Scout" );
				case 11: strcopy( strBuffer, iBufferSize, "Scout MK II" );
				case 12: strcopy( strBuffer, iBufferSize, "Giant Scout" );
				case 13: strcopy( strBuffer, iBufferSize, "Super Scout" );
				case 14: strcopy( strBuffer, iBufferSize, "Force-A-Nature Super Scout" );
				case 15: strcopy( strBuffer, iBufferSize, "Giant Jumping Sandman" );
				case 16: strcopy( strBuffer, iBufferSize, "Major League Scout" );
				case 17: strcopy( strBuffer, iBufferSize, "Armored Sandman Scout" );
				case 18: strcopy( strBuffer, iBufferSize, "Giant Bonk Scout" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Sniper: // Sniper Variants - Sniper Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Sniper" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Sniper" );
				case 1: strcopy( strBuffer, iBufferSize, "Razorback Sniper" );
				case 2: strcopy( strBuffer, iBufferSize, "Sydney Sleeper Sniper" );
				case 3: strcopy( strBuffer, iBufferSize, "Bowman" );
				case 4: strcopy( strBuffer, iBufferSize, "Jarate Master" );
				case 5: strcopy( strBuffer, iBufferSize, "Jarate Master (Slow Down)" );
				case 6: strcopy( strBuffer, iBufferSize, "AWP Sniper" );
				case 7: strcopy( strBuffer, iBufferSize, "Armor Piercing Sniper" );
				case 8: strcopy( strBuffer, iBufferSize, "SMG Sniper" );
				case 9: strcopy( strBuffer, iBufferSize, "Assault Sniper" );
				case 10: strcopy( strBuffer, iBufferSize, "Assault AWP Sniper" );
				case 11: strcopy( strBuffer, iBufferSize, "Mini Critter Sniper" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Soldier: // Soldier Variants - Soldier Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Soldier" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Soldier" );
				case 1: strcopy( strBuffer, iBufferSize, "Extended Buff Soldier" );
				case 2: strcopy( strBuffer, iBufferSize, "Extended Backup Soldier" );
				case 3: strcopy( strBuffer, iBufferSize, "Extended Conch Soldier" );
				case 4: strcopy( strBuffer, iBufferSize, "Push Soldier" );
				case 5: strcopy( strBuffer, iBufferSize, "Black Box Soldier" );
				case 6: strcopy( strBuffer, iBufferSize, "Science Soldier" );
				case 7: strcopy( strBuffer, iBufferSize, "Air Force Soldier" );
				case 8: strcopy( strBuffer, iBufferSize, "Mini Rocket Spammer" );
				case 9: strcopy( strBuffer, iBufferSize, "Stun Soldier" );
				case 10: strcopy( strBuffer, iBufferSize, "Direct Hit Soldier" );
				case 11: strcopy( strBuffer, iBufferSize, "Bizon Soldier" );
				case 12: strcopy( strBuffer, iBufferSize, "Market Gardener Soldier" );
				case 13: strcopy( strBuffer, iBufferSize, "Giant Soldier" );
				case 14: strcopy( strBuffer, iBufferSize, "Rocket Spammer" );
				case 15: strcopy( strBuffer, iBufferSize, "Giant Charged Soldier" );
				case 16: strcopy( strBuffer, iBufferSize, "Giant Rapid Fire Soldier" );
				case 17: strcopy( strBuffer, iBufferSize, "Giant Buff Soldier" );
				case 18: strcopy( strBuffer, iBufferSize, "Giant Backup Soldier" );
				case 19: strcopy( strBuffer, iBufferSize, "Giant Conch Soldier" );
				case 20: strcopy( strBuffer, iBufferSize, "Giant Black Box Soldier" );
				case 21: strcopy( strBuffer, iBufferSize, "Giant Burst Fire Soldier" );
				case 22: strcopy( strBuffer, iBufferSize, "Giant Blast Soldier" );
				case 23: strcopy( strBuffer, iBufferSize, "Giant Direct Hit Soldier" );
				case 24: strcopy( strBuffer, iBufferSize, "Giant Science Soldier" );
				case 25: strcopy( strBuffer, iBufferSize, "Giant Shotgun Soldier" );
				case 26: strcopy( strBuffer, iBufferSize, "Giant Australium Soldier" );
				case 27: strcopy( strBuffer, iBufferSize, "Giant Rocket-Barrage Soldier" );
				case 100: strcopy( strBuffer, iBufferSize, "Sergeant Crits" );
				case 101: strcopy( strBuffer, iBufferSize, "Major Crits" );
				case 102: strcopy( strBuffer, iBufferSize, "Celestial Rocket Spammer" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_DemoMan: // Demo Variants - Demo Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Demoman" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Demoman" );
				case 1: strcopy( strBuffer, iBufferSize, "Demoknight" );
				case 2: strcopy( strBuffer, iBufferSize, "Samurai Demo" );
				case 3: strcopy( strBuffer, iBufferSize, "Burst Fire Demo" );
				case 4: strcopy( strBuffer, iBufferSize, "Cannon Demo" );
				case 5: strcopy( strBuffer, iBufferSize, "Explosive Melee Demo" );
				case 6: strcopy( strBuffer, iBufferSize, "Spammer Demoman" );
				case 7: strcopy( strBuffer, iBufferSize, "Precision Demoman" );
				case 8: strcopy( strBuffer, iBufferSize, "Demopan" );
				case 9: strcopy( strBuffer, iBufferSize, "Charger Demoman" );
				case 10: strcopy( strBuffer, iBufferSize, "Minefield Demoman" );
				case 11: strcopy( strBuffer, iBufferSize, "Giant Rapid Fire Demoman (Type 1)" );
				case 12: strcopy( strBuffer, iBufferSize, "Giant Rapid Fire Demoman (Type 2)" );
				case 13: strcopy( strBuffer, iBufferSize, "Giant Demoknight" );
				case 14: strcopy( strBuffer, iBufferSize, "Giant Burst Fire Demo" );
				case 15: strcopy( strBuffer, iBufferSize, "Giant Cannon Demoman" );
				case 100: strcopy( strBuffer, iBufferSize, "Major Bomber" );
				case 101: strcopy( strBuffer, iBufferSize, "Chief Tavish" );
				case 102: strcopy( strBuffer, iBufferSize, "Sir Nukesalot" );
				case SENTRYBUSTER_CLASSVARIANT: strcopy( strBuffer, iBufferSize, "Sentry Buster" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Medic: // Medic Variants - Medic Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Medic" );
				case 0: strcopy( strBuffer, iBufferSize, "Uber Medic" );
				case 1: strcopy( strBuffer, iBufferSize, "Uber Medic" );
				case 2: strcopy( strBuffer, iBufferSize, "Quick Uber Medic" );
				case 3: strcopy( strBuffer, iBufferSize, "Quick-Fix Medic" );
				case 4: strcopy( strBuffer, iBufferSize, "Big Heal Medic" );
				case 5: strcopy( strBuffer, iBufferSize, "Vaccinator Medic" );
				case 6: strcopy( strBuffer, iBufferSize, "Shield Medic" );
				case 7: strcopy( strBuffer, iBufferSize, "Kritzkrieg Medic" );
				case 8: strcopy( strBuffer, iBufferSize, "Crossbow Medic" );
				case 9: strcopy( strBuffer, iBufferSize, "Battle Medic" );
				case 10: strcopy( strBuffer, iBufferSize, "Ubersaw Medic" );
				case 11: strcopy( strBuffer, iBufferSize, "Giant Medic" );
				case 12: strcopy( strBuffer, iBufferSize, "Giant Uber Medic" );
				case 13: strcopy( strBuffer, iBufferSize, "Giant Shield Medic" );
				case 14: strcopy( strBuffer, iBufferSize, "Giant Kritzkrieg Medic" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Heavy: // Heavy Variants - Heavy Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Heavy" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Heavy" );
				case 1: strcopy( strBuffer, iBufferSize, "Steel Gauntlet" );
				case 2: strcopy( strBuffer, iBufferSize, "Fast Puncher" );
				case 3: strcopy( strBuffer, iBufferSize, "Heavyweight Champ" );
				case 4: strcopy( strBuffer, iBufferSize, "Heavy Mittens" );
				case 5: strcopy( strBuffer, iBufferSize, "Steel Gauntlet Pusher" );
				case 6: strcopy( strBuffer, iBufferSize, "Heavy Shotgun" );
				case 7: strcopy( strBuffer, iBufferSize, "Giant Deflector Heavy" );
				case 8: strcopy( strBuffer, iBufferSize, "Giant Heavy" );
				case 9: strcopy( strBuffer, iBufferSize, "Giant Shotgun Heavy" );
				case 10: strcopy( strBuffer, iBufferSize, "Giant Heavy (Brass Beast)" );
				case 11: strcopy( strBuffer, iBufferSize, "Giant Heavy (Natascha)" );
				case 12: strcopy( strBuffer, iBufferSize, "Giant Deflector Heavy (Type 2)" );
				case 13: strcopy( strBuffer, iBufferSize, "Giant Mafia Heavy" );
				case 14: strcopy( strBuffer, iBufferSize, "Giant Armored Heavy" );
				case 100: strcopy( strBuffer, iBufferSize, "Captain Punch" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Pyro: // Pyro Variants - Pyro Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Pyro" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Pyro" );
				case 1: strcopy( strBuffer, iBufferSize, "Flare Gun Pyro" );
				case 2: strcopy( strBuffer, iBufferSize, "Pyro Pusher" );
				case 3: strcopy( strBuffer, iBufferSize, "Fast Scorch Shot" );
				case 4: strcopy( strBuffer, iBufferSize, "Shotgun Pyro" );
				case 5: strcopy( strBuffer, iBufferSize, "Moonraker" );
				case 6: strcopy( strBuffer, iBufferSize, "Moonman" );
				case 7: strcopy( strBuffer, iBufferSize, "Phlog Pyro" );
				case 8: strcopy( strBuffer, iBufferSize, "Dragun's Fury Pyro" );
				case 9: strcopy( strBuffer, iBufferSize, "Gas Pyro" );
				case 10: strcopy( strBuffer, iBufferSize, "Hot Hand Pyro" );
				case 11: strcopy( strBuffer, iBufferSize, "Long Range Pyro" );
				case 12: strcopy( strBuffer, iBufferSize, "Elite Shotgun Pyro" );
				case 13: strcopy( strBuffer, iBufferSize, "Combo Pyro" );
				case 14: strcopy( strBuffer, iBufferSize, "Thermal Thruster Pyro" );
				case 15: strcopy( strBuffer, iBufferSize, "Giant Pyro" );
				case 16: strcopy( strBuffer, iBufferSize, "Giant Flare Pyro" );
				case 17: strcopy( strBuffer, iBufferSize, "Giant Flare Pyro (Scorch Shot)" );
				case 18: strcopy( strBuffer, iBufferSize, "Giant Airblast Pyro" );
				case 19: strcopy( strBuffer, iBufferSize, "Giant Napalm Pyro" );
				case 100: strcopy( strBuffer, iBufferSize, "Chief Pyro" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Spy: // Spy Variants - Spy Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your Spy" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Spy" );
				case 1: strcopy( strBuffer, iBufferSize, "Gentle Spy" );
				case 2: strcopy( strBuffer, iBufferSize, "Assassin Spy" );
				case 3: strcopy( strBuffer, iBufferSize, "Dead Ringer Spy" );
				case 4: strcopy( strBuffer, iBufferSize, "Gunslinger Spy" );
				case 5: strcopy( strBuffer, iBufferSize, "Ninja Spy" );
				case 6: strcopy( strBuffer, iBufferSize, "Silent Spy" );
				case 7: strcopy( strBuffer, iBufferSize, "Saboteur Spy" );
				case 8: strcopy( strBuffer, iBufferSize, "Dr. Ambasicle Spy" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
		case TFClass_Engineer: // Engineer Variants - Engineer Effects
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Engineer" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Engineer" );
				case 1: strcopy( strBuffer, iBufferSize, "Teleported Engineer" );
				case 2: strcopy( strBuffer, iBufferSize, "Battle Engineer" );
				case 3: strcopy( strBuffer, iBufferSize, "Fast Build Engineer" );
				case 4: strcopy( strBuffer, iBufferSize, "Fast Teleporter Engineer" );
				case 5: strcopy( strBuffer, iBufferSize, "PDQ Engineer" );
				case 6: strcopy( strBuffer, iBufferSize, "Circuit City Engineer" );
				default: strcopy( strBuffer, iBufferSize, "Undefined" );
			}
		}
	}
	return strlen(strBuffer) > 0;
}
stock bool:GetClassName( TFClassType:iClass, String:strBuffer[], iBufferSize )
{
	strcopy( strBuffer, iBufferSize, "" );
	switch( iClass )
	{
		case TFClass_Scout:		strcopy( strBuffer, iBufferSize, "scout" );
		case TFClass_Sniper:	strcopy( strBuffer, iBufferSize, "sniper" );
		case TFClass_Soldier:	strcopy( strBuffer, iBufferSize, "soldier" );
		case TFClass_DemoMan:	strcopy( strBuffer, iBufferSize, "demo" );
		case TFClass_Medic:		strcopy( strBuffer, iBufferSize, "medic" );
		case TFClass_Heavy:		strcopy( strBuffer, iBufferSize, "heavy" );
		case TFClass_Pyro:		strcopy( strBuffer, iBufferSize, "pyro" );
		case TFClass_Spy:		strcopy( strBuffer, iBufferSize, "spy" );
		case TFClass_Engineer:	strcopy( strBuffer, iBufferSize, "engineer" );
	}
	return strlen(strBuffer) > 0;
}

stock ShowClassPanel( iClient )
{
	if( !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	ShowVGUIPanel( iClient, GetClientTeam(iClient) == _:TFTeam_Red ? "class_red" : "class_blue" );
}

stock ShowClassMenu( iClient, TFClassType:iClass = TFClass_Unknown )
{
	if( !IsValidClient( iClient ) )
		return;
		
	//if(GameRules_GetRoundState() == RoundState_BetweenRounds)
	//	CreateExtraSpawnAreas(iClient);
	
	new Handle:hMenu, bool:bGiants = false, i;
	decl String:strVariantID[16], String:strVariantName[32];
	if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
		bGiants = true;
	if( iClass <= TFClass_Unknown || iClass >= TFClassType )
		hMenu = CreateMenu( Menu_Classes );
	else
		hMenu = CreateMenu( Menu_ClassVariants );
	SetMenuTitle( hMenu, "Select Variant:" );
	SetMenuExitBackButton( hMenu, false );
	SetMenuExitButton( hMenu, true );
	switch( iClass )
	{
		case TFClass_Scout:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "scout_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 4 : 7 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "scout_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "scout_", "Random variant" );
		}
		case TFClass_Sniper:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "sniper_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 4; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "sniper_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "sniper_", "Random variant" );
		}
		case TFClass_Soldier:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "soldier_-1", "My loadout" );
			if( !bRandomizer )
			{
				for( i = 0; i <= ( !bGiants ? 4 : 7 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "soldier_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			}
			else
				AddMenuItem( hMenu, "soldier_", "Random variant" );
		}
		case TFClass_DemoMan:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "demo_-1", "My loadout" );
			if( !bRandomizer )
			{
				for( i = 0; i <= ( !bGiants ? 1 : 4 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "demo_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
				AddMenuItem( hMenu, "demo_5", "Sentry Buster" );
			}
			else
				AddMenuItem( hMenu, "demo_", "Random variant" );
		}
		case TFClass_Medic:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "medic_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 4 : 5 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "medic_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "medic_", "Random variant" );
		}
		case TFClass_Heavy:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "heavy_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 5 : 11 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "heavy_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "heavy_", "Random variant" );
		}
		case TFClass_Pyro:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "pyro_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 2 : 6 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "pyro_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "pyro_", "Random variant" );
		}
		case TFClass_Spy:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "spy_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 0; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "spy_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "spy_", "Random variant" );
		}
		case TFClass_Engineer:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "engineer_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 0; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "engineer_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "engineer_", "Random variant" );
		}
		default:
		{
			SetMenuTitle( hMenu, "Select Class:" );
			if( bRandomizer )
			{
				AddMenuItem( hMenu, "random_any",		"Random Robot" );
				AddMenuItem( hMenu, "random_attack",	"Attack Robot" );
				AddMenuItem( hMenu, "random_support",	"Support Robot" );
				if( bMyLoadouts )
				{
					AddMenuItem( hMenu, "scout_-1",			"My Own Scout" );
					AddMenuItem( hMenu, "soldier_-1",		"My Own Soldier" );
					AddMenuItem( hMenu, "pyro_-1",			"My Own Pyro" );
					AddMenuItem( hMenu, "demo_-1",			"My Own Demoman" );
					AddMenuItem( hMenu, "heavy_-1",			"My Own Heavy" );
					AddMenuItem( hMenu, "medic_-1",			"My Own Medic" );
					AddMenuItem( hMenu, "sniper_-1",		"My Own Sniper" );
					AddMenuItem( hMenu, "spy_-1",			"My Own Spy" );
					if( CanPlayEngineer(iClient) )
						AddMenuItem( hMenu, "engineer_-1",	"My Own Engineer" );
				}
			}
			else
			{
				AddMenuItem( hMenu, "1", "Scout" );
				AddMenuItem( hMenu, "3", "Soldier" );
				AddMenuItem( hMenu, "7", "Pyro" );
				AddMenuItem( hMenu, "4", "Demo" );
				AddMenuItem( hMenu, "6", "Heavy" );
				AddMenuItem( hMenu, "5", "Medic" );
				AddMenuItem( hMenu, "2", "Sniper" );
				AddMenuItem( hMenu, "8", "Spy" );
				if( CanPlayEngineer(iClient) )
					AddMenuItem( hMenu, "9", "Engineer" );
			}
		}
	}
	DisplayMenu( hMenu, iClient, MENU_TIME_FOREVER );
}

stock SetRobotModel( iClient, const String:strModel[PLATFORM_MAX_PATH] = "" )
{
	if( !IsValidClient( iClient ) || IsFakeClient( iClient ) || !IsPlayerAlive( iClient ) )
		return;
	if(Is666Mode && StrContains(strModel, "bot_sentry_buster.mdl") == -1 )
	{
		SetVariantString( "" );
		AcceptEntityInput( iClient, "SetCustomModel" );// stop and reapply class model
		return;
	}
	if( strlen(strModel) > 2 )
		PrecacheMdl( strModel );
	
	SetVariantString( strModel );
	AcceptEntityInput( iClient, "SetCustomModel" );
	SetEntProp( iClient, Prop_Send, "m_bUseClassAnimations", 1 );
//	SetEntProp( iClient, Prop_Send, "m_nSkin", 1);
}

stock CreateParticle( Float:flOrigin[3], const String:strParticle[], Float:flDuration = -1.0 )
{
	new iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEdict( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchSpawn( iParticle );
		TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

stock TF2_PlayAnimation( iClient, iEvent, nData = 0 )
{
	if( !IsMvM() || !IsValidClient( iClient ) || !IsPlayerAlive( iClient ) || !( GetEntityFlags( iClient ) & FL_ONGROUND ) )
		return;
	
	TE_Start( "PlayerAnimEvent" );
	TE_WriteNum( "m_iPlayerIndex", iClient );
	TE_WriteNum( "m_iEvent", iEvent );
	TE_WriteNum( "m_nData", nData );
	TE_SendToAll();
}


stock IsMvM( bool:bRecalc = false )
{
	static bool:bChecked = false;
	static bool:bMannVsMachines = false;
	
	if( bRecalc || !bChecked )
	{
		new iEnt = FindEntityByClassname( -1, "tf_logic_mann_vs_machine" );
		bMannVsMachines = ( iEnt > MaxClients && IsValidEntity( iEnt ) );
		bChecked = true;
	}
	
	return bMannVsMachines;
}

stock FindIntInArray( iArray[], iSize, iItem )
{
	for( new i = 0; i < iSize; i++ )
		if( iArray[i] == iItem )
			return i;
	return -1;
}
stock FindStrInArray( const String:strArray[][], iSize, const String:strItem[] )
{
	if( strlen(strItem) > 0 )
		for( new i = 0; i < iSize; i++ )
			if( !strcmp( strArray[i], strItem, false ) )
				return i;
	return -1;
}

stock GetTeamPlayerCount( iTeamNum = -1 )
{
	new iCounter = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient( i ) && !IsFakeClient( i ) && ( iTeamNum == -1 || GetClientTeam( i ) == iTeamNum ) )
			iCounter++;
	return iCounter;
}
stock GetNumEngineers( iClient = 0 )
{
	new iCounter = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( iClient != i && IsValidRobot( i ) && !IsFakeClient( i ) && TF2_GetPlayerClass( i ) == TFClass_Engineer )
			iCounter++;
	return iCounter;
}

stock BeamEffect(Float:startvec[3],Float:endvec[3],Float:life,Float:width,Float:endwidth,const color[4],Float:amplitude,speed)
{
	if( !bSentryBusterDebug ) return;
	TE_SetupBeamPoints(startvec,endvec,iLaserModel,0,0,66,life,width,endwidth,0,amplitude,color,speed);
	TE_SendToAll();
} 

stock DealDamage( victim, damage, attacker = 0, dmg_type = 0 )
{
	if( victim > 0 && IsValidEntity(victim) && ( victim > MaxClients || IsClientInGame(victim) && IsPlayerAlive(victim) ) && damage > 0 )
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		if( pointHurt )
		{
			DispatchKeyValue(victim, "targetname", "point_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "point_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "point_donthurtme");
			AcceptEntityInput(pointHurt, "Kill");
		}
	}
}

stock bool:IsValidRobot( iClient, bool:bIgnoreBots = true )
{
	if( !IsValidClient(iClient) ) return false;
	if( GetClientTeam(iClient) != _:TFTeam_Blue ) return false;
	if( bIgnoreBots && IsFakeClient(iClient) ) return false;
	return true;
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );
	
	if( iFlags )
	{
		if( iFlags & ERROR_LOG && bUseLogs )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			decl String:strTag[64];
			strcopy( strTag, sizeof(strTag), PLUGIN_TAG );
			strcopy( strTag, strlen(strTag)-2, strTag[1] );
			Format( strFile, sizeof(strFile), "TF2BWR%s", strFile );
			BuildPath( Path_SM, strFile, sizeof(strFile), "logs/%s.log", strFile );
			LogToFileEx( strFile, strBuffer );
		}
		
		if( iFlags & ERROR_BREAKF )
			ThrowError( strBuffer );
		if( iFlags & ERROR_BREAKN )
			ThrowNativeError( iNativeErrCode, strBuffer );
		if( iFlags & ERROR_BREAKP )
			SetFailState( strBuffer );
		
		if( iFlags & ERROR_NOPRINT )
			return;
	}
	
	PrintToServer( "%s %s", PLUGIN_TAG, strBuffer );
}
// bomb deploying handle
public Action:Timer_DeployTimer(Handle:timer, any:Deployer)
{
		if(!( GetEntityFlags(Deployer) & FL_ONGROUND ) || !IsValidRobot(Deployer) || !IsPlayerAlive(Deployer)) //bugfix for deploy when touching deploy area while in air would make deploy execute
		{
			if (g_hDeployTimer != INVALID_HANDLE)
			{
				CloseHandle(g_hDeployTimer);
				g_hDeployTimer = INVALID_HANDLE;
				return Plugin_Stop;
			}	
		}
		
		RemoveWearables(Deployer, false);
		
		BombHasBeenDeployed = true;
		SetEntProp(Deployer, Prop_Data, "m_takedamage", 0, 1);	
		
//		TF2_AddCondition(Deployer, TFCond_MegaHeal, 1.4);
//		TF2_AddCondition(Deployer, TFCond_UberchargedHidden, 1.0);
		
		//BombStage[Deployer] = 0;
		CanTeleportBomb = false;
		BombPickup = false;
		Carrier = -1;
		SetEntityRenderMode(Deployer, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Deployer, 255, 255, 255, 0);
		TF2_StunPlayer(Deployer, 15.0, 0.0, TF_STUNFLAGS_LOSERSTATE, _);
		iRobotMode[Deployer] = Robot_None;
		SetRobotModel( Deployer, "models/empty.mdl" );//Disable robot eyes "models/props_td/atom_bomb.mdl"
		FixSounds(Deployer);
//		CreateTimer(0.03, Timer_CaptureIntel);
		//CaptureIntel(); // Crashes?
		TriggerHatchExplosion();
		PrintToChatAll("\x04%N \x01 Deployed the bomb",Deployer);
		LogAction(Deployer, -1, "[BWR2] %L Deployed the bomb", Deployer);
		if (g_hbombs1[Deployer] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs1[Deployer]);
			g_hbombs1[Deployer] = INVALID_HANDLE;
		}
		if (g_hbombs2[Deployer] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs2[Deployer]);
			g_hbombs2[Deployer] = INVALID_HANDLE;
		}
		if (g_hbombs3[Deployer] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs3[Deployer]);
			g_hbombs3[Deployer] = INVALID_HANDLE;
		}
		g_hDeployTimer = INVALID_HANDLE;
		CloseHandle(g_hDeployTimer);
		CreateTimer(0.00001, Timer_RemoveWeapons, Deployer);
		CreateTimer(1.2, Timer_RemoveWeapons, Deployer);
		return Plugin_Handled;
}
stock RemoveWearables(client, bool:HideWerable)
{
	new iOwner, iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			if(!HideWerable)
				AcceptEntityInput( iEntity, "Kill" );
			if(HideWerable)
			{
				SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEntity, 255, 255, 255, 0);
			}
		}
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			if(!HideWerable)
				AcceptEntityInput( iEntity, "Kill" );
			if(HideWerable)
			{
				SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEntity, 255, 255, 255, 0);
			}
		}
	}
}
stock ShowWearables(client)
{
	new iOwner, iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iEntity, 255, 255, 255, 255);
		}
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iEntity, 255, 255, 255, 255);
		}
	}
}
public Action:Timer_RemoveWeapons(Handle:timer, any:Deployer)
{
	for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
	{
		TF2_RemoveWeaponSlot( Deployer, iSlot );
	}
	SetEntProp(Deployer, Prop_Data, "m_iHealth", 110);
}
stock AttachParticleHead(entity, String:particleType[], Float:Time) //Float:offset[]={0.0,0.0,0.0}
{
	new particle=CreateEntityByName("info_particle_system");

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	//position[0]+=offset[0];
	//position[1]+=offset[1];
	//position[2]+=offset[2];
	//TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", entity, particle, 0);
	SetVariantString("head");
	AcceptEntityInput(particle, "SetParentAttachment", particle , particle, 0);
	DispatchSpawn(particle);
	
	SetVariantString(targetName);

	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(Time, DeleteParticle, particle);
	return particle;
}

public Action:Timer_TLKDEPLOYED(Handle:timer, any:i)
{
	if(!IsFakeClient(i) && iDeployingBomb == i )
	{
			SetVariantString("IsBlueTeam:1");
			AcceptEntityInput(i, "AddContext");
			
			SetVariantString("randomnum:100");
			AcceptEntityInput(i, "AddContext");
			
			SetVariantString("TLK_FLAGCAPTURED");
			AcceptEntityInput(i, "SpeakResponseConcept");
			
			AcceptEntityInput(i, "ClearContext");
	}
	return Plugin_Continue;
}
public EventHook_FlagStuff(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "eventtype") == TF_FLAGEVENT_PICKEDUP )
	{
		CanTeleportBomb = false;
		new client = GetEventInt(event, "player");
		BombPickup = true;
		Carrier = client;
		GetClientUserId( client );
		BombStage[client] = 0;
		
		if(!IsFakeClient(client))
			TF2Attrib_SetByName(client, "increased jump height", 0.1);
		if( IsValidRobot(client) && iRobotMode[client] != Robot_Giant && GameRules_GetRoundState() == RoundState_RoundRunning && !bInRespawn[client])  //( GetEntProp( client, Prop_Data, "m_bIsMiniBoss" ) == _:false  )
		{
//			PrintToChatAll("Timer trial has been trigerred.");	// a flag was picked up
			CreateTimer(0.1, Timer_bombhud); //g_hBombHud = 
			g_hbombs1[client] = CreateTimer(5.2, Timer_bombst1, client);
			g_hbombs2[client] = CreateTimer(20.0, Timer_bombst2, client);
			g_hbombs3[client] = CreateTimer(35.0, Timer_bombst3, client);
		}
		else if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
		{
			CreateTimer(0.01, Timer_bosshud, client); //	g_hBombBossHud =
		}
		TF2_RemoveCondition(client, TFCond_UberchargedHidden);
	}
	return;
}
	public Action:Timer_bombst1(Handle:timer, any:client)
	{
		//if(GameRules_GetRoundState() != RoundState_RoundRunning)
		//	return Plugin_Stop;
		if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == false && iRobotMode[client] == Robot_Giant && GameRules_GetRoundState() != RoundState_RoundRunning && bInRespawn[client]  )
			return Plugin_Stop;
		// Do whatever this timer is supposed to do
		//if(!( GetEntityFlags(client) & FL_ONGROUND ) )
		//	TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 3.0);
		BombStage[client] = 1;
		TLK_MVM_BOMB_CARRIER_UPGRADE(client, 1);
		new Float:CurrentTime = GetGameTime();
		new Float:NextTime = CurrentTime+15.0;
		new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntProp(BombOwner, Prop_Send, "m_nFlagCarrierUpgradeLevel", 1);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
		TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, TFCondDuration_Infinite);
		CreateTimer(0.25, Timer_DefenseBuff, client, TIMER_REPEAT);
		PrecacheSound( BOMB_SND_STAGEALERT );
		EmitSoundToAll(BOMB_SND_STAGEALERT, SOUND_FROM_WORLD, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_NOFLAGS, 0.500, SNDPITCH_NORMAL);
		//EmitSoundToAll( BOMB_SND_STAGEALERT, client, SNDCHAN_STATIC, 125 );
		AttachParticleHead(client, "mvm_levelup1", 10.0);
		FakeClientCommand( client, "taunt" );
		g_hbombs1[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	public Action:Timer_bombst2(Handle:timer, any:client)
	{
		// Do whatever this timer is supposed to do
		if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == false && iRobotMode[client] == Robot_Giant && GameRules_GetRoundState() != RoundState_RoundRunning && bInRespawn[client] )
			return Plugin_Stop;
		//if(!( GetEntityFlags(client) & FL_ONGROUND ) )
		//	TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 3.0);
		BombStage[client] = 2;
		TLK_MVM_BOMB_CARRIER_UPGRADE(client, 2);
		new Float:CurrentTime = GetGameTime();
		new Float:NextTime = CurrentTime+15.0;
		new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntProp(BombOwner, Prop_Send, "m_nFlagCarrierUpgradeLevel", 2);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
		TF2Attrib_SetByName(client, "health regen", 45.0);
//		TF2_AddCondition(client, TFCond_HalloweenQuickHeal, TFCondDuration_Infinite);
		//EmitSoundToAll( BOMB_SND_STAGEALERT, client, SNDCHAN_STATIC, 125 );
		EmitSoundToAll(BOMB_SND_STAGEALERT, SOUND_FROM_WORLD, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_NOFLAGS, 0.500, SNDPITCH_NORMAL);
		AttachParticleHead(client, "mvm_levelup2", 10.0);
		FakeClientCommand( client, "taunt" );
		g_hbombs2[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	public Action:Timer_bombst3(Handle:timer, any:client)
	{
		// Do whatever this timer is supposed to do
		if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == false && iRobotMode[client] == Robot_Giant && GameRules_GetRoundState() != RoundState_RoundRunning && bInRespawn[client]  )
			return Plugin_Stop;
		//if(!( GetEntityFlags(client) & FL_ONGROUND ) )
		//	TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 3.0);
		BombStage[client] = 3;
		TLK_MVM_BOMB_CARRIER_UPGRADE(client, 3);
		new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
		SetEntProp(BombOwner, Prop_Send, "m_nFlagCarrierUpgradeLevel", 3);
		TF2_AddCondition(client, TFCond_CritOnKill, TFCondDuration_Infinite);
		//EmitSoundToAll( BOMB_SND_STAGEALERT, client, SNDCHAN_STATIC, 125 );
		EmitSoundToAll(BOMB_SND_STAGEALERT, SOUND_FROM_WORLD, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_NOFLAGS, 0.500, SNDPITCH_NORMAL);
		AttachParticleHead(client, "mvm_levelup3", 10.0);
		FakeClientCommand( client, "taunt" );
		g_hbombs3[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
public Action:Timer_bombhud(Handle:timer, any:client)
{
	new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
	new Float:CurrentTime = GetGameTime();
	new Float:NextTime = CurrentTime+5.1;
	SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
	SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
//	g_hBombHud = INVALID_HANDLE;
}

public EventHook_FlagStuff2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "eventtype") == TF_FLAGEVENT_DROPPED )
	{
		ShowHiddenBombs();
		new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
		SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
		BombPickup = false;
		Carrier = -1;
		new client = GetEventInt(event, "player");
		if(!IsFakeClient(client))
		GetClientUserId( client );
		BombStage[client] = 0;
		if(iDeployingBomb == client)
		{
			KillDeployAnimation3();//gotta put you here since you were bugged
			iDeployingBomb = -1;
			if (g_hDeployTimer != INVALID_HANDLE)
			{
				CloseHandle(g_hDeployTimer);
				g_hDeployTimer = INVALID_HANDLE;
			}
		}
		
//	PrintToChatAll("Timer trial has been killed.");
		if(iRobotMode[client] != Robot_None && !IsFakeClient(client))
		{
			TF2Attrib_RemoveByName(client, "health regen");
		}
		if(!IsFakeClient(client))
			TF2Attrib_RemoveByName(client, "increased jump height");
		TF2_RemoveCondition(client, TFCond_CritOnKill);
		TF2_RemoveCondition(client, TFCond_DefenseBuffNoCritBlock);
		SetEntProp(BombOwner, Prop_Send, "m_nFlagCarrierUpgradeLevel", 0);
		
		if (g_hbombs1[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs1[client]);
			g_hbombs1[client] = INVALID_HANDLE;
		}
		if (g_hbombs2[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs2[client]);
			g_hbombs2[client] = INVALID_HANDLE;
		}
		if (g_hbombs3[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hbombs3[client]);
			g_hbombs3[client] = INVALID_HANDLE;
		}
	}
	return;
}
/*public EventHook_tele(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "index") == 3 )
	{
		CreateTimer(0.1, CheckTeleporter);
	}
}*/
public Removegatebot()
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "filter_multi")) != -1)
	{
	if(IsValidEntity(i) && !IsFakeClient(i))
	{
		decl String:strName[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "filter_blue_bombhat") == 0)
		{
			AcceptEntityInput(i, "Kill");
			//PrintToChatAll("killed filter");
			break;
		}
	}
	}
	new Filter = CreateEntityByName("filter_multi");
	DispatchKeyValue(Filter, "filtertype", "1");
	DispatchKeyValue(Filter, "Filter01", "filter_blueteam");
	DispatchKeyValue(Filter, "Filter02", "filter_gatebot");
	DispatchKeyValue(Filter, "targetname", "filter_blue_bombhat");
	DispatchSpawn(Filter);
	
	new Filter2 = CreateEntityByName("filter_activator_tfteam");
	//DispatchKeyValue(Filter2, "filtertype", "1");
	DispatchKeyValue(Filter2, "Negated", "Allow entities that match criteria");
	DispatchKeyValue(Filter2, "TeamNum", "0");

	DispatchKeyValue(Filter2, "targetname", "filter_moveto23");
	DispatchSpawn(Filter2);
	
	CreateTimer(1.0, Timer_ClearFilter, Filter);
	//PrintToChatAll("created filter");
}

public Action:Timer_ClearFilter(Handle:timer, any:FilterR)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "trigger_multiple")) != -1)
	{
	if(IsValidEntity(i))
	{
		decl String:strName[50];
		//decl String:strName2[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "gate1_door_alarm") == 0 || strcmp(strName, "gate2_door_alarm") == 0)
		{
			SetEntPropEnt(i, Prop_Data, "m_hFilter", -1);

			//new FIL = GetEntPropEnt(i, Prop_Data, "m_hFilter");
			//GetEntPropString(i, Prop_Data, "m_iFilterName", strName2, sizeof(strName2));
			//PrintToChatAll("FILTER DATA %i for %s filtername %s",FIL, strName, strName2);
			if(strcmp(strName, "gate1_door_alarm") == 0 || strcmp(strName, "gate2_door_alarm") == 0)
			{
				SDKHook( i, SDKHook_Touch, OnTriggerAlarmTouch );
				SDKHook( i, SDKHook_StartTouch, OnTriggerAlarmTouch );
			}
		}
	}
	}
}

public Action:Timer_bosshud(Handle:timer, any:client)
{
	new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
	SetEntProp(BombOwner, Prop_Send, "m_nFlagCarrierUpgradeLevel", 4);
//	g_hBombBossHud = INVALID_HANDLE;
}
stock StripCharacterAttributes( iEntity )
{
	TF2Attrib_RemoveByName(iEntity, "dmg taken from blast reduced");
	TF2Attrib_RemoveByName(iEntity, "dmg taken from bullets reduced");
	TF2Attrib_RemoveByName(iEntity, "move speed bonus");
	TF2Attrib_RemoveByName(iEntity, "health regen");
	TF2Attrib_RemoveByName(iEntity, "increased jump height");
	TF2Attrib_RemoveByName(iEntity, "dmg taken from fire reduced");
	TF2Attrib_RemoveByName(iEntity, "dmg taken from crit reduced");
	TF2Attrib_RemoveByName(iEntity, "metal regen");
	TF2Attrib_RemoveByName(iEntity, "engy building health bonus");
	TF2Attrib_RemoveByName(iEntity, "engy disposable sentries");
	TF2Attrib_RemoveByName(iEntity, "engy dispenser radius increased");
	TF2Attrib_RemoveByName(iEntity, "engy sentry radius increased");

// TF2Attrib_RemoveAll(iEntity);
}
/*StripWeapon( iClient )
{
	PrintToChatAll("Event runned");
	new iWeapon = GetPlayerWeaponSlot( iClient, 0 );
	if(iWeapon != -1)
		TF2Attrib_RemoveAll(iWeapon);

	new iWeapon2 = GetPlayerWeaponSlot( iClient, 1 );
	if(iWeapon2 != -1)
		TF2Attrib_RemoveAll(iWeapon2);

	new iWeapon3 = GetPlayerWeaponSlot( iClient, 2 );
	if(iWeapon3 != -1)
		TF2Attrib_RemoveAll(iWeapon3);

	new iWeapon4 = GetPlayerWeaponSlot( iClient, 3 ); //BROKEN
	if(iWeapon4 != -1)
		TF2Attrib_RemoveAll(iWeapon4);

}*/

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[], bool:bWearable = false)
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			if( hSDKEquipWearable != INVALID_HANDLE )
				SDKCall( hSDKEquipWearable, client, entity );
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

stock SpawnWeaponNoForce(client,String:name[],index,level,qual,String:att[], bool:bWearable = false)
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			if( hSDKEquipWearable != INVALID_HANDLE )
				SDKCall( hSDKEquipWearable, client, entity );
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

GetRandomPlayer(team)
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && GetClientTeam(i) == team && IsValidRobot(i))
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
			if(class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Engineer && class != TFClass_Medic && iRobotMode[i] != Robot_SentryBuster && IsPlayerAlive(i) && !IsGateBotPlayer[i])
			{
				clients[clientCount++] = i;
			}
		}
	}
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
/*stock SpawnTeleporter(builder, Float:Position[3], level)
{
	new teleporter = CreateEntityByName("obj_teleporter");
	
	if(IsValidEntity(teleporter))
	{
		DispatchKeyValueVector(teleporter, "origin", Position);
//		DispatchKeyValueVector(teleporter, "angles", Angle);
		
		SetEntProp(teleporter, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(teleporter, Prop_Data, "m_spawnflags", 4);
		SetEntProp(teleporter, Prop_Send, "m_bBuilding", 1);
		//SetEntProp(teleporter, Prop_Data, "m_iTeleportType", mode);
		//SetEntProp(teleporter, Prop_Send, "m_iObjectMode", mode);
		SetEntProp(teleporter, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
		DispatchSpawn(teleporter);
		
		AcceptEntityInput(teleporter, "SetBuilder", builder);
		
		SetVariantInt(GetClientTeam(builder));
		AcceptEntityInput(teleporter, "SetTeam");
		
		AttachParticleTeleporter(teleporter,"teleporter_mvm_bot_persist");
		HookSingleEntityOutput(teleporter, "OnDestroyed", OnDestroyedTeleporter, true);
	}
}*/
public Action:OnPlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	//SetEventInt(event, "customkill", 2);
	//new customkill2 = GetEventInt(event, "customkill");
	//PrintToChatAll("%i", customkill2);
	//new iAttacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
//if(iRobotMode[iAttacker] == Robot_SentryBuster)
//{
//	SetEventString(event, "weapon", "ullapool_caber");
//	PrintToChatAll("Event icon try"); ullapool_caber
//}
	
	new deathflags = GetEventInt(event, "death_flags");
	if (deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( GameRules_GetRoundState() == RoundState_BetweenRounds && GetClientTeam(client) == _:TFTeam_Blue )
	{
		SetEventBool(event, "silent_kill", true);
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", _:false );
	}
		
	if( GameRules_GetRoundState() == RoundState_RoundRunning && bEnableBuster && !g_CanDispatchSentryBuster ) // && iRobotMode[iClient] != Robot_SentryBuster && bEnableBuster)  // && GetRandomInt(0,9) == 0 && CheckCommandAccess( iClient, "tf2bwr_sentrybuster", 0, true ) )
	{
		//PrintToChatAll("Looped a sentry.");
		if( IsThereAnyRedSentry() ) // && IsThereAnyRedEngineer() && SentryBusterQueNotClosed==true)
		{
			//PrintToChatAll("enabled bool.");
		g_CanDispatchSentryBuster = true;
		}
		//else
		//	g_CanDispatchSentryBuster = false;
	}
	//moved setbuster code somewhere else
	/*if( GetClientTeam(client) == _:TFTeam_Blue)
	{
		new TeleporterExit = -1;
		while((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1)
		{
		if(GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
		{
			new Float:position[3];
			GetEntPropVector(TeleporterExit, Prop_Send, "m_vecOrigin", position);
			new OwnerOldTeleporter = GetEntPropEnt(TeleporterExit,Prop_Send,"m_hBuilder");
			if(OwnerOldTeleporter == client)
			{
				SpawnTeleporter(client, position, 3);
			}
		}
		}
		
	}*/
	if( GetClientTeam(client) == _:TFTeam_Red)
		return Plugin_Stop;
	if( iRobotMode[client] == Robot_SentryBuster )
	{
		flLastSentryBuster = GetGameTime()+180.0;// 180s cooldown between busters
		return Plugin_Stop;
	}
		//return Plugin_Stop;
		
	// if( GetClientTeam(client) == _:TFTeam_Blue && !IsFakeClient( client ) && !bInRespawn[client] && GameRules_GetRoundState() == RoundState_RoundRunning && iAttacker > 0 && iAttacker != client )
	// {
		// new MoneypackL = CreateEntityByName( "item_currencypack_large" );
		// new Float:Vec2[3];
		// Vec2[0] += 12;
		// Vec2[1] += 12;
		// Vec2[2] += 12;
		// SetEntProp(MoneypackL, Prop_Data, "m_takedamage", 2 , 1);
		// DispatchKeyValue(MoneypackL, "OnPlayerTouch", "!self,Kill,,0,-1");
		// SetEntPropVector(MoneypackL, Prop_Data, "m_vecVelocity", Vec2);
		// DispatchSpawn(MoneypackL);
		// new Float:position[3];
		// GetClientAbsOrigin(client, position);
		// GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		
		// TeleportEntity(MoneypackL, position, NULL_VECTOR, NULL_VECTOR);
		// CreateTimer( 0.1, Timer_CashTele, MoneypackL );
	// }
	return Plugin_Continue;
}

/*GroundEntity(entity)
{
    new Float:flPos[3], Float:flAng[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flPos);
    flAng[0] = 90.0;//this angles is straight down 90.0
    flAng[1] = 0.0;
    flAng[2] = 0.0;
    new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, entity);
    if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
    {
        new Float:endPos[3];
        TR_GetEndPosition(endPos, hTrace);
        CloseHandle(hTrace);
        endPos[2] += 5;
        TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
    }
}*/

public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
    if(entity >= 1 && entity <= MaxClients)
    {
        return false;
    }
    if(entity != 0)
        return false;
  
    return true;
}

public Action:Timer_CashKill(Handle:timer, any:MoneypackL)
{
	AcceptEntityInput(MoneypackL, "Kill");
}
// public Action:Timer_CashTele(Handle:timer, any:MoneypackL)
// {
	// //PrintToChatAll("triger cash!");
	// for( new i = 1; i <= MaxClients; i++ )
		// if (IsClientInGame(i) && IsPlayerAlive(i))
		// {
			// if(GetClientTeam(i) == _:TFTeam_Red && !IsFakeClient(i))
			// {
				// new Float:Position[3];
				// GetClientAbsOrigin(i, Position);
				// Position[2] += 15;
				// TeleportEntity(MoneypackL, Position, NULL_VECTOR, NULL_VECTOR);
				// //PrintToChatAll("Teleported cash!");
				// return;
			// }
		// }

// }
SetSentryTarget(client, bool:bTarget)
{
	new iFlags = GetEntityFlags(client);	
	if(bTarget)
	{
		SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	}else{
		SetEntityFlags(client, iFlags | FL_NOTARGET);
	}
}
stock bool:IsUpradeableCarrier(client)
{
	if(IsFakeClient(client))
		return false;
	if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
		return false;
	new iFlag = GetEntPropEnt( client, Prop_Send, "m_hItem" );
	if( !IsValidEdict( iFlag ) )
		return false;
	
	return true;
}
public TF2_OnConditionAdded(client, TFCond:condition) 
{
	
	//new TFClassType:class = TF2_GetPlayerClass(client);
	//if(condition==TFCond_Taunting && GetClientTeam(client) == _:TFTeam_Blue && class == TFClass_Engineer && bInRespawn[client] && GameRules_GetRoundState() == RoundState_BetweenRounds)//congafix
	//{
	//	TF2_RemoveCondition(client, TFCond_Taunting);
	//}
	/*if(condition==TFCond_MVMBotRadiowave && GetClientTeam(client) == _:TFTeam_Blue && iRobotMode[client] != Robot_SentryBuster && iRobotMode[client] != Robot_Giant)
	{
		TF2_StunPlayer(client, 22.1, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, _);
	}*/
	if(condition==TFCond_UberchargedHidden && GetClientTeam(client) == _:TFTeam_Blue)
	{
		GetClientUserId( client );
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier hidden", 0.01);
		SetSentryTarget(client, false);
	}
	if(condition==TFCond_UberchargedHidden && GetClientTeam(client) == _:TFTeam_Blue && !IsFakeClient(client))//IsUpradeableCarrier(client)
	{	
		//if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == true)
		if(IsUpradeableCarrier(client))
		{
			if (g_hbombs1[client] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs1[client]);
				g_hbombs1[client] = INVALID_HANDLE;
			}
			if (g_hbombs2[client] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs2[client]);
				g_hbombs2[client] = INVALID_HANDLE;
			}
			if (g_hbombs3[client] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs3[client]);
				g_hbombs3[client] = INVALID_HANDLE;
			}
			if(!IsMannhattan) //mannhattan fix 
			{
				new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
				SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
				SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
			}
		}
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(condition==TFCond_UberchargedHidden && GetClientTeam(client) == _:TFTeam_Blue)
	{
		GetClientUserId( client );
		TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier hidden");
		SetSentryTarget(client, true);
		
		if(g_hbombs1[client] == INVALID_HANDLE && g_hbombs2[client] == INVALID_HANDLE && g_hbombs3[client] == INVALID_HANDLE)
		{
			if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == true && IsUpradeableCarrier(client) && IsPlayerAlive(client))
			{
				new BombOwner = FindEntityByClassname(-1, "tf_objective_resource");
				new Float:CurrentTime = GetGameTime();
				if(BombStage[client] == 0)
				{
					new Float:NextTime = CurrentTime+5.2;
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
					g_hbombs1[client] = CreateTimer(5.0, Timer_bombst1, client);
					g_hbombs2[client] = CreateTimer(20.0, Timer_bombst2, client);
					g_hbombs3[client] = CreateTimer(35.0, Timer_bombst3, client);
				}
				if(BombStage[client] == 1)
				{
					new Float:NextTime = CurrentTime+15.0;
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
					g_hbombs2[client] = CreateTimer(15.0, Timer_bombst2, client);
					g_hbombs3[client] = CreateTimer(30.0, Timer_bombst3, client);
				}
				if(BombStage[client] == 2)
				{
					new Float:NextTime = CurrentTime+14.5;
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMBaseBombUpgradeTime", CurrentTime);
					SetEntPropFloat(BombOwner, Prop_Send, "m_flMvMNextBombUpgradeTime", NextTime);
					g_hbombs3[client] = CreateTimer(15.0, Timer_bombst3, client);
				}
			}
		}
	}
}

//public Action:OnSentryTakeDamage( iBuilding, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
//{
//if(!IsMvM() || !IsValidEdict(iBuilding) )
//	return Plugin_Continue;
//if(iRobotMode[iAttacker] == Robot_SentryBuster && !TF2_IsPlayerInCondition( iAttacker, TFCond_Taunting ))
//{
//	flDamage = 0.0;
//	return Plugin_Changed;
//}
//return Plugin_Continue;
//}

stock TriggerHatchExplosion()
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "logic_relay")) != -1)
	{
		if(IsValidEntity(i))
		{
			decl String:strName[50];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "boss_deploy_relay") == 0)
			{
				AcceptEntityInput(i, "Trigger");
				break;
			}
			else if(strcmp(strName, "bwr_round_win_relay") == 0)
			{
				AcceptEntityInput(i, "Trigger");
				break;
			}
		} 
	}
}
//
//public Action:Timer_CaptureIntel(Handle:hTimer)
stock CaptureIntel()
{
	//GameRules_SetProp( "m_bPlayingMannVsMachine", 0 );
	//CreateTimer( 0.05, Timer_SetMannVsMachines );
}
CopyEventDataInt(Handle:hEvent, Handle:hNew, const String:sKey[]) {
	SetEventInt(hNew, sKey, GetEventInt(hEvent, sKey));
}
public Action:Event_DefaultWinPanel(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Handle:hNew = CreateEvent("pve_win_panel", true);
	CopyEventDataInt(hEvent, hNew, "panel_style");
	CopyEventDataInt(hEvent, hNew, "winning_team");
	CopyEventDataInt(hEvent, hNew, "winreason");
	//CopyEventDataInt(hEvent, hNew, "round_complete");
	CopyEventDataInt(hEvent, hNew, "flagcaplimit");
	FireEvent(hNew);

	return Plugin_Handled;
}
// make sentry level 3
public Action:Timer_SetInstantLevel3( Handle:hTimer, any:iEntity )
{
	new String:sEnt[255];
	Entity_GetClassName(iEntity,sEnt,sizeof(sEnt));
	if (!IsValidEntity(iEntity) || !StrEqual(sEnt, "obj_sentrygun"))
		return Plugin_Stop;
	if( GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
	{
		if( GetEntProp( iEntity, Prop_Send, "m_bMiniBuilding" ) == 1 || GetEntProp( iEntity, Prop_Send, "m_bDisposableBuilding" ) == 1 )
		{
			DispatchKeyValue(iEntity, "defaultupgrade", "0");
		}
		else
		{
			DispatchKeyValue(iEntity, "defaultupgrade", "2");
		}
	}
	return Plugin_Continue;
}

public Action:Timer_DefenseBuff( Handle:hTimer, any:client)
{
	//if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == false || BombHasBeenDeployed)
	if(BombStage[client] < 1 || BombHasBeenDeployed)
		return Plugin_Stop;
		
	new Float:flPos1[3];
	GetClientAbsOrigin(client, flPos1);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue && client != i) //revisited to make code less resource hungry
		{
			new Float:flPos2[3];
			GetClientAbsOrigin(i, flPos2);
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			//if(!TF2_IsPlayerInCondition( i, TFCond_DefenseBuffNoCritBlock ))
			//{
			if(flDistance < 395.0) // && GetClientTeam(i) == _:TFTeam_Blue)
				TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 2.0, client);
			//}
		}
	}
	return Plugin_Continue;
}
public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index = GetEventInt(event, "index");
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Red )
		GlowBuilding(index);
	if(!IsFakeClient(iClient))
		CreateTimer( 0.1, Timer_BuildingCall, index );
}

public Action:Timer_BuildingCall( Handle:hTimer, any:index )
{
	decl String:classname[32];
	GetEdictClassname(index, classname, sizeof(classname));
	if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		CreateTimer( 0.05, Timer_Push, index );
	if( strcmp("obj_teleporter", classname ) == 0 )
	{
		if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
			//new OwnerTeleporter = GetEntPropEnt(index,Prop_Send,"m_hBuilder");
			//if(!bEngiCanBuildSecondTele[OwnerTeleporter])
			DestoryOldTeleport(index);
				
//			SetEntProp( index , Prop_Data, "m_iszMatchingMapPlacedTeleporter", -1); broken don't use
			SetEntProp(index, Prop_Data, "m_iMaxHealth", 300);
			SetVariantInt(300);
			AcceptEntityInput(index, "SetHealth");
			CreateTimer( 0.2, Timer_SetNoUpgrade, index );
			CreateTimer(0.1, OnTeleporterFinished, index, TIMER_REPEAT);
			//PrintToChatAll("teleport hooked");
			CheckTeleportClamping(index);
			/*
			Giant scale 1.75 + teleporter + teleport offset = 220 u
			Player or teleporter horizontal size 60 u
			*/
		}
	}
	if( strcmp("obj_dispenser", classname ) == 0 )
	{
		if( GetEntProp( index, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
			SetEntProp(index, Prop_Send, "m_bMiniBuilding", 1);
			SetEntPropFloat(index, Prop_Send, "m_flModelScale", 0.75);
			SetVariantInt(100);
			AcceptEntityInput(index, "SetHealth");
		}
	}
	
}
public Action:Timer_Push( Handle:hTimer, any:index )
{
	if(IsValidEntity(index))
		BuildingPushBlue(index);
}

stock CheckTeleportClamping(Teleporter) // Teleporter Hull Check
{
	// roof checks [5]
	// roof trace straight
	new Float:flPos[3], Float:flAng[3];
	GetEntPropVector(Teleporter, Prop_Send, "m_vecOrigin", flPos);
	flPos[2] += 5.0;
	
	flAng[0] = 270.0;//up
	flAng[1] = 0.0;
	flAng[2] = 0.0;
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace);
		CloseHandle(hTrace);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true)
		{
			if(flDistance < 130)
			{
				//PrintCenterText(TeleOwner,"clamping roof");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 0; return;
			}
		}
		else
		{
			if(flDistance < 175)
			{
				//PrintCenterText(TeleOwner,"clamping roof");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 0; return;
			}
		}
	}
	//angled roof 1 -110
	flAng[0] = 290.0;//up y
	flAng[1] = 0.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace2 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace2 != INVALID_HANDLE && TR_DidHit(hTrace2))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace2);
		CloseHandle(hTrace2);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true)
		{
			if(flDistance < 90)
			{
				//PrintCenterText(TeleOwner,"clamping roof 1");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 1; return;
			}
		}
		else
		{
			if(flDistance < 120)
			{
				//PrintCenterText(TeleOwner,"clamping roof 1");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 1; return;
			}
		}
	}
	//angled roof 2 -70
	flAng[0] = 250.0;//up y
	flAng[1] = 0.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace3 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace3 != INVALID_HANDLE && TR_DidHit(hTrace3))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace3);
		CloseHandle(hTrace3);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 110)
			{
				//PrintCenterText(TeleOwner,"clamping roof 2");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 2; return;
			}
		}
		else
		{
			if(flDistance < 150)
			{
				//PrintCenterText(TeleOwner,"clamping roof 2");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 2; return;
			}
		}
	}
	//angled roof 3 -70
	flAng[0] = 250.0;//up y
	flAng[1] = 90.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace4 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace4 != INVALID_HANDLE && TR_DidHit(hTrace4))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace4);
		CloseHandle(hTrace4);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 110)
			{
				//PrintCenterText(TeleOwner,"clamping roof 3");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 3; return;
			}
		}
		else
		{
			if(flDistance < 150)
			{
				//PrintCenterText(TeleOwner,"clamping roof 3");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 3; return;
			}
		}
	}
	//angled roof 4 -110
	flAng[0] = 280.0;//up y
	flAng[1] = 90.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace5 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace5 != INVALID_HANDLE && TR_DidHit(hTrace5))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace5);
		CloseHandle(hTrace5);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 110)
			{
				//PrintCenterText(TeleOwner,"clamping roof 4");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 4; return;
			}

		}
		else
		{
			if(flDistance < 150)
			{
				//PrintCenterText(TeleOwner,"clamping roof 4");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 4; return;
			}

		}
	}
	//floor checks [4]
//	flAng[0] = 350.0;// y
//	flAng[1] = 45.0; // z 
//	flAng[2] = 0.0; // x
//	new Handle:hTrace6 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
//	if(hTrace6 != INVALID_HANDLE && TR_DidHit(hTrace6))
//	{
//		new Float:endPos[3];
//		TR_GetEndPosition(endPos, hTrace6);
//		CloseHandle(hTrace6);
//		new Float:flDistance = GetVectorDistance(flPos, endPos);
//		if(flDistance < 70)
//		{
//			//PrintCenterText(TeleOwner,"clamping floor1");
//			DisplayClamping(Teleporter, endPos);
//			CaseClamping = ; return;
//		}
//	}
	//angled floor 1 corner
	flAng[0] = 350.0;// y
	flAng[1] = 45.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace7 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace7 != INVALID_HANDLE && TR_DidHit(hTrace7))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace7);
		CloseHandle(hTrace7);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 70)
		{
			//PrintCenterText(TeleOwner,"clamping floor2");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 11; return;
		}
	}
	//angled floor 2 corner
	flAng[0] = 350.0;// y
	flAng[1] = 135.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace8 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace8 != INVALID_HANDLE && TR_DidHit(hTrace8))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace8);
		CloseHandle(hTrace8);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 70)
		{
			//PrintCenterText(TeleOwner,"clamping floor3");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 12; return;
		}
	}
	//angled floor 3 corner
	flAng[0] = 350.0;// y
	flAng[1] = 225.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace9 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace9 != INVALID_HANDLE && TR_DidHit(hTrace9))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace9);
		CloseHandle(hTrace9);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 70)
		{
			//PrintCenterText(TeleOwner,"clamping floor4");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 13; return;
		}
	}
	//angled floor 4 corner
	flAng[0] = 350.0;// y
	flAng[1] = 315.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace10 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace10 != INVALID_HANDLE && TR_DidHit(hTrace10))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace10);
		CloseHandle(hTrace10);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 70)
		{	
			//PrintCenterText(TeleOwner,"clamping floor5");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 14; return;
		}
	}
	//angled floor 5
	flAng[0] = 350.0;// y
	flAng[1] = 90.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace11 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace11 != INVALID_HANDLE && TR_DidHit(hTrace11))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace11);
		CloseHandle(hTrace11);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 60)
		{	
			//PrintCenterText(TeleOwner,"clamping floor6");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 15; return;
		}
	}
	//angled floor 6
	flAng[0] = 350.0;// y
	flAng[1] = 180.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace12 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace12 != INVALID_HANDLE && TR_DidHit(hTrace12))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace12);
		CloseHandle(hTrace12);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 60)
		{	
			//PrintCenterText(TeleOwner,"clamping floor7");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 16; return;
		}
	}
	//angled floor 7
	flAng[0] = 350.0;// y
	flAng[1] = 180.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace13 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace13 != INVALID_HANDLE && TR_DidHit(hTrace13))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace13);
		CloseHandle(hTrace13);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if(flDistance < 60)
		{	
			//PrintCenterText(TeleOwner,"clamping floor7");
			DisplayClamping(Teleporter, endPos);
			CaseClamping = 17; 
			return;
		}
	}
	//wall check 1
	flAng[0] = 0.0;// y
	flAng[1] = 0.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace14 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace14 != INVALID_HANDLE && TR_DidHit(hTrace14))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace14);
		CloseHandle(hTrace14);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 32)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 18; 
				return;
			}
		}
		else
		{
			if(flDistance < 64)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 18; 
				return;
			}
		}
	}
	//wall check 2
	flAng[0] = 0.0;// y
	flAng[1] = 90.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace15 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace15 != INVALID_HANDLE && TR_DidHit(hTrace15))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace15);
		CloseHandle(hTrace15);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 32)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 19; 
				return;
			}
		}
		else
		{
			if(flDistance < 64)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 19; 
				return;
			}
		}
	}
	//wall check 3
	flAng[0] = 0.0;// y
	flAng[1] = 180.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace16 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace16 != INVALID_HANDLE && TR_DidHit(hTrace16))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace16);
		CloseHandle(hTrace16);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 32)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 20; 
				return;
			}
		}
		else
		{
			if(flDistance < 64)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 20; 
				return;
			}
		}
	}
	//wall check 4
	flAng[0] = 0.0;// y
	flAng[1] = 270.0; // z 
	flAng[2] = 0.0; // x
	new Handle:hTrace17 = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Teleporter);
	if(hTrace17 != INVALID_HANDLE && TR_DidHit(hTrace17))
	{
		new Float:endPos[3];
		TR_GetEndPosition(endPos, hTrace17);
		CloseHandle(hTrace17);
		new Float:flDistance = GetVectorDistance(flPos, endPos);
		if( IsSmallMap == true )
		{
			if(flDistance < 32)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 21; 
				return;
			}
		}
		else
		{
			if(flDistance < 64)
			{	
				//PrintCenterText(TeleOwner,"clamping floor7");
				DisplayClamping(Teleporter, endPos);
				CaseClamping = 21; 
				return;
			}
		}
	}
}

stock DisplayClamping(Teleporter, Float:endPos[3])
{
	new TeleOwner = GetEntPropEnt(Teleporter,Prop_Send,"m_hBuilder");
	PrintCenterText(TeleOwner,"Not enough space to build a teleporter!");
	AcceptEntityInput( Teleporter, "Kill" );
	if(DebugGeneral)
	{
		PrintToChat(TeleOwner, "clamping %i", CaseClamping);
	
		new entindex = CreateEntityByName("obj_dispenser");
		DispatchSpawn(entindex);
		TeleportEntity(entindex, endPos, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(10.0, Timer_killdisp, entindex);
	}
	
	AcceptEntityInput( Teleporter, "Kill" );
}
public Action:Timer_killdisp(Handle:timer, entity)
{
	AcceptEntityInput( entity, "Kill" );
}

stock BuildingPushBlue(Ent)
{
	new Float:flPos1[3];
	GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", flPos1 );

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			new Float:flPos2[3];
			GetClientAbsOrigin(i, flPos2);
			
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			if(flDistance < 300 && ( GetEntProp( Ent, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue ) && IsValidEntity(Ent))// && 
			{
				new Float:Vec[3];
				new Float:AngBuff[3];
				MakeVectorFromPoints(flPos1, flPos2, Vec);
				GetVectorAngles(Vec, AngBuff);
				AngBuff[0] -= 30.0; 
				GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(Vec, Vec);
				ScaleVector(Vec, 320.0);    
				Vec[2] += 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
			}
		}
	}
}

public Action:Timer_SetNoUpgrade( Handle:hTimer, any:iEntity )
{
	if(IsValidEntity(iEntity))
	{
		if( GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
			SetEntProp(iEntity , Prop_Data, "m_iMaxHealth", 300);
			SetVariantInt(300);
			AcceptEntityInput(iEntity , "SetHealth");
			SetEntProp(iEntity, Prop_Send, "m_iUpgradeLevel", 3);
		}
	}
}

public TF2_OnWaitingForPlayersStart()
{
	CreateExtraSpawnAreas();
	flNextChangeTeamBlu = GetGameTime() + 3.2;
	if(nGateCapture != 0)
		nGateCapture = 0;
	if(GateStunEnabled)
		GateStunEnabled = false; //this bool also controls respawn

	ReleaseSpawntimefixblu();
	ResetBombUpTimer();
}
stock ResetBombUpTimer()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			BombStage[i] = 0;
			if (g_hbombs1[i] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs1[i]);
				g_hbombs1[i] = INVALID_HANDLE;
			}
			if (g_hbombs2[i] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs2[i]);
				g_hbombs2[i] = INVALID_HANDLE;
			}
			if (g_hbombs3[i] != INVALID_HANDLE)
			{
				CloseHandle(g_hbombs3[i]);
				g_hbombs3[i] = INVALID_HANDLE;
			}
		}
	}
}
stock LookAtTarget(any:client, any:target, bool:DEntity)
{ 
    new Float:angles[3], Float:clientEyes[3], Float:targetEyes[3], Float:resultant[3]; 
    if(DEntity)
	    GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientEyes);
    else
	    GetClientEyePosition(client, clientEyes);
    if(target > 0 && target <= MaxClients && IsClientInGame(target)){
    GetClientEyePosition(target, targetEyes);
    }else{
    GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetEyes);
    }
    MakeVectorFromPoints(targetEyes, clientEyes, resultant); 
    GetVectorAngles(resultant, angles); 
    if(angles[0] >= 270)
	{ 
        angles[0] -= 270; 
        angles[0] = (90-angles[0]); 
    }
	else
	{ 
        if(angles[0] <= 90)
		{ 
            angles[0] *= -1; 
        } 
    } 
    if(DEntity)//fixes rotated animation prop
	{
     angles[0] == 0;
     angles[2] == 0;
	}
    angles[1] -= 180;
    TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
}
stock CreateExtraSpawnAreas()
{
	//CPrintToChatAll("{fullred}DEBUG:{cyan} Function CreateExtraSpawnAreas called!");
	new ent1 = -1;
	while((ent1 = FindEntityByClassname(ent1, "func_respawnroom")) != -1)
	{
		if(IsValidEntity(ent1))
		{
			decl String:strName[50];
			GetEntPropString(ent1, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "SpawnZoneBluBWR") == 0)
			{
				AcceptEntityInput(ent1, "Kill"); // removes extra func_respawnroom before creating them again to prevent ED_Alloc crashes
			}
		}
	}
	new i = -1;
	while ((i = FindEntityByClassname(i, "info_player_teamspawn")) != -1)
	{
		if(IsValidEntity(i) && GetEntProp( i, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue)//&& bool:GetEntProp( i, Prop_Data, "m_bDisabled" ) == false) //m_bDisabled
		{
			SpawnFuncSpawnZone(i);
			//decl String:strName[50];
			//GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			//if(strcmp(strName, "spawnbot") == 0)
			//{
			//	new Float:pos[3];
			//	GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
			//	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			//	break;
			//}
		}
	}
}
stock SpawnFuncSpawnZone(infoplayerspawn)
{
	new entindex = CreateEntityByName("func_respawnroom");
	if (entindex != -1) //dispatch ent properites
	{
		DispatchKeyValue(entindex, "StartDisabled", "0");
		DispatchKeyValue(entindex, "TeamNum", "3");
		DispatchKeyValue(entindex, "spawnflags", "2");
		DispatchKeyValue(entindex, "targetname", "SpawnZoneBluBWR");
	}

	DispatchSpawn(entindex);
	//IsSpawnedSpawnroom[entindex] = true;
	ActivateEntity(entindex);

	PrecacheModel("models/player/items/pyro/drg_pyro_fueltank.mdl");
	SetEntityModel(entindex, "models/player/items/pyro/drg_pyro_fueltank.mdl");

	new Float:minbounds[3] = {-10.0, -10.0, -50.0};
	new Float:maxbounds[3] = {50.0, 50.0, 50.0};
	SetEntPropVector(entindex, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", maxbounds);
    
	SetEntProp(entindex, Prop_Send, "m_nSolidType", 2);

	new enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);
	
	new Float:pos[3];
	GetEntPropVector(infoplayerspawn, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(entindex, pos, NULL_VECTOR, NULL_VECTOR);
	
//	SDKHook(entindex, SDKHook_Touch, OnSpawnStartTouch );
//	SDKHook(entindex, SDKHook_EndTouch, OnSpawnEndTouch );

//	PrintToChatAll("Created the func_capzone");
}
public Action:Timer_BuildingSmash( Handle:hTimer, any:client )
{
	if(!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != _:TFTeam_Blue)
		return Plugin_Stop;
		
	//SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy ); bot_eye_glow bot_eye_halo eye particles stun bot_radio_waves
	if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == false)
		return Plugin_Stop;
	if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == false)
		return Plugin_Handled;
	new iEnt = -1;
	new Float:flPos1[3];
	GetClientAbsOrigin(client, flPos1);
	new String:strObjects[4][] = { "obj_dispenser","obj_teleporter","obj_teleporter_entrance","obj_teleporter_exit" };
	for( new o = 0; o < sizeof(strObjects); o++ )
	{
		while( ( iEnt = FindEntityByClassname( iEnt, strObjects[o] ) ) != -1 )
		{
			if( IsValidEntity(iEnt) )
			{
				new Float:flPos2[3];
				GetEntPropVector( iEnt, Prop_Send, "m_vecOrigin", flPos2 );
				
				if(bool:GetEntProp(client, Prop_Send, "m_bGlowEnabled") == true)
				{
				
					new Float:flDistance = GetVectorDistance(flPos1, flPos2);
					if(flDistance < 113 && ( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue ))// && 
					{
						//PrintToChatAll("DMG ADDED.");

						SDKHooks_TakeDamage(iEnt, 0, client, 3500.0, DMG_BLAST);		
						//SDKHooks_TakeDamage(i, 0, client, 99999.0, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
GlowBuilding(iEnt)
{
	if(!GetConVarBool(cvarOutlineEnable) || !IsValidEntity(iEnt))
		return;
	new String:sClassName[128];
	GetEdictClassname(iEnt, sClassName, sizeof(sClassName));
	new	Outline = GetConVarInt(cvarSentryVision);
	if(StrEqual(sClassName, "obj_sentrygun") && Outline != 1 && Outline != 3 && Outline != 7 && Outline != 5)
		return;
	if(StrEqual(sClassName, "obj_dispenser") && Outline != 2 && Outline != 3 && Outline != 7 && Outline != 6)
		return;
	if(StrEqual(sClassName, "obj_teleporter") && Outline != 4 && Outline != 5 && Outline != 7 && Outline != 6)
		return;
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sBuffer, sizeof(sBuffer));
	new ent = CreateEntityByName("tf_taunt_prop");
	if (ent != -1 )//&& StrContains(sBuffer, "blueprint") == -1 && strlen(sBuffer) != 0)
	{
		new Float:flModelScale = GetEntPropFloat(iEnt, Prop_Send, "m_flModelScale");
	
		SetEntityModel(ent, sBuffer);
		DispatchSpawn(ent);
		ActivateEntity(ent);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(ent, 0, 0, 0, 0);
		SetEntProp(ent, Prop_Send, "m_bGlowEnabled", 1);
		SetEntPropFloat(ent, Prop_Send, "m_flModelScale", flModelScale);
	
		new iFlags = GetEntProp(ent, Prop_Send, "m_fEffects");
		SetEntProp(ent, Prop_Send, "m_fEffects", iFlags | (1 << 0));
		
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", iEnt);

		SDKHook(ent, SDKHook_SetTransmit, GlowRedBuilding);
	}
}
public Action:GlowRedBuilding(iEntity, iClient)
{
	if(IsValidClient(iClient) && iRobotMode[iClient] != Robot_SentryBuster || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:OnTeleporterFinished(Handle:timer,any:Building)
{
	if(!IsValidEntity(Building)) return Plugin_Stop;
	
	new String:sEnt[255];
	Entity_GetClassName(Building,sEnt,sizeof(sEnt));
	
	if (!StrEqual(sEnt, "obj_teleporter"))
		return Plugin_Stop;
	
	//PrintToChatAll("passed valid teleporter");
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	//FakeClientCommand(client, "destory 1");
	GetEntPropString(Building, Prop_Data, "m_ModelName", sBuffer, sizeof(sBuffer));
	if(StrContains(sBuffer, "light") != -1)//dis and tp
	{
			//DestoryOldTeleport(Building);
			SetEntProp(Building, Prop_Data, "m_iMaxHealth", 300);
			SetVariantInt(300);
			AcceptEntityInput(Building, "SetHealth");
			CreateTimer( 0.2, Timer_SetNoUpgrade, Building ); 
			
//			new Float:position[3];
//			GetEntPropVector(TeleporterExit,Prop_Send, "m_vecOrigin",position);

			//new Teleportonwerclient = GetEntPropEnt(Building,Prop_Send,"m_hBuilder");
			//if(!IsFakeClient(Teleportonwerclient) || IsMannhattan)
			//{
				//bEngiCanBuildSecondTele[Teleportonwerclient] = true; 
			AttachParticleTeleporter(Building,"teleporter_mvm_bot_persist");
			//PrintToChatAll("passed valid teleporte2");
			HookSingleEntityOutput(Building, "OnDestroyed", OnDestroyedTeleporter, true);
			//}
			return Plugin_Stop;
	}

	return Plugin_Continue;
}
public OnDestroyedTeleporter(const char[] output, caller, activator, float delay)
{
	AcceptEntityInput(caller,"KillHierarchy");
}

stock DestoryOldTeleport(Teleporter)
{
	new TeleporterExit = -1;
	while((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1)
	{
		if(GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == _:TFTeam_Blue)
		{
			new OwnerOldTeleporter = GetEntPropEnt(TeleporterExit,Prop_Send,"m_hBuilder");
			new OwnerNewTeleporter = GetEntPropEnt(Teleporter,Prop_Send,"m_hBuilder");
			if(TeleporterExit != Teleporter && OwnerOldTeleporter == OwnerNewTeleporter)
			{
				//SDKHooks_TakeDamage(TeleporterExit, 0, 0, 500.0, DMG_CRUSH);
				SetVariantInt( 900 );
				AcceptEntityInput( TeleporterExit, "RemoveHealth" );
				break;
			}
		}
	}
}


/*stock SetAnimation(client, const String:Animation[PLATFORM_MAX_PATH], AnimationType, ClientCommandType)
{
	SetCommandFlags("mp_playanimation", GetCommandFlags("mp_playanimation") ^FCVAR_CHEAT);
	SetCommandFlags("mp_playgesture", GetCommandFlags("mp_playgesture") ^FCVAR_CHEAT);
	new String:Anim[PLATFORM_MAX_PATH];
	switch(AnimationType)
	{
		case 1:
		{
			Format(Anim, PLATFORM_MAX_PATH, "mp_playanimation %s", Animation);
		}
		case 2:
		{
			Format(Anim, PLATFORM_MAX_PATH, "mp_playgesture %s", Animation);
		}
	}
	switch(ClientCommandType)
	{
		case 1: 	ClientCommand(client, Anim);
		case 2: 	FakeClientCommand(client, Anim);
		case 3:	FakeClientCommandEx(client, Anim);
	}
}*/
stock TLK_MVM_BOMB_CARRIER_UPGRADE(client, iUpgradeLevel = 1)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && ClientHasVoiceLines(client) && GetClientTeam(i) != GetClientTeam(client))
		{
			SetVariantString("randomnum:25");
			AcceptEntityInput(i, "AddContext");
		
			SetVariantString("IsMvMDefender:1");
			AcceptEntityInput(i, "AddContext");
			
			switch(iUpgradeLevel)
			{
				case 1:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE1");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
				case 2:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE2");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
				case 3:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE3");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
			}
			
			AcceptEntityInput(i, "ClearContext");
		}
	}
}
bool:ClientHasVoiceLines(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Soldier 
	|| TF2_GetPlayerClass(client) == TFClass_Medic 
	|| TF2_GetPlayerClass(client) == TFClass_Heavy 
	|| TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		return true;
	}
	return false;

}
stock MyAddServerTag(const String:tag[])
{	
	//PrintToChatAll("att");
	if (FindStringInArray(g_hCustomTags, tag) == -1)
	{
		PushArrayString(g_hCustomTags, tag);
	}
	decl String:current_tags[SVTAGSIZE];
	GetConVarString(sv_tags, current_tags, sizeof(current_tags));
	if (StrContains(current_tags, tag) > -1)
	{
		// already have tag
		return;
	}
	
	decl String:new_tags[SVTAGSIZE];
	Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0]!=0)?",":"", tag);
	
	new flags = GetConVarFlags(sv_tags);
	SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
	g_bIgnoreNextTagChange = true;
	SetConVarString(sv_tags, new_tags);
	g_bIgnoreNextTagChange = false;
	SetConVarFlags(sv_tags, flags);
}
public Action:CommandListener_Build(client, const String:command[], argc)
{
	if(GetClientTeam(client) == _:TFTeam_Blue && bInRespawn[client])	
		return Plugin_Handled;
	return Plugin_Continue;
}

stock CountWaveNumber() /** Get Current Wave Number and Total Waves **/
{
	new iObjective = -1;
	while( ( iObjective = FindEntityByClassname( iObjective, "tf_objective_resource" ) ) != -1 )
	{
		if(IsValidEntity(iObjective))
		{
			iCurrentWave = GetEntProp( iObjective, Prop_Send, "m_nMannVsMachineWaveCount" );
			iTotalWave = GetEntProp( iObjective, Prop_Send, "m_nMannVsMachineMaxWaveCount" );
			iEventPopFileType = GetEntProp( iObjective, Prop_Send, "m_nMvMEventPopfileType" );
		}
	}
}
stock CheckGiantAvailability() /** Uses data from CountWaveNumber to Determine if giants are enabled or not **/
{
	bWaveNumGiants = false;
	
	if(iTotalWave == 1)
	{
		bWaveNumGiants = true;
	}
	
	if(iTotalWave == 2 || iTotalWave == 3)
	{
		if(iCurrentWave == 1)
		{
			bWaveNumGiants = false;
		}
		else if(iCurrentWave >= 2)
		{
			bWaveNumGiants = true;
		}
	}
	
	if( iTotalWave >= 4 && iTotalWave <= 8 )
	{
		if( iCurrentWave <= 3 )
		{
			bWaveNumGiants = false;
		}
		else if( iCurrentWave >= 4 )
		{
			bWaveNumGiants = true;
		}
	}
	
	if( iTotalWave >= 9 && iTotalWave <= 12 )
	{
		if(iCurrentWave <= 6)
		{
			bWaveNumGiants = false;
		}
		else if(iCurrentWave >= 7)
		{
			bWaveNumGiants = true;
		}
	}
	
	if( iTotalWave >= 13 )
	{
		if(iCurrentWave <= 8)
		{
			bWaveNumGiants = false;
		}
		else if(iCurrentWave >= 9)
		{
			bWaveNumGiants = true;
		}
	}
	
	if( bWaveNumGiants == true )
	{
		//LogMessage("[BWR2] Wave Counter: Giants Enabled");
	}
	else
	{
		//LogMessage("[BWR2] Wave Counter: Giants Disabled");
	}
	//LogMessage("[BWR2] Current Wave: %d | Total Waves: %d", iCurrentWave, iTotalWave);
}
stock IsHalloweenMission() /** Check if the current mission is a Halloween (wave 666) mission **/
{
	if( iEventPopFileType == 1 )
	{
		Is666Mode = true;
		//LogMessage("[BWR2] Wave 666 Enabled");
	}
	else
	{
		Is666Mode = false;
		//LogMessage("[BWR2] Wave 666 Disabled");
	}
}

stock SpyTeleportAvailable()
{
	new foundspytele = 0;
	new i5 = -1;
	while((i5 = FindEntityByClassname(i5, "info_target")) != -1)
	{
		if(IsValidEntity(i5))
		{
			decl String:strName[50];
			GetEntPropString(i5, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bwr_spy_spawnpoint") == 0)
			{
				foundspytele = 1;
			}
		}
	}
	if(foundspytele == 1)
	{
		bCanSpyTeleport = true;
	}
	else
	{
		bCanSpyTeleport = false;
	}
}