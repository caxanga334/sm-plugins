
#if defined _stvmngr_included

public void SourceTV_OnStartRecording(int instance, const char[] filename)
{
	if (!cfg_SourceTV.enabled)
		return;

	SendMessage_OnSTVRecordingStart(filename);
}

#endif