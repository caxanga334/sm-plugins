// Attributes handler
#define ATTRIBUTES_MAX_ITERATIONS 20
#define SLOT_RANDOM_WEAPON -1
#define SLOT_ACTIVE_WEAPON -2
#define ATTRIBUTE_NAME_SIZE 64
#define ATTRIBUTE_STRING_VALUE_SIZE 64

enum struct AttributeData_s
{
	char name[ATTRIBUTE_NAME_SIZE]; // Attribute name
	float min; // Minimum random value
	float max; // Maximum random value
	bool is_fixed; // uses fixed value
	float fixed_value; // fixed value
	bool is_string; // is string value
	char szval[ATTRIBUTE_STRING_VALUE_SIZE]; // string value
	int slot; // slot restriction if this is a weapon attribute
	TFClassType class; // class restriction

	// Constructs a "new" AttributeData instance
	void CTor()
	{
		this.name[0] = '\0';
		this.min = 0.0;
		this.max = 0.0;
		this.is_fixed = false;
		this.fixed_value = 0.0;
		this.is_string = false;
		this.szval[0] = '\0';
		this.slot = SLOT_RANDOM_WEAPON;
		this.class = TFClass_Unknown;
	}

	void AssignName(const char[] newname)
	{
		strcopy(this.name, sizeof(this.name), newname);
	}

	void AssignStringValue(const char[] value)
	{
		strcopy(this.szval, sizeof(this.szval), value);
	}

	bool IsClassAllowed(TFClassType other)
	{
		if (this.class != TFClass_Unknown && this.class != other)
		{
			return false;
		}

		return true;
	}

	bool IsFloatValue()
	{
		return !this.is_string;
	}

	bool IsStringValue()
	{
		return this.is_string;
	}

	bool IsRandomValue()
	{
		return !this.is_string && !this.is_fixed;
	}

	// Use this for fixed and random value types
	float GetValue()
	{
		if (this.is_fixed)
		{
			return this.fixed_value;
		}

		return Math_GetRandomFloat(this.min, this.max);
	}

	void GetStringValue(char[] value, int size)
	{
		strcopy(value, size, this.szval);
	}
	// See if the attribute is valid
	bool IsValid()
	{
		if (this.IsRandomValue())
		{
			if (this.min >= this.max)
			{
				return false;
			}
		}

		return true;
	}
}

static ArrayList s_charAttrib;
static ArrayList s_weapAttrib;
static bool s_attribParserValid;
static bool s_attribParserWeapon;
static bool s_attribParserPlayer;
static bool s_attribParserInAttribute;
static AttributeData_s s_attribParserData;
static int s_attribParserIndex;
static int s_attribParserLine;
static int s_attribParserCol;

static SMCResult AttributesParser_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	if (!s_attribParserValid)
	{
		if (strcmp(name, "Attributes", false) == 0)
		{
			s_attribParserValid = true;
			return SMCParse_Continue;
		}
		else
		{
			return SMCParse_HaltFail;
		}
	}

	if (s_attribParserInAttribute)
	{
		LogError("Invalid attribute file format!");
		return SMCParse_HaltFail;
	}

	if (s_attribParserPlayer || s_attribParserWeapon)
	{
		s_attribParserInAttribute = true;
		// begin new attribute
		s_attribParserData.CTor();

		// the section name is the attribute name
		s_attribParserData.AssignName(name);

		return SMCParse_Continue;
	}

	if (strcmp(name, "PlayerAttributes", false) == 0)
	{
		s_attribParserPlayer = true;
		s_attribParserIndex = 0;
		return SMCParse_Continue;
	}
	
	if (strcmp(name, "WeaponAttributes", false) == 0)
	{
		s_attribParserWeapon = true;
		s_attribParserIndex = 0;
		return SMCParse_Continue;
	}

	LogError("Attribute parser: Unknown section \"%s\"");
	return SMCParse_HaltFail;
}

static SMCResult AttributesParser_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (strcmp(key, "min_random_value", false) == 0)
	{
		s_attribParserData.min = StringToFloat(value);
	}
	else if (strcmp(key, "max_random_value", false) == 0)
	{
		s_attribParserData.max = StringToFloat(value);
	}
	else if (strcmp(key, "fixed_value", false) == 0)
	{
		s_attribParserData.is_fixed = true;
		s_attribParserData.fixed_value = StringToFloat(value);
	}
	else if (strcmp(key, "string_value", false) == 0)
	{
		s_attribParserData.is_string = true;
		s_attribParserData.AssignStringValue(value);
	}
	else if (strcmp(key, "slot", false) == 0)
	{
		if (s_attribParserPlayer)
		{
			LogError("Error: Player attribute with slot key value! line %i col %i", s_attribParserLine, s_attribParserCol);
			return SMCParse_Continue;
		}

		s_attribParserData.slot = StringToInt(value);
	}
	else if (strcmp(key, "class", false) == 0)
	{
		TFClassType class = TF2_GetClass(value);

		if (class == TFClass_Unknown)
		{
			LogError("Error: Unknown TF class \"%s\"! line %i col %i", value, s_attribParserLine, s_attribParserCol);
			return SMCParse_Continue;
		}

		s_attribParserData.class = class;
	}
	else
	{
		LogError("Attribute Parser: Unknown key value pair! %s %s", key, value);
	}

	return SMCParse_Continue;
}

