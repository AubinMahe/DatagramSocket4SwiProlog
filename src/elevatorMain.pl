#!/usr/bin/swipl

:- use_module( elevatorConstants ).
:- use_module( elevatorMessages ).
:- use_module( elevator ).

main :-
	%-- Création de la socket pour communiquer avec les modules Cabin et ElevatorShaft (Simulateur IHM Java) --
	msgCabinSize( MSG_CABIN_SIZE ),
	msgElevatorShaftSize( MSG_ELEVATOR_SHAFT_SIZE ),
	MsgMaxSize is max( MSG_CABIN_SIZE, MSG_ELEVATOR_SHAFT_SIZE ),
	createAndConnectDatagramSocket( localhost, 2416, localhost, 2417, MsgMaxSize, DatagramSocket ),
	
	%-- Conditions initiales --
	noRequest( NO_REQUEST ),
	fill( FloorsHasToBeServed, NO_REQUEST ),
	LastCabinLocation is 0.0,
	LastDoorsAreClosed = true,
	noTimer( NO_TIMER ),
	directionHALTED( HALTED ),
	
	%-- Runtime --
	debug( semantic_error ),
	( elevator:run( DatagramSocket, FloorsHasToBeServed, LastCabinLocation, LastDoorsAreClosed, NO_TIMER, NO_TIMER, HALTED )
	-> true    % Inatteignable puisque run ne se termine jamais sauf en cas d'échec 
	;  true ), % Permet de fermer proprement la socket dans tous les cas
	closeDatagramSocket( DatagramSocket ).

:-
	current_prolog_flag( argv, Args ),
	( memberchk( '--log'  , Args ) -> debug( log ) ; true ),
	( memberchk( '--start', Args ) -> main         ; true ).
