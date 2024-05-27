
#if defined _stvmngr_included

public void SourceTV_OnStartRecording(int instance, const char[] filename)
{
	SendMessage_OnSTVRecordingStart(filename);
}

#endif