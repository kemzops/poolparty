#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "[PoolParty] Core"
#define PLUGIN_DESCRIPTION  "PoolParty CS:S Server core plugin."
#define PLUGIN_VERSION      "0.1"
#define PREFIX              "{green}[PoolParty]"

/* GLOBALS */
bool boughtHE[MAXPLAYERS + 1];
bool boughtSmoke[MAXPLAYERS + 1];
int usedWeaponCommand[MAXPLAYERS + 1];
int collisionGroup;
float roundStartTime;

public Plugin myinfo = {
    name = PLUGIN_NAME,
    author = "kemzops",
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "https://github.com/kemzops/poolparty"
};

public void OnPluginStart() {
    /* MULTICOLORS PREFIX */
    CSetPrefix(PREFIX);

    collisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

    /* CONSOLE/CHAT COMMANDS */
    RegConsoleCmd("resetscore", CommandResetScore, "Reset the client score.");
    RegConsoleCmd("rs", CommandResetScore, "Reset the client score.");

    /* COMMAND LISTNER */
    AddCommandListener(CommandSay, "say");
    AddCommandListener(CommandSay, "say_team"); // https://sm.alliedmods.net/new-api/console/OnClientSayCommand

    /* EVENTS HOOKS */
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
}

public void OnMapStart() {
    ClientReset();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    RoundMoney();
    ClientReset();
    roundStartTime = GetGameTime();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    // EMPTY FOR NOW ^^
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    SetEntData(client, collisionGroup, 2, 4, true);
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {
    if (strcmp(classname, "smokegrenade_projectile") == 0) {
        SetEntData(entity, collisionGroup, 2, 4, true); // NO BLOCK SMOKE ;D
    }
}

/* COMMANDS */
public Action CommandSay(int client, const char[] command, int args) {
    if (!IsClientInGame(client))
        return Plugin_Continue;

    char msg[192];
    GetCmdArgString(msg, sizeof(msg));
    StripQuotes(msg);

    if (msg[0] != '!' && msg[0] != '/')
        return Plugin_Continue;

    char cmd[192];
    strcopy(cmd, sizeof(cmd), msg[1]); // copy everything after first character (to skip ! & /)

    /* WEAPONS COMMANDS SECTION */
    if (strcmp(cmd, "ak") == 0) {
        WeaponsCommands(client, "weapon_ak47", 0);
    } else if (strcmp(cmd, "m4") == 0 || strcmp(cmd, "m4a1") == 0) {
        WeaponsCommands(client, "weapon_m4a1", 0);
    } else if (strcmp(cmd, "tmp") == 0) {
        WeaponsCommands(client, "weapon_tmp", 0);
    } else if (strcmp(cmd, "galil") == 0) {
        WeaponsCommands(client, "weapon_galil", 0);
    } else if (strcmp(cmd, "famas") == 0) {
        WeaponsCommands(client, "weapon_famas", 0);
    } else if (strcmp(cmd, "mac10") == 0) {
        WeaponsCommands(client, "weapon_mac10", 0);
    } else if (strcmp(cmd, "elite") == 0) {
        WeaponsCommands(client, "weapon_elite", 1);
    } else if (strcmp(cmd, "fn57") == 0) {
        WeaponsCommands(client, "weapon_fiveseven", 1);
    } else if (strcmp(cmd, "xm") == 0) {
        WeaponsCommands(client, "weapon_xm1014", 0); // for wizex ;)
    }

    /* TEAM SWITCH COMMANDS */
    else if (strcmp(cmd, "spec") == 0 || strcmp(cmd, "spectate") == 0 || strcmp(cmd, "away") == 0 || strcmp(cmd, "afk") == 0) {
        ChangeTeam(client, 1); // 1 = Spectator
    } else if (strcmp(cmd, "ct") == 0 || strcmp(cmd, "counterterrorist") == 0) {
        ChangeTeam(client, 3); // 3 = Counter-Terrorist
    } else if (strcmp(cmd, "t") == 0 || strcmp(cmd, "terrorist") == 0) {
        ChangeTeam(client, 2); // 2 = Terrorist
    } else {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

public void ChangeTeam(int client, int team) {
    if (!IsClientInGame(client))
        return;

    int currentTeam = GetClientTeam(client);
    if (team == currentTeam) {
        CPrintToChat(client, "{red}You are already on this team.");
        return;
    }

    if (IsPlayerAlive(client))
        ForcePlayerSuicide(client);

    ChangeClientTeam(client, team);
    switch (team) {
        case 1:
            CPrintToChat(client, "{green}You have been moved to {lightgreen}Spectator{green} team.");
        case 2:
            CPrintToChat(client, "{green}You have been moved to {red}Terrorist{green} team.");
        case 3:
            CPrintToChat(client, "{green}You have been moved to {blue}Counter-Terrorist{green} team.");
    }
}

public void WeaponsCommands(int client, const char[] weaponName, int slot) {
    if(!IsPlayerAlive(client))
        return;

    if (usedWeaponCommand[client] >= 2) {
        CPrintToChat(client, "{red}Twice per round limit.");
        return;
    }

    float currentTime = GetGameTime();
    if (currentTime - roundStartTime > 15.0) {
        CPrintToChat(client, "{red}Too late, 15s limit.");
        return;
    }

    ReplaceWeapon(client, weaponName, slot);
}

public Action CS_OnBuyCommand(int client, const char[] weapon) {

    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (strcmp(weapon, "hegrenade") == 0) {
        if (boughtHE[client]) {
            return Plugin_Handled;
        }
        boughtHE[client] = true;
    } else if(strcmp(weapon, "smokegrenade") == 0) {
        if (boughtSmoke[client]) {
            return Plugin_Handled;
        }
        boughtSmoke[client] = true;
    }

    return Plugin_Continue;
}

public Action CommandResetScore(int client, int args) {
    if (IsClientInGame(client)) {
        if (GetClientDeaths(client) == 0 && GetClientFrags(client) == 0) {
            CPrintToChat(client, "{red}Your score is already 0.");
            return Plugin_Handled;
        }

        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));

        SetEntProp(client, Prop_Data, "m_iFrags", 0);
        SetEntProp(client, Prop_Data, "m_iDeaths", 0);
        CS_SetMVPCount(client, 0);

        int team = GetClientTeam(client);
        if (team == 2) {
            CPrintToChatAll("%s {red}%s{default} has reset their score.", PREFIX, name);
        } else if (team == 3) {
            CPrintToChatAll("%s {blue}%s{default} has reset their score.", PREFIX, name);
        } else {
            CPrintToChatAll("%s {lightgreen}%s{default} has reset their score.", PREFIX, name);
        }
    }
    return Plugin_Handled;
}

/* HELPERS */
public void ReplaceWeapon(int client, const char[] weaponName, int slot) {
    int currentWeapon = GetPlayerWeaponSlot(client, slot);
    if (currentWeapon != -1) RemovePlayerItem(client, currentWeapon);
    GivePlayerItem(client, weaponName);
    usedWeaponCommand[client]++;
    CPrintToChat(client, "{default} You received: %s!", weaponName);
}

public void ClientReset() {
    for (int client = 1; client <= MaxClients; client++) {
        boughtHE[client] = false;
        boughtSmoke[client] = false;
        usedWeaponCommand[client] = 0;
    }
}

public void RoundMoney() {
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            SetEntProp(client, Prop_Send, "m_iAccount", 16000);
        }
    }
}
