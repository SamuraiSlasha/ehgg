public PlVers:__version =
{
	version = 5,
	filevers = "1.11.0.6825",
	date = "07/17/2022",
	time = "04:25:21"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[16];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_builtinvotes =
{
	name = "BuiltinVotes",
	file = "builtinvotes.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
new String:CTag[][48];
new String:CTagCode[8][48];
new bool:CTagReqSayText2[12] =
{
	0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0
};
new bool:CEventIsHooked;
new bool:CSkipList[66];
new bool:CProfile_Colors[12] =
{
	1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
new CProfile_TeamIndex[10] =
{
	-1, ...
};
new bool:CProfile_SayText2;
public SharedPlugin:__pl_readyup =
{
	name = "readyup",
	file = "readyup.smx",
	required = 0,
};
new g_iCurrentMode;
new g_iVotingMode;
new bool:g_bIsAdminVote;
new bool:g_bVoteUnderstood[66];
new Menu:g_hMenu;
new Handle:g_hVote;
public Plugin:myinfo =
{
	name = "Weapon Loadout",
	description = "Allows the Players to choose which weapons to play the mode in.",
	author = "Sir, A1m`",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action InitMenu()
{
	g_hMenu = Menu.Menu(53, 28);
	Menu.SetTitle(g_hMenu, "Hunters vs ???");
	Menu.AddItem(g_hMenu, "Pump Shotguns", "Pump Shotgun", 0);
	Menu.AddItem(g_hMenu, "Chrome Shotguns", "Chrome Shotgun", 0);
	Menu.AddItem(g_hMenu, "Uzis", "Uzi", 0);
	Menu.AddItem(g_hMenu, "Silenced Uzis", "Silenced Uzi", 0);
	Menu.AddItem(g_hMenu, "Scouts", "Scout", 0);
	Menu.AddItem(g_hMenu, "AWPs", "AWP", 0);
	Menu.AddItem(g_hMenu, "Grenade Launchers", "Grenade Launcher", 0);
	Menu.AddItem(g_hMenu, "Deagles", "Deagle", 0);
	Menu.AddItem(g_hMenu, "Military Sniper", "Military Sniper", 0);	
	Menu.AddItem(g_hMenu, "Hunting Rifle", "Hunting Rifle", 0);	
	Menu.ExitButton.set(g_hMenu, true);
	return Plugin_Handled;
}

public Action ShowMenu(int _arg0)
{
	if (IsInReady())
	{
		FakeClientCommand(_arg0, "sm_hide");
	}
	Menu.Display(g_hMenu, _arg0, 0);
	return Plugin_Handled;
}

ReadyPlayers()
{
	new iPlayersCount;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) > 1)
			{
				iPlayersCount++;
			}
		}
		i++;
	}
	return iPlayersCount;
}

public Action GiveSurvivorsWeapons(int _arg0, bool _arg1)
{
	decl String:sWeapon[1024];
	strcopy(sWeapon, 64, sGiveWeaponNames[g_iCurrentMode]);
	if (strlen(sWeapon) == 0)
	{
		LogError("Failed to get the name of the weapon! Current mode: %d", 9640);
		return Plugin_Handled;
	}
	if (_arg0 != 0)
	{
		GiveAndRemovePlayerWeapon(_arg0, sWeapon, _arg1);
		return Plugin_Handled;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		GiveAndRemovePlayerWeapon(i, sWeapon, _arg1);
		i++;
	}
	return Plugin_Handled;
}

public Action GiveAndRemovePlayerWeapon(int _arg0, const char[] _arg1, bool _arg2)
{
	if (IsClientInGame(_arg0))
	{
		if (!(GetClientTeam(_arg0) != 2))
		{
			if (IsPlayerAlive(_arg0))
			{
				new iCurrMainWeapon;
				new iCurrMainWeapon = GetPlayerWeaponSlot(_arg0, iCurrMainWeapon);
				new iCurrSecondaryWeapon = 1;
				new iCurrSecondaryWeapon = GetPlayerWeaponSlot(_arg0, iCurrSecondaryWeapon);
				if (iCurrMainWeapon != -1)
				{
					if (_arg2)
					{
						return Plugin_Handled;
					}
					RemovePlayerItem(_arg0, iCurrMainWeapon);
					KillEntity(iCurrMainWeapon);
				}
				if (iCurrSecondaryWeapon != -1)
				{
					RemovePlayerItem(_arg0, iCurrSecondaryWeapon);
					KillEntity(iCurrSecondaryWeapon);
				}
				GivePlayerItem(_arg0, _arg1, 0);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

public Action ReturnReadyUpPanel()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!(IsFakeClient(i)))
			{
				if (GetClientTeam(i) > 1)
				{
					FakeClientCommand(i, "sm_show");
				}
			}
		}
		i++;
	}
	return Plugin_Handled;
}

