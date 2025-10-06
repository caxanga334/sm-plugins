/**
 * Applies the luck effect 'TF Condition'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyTFCondEffect(int client)
{
	// Array with conditions to be selected
	static const int conds[50] = {14,16,17,19,24,26,27,28,29,30,31,32,33,34,51,52,53,54,58,59,60,61,62,63,64,66,72,73,74,75,79,80,84,85,86,87,90,91,92,93,94,95,96,97,102,109,110,111,114,123};

	TF2_AddCondition(client, view_as<TFCond>(conds[Math_GetRandomInt(0, sizeof(conds)-1)]), Math_GetRandomFloat(1.0, 60.0));

	CPrintToChatAll("{green}[LUCK] {cyan}%N received a random condition.", client);
}

/**
 * Applies the luck effect 'Random Name'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyRandomNameEffect(int client)
{
	if (g_RandomNames1.Length == 0 && g_RandomNames2.Length == 0)
	{
		ThrowError("Name lists are empty!");
		return;
	}

	int r1 = Math_GetRandomInt(0, g_RandomNames1.Length - 1);
	int r2 = Math_GetRandomInt(0, g_RandomNames2.Length - 1);

	char name1[MAX_NAME_LENGTH];
	char name2[MAX_NAME_LENGTH];

	g_RandomNames1.GetString(r1, name1, sizeof(name1));
	g_RandomNames2.GetString(r2, name2, sizeof(name2));

	char newname[MAX_NAME_LENGTH * 2];
	FormatEx(newname, sizeof(newname), "%s %s", name1, name2);
	CPrintToChatAll("{green}[LUCK] {cyan}%N received a random name {gold}\"%s\"{cyan}.", client, newname);
	SetClientName(client, newname);
}

/**
 * Applies the luck effect 'Weapon Deleter'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyWeaponDeleterEffect(int client)
{
	int slot = Math_GetRandomInt(0,2);
	int entity = TF2Util_GetPlayerLoadoutEntity(client, slot, true);

	if(IsValidEntity(entity))
	{
		if(TF2Util_IsEntityWearable(entity))
		{
			TF2_RemoveWearable(client, entity);
		}
		else
		{
			RemoveEntity(entity);
		}
	}

	CPrintToChatAll("{green}[LUCK] {cyan}%N lost a random weapon.", client);
}

/**
 * Applies the luck effect 'Health Bonus'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyHealthBonusEffect(int client)
{
	TF2Util_TakeHealth(client, Math_GetRandomFloat(1.0, 2500.0), TAKEHEALTH_IGNORE_MAXHEALTH);
	CPrintToChatAll("{green}[LUCK] {cyan}%N received a health bonus.", client);
}

/**
 * Applies the luck effect 'Soul Sphere'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplySoulSphereEffect(int client)
{
	TF2Util_TakeHealth(client, 100.0, TAKEHEALTH_IGNORE_MAXHEALTH);
	CPrintToChatAll("{green}[LUCK] {cyan}%N received a soul sphere.", client);
}

/**
 * Applies the luck effect 'Oil Drum Rain'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyOilDrumRainEffect(int client)
{
	float distance = GetDistanceToCeiling(client);

	if(distance < 256.0)
		return;

	float vec[3];
	vec = GetPositionAboveClient(client, 200.0);
	 
	int entity = SpawnOilDrum(vec);
	AcceptEntityInput(entity, "Ignite");
}

/**
 * Applies the luck effect 'Character Attribute'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyCharAttribEffect(int client)
{
	AttributeData_s attrib;

	if (!Attributes_GetRandomPlayerAttribute(client, attrib))
	{
		return;
	}

	Attributes_ApplyAttribute(client, attrib);
	CPrintToChatAll("{green}[LUCK] {cyan}%N received a random character attribute {gold}\"%s\"{cyan}.", client, attrib.name);
}

/**
 * Applies the luck effect 'Weapon Attribute'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyWeaponAttribEffect(int client)
{
	AttributeData_s attrib;

	if (!Attributes_GetRandomWeaponAttribute(client, attrib))
	{
		return;
	}

	int weapon = Attributes_SelectClientWeapon(client, attrib.slot);

	if (weapon == INVALID_ENT_REFERENCE) { return; }

	char classname[64];
	if (!GetEntityClassname(weapon, classname, sizeof(classname))) { strcopy(classname, sizeof(classname), "NULL"); }
	Attributes_ApplyAttribute(weapon, attrib);
	CPrintToChatAll("{green}[LUCK] {cyan}%N received a random weapon attribute {gold}\"%s\"{cyan} on their {gold}\"%s\"{cyan}.", client, attrib.name, classname);
}

/**
 * Applies the luck effect 'Random Impulse'
 *
 * @param client        The client to apply the effect to
 * @return     no return
 */
void ApplyRandomImpulseEffect(int client)
{
	float vec[3];
	vec[0] = Math_GetRandomFloat(-1000.0, 1000.0);
	vec[1] = Math_GetRandomFloat(-1000.0, 1000.0);
	vec[2] = Math_GetRandomFloat(-1000.0, 1000.0);

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}

/**
 * Applies the luck effect 'Lag'
 *
 * @param client        The client to apply the effect to
 * @param vec           The position where the client will be teleported to simulate lag
 * @return     no return
 */
void ApplyLagEffect(int client, float vec[3])
{
	TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
}

void ApplyCoordinateShiftEffect(int client)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);

	float x = origin[0];
	float y = origin[1];
	origin[0] = y;
	origin[1] = x;

	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}