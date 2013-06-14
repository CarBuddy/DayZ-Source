
/*
        Created exclusively for ArmA2:OA - DayZMod.
        Please request permission to use/alter/distribute from project leader (R4Z0R49) AND the author (facoptere@gmail.com)
*/

private ["_unit", "_type", "_vehicle", "_speed", "_nextPlayerPos", "_distance", "_isVehicle", "_isSameFloor", "_isStairway", "_isClear", "_epu", "_epv", "_gpu_asl", "_gpv_asl", "_areaAffect", "_hu", "_hv", "_ob_arr", "_cob", "_deg", "_sign", "_a", "_rnd", "_move", "__FILE__", "_vel", "_hpList", "_hp", "_wound", "_damage", "_strH", "_dam", "_total", "_cnt", "_index", "_woundDamage"];
_start = diag_tickTime;

_unit = _this select 0;
_type = _this select 1;

_vehicle = (vehicle player);
_speed = speed player;
_nextPlayerPos = player call dayz_futurePos;
_distance = [_unit, _nextPlayerPos] call BIS_fnc_distance2D;

_isVehicle = (_vehicle != player);
_isSameFloor = false;
_isStairway = false;
_isClear = false;

_gpu_asl = getPosASL _unit;
_hu = _gpu_asl select 2;
_gpv_asl = getPosASL _vehicle;
_hv = _gpv_asl select 2;

if (_type != "zombie") exitWith {"not a zombie"}; // we deal only with zombies in this function
if (_distance > dayz_areaAffect) exitWith {"too far:"}; // distance too far according to any logic dealt here //+str(_unit distance _nextPlayerPos)+"/"+str(_areaAffect)
if (((!_isVehicle) AND {(random 8 > 1)}) AND {((toArray(animationState player) select 5) == 112)}) exitWith {"player down"}; // less attack if player prones

// check if fight is in stairway or not,
if (abs(_hu - _hv) < 1.3) then {
	_isSameFloor = true;
	if ((!_isVehicle) AND {(abs(_hu - _hv) > 0.15)}) then { _isStairway = true; };
};

//if (!_isSameFloor) exitWith {"not on same floor"}; // no attack if the 2 fighters are not on the same level
/*
// Not needed LOS is checked by the FSM
// check if space between player/vehicle and Z is clear or not
_gpu_asl set [ 2, 0.40 + _hu ];
_gpv_asl set [ 2, 0.40 + _hv ];
_ob_arr = lineIntersectsWith [_gpu_asl,  _gpv_asl,  _unit,  _vehicle];
_cob = count _ob_arr;
_isClear = (_cob == 0 or {!((_ob_arr select 0) isKindOf "All")});

if (!_isClear) exitWith {"something between"}; // no attack if there is a wall between fighters.
*/
// check relative angle (where is the player/vehicle in the Z sight)
_deg = [_unit,  _nextPlayerPos] call BIS_fnc_relativeDirTo;
if (_deg > 180) then { _deg = _deg - 360; };

/*
// angle check depends on player speed (very strict if player is still)
if (abs(_deg) > (30 + 1 * _speed)) exitWith { // we cancel the attack,  but we spin smoothly the Zombie
	[_unit, _nextPlayerPos] spawn {
		_unit = _this select 0;
		_plr = _this select 1;
		for "_i" from 1 to 29 do {
			_deg = [_unit,  _plr] call BIS_fnc_relativeDirTo;
			if (_deg > 180) then { _deg = _deg - 360; };
			if (_deg == 0) exitWith{};
			_sign = _deg/abs(_deg);
			_deg = abs(_deg);
			if (_deg < 10) exitWith{};
			//waituntil {_a = toArray(animationState _unit); (isNil "_a") OR {((count _a < 5) OR {((_a select 1) == 105)})}}; // 105='i' like idl
			_unit setDir ((getDir _unit) + _sign*5);
			sleep 0.01;
		};
	};
	("bad angle:") // +str(round(abs(_deg)))+"/"+str(round(15 + 3 * _speed))
};
*/

// check Z stance. Stand up Z if it prones/kneels. Cancel the attack.
if (unitPos _unit != "UP") exitWith {
	_unit setUnitPos "UP";
	"bad stance"
};

// compute the animation move
_rnd = 0;

