// Attributes handler

#define CONST_MAX_CHAR_ATTRIBUTES 13 // Maximum number of char attributes listed
#define CONST_MAX_WEAPON_ATTRIBUTES 13 // Maximum number of weapon attributes listed

// Enum Struct with char attribute data
enum struct eCharAttributes
{
	char name[64]; // Attribute name
	float min; // Min Random Value
	float max; // Max Random Value
	TFClassType class; // Class limited attribute
}
eCharAttributes g_charattrib[CONST_MAX_CHAR_ATTRIBUTES];

// Enum Struct with weapon attribute data
enum struct eWeaponAttributes
{
	char name[64]; // Attribute name
	float min; // Min Random Value
	float max; // Max Random Value
	TFClassType class; // Class limited attribute
	int slot; // Only apply to a specific weapon slot
}
eWeaponAttributes g_weaponattrib[CONST_MAX_WEAPON_ATTRIBUTES];

// Initializes attribute data. TO-DO: Move this to a config file
void InitAttributes()
{
	// Character attributes
	g_charattrib[0].name = "move speed bonus";
	g_charattrib[0].min = 1.10;
	g_charattrib[0].max = 5.00;
	g_charattrib[0].class = TFClass_Unknown;

	g_charattrib[1].name = "health regen";
	g_charattrib[1].min = -1.00;
	g_charattrib[1].max = 100.0;
	g_charattrib[1].class = TFClass_Unknown;

	g_charattrib[2].name = "dmg taken from fire reduced";
	g_charattrib[2].min = 0.05;
	g_charattrib[2].max = 0.95;
	g_charattrib[2].class = TFClass_Unknown;

	g_charattrib[3].name = "dmg taken from blast reduced";
	g_charattrib[3].min = 0.05;
	g_charattrib[3].max = 0.95;
	g_charattrib[3].class = TFClass_Unknown;

	g_charattrib[4].name = "dmg taken from bullets reduced";
	g_charattrib[4].min = 0.05;
	g_charattrib[4].max = 0.95;
	g_charattrib[4].class = TFClass_Unknown;

	g_charattrib[5].name = "dmg taken from crit reduced";
	g_charattrib[5].min = 0.05;
	g_charattrib[5].max = 0.95;
	g_charattrib[5].class = TFClass_Unknown;

	g_charattrib[6].name = "dmg taken from fire increased";
	g_charattrib[6].min = 1.15;
	g_charattrib[6].max = 5.00;
	g_charattrib[6].class = TFClass_Unknown;

	g_charattrib[7].name = "dmg taken from blast increased";
	g_charattrib[7].min = 1.15;
	g_charattrib[7].max = 5.00;
	g_charattrib[7].class = TFClass_Unknown;

	g_charattrib[8].name = "dmg taken from bullets increased";
	g_charattrib[8].min = 1.15;
	g_charattrib[8].max = 5.00;
	g_charattrib[8].class = TFClass_Unknown;

	g_charattrib[9].name = "dmg taken from crit increased";
	g_charattrib[9].min = 1.15;
	g_charattrib[9].max = 5.00;
	g_charattrib[9].class = TFClass_Unknown;

	g_charattrib[10].name = "move speed penalty";
	g_charattrib[10].min = 0.25;
	g_charattrib[10].max = 0.85;
	g_charattrib[10].class = TFClass_Unknown;

	g_charattrib[11].name = "max health additive bonus";
	g_charattrib[11].min = 1.00;
	g_charattrib[11].max = 1000.0;
	g_charattrib[11].class = TFClass_Unknown;

	g_charattrib[12].name = "max health additive penalty";
	g_charattrib[12].min = -60.00;
	g_charattrib[12].max = -1.0;
	g_charattrib[12].class = TFClass_Unknown;

	// Weapon Attributes
	g_weaponattrib[0].name = "damage bonus";
	g_weaponattrib[0].min = 1.05;
	g_weaponattrib[0].max = 10.00;
	g_weaponattrib[0].class = TFClass_Unknown;
	g_weaponattrib[0].slot = -1;

	g_weaponattrib[1].name = "damage penalty";
	g_weaponattrib[1].min = -3.00;
	g_weaponattrib[1].max = 0.50;
	g_weaponattrib[1].class = TFClass_Unknown;
	g_weaponattrib[1].slot = -1;

	g_weaponattrib[2].name = "kill forces attacker to laugh";
	g_weaponattrib[2].min = 1.00;
	g_weaponattrib[2].max = 1.00;
	g_weaponattrib[2].class = TFClass_Unknown;
	g_weaponattrib[2].slot = -1;

	g_weaponattrib[3].name = "hit self on miss";
	g_weaponattrib[3].min = 1.00;
	g_weaponattrib[3].max = 1.00;
	g_weaponattrib[3].class = TFClass_Unknown;
	g_weaponattrib[3].slot = TFWeaponSlot_Melee;

	g_weaponattrib[4].name = "restore health on kill";
	g_weaponattrib[4].min = 1.00;
	g_weaponattrib[4].max = 100.00;
	g_weaponattrib[4].class = TFClass_Unknown;
	g_weaponattrib[4].slot = -1;

	g_weaponattrib[5].name = "no crit boost";
	g_weaponattrib[5].min = 1.00;
	g_weaponattrib[5].max = 1.00;
	g_weaponattrib[5].class = TFClass_Unknown;
	g_weaponattrib[5].slot = -1;

	g_weaponattrib[6].name = "critboost on kill";
	g_weaponattrib[6].min = 1.00;
	g_weaponattrib[6].max = 60.00;
	g_weaponattrib[6].class = TFClass_Unknown;
	g_weaponattrib[6].slot = -1;

	g_weaponattrib[7].name = "ammo regen";
	g_weaponattrib[7].min = 0.01;
	g_weaponattrib[7].max = 1.00;
	g_weaponattrib[7].class = TFClass_Unknown;
	g_weaponattrib[7].slot = -1;

	g_weaponattrib[8].name = "Reload time decreased";
	g_weaponattrib[8].min = -2.00;
	g_weaponattrib[8].max = 0.75;
	g_weaponattrib[8].class = TFClass_Unknown;
	g_weaponattrib[8].slot = -1;

	g_weaponattrib[9].name = "Reload time increased";
	g_weaponattrib[9].min = 1.25;
	g_weaponattrib[9].max = 10.00;
	g_weaponattrib[9].class = TFClass_Unknown;
	g_weaponattrib[9].slot = -1;

	g_weaponattrib[10].name = "bleeding duration";
	g_weaponattrib[10].min = 1.00;
	g_weaponattrib[10].max = 60.00;
	g_weaponattrib[10].class = TFClass_Unknown;
	g_weaponattrib[10].slot = -1;

	g_weaponattrib[11].name = "turn to gold";
	g_weaponattrib[11].min = 1.00;
	g_weaponattrib[11].max = 1.00;
	g_weaponattrib[11].class = TFClass_Unknown;
	g_weaponattrib[11].slot = -1;

	g_weaponattrib[12].name = "minicrits become crits";
	g_weaponattrib[12].min = 1.00;
	g_weaponattrib[12].max = 1.00;
	g_weaponattrib[12].class = TFClass_Unknown;
	g_weaponattrib[12].slot = -1;
}