GetMaxPlayers()
{
	return ConVar.IntValue.get(FindConVar("z_max_player_zombies")) + ConVar.IntValue.get(FindConVar("survivor_limit"));
}

public bool InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound", 1, 0);
}

public Action KillEntity(int _arg0)
{
	RemoveEntity(_arg0);
	return Plugin_Handled;
}

public bool StrEqual(const char[] _arg0, const char[] _arg1, bool _arg2)
{
	return strcmp(_arg0, _arg1, _arg2) == 0;
}

Handle:StartMessageOne(const char[] _arg0, int _arg1, int _arg2)
{
	new players[1] = _arg1;
	return StartMessage(_arg0, players, 1, _arg2);
}

public bool GetEntityClassname(int _arg0, char[] _arg1, int _arg2)
{
	return !!GetEntPropString(_arg0, 1, "m_iClassname", _arg1, _arg2, 0);
}

public bool IsNewBuiltinVoteAllowed()
{
	new var1;
	return IsBuiltinVoteInProgress() || CheckBuiltinVoteDelay() != 0;
}

/* ERROR! null */
 function "CPrintToChat" (number 13)
void:CPrintToChatAll(String:_arg0[], any:_arg1)
{
	decl String:szBuffer[4000];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!(IsFakeClient(i)))
			{
				if (!CSkipList[i])
				{
					SetGlobalTransTarget(i);
					VFormat(szBuffer, 250, _arg0[0], 2);
					CPrintToChat(i, "%s", szBuffer);
				}
			}
		}
		CSkipList[i] = 0;
		i++;
	}
	return 0;
}

CFormat(String:_arg0[], _arg1, _arg2)
{
	decl String:szGameName[480];
	GetGameFolderName(szGameName, 30);
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", 43, 2);
		CEventIsHooked = true;
	}
	new iRandomPlayer = -1;
	if (StrEqual(szGameName, "csgo", false))
	{
		Format(_arg0[0], _arg1, " \x01\x0B\x01%s", _arg0[0]);
	}
	if (_arg2 != -1)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(_arg0[0], _arg1, "{teamcolor}", "\x03", false);
			iRandomPlayer = _arg2;
		}
		else
		{
			ReplaceString(_arg0[0], _arg1, "{teamcolor}", CTagCode[2], false);
		}
	}
	else
	{
		ReplaceString(_arg0[0], _arg1, "{teamcolor}", "", false);
	}
	new i;
	while (i < 12)
	{
		if (!(StrContains(_arg0[0], CTag[i], false) == -1))
		{
			if (CProfile_Colors[i])
			{
				if (CTagReqSayText2[i])
				{
					if (CProfile_SayText2)
					{
						if (iRandomPlayer == -1)
						{
							iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);
							if (iRandomPlayer == -2)
							{
								ReplaceString(_arg0[0], _arg1, CTag[i], CTagCode[2], false);
							}
							else
							{
								ReplaceString(_arg0[0], _arg1, CTag[i], CTagCode[i], false);
							}
						}
						ThrowError("Using two team colors in one message is not allowed");
					}
					ReplaceString(_arg0[0], _arg1, CTag[i], CTagCode[2], false);
				}
				ReplaceString(_arg0[0], _arg1, CTag[i], CTagCode[i], false);
			}
			ReplaceString(_arg0[0], _arg1, CTag[i], CTagCode[2], false);
		}
		i++;
	}
	return iRandomPlayer;
}

CFindRandomPlayerByTeam(_arg0)
{
	if (_arg0 == 0)
	{
		return 0;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (_arg0 == GetClientTeam(i))
			{
				return i;
			}
		}
		i++;
	}
	return -2;
}


/* ERROR! null */
 function "CSayText2" (number 17)