switch true do {
	case ((toArray(animationState player) select 5) == 112) : {
		if (_distance < 2) then {
			_rnd = ceil(random 9);
			diag_log (str(_rnd));
			_move = "ZombieFeed" + str(_rnd);
		};
	};
	case (r_player_unconscious) : {
		if (random 3 < 1) then {
			_rnd = ceil(random 9);
			_move = "ZombieFeed" + str(_rnd);
		};
	};
	case (_isStairway) : {
		if (_distance < 1.7) then {
			_rnd = [1, 2, 4, 9] call BIS_fnc_selectRandom;
			_move = "ZombieStandingAttack" + str(_rnd);
		};
	};
	case (_isVehicle AND {(_distance > 2.2)}) : { // enable attack if Z is between 2.2 and 3.5. Other cases are handled in "default"
		if (_distance < 3.5) then {
			_rnd = 8;
			_move = "ZombieStandingAttack" + str(_rnd);
		};
	};
	case (_speed >= 5) : {
		if (_distance < 2.3) then {
			_rnd = 8;
			_move = "ZombieStandingAttack" + str(_rnd);
		};
	};
	default {
		// attack moves depends on the distance between player and Z
		// we compute the distance in 10cm slots.
		_rnd = round(_distance*10);
		_rnd = switch _rnd do {
			case 10 : {[ 1, 4, 9, 3, 6 ]};
			case 11 : {[ 1, 4, 9, 3, 6 ]};
			case 12 : {[ 1, 9, 3, 6 ]};
			case 13 : {[ 3, 6 ]};
			case 14 : {[ 3, 6, 7 ]};
			case 15 : {[ 7, 5 ]};
			case 16 : {[ 7, 5, 10 ]};
			case 17 : {[ 7, 5, 10 ]};
			case 18 : {[ 7, 8, 10 ]};
			case 19 : {[ 8, 10 ]};
			case 20 : {[ 8, 10 ]};
			case 21 : {[ 8 ]};
			case 22 : {[ 8 ]};
			default { if (_rnd < 10) then {[ 1, 2, 4, 9 ]} else {[0]} };
		};
		//if (_nextPlayerPos distance _unit > 2.2) then { diag_log(format["%1:  dis:%2  rndlist:%3",  __FILE__,  (round((_nextPlayerPos distance _unit)*10)),  _rnd]); };
		_rnd = _rnd call BIS_fnc_selectRandom;
		_move = "ZombieStandingAttack" + str(_rnd);
	};
};
if (_rnd == 0) exitWith {"bad move (too far)"};  // move not found -- Z too far?
// diag_log(format["%1:  dis:%2  rndlist:%3",  __FILE__,  (round((_nextPlayerPos distance _unit)*10)),  _rnd]);

// fix the direction
_unit setDir ((getDir _unit) + _deg);
//_unit setPosATL (getPosATL _unit);


// let's animate the Z
if (local _unit) then {
	_unit switchMove _move;
}
else {
	[objNull,  _unit,  rSwitchMove,  _move] call RE;
};

// Damage is done after the move
sleep 0.3;

if (r_player_unconscious) exitWith {"player unconscious"};  // no damage if player still unconscious.

// broadcast hit noise
[_unit,  "hit",  1,  false] call dayz_zombieSpeak;

// player may fall...
_deg = [player, _unit] call BIS_fnc_relativeDirTo;
//if (_deg > 180) then { _deg = _deg - 360; };
//	AND {((abs(_deg) < 50) OR {(abs(_deg) >(180-50))})}) then { // no tackle if Zed is not in front or in back
//((!_isVehicle) and (_speed >= 5.62))
diag_log (str(_deg));
switch true do {
	case (((!_isVehicle) and (_speed >= 5.62)) and (((_deg > 293) and (_deg <= 360)) or ((_deg > 0) and (_deg < 68)))) : {
		diag_log ("Front");
		player setVelocity [(velocity player select 0) + 5 * sin direction _unit, (velocity player select 1) + 5 * cos direction _unit, (velocity player select 2) + 1];
	};
	case (((!_isVehicle) and (_speed >= 5.62)) and ((_deg > 248) and (_deg < 293))) : {
		diag_log ("Left");
		player setVelocity [(velocity player select 0) + 5 * sin direction _unit, (velocity player select 1) + 5 * cos direction _unit, (velocity player select 2) + 1];
	};
	case (((!_isVehicle) and (_speed >= 5.62)) and ((_deg > 68) and (_deg < 113))) : {
		diag_log ("Right");
		player setVelocity [(velocity player select 0) + 5 * sin direction _unit, (velocity player select 1) + 5 * cos direction _unit, (velocity player select 2) + 1];
	};
	case (((!_isVehicle) and (_speed >= 5.62)) and ((_deg > 135) and (_deg < 225))) : {
		_lastTackle = player getVariable ["lastTackle", 0];
		if (time - _lastTackle > 5) then { // no tackle if previous tackle occured less than X seconds before
			player setVariable ["lastTackle", time];
			// stop player
			//_vel = velocity player;
			//player setVelocity [-(_vel select 0),  -(_vel select 1),  0];
			// make player dive
			_move = switch (toArray(animationState player) select 17) do {
				case 114 : {"ActsPercMrunSlowWrflDf_TumbleOver"}; // rifle
				case 112 : {"AmovPercMsprSlowWpstDf_AmovPpneMstpSrasWpstDnon"}; // pistol
				default {"ActsPercMrunSlowWrflDf_TumbleOver"};
			};
			player switchMove _move;
	//		diag_log(format["%1 player tackled. Weapons: cur:""%2"" anim.state:%6 (%7)--> move: %3. Angle:%4 Delta-time:%5",  __FILE__, currentWeapon player, _move, _deg, time - _lastTackle, animationState player, toArray(animationState player) select 17 ]);
		};
	};
};

