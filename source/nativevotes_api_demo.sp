#include <sourcemod>
#include <nativevotes_api>

NativeVote_s g_Vote;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Let native votes API figure out the current game.
	NativeVotesAPI.RunAutoGameTypeDetection();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_Vote.name = "my cool vote";
	g_Vote.on_start = OnVoteStarted;
	g_Vote.on_option_cast = OnVoteOptionCast;
	g_Vote.on_time_up = OnVoteEnded;

	RegAdminCmd("sm_testvote", CreateVoteCommand, ADMFLAG_VOTE, "Creates a test native vote.");
}

public Action OnClientCommand(int client, int args)
{
	// This is needed to allow Native Votes to detect votes being cast by clients.
	if (NativeVotesAPI.OnClientCommand(client, args))
	{
		// Block the command from running to prevent conflicts with the game's own voting system.
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action CreateVoteCommand(int client, int args)
{
	NativeVote_Options_s options;
	NativeVotesAPI.VoteOptions_YesNo(options, NATIVEVOTES_API_CALLER_IS_SERVER, 0, NATIVEVOTES_TEAM_ALL);
	NativeVotesAPI.StartVote(g_Vote, options);

	return Plugin_Handled;
}

void OnVoteStarted()
{
	PrintToServer("Vote started!");
}

void OnVoteOptionCast(int clientidx, const char[] option)
{
	PrintToServer("Option cast: %L %s", clientidx, option);
}

void OnVoteEnded()
{
	PrintToServer("Vote ended!");
	NativeVotesAPI.VotePassed("my cool vote", "good job! \n\n\n\n\n");
}