void:CSetupProfile()
{
	decl String:szGameName[480];
	GetGameFolderName(szGameName, 30);
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_Colors[5] = 1;
		CProfile_Colors[6] = 1;
		CProfile_TeamIndex[3] = 0;
		CProfile_TeamIndex[4] = 2;
		CProfile_TeamIndex[5] = 3;
		CProfile_SayText2 = true;
	}
	else
	{
		if (StrEqual(szGameName, "csgo", false))
		{
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_Colors[6] = 1;
			CProfile_Colors[1] = 1;
			CProfile_Colors[7] = 1;
			CProfile_Colors[8] = 1;
			CProfile_Colors[9] = 1;
			CProfile_Colors[10] = 1;
			CProfile_Colors[11] = 1;
			CProfile_TeamIndex[4] = 2;
			CProfile_TeamIndex[5] = 3;
			CProfile_SayText2 = true;
		}
		if (StrEqual(szGameName, "tf", false))
		{
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_Colors[6] = 1;
			CProfile_TeamIndex[3] = 0;
			CProfile_TeamIndex[4] = 2;
			CProfile_TeamIndex[5] = 3;
			CProfile_SayText2 = true;
		}
		if (!(StrEqual(szGameName, "left4dead", false)))
		{
			if (!(StrEqual(szGameName, "left4dead2", false)))
			{
				if (StrEqual(szGameName, "hl2mp", false))
				{
					if (GetConVarBool(FindConVar("mp_teamplay")))
					{
						CProfile_Colors[4] = 1;
						CProfile_Colors[5] = 1;
						CProfile_Colors[6] = 1;
						CProfile_TeamIndex[4] = 3;
						CProfile_TeamIndex[5] = 2;
						CProfile_SayText2 = true;
					}
					else
					{
						CProfile_SayText2 = false;
						CProfile_Colors[6] = 1;
					}
				}
				if (StrEqual(szGameName, "dod", false))
				{
					CProfile_Colors[6] = 1;
					CProfile_SayText2 = false;
				}
				if (GetUserMessageId("SayText2") == -1)
				{
					CProfile_SayText2 = false;
				}
				CProfile_Colors[4] = 1;
				CProfile_Colors[5] = 1;
				CProfile_TeamIndex[4] = 2;
				CProfile_TeamIndex[5] = 3;
				CProfile_SayText2 = true;
			}
		}
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_Colors[5] = 1;
		CProfile_Colors[6] = 1;
		CProfile_TeamIndex[3] = 0;
		CProfile_TeamIndex[4] = 3;
		CProfile_TeamIndex[5] = 2;
		CProfile_SayText2 = true;
	}
	return 0;
}

public void:BV_VoteActionHandler(Handle:_arg0, BuiltinVoteAction:_arg1, _arg2, _arg3)
{
	switch (_arg1)
	{
		case 2:
		{
			CloseHandle(_arg0);
			_arg0 = 0;
			g_hVote = 0;
		}
		case 8:
		{
			DisplayBuiltinVoteFail(_arg0, _arg2);
		}
		default:
		{
		}
	}
	return 0;
}

public void:BV_VoteResultHandler(Handle:_arg0, _arg1, _arg2, _arg3[][], _arg4, _arg5[][])
{
	ReturnReadyUpPanel();
	new i;
	while (i < _arg4)
	{
		if (_arg5[0][i] == 1)
		{
			if (_arg5[0][i][1] > _arg2 / 2)
			{
				if (!(IsInReady()))
				{
					if (g_iCurrentMode != 0)
					{
						if (!g_bIsAdminVote)
						{
							DisplayBuiltinVoteFail(_arg0, 3);
							CPrintToChatAll("{blue}[{green}Zone{blue}]{default}: Vote didn't pass before you left ready-up.");
							return 0;
						}
					}
				}
				g_bIsAdminVote = false;
				DisplayBuiltinVotePass(_arg0, "Survivor Weapons Set!");
				g_iCurrentMode = g_iVotingMode;
				GiveSurvivorsWeapons(0, false);
				return 0;
			}
		}
		i++;
	}
	g_bIsAdminVote = false;
	new i = 3;
	DisplayBuiltinVoteFail(_arg0, i);
	return 0;
}

public void:CEvent_MapStart(Event:_arg0, String:_arg1[], bool:_arg2)
{
	CSetupProfile();
	new i = 1;
	while (i <= MaxClients)
	{
		CSkipList[i] = 0;
		i++;
	}
	return 0;
}

public Action:Cmd_ForceVoteMode(_arg0, _arg1)
{
	if (_arg0 == 0)
	{
		return 3;
	}
	g_bVoteUnderstood[_arg0] = 1;
	if (IsNewBuiltinVoteAllowed())
	{
		ShowMenu(_arg0);
		return 3;
	}
	CPrintToChat(_arg0, "A vote cannot be called at this moment, try again in a second or five.");
	return 3;
}

