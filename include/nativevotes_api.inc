#if defined _nativevotes_api_included
 #endinput
#endif
#define _nativevotes_api_included

#include <sourcemod>
#include <sdktools>

/**
 * Header only native votes API by caxanga334
*/

#define NATIVEVOTES_API_REV 1
#define NATIVEVOTES_API_CALLER_IS_SERVER 99 // Use this value as the vote caller's client index to make the vote as called by the server.
#define NATIVEVOTES_TEAM_ALL 0
#define __NATIVEVOTESAPI_VOTE_INDEX 999999
#define __INVALID_VOTE_ISSUE -1 // this might not be the same value for all games

typedef OnNativeVoteStarted = function void();
typedef OnNativeVoteOptionCast = function void(int clientidx, const char[] option);
typedef OnNativeVoteTimeUp = function void();

enum struct NativeVote_s
{
	char name[64]; // vote name
	OnNativeVoteStarted on_start;
	OnNativeVoteOptionCast on_option_cast;
	OnNativeVoteTimeUp on_time_up;
}

enum struct NativeVote_Options_s
{
	int caller;
	int target;
	bool is_yesno;
	bool is_team_restricted;
	int team;
	char option1[128];
	char option2[128];
	char option3[128];
	char option4[128];
	char option5[128];
	int num_options;
}

static NativeVote_s s_activeVote;
static NativeVote_Options_s s_voteOptions;
static bool s_isVoteActive;
static int s_voteController;

static int __NativeVotesAPI_VoteOptionToIndex(const char[] option)
{
	if (strcmp(option, "option1", false) == 0)
	{
		return 0;
	}

	if (strcmp(option, "option2", false) == 0)
	{
		return 1;
	}

	if (strcmp(option, "option3", false) == 0)
	{
		return 2;
	}

	if (strcmp(option, "option4", false) == 0)
	{
		return 3;
	}

	if (strcmp(option, "option5", false) == 0)
	{
		return 4;
	}

	LogError("Failed to convert an option string to index! %s", option);
	return -1;
}

static void __NativeVotesAPI_OnVoteOptionCast(int client, const char[] option)
{
	int optionidx = __NativeVotesAPI_VoteOptionToIndex(option);

	if (optionidx < 0)
	{
		return;
	}

	Event event = CreateEvent("vote_cast");

	if (event != null)
	{
		event.SetInt("voteidx", __NATIVEVOTESAPI_VOTE_INDEX);
		event.SetInt("vote_option", optionidx);
		event.SetInt("team", s_voteOptions.team);
		event.SetInt("entityid", client);

		event.Fire();
	}

	__nativeVotesAPI_UpdateVoteController(optionidx);
}

static void __NativeVotesAPI_SendOptions(NativeVote_Options_s voteOptions)
{
	Event event = CreateEvent("vote_options");

	if (event != null)
	{
		event.SetInt("count", voteOptions.num_options);

		if (voteOptions.num_options >= 1)
		{
			event.SetString("option1", voteOptions.option1);
		}

		if (voteOptions.num_options >= 2)
		{
			event.SetString("option2", voteOptions.option2);
		}

		if (voteOptions.num_options >= 3)
		{
			event.SetString("option3", voteOptions.option3);
		}

		if (voteOptions.num_options >= 4)
		{
			event.SetString("option4", voteOptions.option4);
		}

		if (voteOptions.num_options >= 5)
		{
			event.SetString("option5", voteOptions.option5);
		}

		event.Fire();
	}
}

static void __NativeVotesAPI_SendVoteStartMessage(Handle msg, NativeVote_Options_s voteOptions)
{
	Protobuf pb = UserMessageToProtobuf(msg);

	if (pb != null)
	{
		// TO-DO:
		EndMessage();
		return;
	}

	// bitbuf
	BfWrite bitbuf = UserMessageToBfWrite(msg);

	bitbuf.WriteByte(voteOptions.is_team_restricted ? 1 : 0); // m_iOnlyTeamToVote
	bitbuf.WriteNum(__NATIVEVOTESAPI_VOTE_INDEX); // m_nVoteIdx
	bitbuf.WriteByte(voteOptions.caller); // m_iEntityHoldingVote
	bitbuf.WriteString("Display String");
	bitbuf.WriteString("Detail String");
	bitbuf.WriteBool(voteOptions.is_yesno); // pCurrentIssue->IsYesNoVote()
	bitbuf.WriteByte(voteOptions.target); // pCurrentIssue->m_hPlayerTarget (ent index)

	EndMessage();
}

