#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <geoip>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>

#define PLUGIN_NAME 	"GeoIP Language Selection"
#define PLUGIN_VERSION 	"1.3.1"

Handle g_hLangList = INVALID_HANDLE;
Handle g_hLangMenu = INVALID_HANDLE;
Handle g_hCookie = INVALID_HANDLE;
Handle g_OnLangChanged = INVALID_HANDLE;

bool g_bLoaded[MAXPLAYERS+1];
bool g_bUseCPrefs;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Automatically assign languages to players geographically",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_OnLangChanged = CreateGlobalForward("GeoLang_OnLanguageChanged", ET_Ignore, Param_Cell, Param_Cell);
	RegPluginLibrary("geolanguage");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Convars.
	ConVar hCvar = CreateConVar("sm_geolanguage_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hCvar, PLUGIN_VERSION);
	
	// Commands.
	RegConsoleCmd("sm_language", Command_Language);
	
	// Initialize language list and menu.
	Init_GeoLang();
	
	// Ignoring the unlikely event where clientprefs is late-(re)loaded.
	if (LibraryExists("clientprefs"))
	{
		g_hCookie = RegClientCookie("GeoLanguage", "The client's preferred language.", CookieAccess_Protected);
		SetCookieMenuItem(CookieMenu_GeoLanguage, 0, "Language");
		g_bUseCPrefs = true;
	}
}

void Init_GeoLang()
{
	// Parse KV file into trie of languages.
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/geolanguage.txt");
	
	Handle hKV = CreateKeyValues("GeoLanguage");
	
	if (!FileToKeyValues(hKV, sPath))
	{
		SetFailState("File missing: %s", sPath);
	}
	
	char sCCode[4], sLanguage[32];
	g_hLangList = CreateTrie();
	
	if (KvGotoFirstSubKey(hKV, false))
	{
		do
		{
			KvGetSectionName(hKV, sCCode, sizeof(sCCode));
			KvGetString(hKV, NULL_STRING, sLanguage, sizeof(sLanguage));
			
			SetTrieString(g_hLangList, sCCode, sLanguage);
			
		} while (KvGotoNextKey(hKV, false));
		
		KvGoBack(hKV);
	}
	
	CloseHandle(hKV);
	
	// Create and cache language selection menu.
	Handle hLangArray = CreateArray(32);
	char sLangID[4];
	
	int maxLangs = GetLanguageCount();
	for (int i = 0; i < maxLangs; i++)
	{
		GetLanguageInfo(i, _, _, sLanguage, sizeof(sLanguage));
		FormatLanguage(sLanguage);
		PushArrayString(hLangArray, sLanguage);
	}
	
	// Sort languages alphabetically.
	SortADTArray(hLangArray, Sort_Ascending, Sort_String);
	
	// Create and cache the menu.
	g_hLangMenu = CreateMenu(LanguageMenu_Handler, MenuAction_DrawItem);
	SetMenuTitle(g_hLangMenu, "Language:");
	
	maxLangs = GetArraySize(hLangArray);
	for (int i = 0; i < maxLangs; i++)
	{
		GetArrayString(hLangArray, i, sLanguage, sizeof(sLanguage));
		
		// Get language ID.
		IntToString(GetLanguageByName(sLanguage), sLangID, sizeof(sLangID));
		
		// Add to menu.
		AddMenuItem(g_hLangMenu, sLangID, sLanguage);
	}
	
	SetMenuExitButton(g_hLangMenu, true);
	
	CloseHandle(hLangArray);
}