static SMCResult AttributesParser_EndSection(SMCParser smc)
{
	if (s_attribParserInAttribute)
	{
		s_attribParserInAttribute = false;

		if (!s_attribParserData.IsValid())
		{
			LogError("Invalid attribute %s at line %i col %i", s_attribParserData.name, s_attribParserLine, s_attribParserCol);
			return SMCParse_Continue;
		}

		s_attribParserIndex++;
		
		if (s_attribParserPlayer)
		{
			s_charAttrib.PushArray(s_attribParserData, sizeof(s_attribParserData));
		}

		if (s_attribParserWeapon)
		{
			s_weapAttrib.PushArray(s_attribParserData, sizeof(s_attribParserData));
		}

		return SMCParse_Continue;
	}

	if (s_attribParserPlayer)
	{
		s_attribParserPlayer = false;
		return SMCParse_Continue;
	}

	if (s_attribParserWeapon)
	{
		s_attribParserWeapon = false;
		return SMCParse_Continue;
	}

	if (s_attribParserValid)
	{
		s_attribParserValid = false;
		return SMCParse_Continue;
	}

	return SMCParse_Continue;
}

void Attributes_Init()
{
	s_charAttrib = new ArrayList(sizeof(AttributeData_s));
	s_weapAttrib = new ArrayList(sizeof(AttributeData_s));

	Attributes_LoadConfig();

	if (s_charAttrib.Length == 0 && s_weapAttrib.Length == 0)
	{
		SetFailState("Must have at least one player and one weapon attribute!");
	}
}

static void Attributes_LoadConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/gpluck/attributes.cfg");

	if (!FileExists(path))
	{
		SetFailState("Faile to load attributes! File \"%s\" does not exists!", path);
		return;
	}

	s_attribParserValid = false;
	s_attribParserWeapon = false;
	s_attribParserPlayer = false;
	s_attribParserInAttribute = false;
	s_attribParserIndex = 0;

	SMCParser smc = new SMCParser();
	smc.OnEnterSection = AttributesParser_NewSection;
	smc.OnKeyValue = AttributesParser_KeyValue;
	smc.OnLeaveSection = AttributesParser_EndSection;

	SMCError error = smc.ParseFile(path, s_attribParserLine, s_attribParserCol);

	if (error != SMCError_Okay)
	{
		char szerror[64];
		SMC_GetErrorString(error, szerror, sizeof(szerror));
		delete smc;
		SetFailState("Error while parsing attribute config file! Error: \"%s\" line %i col %i", szerror, s_attribParserLine, s_attribParserCol);
		return;
	}

	PrintToServer("Loaded %i player and %i weapon attributes", s_charAttrib.Length, s_weapAttrib.Length);
	delete smc;
}

bool Attributes_GetRandomPlayerAttribute(int client, AttributeData_s attrib)
{
	TFClassType class = TF2_GetPlayerClass(client);
	int n = 0;
	int index = Math_GetRandomInt(0, s_charAttrib.Length - 1);

	do
	{
		n++;
		AttributeData_s data;
		s_charAttrib.GetArray(index, data, sizeof(AttributeData_s));

		if (++index >= s_charAttrib.Length)
		{
			index = 0;
		}

		if (!data.IsClassAllowed(class))
		{
			continue;
		}

		attrib = data;
		return true;
	}
	while (n <= ATTRIBUTES_MAX_ITERATIONS);

	return false;
}

int Attributes_SelectClientWeapon(int client, int slot)
{
	if (slot == SLOT_ACTIVE_WEAPON)
	{
		return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	}

	if (slot == SLOT_RANDOM_WEAPON)
	{
		int weapons[48];
		int n = 0;

		for (int s = 0; s <= view_as<int>(TFWeaponSlot_Item2); s++)
		{
			int entity = TF2Util_GetPlayerLoadoutEntity(client, s);

			if (entity != INVALID_ENT_REFERENCE)
			{
				weapons[n] = entity;
				n++;
			}

			if (n >= sizeof(weapons)) { break; }
		}

		if (n == 0) { return INVALID_ENT_REFERENCE; }

		return weapons[Math_GetRandomInt(0, n - 1)];
	}

	// specific slot
	return TF2Util_GetPlayerLoadoutEntity(client, slot);
}

bool Attributes_GetRandomWeaponAttribute(int client, AttributeData_s attrib)
{
	TFClassType class = TF2_GetPlayerClass(client);
	int n = 0;
	int index = Math_GetRandomInt(0, s_weapAttrib.Length - 1);

	do
	{
		n++;
		AttributeData_s data;
		s_weapAttrib.GetArray(index, data, sizeof(AttributeData_s));

		if (++index >= s_weapAttrib.Length)
		{
			index = 0;
		}

		if (!data.IsClassAllowed(class))
		{
			continue;
		}

		if (data.slot == SLOT_ACTIVE_WEAPON)
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == INVALID_ENT_REFERENCE)
			{
				continue;
			}
		}

		if (data.slot >= view_as<int>(TFWeaponSlot_Primary))
		{
			// specific slot, check if the player has an item on the slot
			if (TF2Util_GetPlayerLoadoutEntity(client, data.slot) == INVALID_ENT_REFERENCE)
			{
				continue;
			}
		}

		attrib = data;
		return true;
	}
	while (n <= ATTRIBUTES_MAX_ITERATIONS);

	return false;
}

void Attributes_ApplyAttribute(int entity, AttributeData_s attrib)
{
	if (attrib.IsStringValue())
	{
		TF2Attrib_SetFromStringValue(entity, attrib.name, attrib.szval);
	}
	else if (!attrib.IsRandomValue())
	{
		TF2Attrib_SetByName(entity, attrib.name, attrib.fixed_value);
	}
	else
	{
		float random = Math_GetRandomFloat(attrib.min, attrib.max);
		TF2Attrib_SetByName(entity, attrib.name, random);
	}
}