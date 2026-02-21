_player = _this select 0;

waitUntil {!isNil "bulwarkBox"};
["Terminate"] call BIS_fnc_EGSpectator;
_player setVariable ["buildItemHeld", false];

private _fallDamageEnabled = (["PLAYER_FALLDAMAGE", 0] call BIS_fnc_getParamValue) == 1;
missionNamespace setVariable ["DB_fallDamageEnabled", _fallDamageEnabled];

// Read mission params locally (robust for JIP / timing)
private _startWeapon = (["PLAYER_STARTWEAPON", 1] call BIS_fnc_getParamValue) == 1;
private _startMap    = (["PLAYER_STARTMAP",    1] call BIS_fnc_getParamValue) == 1;
private _startNVG    = (["PLAYER_STARTNVG",    1] call BIS_fnc_getParamValue) == 1;

// Make fall damage optional + keep revive logic sane
private _oldEh = _player getVariable ["DB_HandleDamageEH", -1];
if (_oldEh >= 0) then {
  _player removeEventHandler ["HandleDamage", _oldEh];
};

private _eh = _player addEventHandler ["HandleDamage", {
  params ["_unit", "_selection", "_incDamage", "_source", "_projectile"];

  private _beingRevived = _unit getVariable ["RevByMedikit", false];
  private _teamDamage   = missionNamespace getVariable ["TEAM_DAMAGE", false];
  private _players      = allPlayers;

  private _isFall = (_projectile isEqualTo "" && isNull _source);

  if (
      (_isFall && !(missionNamespace getVariable ["DB_fallDamageEnabled", false]))
      || lifeState _unit == "INCAPACITATED"
      || _beingRevived
      || (_source in _players && !_teamDamage && !(_source isEqualTo _unit))
     ) then
  {
    0
  }
  else
  {
    // Medikit “save” on big hits; otherwise fall back to revive EH
    if (_incDamage >= 0.9 && ("Medikit" in items _unit)) then {
      _unit removeItem "Medikit";
      _unit setVariable ["RevByMedikit", true, true];
      _unit playActionNow "agonyStart";
      _unit playAction "agonyStop";
      _unit setDamage 0;
      [_unit] remoteExec ["bulwark_fnc_revivePlayer", 2];
      0
    } else {
      _this call BIS_fnc_reviveEhHandleDamage
    };
  };
}];

_player setVariable ["DB_HandleDamageEH", _eh];

// delete empty containers (add only once per client)
private _oldTakeEh = _player getVariable ["DB_TakeEH", -1];
if (_oldTakeEh < 0) then {
  private _takeEh = _player addEventHandler ["Take", {
    params ["_unit", "_container", "_item"];
    [_container] remoteExecCall ["loot_fnc_deleteIfEmpty", 2];
  }];
  _player setVariable ["DB_TakeEH", _takeEh];
};

removeHeadgear _player;
removeGoggles _player;
removeVest _player;
removeBackpack _player;
removeAllWeapons _player;
removeAllAssignedItems _player;
_player setPosASL ([bulwarkBox] call bulwark_fnc_findPlaceAround);

if (_startWeapon) then {
    _player addMagazine "16Rnd_9x21_Mag";
    _player addMagazine "16Rnd_9x21_Mag";
    _player addWeapon "hgun_P07_F";
};

if (_startMap) then {
    _player addItem "ItemMap";
    _player assignItem "ItemMap";
    _player linkItem "ItemMap";
};

if (_startNVG) then {
    _player addItem "Integrated_NVG_F";
    _player assignItem "Integrated_NVG_F";
    _player linkItem "Integrated_NVG_F";
};

if (isClass (configfile >> "CfgVehicles" >> "tf_anarc164")) then {
  _player addItem "tf_anprc152";
};

waituntil {alive _player};

[] remoteExec ["killPoints_fnc_updateHud", 0];