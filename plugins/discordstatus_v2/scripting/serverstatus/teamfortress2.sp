
/**
 * Checks if the current game mode is Mann vs Machine
 * 
 * @return     TRUE if the current game mode is MvM. Always FALSE if the game is not TF2
 */
bool IsPlayingMannVsMachine()
{
	if(g_engine != Engine_TF2)
		return false;

	return !!GameRules_GetProp("m_bPlayingMannVsMachine");
}

/**
 * Gets the Objective Resource entity index.
 *
 * @return					entity index if found or -1 if not found
 */
int TF2_GetObjectiveResourceEntity()
{
	int entity = FindEntityByClassname(-1, "tf_objective_resource");

	if(IsValidEntity(entity)) // Validate here so we don't to validade it later
	{
		return entity;
	}

	return -1;
}

/**
 * Gets the current MvM mission name
 *
 * @param name			Buffer to store the mission name
 * @param size			Buffer size
 */
void TF2MvM_GetMissionName(char[] name, int size)
{
	int entity = TF2_GetObjectiveResourceEntity();
	GetEntPropString(entity, Prop_Send, "m_iszMvMPopfileName", name, size);
	ReplaceString(name, size, "scripts/population/", "");
	ReplaceString(name, size, ".pop", "");
}


void EV_TF2_OnMvMWaveStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!cfg_GameEvents.enabled)
		return;

	int wave = event.GetInt("wave_index", -1);
	int max = event.GetInt("max_waves", -1);
	SendMessage_TF2_OnMvMWaveStart(wave + 1, max);
}