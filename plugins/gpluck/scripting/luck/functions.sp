#define SIZE_OF_INT         2147483647 // without 0

/**
 * Makes a negative integer number to a positive integer number.
 * This is faster than Sourcemod's native FloatAbs() for integers.
 * Use FloatAbs() for Float numbers.
 *
 * @param number		A number that can be positive or negative.
 * @return				Positive number.
 */
stock int Math_Abs(int value)
{
	return (value ^ (value >> 31)) - (value >> 31);
}

/**
 * Checks if 2 vectors are equal.
 * You can specfiy a tolerance, which is the maximum distance at which vectors are considered equals
 *
 * @param vec1			First vector (3 dim array)
 * @param vec2			Second vector (3 dim array)
 * @param tolerance 	If you want to check that those vectors are somewhat even. 0.0 means they are 100% even if this function returns true.
 * @return				True if vectors are equal, false otherwise.
 */
stock bool Math_VectorsEqual(float vec1[3], float vec2[3], float tolerance = 0.0)
{
	float distance = GetVectorDistance(vec1, vec2, true);

	return distance <= (tolerance * tolerance);
}

/**
 * Sets the given value to min
 * if the value is smaller than the given.
 * Don't use this with float values.
 *
 * @param value			Value
 * @param min			Min Value used as lower border
 * @return				Correct value not lower than min
 */
stock any Math_Min(any value, any min)
{
	if (value < min) {
		value = min;
	}

	return value;
}

/**
 * Sets the given value to max
 * if the value is greater than the given.
 * Don't use this with float values.
 *
 * @param value			Value
 * @param max			Max Value used as upper border
 * @return				Correct value not upper than max
 */
stock any Math_Max(any value, any max)
{
	if (value > max) {
		value = max;
	}

	return value;
}

/**
 * Makes sure a value is within a certain range and
 * returns the value.
 * If the value is outside the range it is set to either
 * min or max, if it is inside the range it will just return
 * the specified value.
 * Don't use this with float values.
 *
 * @param value			Value
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Correct value not lower than min and not greater than max.
 */
stock any Math_Clamp(any value, any min, any max)
{
	value = Math_Min(value, min);
	value = Math_Max(value, max);

	return value;
}

/*
 * Checks if the value is within the given bounds (min & max).
 * Don't use this with float values.
 *
 * @param value		The value you want to check.
 * @param min		The lower border.
 * @param max		The upper border.
 * @return			True if the value is within bounds (bigger or equal min / smaller or equal max), false otherwise.
 */
stock bool Math_IsInBounds(any value, any min, any max)
{
	if (value < min || value > max) {
		return false;
	}

	return true;
}

/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

/**
 * Returns a random, uniform Float number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Float number between min and max
 */
stock float Math_GetRandomFloat(float min, float max)
{
	return (GetURandomFloat() * (max  - min)) + min;
}

/**
 * Returns either true or false based on a random number
 *
 * @param chance    The chance of returning true [0-100]
 * @return     random TRUE or FALSE
 */
stock bool Math_RandomChance(int chance)
{
	return GetRandomInt(1, 100) <= chance;
}

/**
 * Checks if the current game mode is Mann Vs Machine
 *
 * @return		TRUE if the current game mode is Mann vs Machine, FALSE otherwise.
 */
bool IsMannVsMachine()
{
	return !!GameRules_GetPropEnt("m_bPlayingMannVsMachine");
}

/**
 * Spawns an oildrum
 *
 * @return		The oildrum entity reference
 */
