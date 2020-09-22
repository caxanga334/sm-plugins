/** Caxanga334's include file (AKA Anonymous Player)
*
*/

/**
 * Checks if the given client index is valid.
 *
 * @param client         The client index.  
 * @return              True if the client is valid
 *                      False if the client is invalid.
 */
stock bool IsValidClient(int client)
{
	if( client < 1 || client > MaxClients ) return false;
	if( !IsValidEntity(client) ) return false;
	return IsClientInGame(client);
}

/**
 * Gets a random player in game.
 * Do not call this if the server is empty.
 *
 * @param bBots         Include bots?
 * @return              The client index
 */
stock int GetRandomClient(bool bBots = false)
{
	int players_available[MAXPLAYERS+1];
	int counter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if( bBots )
		{
			if ( IsClientConnected(i) && IsClientInGame(i) )
			{
				players_available[counter] = i;
				counter++;
			}			
		}
		else
		{
			if ( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) )
			{
				players_available[counter] = i;
				counter++;
			}						
		}
	}
	
	return players_available[GetRandomInt(0,(counter-1))];
}

/**
 * Gets a random player in game from a specific team.
 * Do not call this if the server is empty.
 *
 * @param iTeam         Team Index
 * @param bBots         Include bots?
 * @return              The client index
 */
stock int GetRandomClientFromTeam(const int iTeam, bool bBots = false)
{
	int players_available[MAXPLAYERS+1];
	int counter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if( bBots )
		{
			if ( IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == iTeam )
			{
				players_available[counter] = i;
				counter++;
			}			
		}
		else
		{
			if ( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam )
			{
				players_available[counter] = i;
				counter++;
			}						
		}
	}
	
	return players_available[GetRandomInt(0,(counter-1))];
}