/*
	Author: Aaron Clark - EpochMod.com

    Contributors:

	Description:
	Server side spawing of shipwreck loots

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_server/compile/epoch_looting/EPOCH_server_spawnBoatLoot.sqf
*/
//[[[cog import generate_private_arrays ]]]
private ["_cfgEpoch","_debug","_showBoatMarkers","_decayMarkerColor","_compromisedColor","_worldSize","_shipwrecks","_total","_count","_distFromOthers","_tooClose","_spawnedLoot","_wreck","_item","_markers","_position","_debugMkr","_heightenedPVP"];
//[[[end]]]
_cfgEpoch = configFile >> "CfgEpoch" >> worldname;
_debug = if(getNumber(_cfgEpoch >> "debugShipwreckLoot") isEqualTo 1)then{true}else{false};
_showBoatMarkers = if(getNumber(_cfgEpoch >> "showBoatLootMarkers") isEqualTo 1)then{true}else{false};
_decayMarkerColor = getText(_cfgEpoch >> "shipwreckDecayMarkerColor");
_compromisedColor = getText(_cfgEpoch >> "shipwreckCompromisedColor");
_heightenedPVP = if(getNumber(_cfgEpoch >> "HeightenedPlayerVsPlayer") isEqualTo 1)then{true}else{false};
_markers = [];
_originalColors = [];

if (getNumber(_cfgEpoch >> "shipwreckLootEnabled") isEqualTo 1) then {
	_worldSize = worldSize/2;
	_shipwrecks = nearestTerrainObjects [ [_worldSize, _worldSize], ["SHIPWRECK"], _worldSize];
	_total = getNumber(_cfgEpoch >> "maxSpawnedShipwrecks");
	
	if(_shipwrecks isEqualTo [])exitWith{if(_debug)then{diag_log "EPOCHDebug: no shipwrecks found"}};
	if(_total isEqualTo 0)exitWith{if(_debug)then{diag_log "EPOCHDebug: no shipwrecks allowed"}};
	
	_count = count(_shipwrecks);
	if(_count < _total)then{if(_debug)then{diag_log "EPOCHDebug: not enough shipwrecks to fill your needs on this map, trying all available locations!"}};
	
	_distFromOthers = getNumber(_cfgEpoch >> "distFromOtherShipwrecks");
	_spawnedLoot = [];
	for "_i" from 1 to _total do {
		if(_shipwrecks isEqualTo [])exitWith{if(_debug)then{diag_log "EPOCHDebug: no more shipwrecks found"}};
		
		_tooClose = false;
		_wreck = selectRandom _shipwrecks;
		if(isNil "_wreck")exitWith{};
		{
			if(!(_spawnedLoot isEqualTo []) && ((_wreck distance _x) < _distFromOthers))exitWith{
				if(_debug)then{diag_log "EPOCHDebug: Shipwreck too close to another shipwreck"};
				_tooClose = true;
				_i = (_i - 1);
			};
		}forEach _spawnedLoot;
		
		_shipwrecks = _shipwrecks - [_wreck];
		if!(_tooClose)then{
			_position = [_wreck,1,20,3,1,20,0] call BIS_fnc_findSafePos;
			_item = createVehicle["container_epoch",_position, [], 0, "NONE"];
			_spawnedLoot pushback _wreck;
			if(_debug)then{
				_debugMkr = createMarker [str(_position),_position];
				_debugMkr setMarkerShape "ICON";
				_debugMkr setMarkerType "mil_dot";
				_debugMkr setMarkerColor "ColorRed";
			};
			_item setMass 220;
			_item setVariable["EPOCH_Loot",false,true];
			if (_showBoatMarkers) then {
				_markers = ["Shipwreck",_wreck] call EPOCH_server_createGlobalMarkerSet;
				{
					_originalColors pushBack (getMarkerColor _x);
				}forEach _markers;
			};
			
			// Check for HeightenedPlayerVsPlayer false and remove comprimised coloring
			if((_showBoatMarkers) && !(_heightenedPVP))then{
				_compromisedColor = getMarkerColor (_markers select 0);
			};

			_rEvents = missionNameSpace getVariable["EPOCH_RunningEvents",[]];
			_shipwreckEvent = [_position, [_item], [], "shipwreckCounter", diag_tickTime, 99999, _showBoatMarkers, _markers, _originalColors, _decayMarkerColor, _compromisedColor];
			missionNameSpace setVariable["EPOCH_RunningEvents",_rEvents + [_shipwreckEvent]];
		};
	};
	if(_debug)then{
		diag_log format["EPOCHDebug: Safely spawned %1 loot container(s) at these shipwreck locations:%2",count _spawnedLoot , _spawnedLoot];
	};
};