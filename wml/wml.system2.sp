/*
 * Gets called when response is received.
 */
public System2_OnGetPage(const String:output[], const size, CMDReturn:status, any:data)
{
	// Get associated ID
	decl String:id[MAX_ID_LEN];
	ResetPack(data);
	ReadPackString(data, id, sizeof(id));
	
	if (status == CMD_ERROR)
	{
		LogError("Steam API error: couldn't fetch data for file ID %s", id);
		CloseHandle(data);
		return;
	}
	
	// Create temporary directory
	decl String:path[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, path, sizeof(path), "%s", WML_TMP_DIR);
	if (!DirExists(path))
		CreateDirectory(path, 511);
	
	// Create Kv file
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.txt", WML_TMP_DIR, id);
	new Handle:file = OpenFile(path, "a+t");
	if (file == INVALID_HANDLE)
	{
		LogError("Couldn't create temporary file %s", path);
		CloseHandle(data);
		return;
	}
	
	// Interpret response status
	switch (status)
	{
		case CMD_PROGRESS:
		{
			LogMessage("Successfully received a part for file ID %s", id);
			WriteFileString(file, output, false);
			CloseHandle(file);
		}
		case CMD_SUCCESS:
		{
			CloseHandle(data);
			LogMessage("Successfully received file details for ID %s", id);
			WriteFileString(file, output, false);
			CloseHandle(file);
			
			// Begin parse response
			new Handle:kv = CreateKeyValues("response");
			if(kv != INVALID_HANDLE)
			{
				if (FileToKeyValues(kv, path))
				{
					BrowseKeyValues(kv, id);
					CloseHandle(kv);
					// Once the map has been tagged, it's origin may be purged
					DB_RemoveUntagged(StringToInt(id));
				}
				else
					LogError("Couldn't open KeyValues for file ID %s", id);
			}
			
			// Delete (temporary) Kv file
			DeleteFile(path);
		}
		default:
			CloseHandle(file);
	}
}