public Action:Cmd_VoteMode(_arg0, _arg1)
{
	if (!(_arg0 == 0))
	{
		if (!(GetClientTeam(_arg0) < 2))
		{
			if (IsInReady())
			{
				if (!(InSecondHalfOfRound()))
				{
					g_bVoteUnderstood[_arg0] = 1;
					if (IsNewBuiltinVoteAllowed())
					{
						if (GetMaxPlayers() != ReadyPlayers())
						{
							CPrintToChat(_arg0, "{blue}[{green}Zone{blue}]{default}: Both teams need to be full.");
							return 3;
						}
						ShowMenu(_arg0);
						return 3;
					}
					CPrintToChat(_arg0, "A vote cannot be called at this moment, try again in a second or five.");
					return 3;
				}
			}
			CPrintToChat(_arg0, "{blue}[{green}Zone{blue}]{default}: You can only call for the vote during the first ready-up of a round");
			return 3;
		}
	}
	return 3;
}

public void:Event_PlayerTeam(Event:_arg0, String:_arg1[], bool:_arg2)
{
	if (g_iCurrentMode == 0)
	{
		return 0;
	}
	if (IsInReady())
	{
		new iTeam;

/* ERROR! unknown load SysReq */
 function "Event_PlayerTeam" (number 24)
public void:Event_RoundStart(Event:_arg0, String:_arg1[], bool:_arg2)
{
	CreateTimer(0.5, 61, 0, 2);
	if (g_iCurrentMode == 0)
	{
		CreateTimer(15.0, 65, 0, 1);
		return 0;
	}
	CreateTimer(2.0, 63, 0, 2);
	return 0;
}

public Menu_VoteMenuHandler(Menu:_arg0, MenuAction:_arg1, _arg2, _arg3)
{
	switch (_arg1)
	{
		case 4:
		{
			if (IsNewBuiltinVoteAllowed())
			{
				decl String:sInfo[512];
				decl String:sVoteTitle[1024];

/* ERROR! Can't print expression: Heap */
 function "Menu_VoteMenuHandler" (number 26)
public void:OnPluginStart()
{
	HookEvent("round_start", 51, 1);
	HookEvent("player_team", 49, 1);
	RegConsoleCmd("sm_mode", 47, "Opens the Voting menu", 0);
	RegAdminCmd("sm_forcemode", 45, 16384, "Forces the Voting menu", "", 0);
	InitMenu();
	return 0;
}

public void:OnRoundIsLive()
{
	Menu.Cancel(g_hMenu);
	return 0;
}

public Action:Timer_ChangeTeamDelay(Handle:_arg0, any:_arg1)
{
	new iPlayer = GetClientOfUserId(_arg1);
	if (iPlayer > 0)
	{
		if (GetClientTeam(iPlayer) == 2)
		{
			GiveSurvivorsWeapons(iPlayer, true);
		}
	}
	return 4;
}


/* ERROR! null */
 function "Timer_ClearMap" (number 30)
public Action:Timer_GiveWeapons(Handle:_arg0)
{
	GiveSurvivorsWeapons(0, false);
	return 4;
}

public Action:Timer_InformPlayers(Handle:_arg0)
{
	static iNumPrinted;
	if (iNumPrinted < 6)
	{
		if (!(g_iCurrentMode != 0))
		{
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) != 1)
					{
						if (!g_bVoteUnderstood[i])
						{
							CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Welcome to {blue}Zone{green}Hunters{default}.");
							CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Type {olive}!mode {default}in chat to vote on weapons used.");
						}
					}
				}
				i++;
			}
			iNumPrinted += 1;
			return 0;
		}
	}
	iNumPrinted = 0;
	return 4;
}

public void:__ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.BytesLeft.get");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadInt64");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetInt64");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddInt64");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return 0;
}

public void:__pl_readyup_SetNTVOptional()
{
	MarkNativeAsOptional("GetFooterStringAtIndex");
	MarkNativeAsOptional("FindIndexOfFooterString");
	MarkNativeAsOptional("EditFooterStringAtIndex");
	MarkNativeAsOptional("AddStringToReadyFooter");
	MarkNativeAsOptional("IsInReady");
	MarkNativeAsOptional("ToggleReadyPanel");
	return 0;
}