/**
 * Retreives a random character attribute
 *
 * @param client        The client which the attribute will be applied to
 * @param name          Char buffer to store the attribute name
 * @param size          Char buffer size
 * @param min           The attribute min random value
 * @param max           The attribute max random value
 * @return              TRUE on success
 */
bool GetRandomCharAttribute(int client, char[] name, int size, float &min, float &max)
{
	TFClassType class = TF2_GetPlayerClass(client);

	int[] id = new int[CONST_MAX_CHAR_ATTRIBUTES];
	int counter = 0;

	for(int i = 0;i < CONST_MAX_CHAR_ATTRIBUTES;i++)
	{
		// Filter class
		if(g_charattrib[i].class != TFClass_Unknown && g_charattrib[i].class != class)
			continue;

		id[counter] = i;
		counter++;
	}

	if(counter == 0)
		return false;

	int y = id[Math_GetRandomInt(0, counter-1)];

	strcopy(name, size, g_charattrib[y].name);
	min = g_charattrib[y].min;
	max = g_charattrib[y].max;

	PrintToServer("GetRandomCharAttribute:: name: \"%s\" min: %.2f max: %.2f counter: %i id: %i", name, min, max, counter, y);

	return true;
}

/**
 * Retreives a random weapon attribute
 *
 * @param client        The client which the attribute will be applied to
 * @param name          Char buffer to store the attribute name
 * @param size          Char buffer size
 * @param min           The attribute min random value
 * @param max           The attribute max random value
 * @param slot          Weapon slot restriction
 * @return              TRUE on success
 */
bool GetRandomWeaponAttribute(int client, char[] name, int size, float &min, float &max, int &slot)
{
	TFClassType class = TF2_GetPlayerClass(client);

	int[] id = new int[CONST_MAX_CHAR_ATTRIBUTES];
	int counter = 0;

	for(int i = 0;i < CONST_MAX_CHAR_ATTRIBUTES;i++)
	{
		// Filter class
		if(g_weaponattrib[i].class != TFClass_Unknown && g_weaponattrib[i].class != class)
			continue;

		id[counter] = i;
		counter++;
	}

	if(counter == 0)
		return false;

	int y = id[Math_GetRandomInt(0, counter-1)];

	strcopy(name, size, g_weaponattrib[y].name);
	min = g_weaponattrib[y].min;
	max = g_weaponattrib[y].max;
	slot = g_weaponattrib[y].slot;

	PrintToServer("GetRandomWeaponAttribute:: name: \"%s\" min: %.2f max: %.2f counter: %i id: %i", name, min, max, counter, y);

	return true;
}