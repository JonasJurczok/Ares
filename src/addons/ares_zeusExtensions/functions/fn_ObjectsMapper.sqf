/*
	File: objectMapper.sqf
	Author: Joris-Jan van 't Land

	Description:
	Takes an array of data about a dynamic object template and creates the objects.

	Parameter(s):
	0: (Position) - The anchor object to place the objects relative to, or objNull to use the original position.
	1: (Array of data) - The data for the objects to paste in. See Ares_fnc_ObjectsGrabber.
	2: (Boolean) - Snap to ground. True to snap the objects to the ground at their new position, false to leave them at their original position. Default false.

	Returns:
	Created objects (Array)
	
	Modified for Ares by Anton Struyk
*/

private ["_newAnchorObject", "_objs"];
_newAnchorObject = [_this, 0, objNull, [objNull]] call BIS_fnc_Param;
_objs = [_this, 1, [[0,0,0]], [[]]] call BIS_fnc_Param;
_snapToGround = [_this, 2, false] call BIS_fnc_Param;

// The copy script will have added the reference point as the last object in the array.
// Get the position from it, and then remove it from the array so we no longer process it.
_originalAnchorPosition = _objs select ((count _objs) - 2);
_metadata = _objs select ((count _objs) - 1); // Right now this only contains the version number
_objs resize ((count _objs) - 2);

//Make sure there are definitions in the final object array
if ((count _objs) == 0) exitWith {debugLog "Log: [BIS_fnc_objectMapper] No elements in the object array!"; []};

private ["_newObjs"];
_newObjs = [];

private ["_useAbsolutePositions"];
_useAbsolutePositions = isNull _newAnchorObject;

private ["_newAnchorX", "_newAnchorY"];
_newAnchorX = (getPosWorld _newAnchorObject) select 0;
_newAnchorY = (getPosWorld _newAnchorObject) select 1;
_newAnchorZ = (getPosWorld _newAnchorObject) select 2;

{
	private ["_type", "_originalPosition", "_azimuth", "_fuel", "_damage", "_newObj"];
	_type = _x select 0;
	_originalPosition = _x select 1;
	_azimuth = _x select 2;
	
	//Optionally map certain features if they're included in the data. Order must match the grabber order.
	if ((count _x) > 3) then {_fuel = _x select 3};
	if ((count _x) > 4) then {_damage = _x select 4};

	if (_useAbsolutePositions) then
	{
		_newObj = createVehicle [_type, _originalPosition, [], 0, "CAN_COLLIDE"];
		_newObj setPosWorld _originalPosition;
	}
	else
	{
		// The new position = (new anchor position) + (old position relative to anchor)
		//                  = (new anchor position) + (old absolute position - old anchor position)
		_newPos = [
			_newAnchorX + ((_originalPosition select 0) - (_originalAnchorPosition select 0)),
			_newAnchorY + ((_originalPosition select 1) - (_originalAnchorPosition select 1)),
			_newAnchorZ + ((_originalPosition select 2) - (_originalAnchorPosition select 2))
			];

		_newObj = createVehicle [_type, _newPos, [], 0, "CAN_COLLIDE"];
		_newObj setPosWorld _newPos;
		
		/*if (abs(_originalPosition select 2) > 0.01) then
		{
			// If the unit was sufficiently above the ground level at their original position, then we want to translate
			// that into the same offset above ground level in the new location.
			_newHeightASL = (getTerrainHeightASL _newPos) + (_originalPosition select 2);
			_newObj setPosASL [_newPos select 0, _newPos select 1, _newHeightASL];
		};*/
	};
	
	
	// Orient the object correctly
	_newObj setDir (_azimuth);
	
	// Snap to ground (if applicable)
	if (_snapToGround) then
	{
		_newObj setPos [(getPos _newObj) select 0, (getPos _newObj) select 1, 0];
	};

	//If fuel and damage were grabbed, map them
	if (!isNil "_fuel") then {_newObj setFuel _fuel};
	if (!isNil "_damage") then {_newObj setDamage _damage;};
	_newObjs pushback _newObj;
} forEach _objs;

_newObjs