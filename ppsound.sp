#include <sourcemod>
#include <sdktools>
#include <lvl_ranks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME        "[PoolParty] Sound"
#define PLUGIN_DESCRIPTION "PoolParty CS:S Server sound plugin"

char SOUND_HEADSHOT[] = "poolparty/pphead.wav";
char SOUND_KNIFE[]    = "poolparty/ppknife.wav";
char SOUND_NADE[]     = "poolparty/ppnade.wav";
char SOUND_NADE2[]    = "poolparty/ppnade2.wav";
char SOUND_HAX[]      = "poolparty/pphax.wav";

int playerSelectedNadeSound[MAXPLAYERS + 1];

public Plugin myinfo = {
    name = PLUGIN_NAME,
    author = "kemzops",
    description = PLUGIN_DESCRIPTION,
    version = "1.8",
    url = "https://github.com/kemzops/poolparty"
};

public void OnPluginStart() {
    PrecacheAllSounds();

    CSetPrefix("{green}[PoolParty]");

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

    RegAdminCmd("sm_hax", Command_HAX, ADMFLAG_GENERIC, "PPHAX sound.");
    RegConsoleCmd("sm_ppsound", Command_ShowSoundMenu);
}

public void OnMapStart() {
    PrecacheAllSounds();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    float pos[3];
    GetClientAbsOrigin(victim, pos);

    bool headshot = event.GetBool("headshot");
    if (headshot) {
        float volume = GetRandomFloat(0.90, SNDVOL_NORMAL);
        int pitch = GetRandomInt(SNDPITCH_LOW, SNDPITCH_HIGH);
        EmitAmbientSound(SOUND_HEADSHOT, pos, -1, SNDLEVEL_GUNFIRE, SND_NOFLAGS, volume, pitch, 0.0);
    }

    if (attacker != victim) {
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));
        if (StrEqual(weapon, "knife", false)) {
            EmitAmbientSound(SOUND_KNIFE, pos, -1, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, 0.0);
        } else if (StrEqual(weapon, "hegrenade", false)) {
            PlaySelectedNadeSound(attacker);
        }
    }
}


public Action Command_HAX(int client, int args) {
    if (!IsClientInGame(client)) return Plugin_Handled;
    PlaySoundToAll(SOUND_HAX, 1.0);
    return Plugin_Handled;
}

public Action Command_ShowSoundMenu(int client, int args) {
    if (!IsClientInGame(client)) return Plugin_Handled;

    Menu menu = new Menu(SoundMenuHandler);
    menu.SetTitle("[PPSOUND] Select your Nade Sound");
    menu.AddItem("ppnade", "Owned (default)");
    menu.AddItem("ppnade2", "Perfect (1000+ EXP)");
    menu.ExitButton = true;
    menu.Display(client, 20);

    return Plugin_Handled;
}

public int SoundMenuHandler(Menu menu, MenuAction action, int client, int selection) {
    if (action == MenuAction_Select) {
        char sound[32];
        bool found = menu.GetItem(selection, sound, sizeof(sound));
        if (!found) return Plugin_Handled;

        if (StrEqual(sound, "ppnade2", false)) {
            int exp = LR_GetClientInfo(client, ST_EXP);
            if (exp >= 1000) {
                playerSelectedNadeSound[client] = 2;
                CPrintToChat(client, "{default}You selected ppnade2.wav.");
                EmitSoundToClient(client, SOUND_NADE2, _, _, _, _, 1.0);
                return Plugin_Handled;
            } else {
                CPrintToChat(client, "{default}You need 1000+ EXP to select ppnade2.wav.");
            }
        } else {  // Default sound (ppnade)
            playerSelectedNadeSound[client] = 1;
            CPrintToChat(client, "{default}You selected ppnade.wav.");
            EmitSoundToClient(client, SOUND_NADE, _, _, _, _, 1.0);
        }
    } else if (action == MenuAction_Cancel) {
        CPrintToChat(client, "{default}You cancelled the menu.");
    } else if (action == MenuAction_End) {
        delete menu;
    }

    return Plugin_Handled;
}


void PrecacheAllSounds() {
    PrecacheSound(SOUND_HEADSHOT, true);
    PrecacheSound(SOUND_KNIFE, true);
    PrecacheSound(SOUND_NADE, true);
    PrecacheSound(SOUND_NADE2, true);
    PrecacheSound(SOUND_HAX, true);

    AddFileToDownloadsTable("sound/poolparty/pphead.wav");
    AddFileToDownloadsTable("sound/poolparty/ppknife.wav");
    AddFileToDownloadsTable("sound/poolparty/ppnade.wav");
    AddFileToDownloadsTable("sound/poolparty/ppnade2.wav");
    AddFileToDownloadsTable("sound/poolparty/pphax.wav");
}

void PlaySelectedNadeSound(int client) {
    if (playerSelectedNadeSound[client] == 2) {
        PlaySoundToAll(SOUND_NADE2, 1.0);
        return;
    }

    PlaySoundToAll(SOUND_NADE, 1.0);
}

void PlaySoundToAll(const char[] soundPath, float volume = 1.0) {
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            EmitSoundToClient(client, soundPath, _, _, _, _, volume);
        }
    }
}
