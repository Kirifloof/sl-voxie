list headprops = [ // [name, rest rotation, rot offset]
    "spine1l",
    <33.75000, 351.54999, 339.04999>,
    <24.0, -15.0, -7.0>,
    "spine1r",
    <33.75000, 8.39999, 20.95001>,
    <24.0, 15.0, 7.0>,
    "spine2l",
    <339.04999, 8.39999, 339.04999>,
    <-12.0, 0.0, -10.0>,
    "spine2r",
    <339.04999, 351.54999, 20.95001>,
    <-12.0, 0.0, 10.0>
];
integer lnBlush = -1;

// init data
Init() {
    integer numLinks = llGetNumberOfPrims();
    integer numItems = 4;
    integer i; integer j; string name;
    for (i = 1; i <= numLinks; i++) {
        name = llGetLinkName(i);
        for (j = 0; j < numItems; j++) {
            if (name == llList2String(headprops, j*3)) headprops = llListReplaceList(headprops, [i], j*3, j*3);
        }
        if (lnBlush == -1 && name == "blush") lnBlush = i;
    }
}

float lastExpression = 0;

SetSpineExpression(float amt) {
    if (amt != amt) return; // no change if not a number
    lastExpression = amt;
    if (amt > 0) amt = amt * 0.75; // adjust
    
    integer i;
    for (i = 0; i < 4; i++) {
        llSetLinkPrimitiveParamsFast(llList2Integer(headprops, i*3), [PRIM_ROT_LOCAL, llEuler2Rot((llList2Vector(headprops, 1+i*3) + ( llList2Vector(headprops, 2+i*3) * amt)) * DEG_TO_RAD)]);
    }
}
SetSpineExpressionRaw(float amt) {
    if (amt != amt) return; // no change if not a number
    if (amt > 0) amt = amt * 0.75; // adjust
    
    integer i;
    for (i = 0; i < 4; i++) {
        llSetLinkPrimitiveParamsFast(llList2Integer(headprops, i*3), [PRIM_ROT_LOCAL, llEuler2Rot((llList2Vector(headprops, 1+i*3) + ( llList2Vector(headprops, 2+i*3) * amt)) * DEG_TO_RAD)]);
    }
}
LerpSpineExpression(float amt) {
    float step = (amt - lastExpression) / 25.0;
    float c = lastExpression;
    integer i;
    for (i = 0; i < 24; i++) {
        c += step;
        SetSpineExpressionRaw(c);
    }
    SetSpineExpression(amt);
}

SetBlush(float amt) {
    if (amt != amt) return; // no change if not a number
    
    float startAlpha = llList2Float(llGetLinkPrimitiveParams(lnBlush, [PRIM_COLOR, 1]), 1);
    float endAlpha = amt * 0.36;
    float step = (endAlpha - startAlpha) / 75.0;
	llOwnerSay("step " + (string)step);
    float alpha = startAlpha;
    integer i;
    for (i = 0; i < 74; i++) {
        alpha += step;
        //llSetLinkPrimitiveParamsFast(lnBlush, [PRIM_COLOR, ALL_SIDES, <1, 0, 0>, alpha]);
        llSetLinkAlpha(lnBlush, alpha, ALL_SIDES);
    }
    //llSetLinkPrimitiveParamsFast(lnBlush, [PRIM_COLOR, ALL_SIDES, <1, 0, 0>, endAlpha]);
    llSetLinkAlpha(lnBlush, endAlpha, ALL_SIDES);
    
    //llSetLinkPrimitiveParamsFast(lnBlush, [PRIM_COLOR, ALL_SIDES, <1, 0, 0>, amt * 0.36]);
}

SetFaceState(integer mouth, integer eyes) {
    key owner = llGetOwner();
    if (mouth > -1) llRegionSayTo(owner, 42, "MouthState|0|" + (string)mouth);
    if (mouth > -1) llRegionSayTo(owner, 42, "EyelidState|0|" + (string)eyes);
}

SetAll(integer mouth, integer eyes, float spines, float blush) { SetFaceState(mouth, eyes); LerpSpineExpression(spines); SetBlush(blush); }

OnCommand(string cmd) {
    list tk = llParseString2List(cmd, [" "], []);
    SetAll((integer)llList2String(tk, 0), (integer)llList2String(tk, 1), (float)llList2String(tk, 2), (float)llList2String(tk, 3));
}

default
{
    state_entry()
    {
        Init();
        //
    }

    /*touch_start(integer total_number)
    {
        //
    }*/
    
    link_message(integer sender_num, integer num, string msg, key id) {
        if (num != -7993) return; // not a plugin message
        {
            list tk = llParseStringKeepNulls(msg, ["|"], []);
            if (llList2String(tk, 0) != "kobold") return;
            msg = llDumpList2String(llList2List(tk, 1, -1), "|");
            OnCommand(msg);
        }
        
    }
}
