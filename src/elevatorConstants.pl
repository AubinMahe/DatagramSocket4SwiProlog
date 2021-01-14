:- module( elevatorConstants, [
	epsilon/1,
	floorsMax/1,
	inactivityTimeout/1,
	openDoorsDuration/1,
	doorsCommandNONE/1,
	doorsCommandOPEN/1,
	doorsCommandCLOSE/1,
	directionNONE/1,
	directionHALTED/1,
	directionUP/1,
	directionDOWN/1,
	intentionNONE/1,
	intentionUP/1,
	intentionDOWN/1,
	noTimestamp/1,
	noIndex/1,
	noRequest/1,
	noTimer/1,
	timerIsRunning/1
]).

epsilon( 0.005 ).
floorsMax( 6 ).

inactivityTimeout( 10.0 ). % secondes
openDoorsDuration(  2.0 ). % secondes

doorsCommandNONE(  0 ).
doorsCommandOPEN(  1 ).
doorsCommandCLOSE( 2 ).

directionNONE(  -1 ).
directionHALTED( 0 ).
directionUP(     1 ).
directionDOWN(   2 ).

intentionNONE( 0 ).
intentionUP(   1 ).
intentionDOWN( 2 ).

noTimestamp( -1 ).
noIndex( -1 ).
noRequest( request( false, NO_INTENTION, NO_TIMESTAMP )) :-
	intentionNONE( NO_INTENTION ),
	noTimestamp( NO_TIMESTAMP ).
noTimer( NO_TIMESTAMP) :-
	noTimestamp( NO_TIMESTAMP ).
timerIsRunning( Value ) :-
	noTimestamp( NO_TIMESTAMP ),
	Value > NO_TIMESTAMP.