void FormatLanguage(char[] language)
{
	// Format the input language.
	int length = strlen(language);
	
	if (length <= 1)
		return;
	
	// Capitalize first letter.
	language[0] = CharToUpper(language[0]);
	
	// Lower case the rest.
	for (int i = 1; i < length; i++)
	{
		language[i] = CharToLower(language[i]);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
	
	if (g_bUseCPrefs)
	{
		// If they aren't cached yet then we'll catch them on the cookie forward.
		if (AreClientCookiesCached(client) && !g_bLoaded[client])
		{
			LoadCookies(client);
		}
	}
	else if (GetClientLanguage(client) == 0)
	{
		// CPrefs disabled. Set language without displaying help text.
		SetClientLanguageByGeoIP(client);
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	// If they aren't in-game yet then we'll catch them on the PutInServer forward.
	if (IsClientInGame(client) && !g_bLoaded[client])
	{
		LoadCookies(client);
	}
}

public void OnClientDisconnect(int client)
{
	g_bLoaded[client] = false;
}

public Action Command_Language(int client,int args)
{
	/* The language command has been invoked. */
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command is for players only.");
		return Plugin_Handled;
	}
	
	// Usage: sm_language
	if (args < 1)
	{
		DisplayMenu(g_hLangMenu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	
	// Usage: sm_language <name>
	char sLanguage[32], sLangCode[4];
	GetCmdArg(1, sLanguage, sizeof(sLanguage));
	int iLangID = GetLanguageByName(sLanguage);
	
	if (iLangID < 0)
	{
		ReplyToCommand(client, "[SM] Language not found: %s", sLanguage);
		return Plugin_Handled;
	}
	
	GetLanguageInfo(iLangID, sLangCode, sizeof(sLangCode), sLanguage, sizeof(sLanguage));
	SetClientLanguage2(client, iLangID);
	
	if (g_bUseCPrefs)
	{
		SetClientCookie(client, g_hCookie, sLangCode);
	}
	
	FormatLanguage(sLanguage);
	ReplyToCommand(client, "[SM] Language changed to \"%s\".", sLanguage);
	
	return Plugin_Handled;
}

public Action Timer_LanguageHelp(Handle timer, any userid)
{
	/* Tell the client that their language has been automatically set. */
	int client = GetClientOfUserId(userid);
	
	if (client == 0)
		return Plugin_Stop;
	
	char sLanguage[32];
	GetLanguageInfo(GetClientLanguage(client), _, _, sLanguage, sizeof(sLanguage));
	
	FormatLanguage(sLanguage);
	PrintToChat(client, "[SM] Your language has been set to \"%s\". Type !language to change your language.", sLanguage);
	
	return Plugin_Stop;
}

public int CookieMenu_GeoLanguage(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	/* Menu when accessed through !settings. */
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Language");
		}
		case CookieMenuAction_SelectOption:
		{
			DisplayMenu(g_hLangMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public int LanguageMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	/* Handle the language selection menu. */
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			// Disable selection for currently used language.
			char sLangID[4];
			GetMenuItem(menu, param2, sLangID, sizeof(sLangID));
			
			if (StringToInt(sLangID) == GetClientLanguage(param1))
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			char sLangID[4], sLanguage[32];
			GetMenuItem(menu, param2, sLangID, sizeof(sLangID), _, sLanguage, sizeof(sLanguage));
			
			int iLangID = StringToInt(sLangID);
			SetClientLanguage2(param1, iLangID);
			
			if (g_bUseCPrefs)
			{
				char sLangCode[6];
				GetLanguageInfo(iLangID, sLangCode, sizeof(sLangCode));
				SetClientCookie(param1, g_hCookie, sLangCode);
			}
			
			PrintToChat(param1, "[SM] Language changed to \"%s\".", sLanguage);
		}
	}
	
	return 0;
}

void LoadCookies(int client)
{
	/* Load the language selection data for this client. */
	char sCookie[4];
	sCookie[0] = '\0';
	
	GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));
	
	if (sCookie[0] != '\0')
	{
		// Set the saved preference.
		SetClientLanguageByCode(client, sCookie);
	}
	else if (GetClientLanguage(client) == 0)
	{
		// Only act on clients that haven't changed Steam's default language.
		SetClientLanguageByGeoIP(client);
		
		CreateTimer(15.0, Timer_LanguageHelp, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_bLoaded[client] = true;
}

void SetClientLanguageByCode(int client, const char[] code)
{
	/* Set a client's language based on the language code. */
	int iLangID = GetLanguageByCode(code);
	
	if (iLangID >= 0)
	{
		SetClientLanguage2(client, iLangID);
	}
}

void SetClientLanguageByGeoIP(int client)
{
	/* Set a client's language relative to their country. */
	char ip[17], ccode[4];
	
	if (!GetClientIP(client, ip, sizeof(ip)))
		return;
	
	if (!GeoipCode3(ip, ccode))
		return;
	
	int iLangID = GetLanguageByGeoIP(ccode);
	SetClientLanguage2(client, iLangID);
}

int GetLanguageByGeoIP(const char[] ccode)
{
	/*
	* Retrieve the most popular language spoken in a given country.
	*
	* Defaults to English (0) if the language doesn't exist in languages.cfg
	* or if there is a problem retrieving the language.
	*/
	char sLanguage[32];
	
	if (GetTrieString(g_hLangList, ccode, sLanguage, sizeof(sLanguage)))
	{
		int iLangID = GetLanguageByName(sLanguage);
		
		if (iLangID >= 0)
			return iLangID;
	}
	
	return 0;
}

void SetClientLanguage2(int client,int language)
{
	// Set language.
	SetClientLanguage(client, language);
	
	// forward GeoLang_OnLanguageChanged(client, language);
	Call_StartForward(g_OnLangChanged);
	Call_PushCell(client);
	Call_PushCell(language);
	Call_Finish();
}
