////////////////
string defURL = "https://github.com/Kirifloof/sl-voxie/raw/master/dwaggietest.json";
////////////////

list aliasMood;
list aliasExpression;
list aliasEmote;

list dataExpressions;
list dataEmotes;

string stateMood;
string stateExpression;
string stateExpressionOvr;
key stateExpressionOvrKey;
string stateEmote;

list sequence;
list seqflags;
integer pc; // program counter

string GetCurrentExpression() {
    if (stateExpression == "") stateExpression = "idle"; // might as well go here
    if (stateExpressionOvr != "") return stateExpressionOvr;
    return stateExpression;
}

string ResolveAlias_Mood(string name) {
    integer f = llListFindList(aliasMood, [name]);
    if (f < 0) return name; // early out
    string cur;
    while (f > 0) {
        f--;
        cur = llList2String(aliasMood, f);
        if (llGetSubString(cur, 0, 0) == "|") return llGetSubString(cur, 1, -1);
    }
    return name; // malformed list, how did this happen?
}
string ResolveAlias_Expression(string name) {
    integer f = llListFindList(aliasExpression, [name]);
    if (f < 0) return name; // early out
    string cur;
    while (f > 0) {
        f--;
        cur = llList2String(aliasExpression, f);
        if (llGetSubString(cur, 0, 0) == "|") return llGetSubString(cur, 1, -1);
    }
    return name; // malformed list, how did this happen?
}
string ResolveAlias_Emote(string name) {
    integer f = llListFindList(aliasEmote, [name]);
    if (f < 0) return name; // early out
    string cur;
    while (f > 0) {
        f--;
        cur = llList2String(aliasEmote, f);
        if (llGetSubString(cur, 0, 0) == "|") return llGetSubString(cur, 1, -1);
    }
    return name; // malformed list, how did this happen?
}
string ResolveAlias(string name, integer type) {
    if (type == 2) return ResolveAlias_Mood(name);
    if (type == 1) return ResolveAlias_Emote(name);
    return ResolveAlias_Expression(name);
}
string ResolveStateName(string name, integer isEmote) {
    list tk = llParseString2List(name, ["."], []);
    if (llGetListLength(tk) > 1) {
        name = llList2String(tk, 0);
        string mood = llList2String(tk, 1);
        name = ResolveAlias(name, isEmote);
        mood = ResolveAlias(mood, 2);
        return name + "." + mood;
    }
    return ResolveAlias(name, isEmote);
}
string FindExpression(string name) {
    integer f = llListFindList(dataExpressions, [name]);
    if (f >= 0) return llList2String(dataExpressions, f+1);
    return "";
}
string FindEmote(string name) {
    integer f = llListFindList(dataEmotes, [name]);
    if (f >= 0) return llList2String(dataEmotes, f+1);
    return "";
}
string FindEntry(string name, integer isEmote) { if (isEmote) return FindEmote(name); return FindExpression(name); }

string GetState(string name, integer isEmote) {
    name = ResolveStateName(name, isEmote);
    
    //string res = FindEntry(name, isEmote);
    //if (res != "") return res;
    string res;
    { // tokenize
        list tk = llParseString2List(name, ["."], []);
        name = llList2String(tk, 0);
        
        if (llGetListLength(tk) > 1) {
            res = FindEntry(name + "." + llList2String(tk, 1), isEmote);
            if (res != "") return res;
        }
    }
    
    res = FindEntry(name + "." + stateMood, isEmote);
    if (res != "") return res;
    
    res = FindEntry(name, isEmote);
    if (res != "") return res;
    
    if (isEmote) return ""; // no "idle" emotes!
    
    res = FindEntry("idle." + stateMood, isEmote);
    if (res != "") return res;
    
    return FindEntry("idle", isEmote);
}

InitSequence(string seq) {
    pc = 0;
    sequence = llJson2List(seq);
	seqflags = [];
    llSetTimerEvent(0);
}
RunSequence() {
    integer pcl = llGetListLength(sequence);
    string cmd; list ct;
    for (; pc < pcl; pc++) {
        cmd = llList2String(sequence, pc);
        ct = llParseString2List(cmd, [" "], []);
        cmd = llToLower(llList2String(ct, 0));
        integer args = llGetListLength(ct) - 1;
        
        // commands
        if (FALSE) {integer blahblahblah = 0;} // alignment.
        
        else if (cmd == "sleep") {
            float min = (float)llList2String(ct, 1);
            float max = min;
            if (args > 1) max = (float)llList2String(ct, 2);
            llSetTimerEvent(min + llFrand(max - min));
            pc++; return; // yield
        }
        else if (cmd == "plugin") {
            // operate plugin
            string cmdOut = llList2String(ct, 1) + "|" + llDumpList2String(llList2List(ct, 2, -1), " ");
            llRegionSayTo(llGetOwner(), -7993, "vxp-plugin-" + cmdOut);
            llMessageLinked(LINK_SET, -7993, cmdOut, NULL_KEY);
        }
        else if (cmd == "sound") {
            // operate voxie!
        }
        else if (cmd == "expression") {
            // ...
        }
        else if (cmd == "mood") {
            // ...
        }
		else if (cmd == "{") {
			// conditional!
			string scmd = llToLower(llList2String(ct, 1));
			if (scmd == "if") {
				// rudimentary for now
				if (llListFindList(seqflags, [llList2String(ct, 2)]) == -1) {
					integer lv = 1;
					while (lv > 0) {
						pc++;
						if (pc >= llGetListLength(sequence)) jump afterSCmds; // bleh
						string token = llList2String(llParseString2List(llList2String(sequence, pc), [" "], []), 0);
						if (token == "{") lv++;
						else if (token == "}") lv--;
					}
				}
			}
		}
        else if (cmd == "debug") {
            llOwnerSay("/me [DEBUG] " + llDumpList2String(llList2List(ct, 1, -1), " "));
        }
    }
	@afterSCmds;
    // after emote end, step down
    if (stateEmote != "") {
        // step down... NYI
        stateEmote = "";
        InitSequence(GetState(GetCurrentExpression(), FALSE));
        RunSequence();
    }
    // else just let processes halt
}

