
// player globals
int g_ffdamage[MAXPLAYERS + 1];
float g_fftimer[MAXPLAYERS + 1];

methodmap Player
{
	public Player(int index)
	{
		return view_as<Player>(index);
	}

	public void Reset()
	{
		g_ffdamage[this.index] = 0;
		g_fftimer[this.index] = 0.0;
	}

	public bool IsValid()
	{
		if (this.index > 0 && this.index <= MaxClients)
		{
			return IsClientInGame(this.index);
		}

		return false;
	}

	public void OnFriendlyFireDamage(int damage)
	{
		if (g_fftimer[this.index] < GetGameTime())
		{
			g_ffdamage[this.index] = 0; // reset damage
		}

		g_ffdamage[this.index] += damage;
		g_fftimer[this.index] = GetGameTime() + g_cfg.ff_reset_time;
	}

	public int GetAccumulatedFriendlyFireDamage()
	{
		return g_ffdamage[this.index];
	}

	public void OnFriendlyFireActionTaken()
	{
		g_ffdamage[this.index] = 0;
		g_fftimer[this.index] = 0.0;
	}

	property int index
	{
		public get() { return view_as<int>(this); }
	}
}
