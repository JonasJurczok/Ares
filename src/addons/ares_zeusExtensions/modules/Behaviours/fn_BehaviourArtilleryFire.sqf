#include "\ares_zeusExtensions\module_header.hpp"

_artillery = [_logic] call Ares_fnc_GetUnitUnderCursor;

// Choose the kind of ammunition to fire
_allAmmunition = getArtilleryAmmo [_artillery];

if (count _allAmmunition > 0) then
{
	_dialogResult = [
		"Artillery Options",
		[
			["Ammunition Type", _allAmmunition],
			["Rounds", ["1", "2", "3", "4", "5"]],
			["Choose Target", ["Random", "Nearest", "Farthest"], 1]
		]] call Ares_fnc_ShowChooseDialog;
	if (count _dialogResult > 0) then
	{
		// Get the data that the dialog set.
		_selectedAmmoType = _allAmmunition select (_dialogResult select 0);
		_roundsToFire = (_dialogResult select 1) + 1; // +1 since the options are 0-based. (0 actually fires a whole clip)
		_targetChooseAlgorithm = _dialogResult select 2;
		
		// Choose a target to fire at
		_allTargets = allMissionObjects "Ares_Module_Behaviour_Create_Artillery_Target";
		
		// Make sure we only consider targets that are in range.
		_targetsInRange = [];
		{
			if ((position _x) inRangeOfArtillery [[_artillery], _selectedAmmoType]) then
			{
				_targetsInRange set [count _targetsInRange, _x];
			};
		} forEach _allTargets;
		
		if (count _targetsInRange > 0) then
		{
			// Choose a target to fire at
			_selectedTarget = _allTargets call BIS_fnc_selectRandom;
			if (_targetChooseAlgorithm == 1) then
			{
				_selectedTarget = [position _logic, _targetsInRange] call Ares_fnc_GetNearest;
			};
			if (_targetChooseAlgorithm == 2) then
			{
				_selectedTarget = [position _logic, _targetsInRange] call Ares_fnc_GetFarthest;
			};
			
			// Fire at the target where the unit is local (See #129)
			enableEngineArtillery true;
			_roundEta = _artillery getArtilleryETA [position _selectedTarget, _selectedAmmoType];
			
			if (isNil "Ares_FireArtilleryFunction") then
			{
				Ares_FireArtilleryFunction = {
					_artilleryUnit = _this select 0;
					_targetPos = _this select 1;
					_ammoType = _this select 2;
					_roundsToFire = _this select 3;
					enableEngineArtillery true;
					_artilleryUnit commandArtilleryFire [_targetPos, _ammoType, _roundsToFire];
				};
				publicVariable "Ares_FireArtilleryFunction";
			};
			[[_artillery, (position _selectedTarget), _selectedAmmoType, _roundsToFire], "Ares_FireArtilleryFunction", _artillery] call BIS_fnc_MP;
			
			[objNull, format ["Firing %1 rounds of '%2' at target. ETA %3", _roundsToFire, _selectedAmmoType, _roundEta]] call bis_fnc_showCuratorFeedbackMessage;
		}
		else
		{
			[objNull, "No targets in range"] call bis_fnc_showCuratorFeedbackMessage;
		};
	};
};

#include "\ares_zeusExtensions\module_footer.hpp"
