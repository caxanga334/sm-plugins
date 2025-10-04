// Trace functions

// **** TRACE FILTERS ****

// Only world is solid
bool TraceFilter_SolidWorld(int entity, int contentsMask, any data)
{
	if(entity == data)
		return false;

	if(entity == 0) // Worldspawn
		return true;

	return false;
}

// **** TRACERS ****

/**
 * Fires a tracer to get the distance between the client's head and the ceiling
 *
 * @param client    The client to check the distance
 * @return          Distance as a float
 */
float GetDistanceToCeiling(int client)
{
	float origin[3], maxs[3], end[3];
	float distance = 0.0;
	static const float angles[3] = { 270.0, 0.0, 0.0 };
	Handle tr = null;
	GetClientAbsOrigin(client, origin);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	
	origin[2] += maxs[2];
	tr = TR_TraceRayFilterEx(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_SolidWorld, client);

	if(TR_DidHit(tr))
	{
		TR_GetEndPosition(end, tr);
		distance = GetVectorDistance(origin, end, true);
	}

	delete tr;
	return distance;
}