int SpawnOilDrum(float origin[3])
{
	int drum = CreateEntityByName("prop_physics_multiplayer");
	
	if(drum == -1)
		return -1;

	TeleportEntity(drum, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(drum, "model", "models/props_c17/oildrum001_explosive.mdl");
	DispatchKeyValue(drum, "spawnflags", "8192"); // Force server side spawnflag
	DispatchKeyValue(drum, "disableshadows", "1");
	DispatchKeyValue(drum, "ExplodeDamage", "75");
	DispatchKeyValue(drum, "ExplodeRadius", "400");
	DispatchKeyValue(drum, "PerformanceMode", "1"); // Disable gibs
	DispatchKeyValue(drum, "physicsmode", "2"); // Non-Solid, Server-Side
	DispatchSpawn(drum);
	ActivateEntity(drum);

	return drum;
}

/**
 * Gets a position vector above a client
 *
 * @param client	The client to get the position from
 * @param distance	The distance above the client
 * @return     Position Vector
 */
float[] GetPositionAboveClient(int client,const float distance)
{
	float origin[3], clientangles[3], up[3];
	GetClientAbsAngles(client, clientangles);
	GetClientAbsOrigin(client, origin);
	GetAngleVectors(clientangles, NULL_VECTOR, NULL_VECTOR, up);
	ScaleVector(up, distance);
	float retvec[3];
	AddVectors(origin, up, retvec);
	return retvec;
}

/**
 * Checks if the given effect ID is valid
 *
 * @param effect	Effect ID
 * @return     TRUE if valid
 */
bool IsValidLuckEffect(const int effect)
{
	return effect > LUCK_EFFECT_NONE && effect < LUCK_EFFECT_MAX;
}

/**
 * Gets a luck effect display name
 *
 * @param effect		Effect ID
 * @param buffer		Char array to store the effect name
 * @param size			Char array size
 * @return		No return
 */
void GetEffectName(const int effect, char[] buffer, int size)
{
	switch(effect)
	{
		case LUCK_EFFECT_INVALID: strcopy(buffer, size, "Invalid");
		case LUCK_EFFECT_NONE: strcopy(buffer, size, "None");
		case LUCK_EFFECT_TFCOND: strcopy(buffer, size, "TF Condition");
		case LUCK_EFFECT_RANDOM_NAME: strcopy(buffer, size, "Random Name");
		case LUCK_EFFECT_WEAPON_DELETER: strcopy(buffer, size, "Weapon Deleter");
		case LUCK_EFFECT_HEALTH: strcopy(buffer, size, "Health Bonus");
		case LUCK_EFFECT_SOULSPHERE: strcopy(buffer, size, "Soul Sphere");
		case LUCK_EFFECT_OILDRUM_RAIN: strcopy(buffer, size, "Oil Drum Rain");
		case LUCK_EFFECT_CHAR_ATTRIBUTE: strcopy(buffer, size, "Character Attribute");
		case LUCK_EFFECT_WEAPON_ATTRIBUTE: strcopy(buffer, size, "Weapon Attribute");
		case LUCK_EFFECT_RANDOM_IMPULSE: strcopy(buffer, size, "Random Impulse");
		case LUCK_EFFECT_LAG: strcopy(buffer, size, "Lag");
		case LUCK_EFFECT_FORCE_MOVE: strcopy(buffer, size, "Force Move");
		case LUCK_EFFECT_FORCE_ATTACK: strcopy(buffer, size, "Force Attack");
		case LUCK_EFFECT_XY_SHIFT: strcopy(buffer, size, "XY Shift");
		case LUCK_EFFECT_MAX: strcopy(buffer, size, "Invalid (Max)");
		default: strcopy(buffer, size, "Invalid (Unknown)");
	}
}

/**
 * Gets the first available weapon entity via loop
 *
 * @param client		Client index
 * @return		Entity index
 */
int GetFirstWeaponViaLoop(int client)
{
	int entity = -1;

	for(int slot = 0;slot <= 5;slot++)
	{
		entity = TF2Util_GetPlayerLoadoutEntity(client, slot, true);
		if(IsValidEntity(entity))
		{
			return entity;
		}
	}

	return -1;
}

/**
 * Gets the entity index for the best weapon available for the given client and class
 *
 * @param client		Client index
 * @param class			Client's TF class
 * @return				Entity index or -1 on failure
 */
int GetBestWeaponEntity(int client, const TFClassType class)
{
	int entity = -1;

	switch(class)
	{
		case TFClass_Spy:
		{
			entity = TF2Util_GetPlayerLoadoutEntity(client, TFWeaponSlot_Melee, true); // For spy, try the knife first

			if(!IsValidEntity(entity))
			{
				entity = GetFirstWeaponViaLoop(client);
			}
		}
		default:
		{
			entity = GetFirstWeaponViaLoop(client);
		}
	}

	return entity;
}

/**
 * Forces the client to move forwards
 *
 * @param vel       Velocity vector
 * @param speed     Speed
 * @return     no return
 */
void MoveForward(float vel[3], float speed = 450.0)
{
	vel[0] = speed;
	vel[1] = 0.0;
	vel[2] = 0.0;
}

/**
 * Forces the client to move backwards
 *
 * @param vel       Velocity vector
 * @param speed     Speed
 * @return     no return
 */
void MoveBackwards(float vel[3], float speed = 450.0)
{
	vel[0] = -speed;
	vel[1] = 0.0;
	vel[2] = 0.0;
}

/**
 * Forces the client to move right
 *
 * @param vel       Velocity vector
 * @param speed     Speed
 * @return     no return
 */
void MoveRight(float vel[3], float speed = 450.0)
{
	vel[0] = 0.0;
	vel[1] = speed;
	vel[2] = 0.0;
}

/**
 * Forces the client to move left
 *
 * @param vel       Velocity vector
 * @param speed     Speed
 * @return     no return
 */
void MoveLeft(float vel[3], float speed = 450.0)
{
	vel[0] = 0.0;
	vel[1] = -speed;
	vel[2] = 0.0;
}
