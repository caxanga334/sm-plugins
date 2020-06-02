#if defined _geolanguage_included
  #endinput
#endif
#define _geolanguage_included

/**
 * Called when a client's language has been set.
 *
 * @param client	Client index.
 * @param language	Language number.
 * @noreturn
 */
forward GeoLang_OnLanguageChanged(int client,int language);


public SharedPlugin __pl_geolanguage = 
{
	name = "geolanguage",
	file = "geolanguage.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