OnCommand(string msg, key sender, integer fromOwner) {
    list arg = llParseString2List(msg, ["|"], []);
    if (llList2String(arg, 0) != "vxp") return; // not voxpressions!
    string cmd = llList2String(arg, 1);
    if (fromOwner) cmd = llStringTrim(cmd, STRING_TRIM_HEAD);
    arg = llList2List(arg, 2, -1);
    
    // commands
    if (FALSE) {} // alignment
    
    else if (cmd == "mood") {
        string new = llList2String(arg, 0);
        if (fromOwner) new = llStringTrim(new, STRING_TRIM_HEAD);
        if (new == "none") new = "";
        if (stateMood != new) {
            stateMood = new;
            if (llSubStringIndex(stateMood, ".") == -1) {
                InitSequence(GetState(GetCurrentExpression(), FALSE));
                RunSequence();
            }
        }
    }
    else if (cmd == "expression") {
        string new = llList2String(arg, 0);
        if (fromOwner) new = llStringTrim(new, STRING_TRIM_HEAD);
        if (new == "none") new = "idle";
        string old = GetCurrentExpression();
        stateExpression = new;
        if (new != old) {
            InitSequence(GetState(GetCurrentExpression(), FALSE));
            RunSequence();
        }
    }
    else if (cmd == "expression-override") {
        string new = llList2String(arg, 0);
        integer shouldStartNew = (new != GetCurrentExpression());
        stateExpressionOvr = new;
        stateExpressionOvrKey = sender;
        if (shouldStartNew) {
            InitSequence(GetState(GetCurrentExpression(), FALSE));
            RunSequence();
        }
    }
    else if (cmd == "expression-release") {
        if (stateExpressionOvrKey == sender) {
            integer shouldStartNew = (stateExpressionOvr != stateExpression);
            stateExpressionOvr = "";
            stateExpressionOvrKey = NULL_KEY;
            
            if (shouldStartNew) {
                InitSequence(GetState(GetCurrentExpression(), FALSE));
                RunSequence();
            }
        }
    }
    else if (cmd == "emote") {
        string new = llList2String(arg, 0);
        if (fromOwner) new = llStringTrim(new, STRING_TRIM_HEAD);
        stateEmote = new;
        string nstate = GetState(stateEmote, TRUE);
        if (nstate != "") {
            InitSequence(nstate);
            RunSequence();
        }
    }
    else if (cmd == "debug" && fromOwner) {
        llOwnerSay("/me [VXP] Mood: " + stateMood + "; Expression: " + stateExpression);
    }
    else if (cmd == "refresh" && fromOwner) {
        llOwnerSay("/me [VXP] Refreshing configuration");
        state loadConfig;
    }
}

default { // if you're here, you've just reset
    state_entry() {
        state loadConfig;
    }
}
state loadConfig { // for loading
    state_entry() {
        llSetTimerEvent(60);
        llHTTPRequest(defURL, [], ""); // request config
    }
    timer() {
        llHTTPRequest(defURL, [], "");
    }
    http_response(key request_id, integer status, list metadata, string body) {
        llSetTimerEvent(0);
        
        // clear out old settings
        aliasExpression = [];
        aliasEmote = [];
        aliasMood = [];
        
        integer i; integer t;
        
        { // parse aliases first
            list aliasDef;
            
            aliasDef = llJson2List(llJsonGetValue(body, ["aliases", "mood"]));
            t = llGetListLength(aliasDef) / 2;
            for (i = 0; i < t; i++) {
                aliasMood += ["|" + llList2String(aliasDef, i*2)];
                aliasMood += llJson2List(llList2String(aliasDef, 1+i*2));
            }
            
            aliasDef = llJson2List(llJsonGetValue(body, ["aliases", "expression"]));
            t = llGetListLength(aliasDef) / 2;
            for (i = 0; i < t; i++) {
                aliasExpression += ["|" + llList2String(aliasDef, i*2)];
                aliasExpression += llJson2List(llList2String(aliasDef, 1+i*2));
            }
            
            aliasDef = llJson2List(llJsonGetValue(body, ["aliases", "emote"]));
            t = llGetListLength(aliasDef) / 2;
            for (i = 0; i < t; i++) {
                aliasEmote += ["|" + llList2String(aliasDef, i*2)];
                aliasEmote += llJson2List(llList2String(aliasDef, 1+i*2));
            }
        }
        
        dataExpressions = llJson2List(llJsonGetValue(body, ["expressions"]));
        dataEmotes = llJson2List(llJsonGetValue(body, ["emotes"]));
        
        state main;
    }
}

state main {
    state_entry() {
        llListen(-7992, "", NULL_KEY, "");
        llListen(7992, "", llGetOwner(), "");
        
        stateEmote = "";
        stateExpressionOvr = "";
        stateExpression = "idle";
        
        InitSequence(GetState("idle", FALSE));
        RunSequence();
    }
    listen(integer channel, string name, key id, string message) {
        OnCommand(message, id, (channel == 7992));
    }
    timer() { llSetTimerEvent(0); RunSequence(); } // continue from sleep
}