/*
//Back
if (((!_isVehicle) and (_speed >= 5.62)) and ((_deg > 90) and (_deg < 270))) then {
	_lastTackle = player getVariable ["lastTackle", 0];
	if (time - _lastTackle > 5) then { // no tackle if previous tackle occured less than X seconds before
		player setVariable ["lastTackle", time];
		// stop player
		_vel = velocity player;
		player setVelocity [-(_vel select 0),  -(_vel select 1),  0];
		// make player dive
		_move = switch (toArray(animationState player) select 17) do {
			case 114 : {"AmovPercMsprSlowWrflDf_AmovPpneMstpSrasWrflDnon"}; // rifle
			case 112 : {"AmovPercMsprSlowWpstDf_AmovPpneMstpSrasWpstDnon"}; // pistol
			default {"AmovPercMsprSnonWnonDf_AmovPpneMstpSnonWnonDnon"};
		};
		player playMove _move;
//		diag_log(format["%1 player tackled. Weapons: cur:""%2"" anim.state:%6 (%7)--> move: %3. Angle:%4 Delta-time:%5",  __FILE__, currentWeapon player, _move, _deg, time - _lastTackle, animationState player, toArray(animationState player) select 17 ]);
	};
};
*/


// compute damage for vehicle and/or the player
if (_isVehicle) then {
	// eject the player of the open vehicle. There will be no damage in this case
	if (0 != {_vehicle isKindOf _x} count ["ATV_Base_EP1",  "Motorcycle",  "Bicycle"]) then {
		if (random 3 < 1) then {
			player action ["eject",  _vehicle];
		};
		diag_log(format["%1: Player ejected from %2", __FILE__, _vehicle]);
	}
	else { // vehicle with a compartment
		_wound = _this select 2; // what is this? wound linked to Z attack?
		if (isNil "_wound") then {
			_hpList = _vehicle call vehicle_getHitpoints;
			_hp = _hpList call BIS_fnc_selectRandom;
			_wound = getText(configFile >> "cfgVehicles" >> (typeOf _vehicle) >> "HitPoints" >> _hp >> "name");
		};
		_woundDamage = _unit getVariable ["hit_"+_wound, 0];
		// we limit how vehicle could be damaged by Z. Above 0.8, the vehicle could explode, which is ridiculous.
		_damage = random (if (_woundDamage < 0.8) then {0.1} else {0.01});
		// Add damage to vehicle. the "sethit" command will be done by the gameengine for which vehicle is local
		diag_log(format["%1: Part ""%2"" damaged from vehicle, damage:+%3", __FILE__, _wound, _damage]);
		_total = [_vehicle,  _wound,  _woundDamage + _damage,  _unit,  "zombie", true] call fnc_veh_handleDam;
		if ((_total >= 1) AND {(_wound IN [ "glass1",  "glass2",  "glass3",  "glass4",  "glass5",  "glass6" ])}) then {
			// glass is broken,  so hurt the player in the vehicle
			if (r_player_blood < (r_player_bloodTotal * 0.8)) then {
				_cnt = count (DAYZ_woundHit select 1);
				_index = floor (random _cnt);
				_index = (DAYZ_woundHit select 1) select _index;
				_wound = (DAYZ_woundHit select 0) select _index;
			} else {
				_cnt = count (DAYZ_woundHit_ok select 1);
				_index = floor (random _cnt);
				_index = (DAYZ_woundHit_ok select 1) select _index;
				_wound = (DAYZ_woundHit_ok select 0) select _index;
			};
			_damage = 0.2 + random (0.512);
			diag_log(format["%1 Player wounded through ""%4"" vehicle window. hit:%2 damage:+%3", __FILE__, _wound, _damage, _vehicle]);
			[player,  _wound,  _damage,  _unit,  "zombie"] call fnc_usec_damageHandler;
		};
	}; // fi veh with compartment
}
else { // player by foot
	_damage = 0.2 + random (0.512);

	switch true do {
		case (_isStairway AND (_hv > _hu)) : { // player is higher than Z,  so Z hurts legs
			[player,  "legs",  _damage,  _unit, "zombie"] call fnc_usec_damageHandler;
		};
		case (_isStairway AND (_hu > _hv)) : { // player is lower than Z,  so Z hurts head
			[player,  "head_hit",  _damage,  _unit, "zombie"] call fnc_usec_damageHandler;
		};
		default {
			if (r_player_blood < (r_player_bloodTotal * 0.8)) then {
				_cnt = count (DAYZ_woundHit select 1);
				_index = floor (random _cnt);
				_index = (DAYZ_woundHit select 1) select _index;
				_wound = (DAYZ_woundHit select 0) select _index;
			} else {
				_cnt = count (DAYZ_woundHit_ok select 1);
				_index = floor (random _cnt);
				_index = (DAYZ_woundHit_ok select 1) select _index;
				_wound = (DAYZ_woundHit_ok select 0) select _index;
			};
			[player,  _wound,  _damage,  _unit, "zombie"] call fnc_usec_damageHandler;
		};
	};
}; // fi player by foot

_stop = diag_tickTime;
diag_log format ["%2 Execution Time: %1",_stop - _start, __FILE__];

// please do not remove this last line! It's the return code
""
