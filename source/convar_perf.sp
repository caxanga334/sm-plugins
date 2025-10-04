#include <sourcemod>
#include <profiler>

ConVar plugin_cvar = null;
#define ITERATIONS 1000

public void OnPluginStart()
{
	plugin_cvar = CreateConVar("sm_my_plugin_var", "1.0");
}

public void OnMapStart()
{
	float cached_value = plugin_cvar.FloatValue;
	float foo = 0.0;

	Profiler timer1 = new Profiler();
	Profiler timer2 = new Profiler();
	Profiler timer3 = new Profiler();

	timer1.Start();

	for (int i = 0; i < ITERATIONS; i++)
	{
		foo += plugin_cvar.FloatValue;
	}

	timer1.Stop();
	timer2.Start();

	for (int i = 0; i < ITERATIONS; i++)
	{
		ConVar cvar = FindConVar("sm_my_plugin_var");
		foo += cvar.FloatValue;
	}

	timer2.Stop();
	timer3.Start();

	for (int i = 0; i < ITERATIONS; i++)
	{
		foo += cached_value;
	}

	timer3.Stop();

	LogMessage("Cached ConVar: %f", timer1.Time);
	LogMessage("FindConVar: %f", timer2.Time);
	LogMessage("Variable: %f", timer3.Time);

	// shut up the compiler
	PrintToServer("%f", foo);

	delete timer1;
	delete timer2;
	delete timer3;
}