static void __NativeVotesAPI_FindVoteController()
{
	int ent = FindEntityByClassname(INVALID_ENT_REFERENCE, "vote_controller");
	
	if (ent != INVALID_ENT_REFERENCE)
	{
		s_voteController = EntIndexToEntRef(ent);
	}
	else
	{
		LogError("Failed to get an index to the vote_controller entity!");
		s_voteController = INVALID_ENT_REFERENCE;
	}
}

static void __nativeVotesAPI_InitVoteController(NativeVote_Options_s voteOptions)
{
	int ent = EntRefToEntIndex(s_voteController);

	if (ent != INVALID_ENT_REFERENCE)
	{
		int maxoptions = GetEntPropArraySize(ent, Prop_Send, "m_nVoteOptionCount");

		for (int i = 0; i < maxoptions; i++)
		{
			SetEntProp(ent, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}

		SetEntProp(ent, Prop_Send, "m_nVoteIdx", __NATIVEVOTESAPI_VOTE_INDEX);

		if (voteOptions.is_team_restricted)
		{
			SetEntProp(ent, Prop_Send, "m_iOnlyTeamToVote", voteOptions.team);
		}
		else
		{
			SetEntProp(ent, Prop_Send, "m_iOnlyTeamToVote", 0);
		}

		SetEntProp(ent, Prop_Send, "m_bIsYesNoVote", view_as<int>(voteOptions.is_yesno));
		SetEntProp(ent, Prop_Send, "m_nPotentialVotes", MaxClients); // TO-DO: See if we actually need to set this correctly.
	}
}

static void __nativeVotesAPI_UpdateVoteController(int option)
{
	int ent = EntRefToEntIndex(s_voteController);

	if (ent != INVALID_ENT_REFERENCE)
	{
		int num = GetEntProp(ent, Prop_Send, "m_nVoteOptionCount", _, option);
		num += 1;
		SetEntProp(ent, Prop_Send, "m_nVoteOptionCount", num, _, option);
	}
}

static void __NativeVotesAPI_ResetVoteController()
{
	int ent = EntRefToEntIndex(s_voteController);

	if (ent != INVALID_ENT_REFERENCE)
	{
		int maxoptions = GetEntPropArraySize(ent, Prop_Send, "m_nVoteOptionCount");

		for (int i = 0; i < maxoptions; i++)
		{
			SetEntProp(ent, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}

		SetEntProp(ent, Prop_Send, "m_nVoteIdx", -1);
		SetEntProp(ent, Prop_Send, "m_iOnlyTeamToVote", 0);
		SetEntProp(ent, Prop_Send, "m_bIsYesNoVote", 0);
		SetEntProp(ent, Prop_Send, "m_nPotentialVotes", 0);
	}
}

static bool __NativeVotesAPI_StartVote(NativeVote_Options_s voteOptions)
{
	__NativeVotesAPI_FindVoteController();

	if (s_voteController == INVALID_ENT_REFERENCE)
	{
		return false;
	}

	int ent = EntRefToEntIndex(s_voteController);

	// an actual game vote is active, don't interrupt
	if (GetEntProp(ent, Prop_Send, "m_iActiveIssueIndex") != __INVALID_VOTE_ISSUE)
	{
		return false;
	}

	s_isVoteActive = true;

	if (s_activeVote.on_start != INVALID_FUNCTION)
	{
		Call_StartFunction(null, s_activeVote.on_start);
		Call_Finish();
	}

	// send vote options to clients
	__NativeVotesAPI_SendOptions(voteOptions);

	Handle msg = StartMessageAll("VoteStart", USERMSG_RELIABLE);

	if (msg == null)
	{
		ThrowError("Got NULL message handle from StartMessageAll!");
	}

	__NativeVotesAPI_SendVoteStartMessage(msg, voteOptions);
	__nativeVotesAPI_InitVoteController(voteOptions);

	return true;
}

static void __NativeVotesAPI_PassVote(const char[] details, const char[] text)
{
	Handle msg = StartMessageAll("VotePass", USERMSG_RELIABLE);

	Protobuf pb = UserMessageToProtobuf(msg);

	if (pb != null)
	{
		// TO-DO
		EndMessage();
		return;
	}

	BfWrite bf = UserMessageToBfWrite(msg);

	bf.WriteByte(s_voteOptions.team); // m_iOnlyTeamToVote
	bf.WriteNum(__NATIVEVOTESAPI_VOTE_INDEX); // m_nVoteIdx
	bf.WriteString(details);
	bf.WriteString(text);

	EndMessage();
}

static void __NativeVotesAPI_Timer_VoteEnd(Handle timer)
{
	if (s_activeVote.on_time_up != INVALID_FUNCTION)
	{
		Call_StartFunction(null, s_activeVote.on_time_up);
		Call_Finish();
	}
	else
	{
		// no vote end function, assume always pass
		__NativeVotesAPI_PassVote("", "Vote passed.\n\n\n\n");
	}

	s_isVoteActive = false;
}

static void __NativeVotesAPI_FailVote(int reason)
{
	Handle msg = StartMessageAll("VoteFailed", USERMSG_RELIABLE);

	Protobuf pb = UserMessageToProtobuf(msg);

	if (pb != null)
	{
		// TO-DO
		EndMessage();
		return;
	}

	BfWrite bf = UserMessageToBfWrite(msg);

	bf.WriteByte(s_voteOptions.team); // m_iOnlyTeamToVote
	bf.WriteNum(__NATIVEVOTESAPI_VOTE_INDEX); // m_nVoteIdx
	bf.WriteByte(reason); // nReason

	EndMessage();
}

methodmap NativeVotesAPI
{
	/**
	 * Handles votes client command.
	 * 
	 * @param		client	Client who sent the command.
	 * @param		args	Number of command arguments ent.
	 * @return				If this function returns true, the command was handled.
	 */
	public static bool OnClientCommand(int client, int args)
	{
		if (!s_isVoteActive)
		{
			return false;
		}

		if (args < 2)
		{
			return false;
		}

		char cmd[8];
		GetCmdArg(0, cmd, sizeof(cmd));

		// this is a vote...
		if (strcmp(cmd, "vote", false) == 0)
		{
			// there are two args
			// the first arg is the vote index (we don't use it)
			// the second arg is the option

			char option[128];
			GetCmdArg(2, option, sizeof(option));

			__NativeVotesAPI_OnVoteOptionCast(client, option);

			if (s_activeVote.on_option_cast == INVALID_FUNCTION)
			{
				return false;
			}

			Call_StartFunction(null, s_activeVote.on_option_cast);
			Call_PushCell(client);
			Call_PushString(option);
			Call_Finish();

			return true;
		}

		return false;
	}

	// Returns true if a vote handled by this API is active.
	public static bool IsVoteActive()
	{
		return s_isVoteActive;
	}

	/**
	 * Initializes a NativeVote_Options_s struct for a Yes/No vote.
	 * 
	 * @param		voteOptions		Vote options struct to initialize.
	 * @param		caller			Client index of the vote's caller.
	 * @param		target			Client index of the vote target or 0 if no target.
	 * @param		teamOnly		If true, the vote is restricted to the caller's team.
	 */
	public static void VoteOptions_YesNo(NativeVote_Options_s voteOptions, int caller, int target, int team)
	{
		voteOptions.is_yesno = true;
		voteOptions.is_team_restricted = team == NATIVEVOTES_TEAM_ALL ? false : true;
		voteOptions.team = team;
		voteOptions.num_options = 2;
		voteOptions.caller = caller;
		voteOptions.target = target;
		voteOptions.option1 = "Yes";
		voteOptions.option2 = "No";
	}

	/**
	 * Starts a native vote.
	 * 
	 * @param		voteStruct		Native vote object.
	 * @param		voteOptions		Vote options object.
	 * @param		voteTime		How long in seconds the vote is available.
	 * @return						True if the vote started, false otherwise.
	 */
	public static bool StartVote(NativeVote_s voteStruct, NativeVote_Options_s voteOptions, float voteTime = 30.0)
	{
		s_activeVote = voteStruct;
		s_voteOptions = voteOptions;

		// run internal logic
		bool started = __NativeVotesAPI_StartVote(voteOptions);

		if (started)
		{
			CreateTimer(voteTime, __NativeVotesAPI_Timer_VoteEnd);
		}

		return started;
	}

	public static void VotePassed(const char[] detail, const char[] text)
	{
		__NativeVotesAPI_PassVote(detail, text);
		__NativeVotesAPI_ResetVoteController();
		s_isVoteActive = false;
	}
	/**
	 * Ends native vote with a vote failed message.
	 * 
	 * @param		reason			Reason the vote failed, depends on the current game. Leave at default for a generic reason.
	 */
	public static void VoteFailed(int reason = 0)
	{
		__NativeVotesAPI_FailVote(reason);
		__NativeVotesAPI_ResetVoteController();
		s_isVoteActive = false;
	}

	/**
	 * Gets the entity index of the vote controller entity or -1 on failure.
	 * 
	 * @return		Vote controller entity index.
	 */
	public static int GetVoteControllerEntity()
	{
		return EntRefToEntIndex(s_voteController);
	}
}