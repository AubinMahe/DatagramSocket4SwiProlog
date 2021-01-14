#!/usr/bin/swipl

:- begin_tests( elevator ).

:- use_module( elevatorConstants ).
:- use_module( elevatorMessages ).
:- use_module( elevator ).

%------------------------------------------------------------------------------------------------------------------------------

test( fill ) :-
	noTimestamp( NO_TIMESTAMP ),
	fill( ListOfNoTimestamp, NO_TIMESTAMP ),
	ListOfNoTimestamp = [NO_TIMESTAMP, NO_TIMESTAMP, NO_TIMESTAMP, NO_TIMESTAMP, NO_TIMESTAMP, NO_TIMESTAMP, NO_TIMESTAMP ].

%------------------------------------------------------------------------------------------------------------------------------

stopReq( Requests ) :-
	intentionNONE( NONE ),
	intentionDOWN( DOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,                   % 0 - 0.00
		NO_REQUEST,                   % 1 - 0.16
		request( true , NONE, 60 ),   % 2 - 0.33
		NO_REQUEST,                   % 3 - 0.50
		request( true , DOWN, 80 ),   % 4 - 0.66
		NO_REQUEST,                   % 5 - 0.83
		request( true , NONE, 40 ) ]. % 6 - 1.00

test( stopIsRequiredAt0, [fail] ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.0000, 6, UP, false ).
test( stopIsRequiredAt1, [fail] ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.1667, 6, UP, false ).
test( stopIsRequiredAt2         ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.3333, 6, UP, false ).
test( stopIsRequiredAt3, [fail] ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.5000, 6, UP, false ).
test( stopIsRequiredAt4, [fail] ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.6667, 6, UP, false ).
test( stopIsRequiredAt5, [fail] ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 0.8333, 6, UP, false ).
test( stopIsRequiredAt6         ) :- stopReq( Requests ), directionUP( UP ), stopIsRequired( Requests, 1.0000, 6, UP, false ).
test( stopIsRequiredAt6_bug ) :-
	intentionNONE( INONE ),
	intentionDOWN( IDOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		request( true , INONE, 1606584606209 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , IDOWN, 1606584602187 )],
	CabinLocation is 1.0,
	directionUP( LastDirection ),
	NextDestination is 6,
	stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ),
	!.
test( stopIsRequiredAt5_bug ) :-
	intentionNONE( INONE ),
	intentionDOWN( IDOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST, 
		NO_REQUEST,
		request( true , INONE, 1606600140360 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true , IDOWN, 1606600148583 ),
		NO_REQUEST ],
	CabinLocation is 0.8360000000000006,
	NextDestination is 2,
	directionHALTED( LastDirection ),
	stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ),
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( nextDestination ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE, 60 ),
		NO_REQUEST,
		request( true , NONE, 80 ) ],
	nextDestination( Requests, Index ),
	Index = 4,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( mergeRequests ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	CabinRequests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LandingRequests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	mergeRequests( CabinRequests, LandingRequests, FloorRequests ),
	FloorRequests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	!.

%------------------------------------------------------------------------------------------------------------------------------

% Cas 1 : Il n'existe pas d'anciennes requêtes, les portes sont fermées.
test( listFloorsToBeServed ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorRequests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	LastFloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	CabinLocation is 0.5,
	DoorsAreOpen = false,
	listFloorsToBeServed( FloorRequests, LastFloorsToBeServed, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	FloorsToBeServed = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	!.

% Cas 2 : Il n'existe pas d'anciennes requêtes, mais les portes sont ouvertes car on vient de desservir un étage demandé
test( listFloorsToBeServed_HasBeenServed ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorRequests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	LastFloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	CabinLocation is 1.0,
	DoorsAreOpen = true,
	listFloorsToBeServed( FloorRequests, LastFloorsToBeServed, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	FloorsToBeServed = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ], % La demande a disparue
	!.

% Cas 3 : Il existe une ancienne requête, les portes sont fermées.
test( listFloorsToBeServedOld ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorRequests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE, 120 ) ], % L'utilisateur s'impatiente !
	LastFloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ], % La demande existe déjà
	CabinLocation is 0.5,
	DoorsAreOpen = false,
	listFloorsToBeServed( FloorRequests, LastFloorsToBeServed, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	FloorsToBeServed = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ], % On conserve la date la plus ancienne
	!.

% Cas 4 : Il n'y a pas de nouvelles requêtes et les portes sont ouvertes car on vient de desservir un étage demandé
test( listFloorsToBeServed_HasBeenServed2 ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorRequests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LastFloorsToBeServed = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	CabinLocation is 1.0,
	DoorsAreOpen = true,
	listFloorsToBeServed( FloorRequests, LastFloorsToBeServed, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	FloorsToBeServed = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ], % La demande a disparue
	!.

%------------------------------------------------------------------------------------------------------------------------------
%
% closeDoorsWhenNoRequests( +Now, +FloorsHasToBeServed, +DoorsAreClosed, +LastInactivityTimer, ?DoorsCommand, ?InactivityTimer )
%
test( closeDoorsWhenNoRequests_closed ) :- %
	closeDoorsWhenNoRequests( _, _, true, _, DoorsCommand, InactivityTimer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	noTimer( NO_TIMER ),
	InactivityTimer = NO_TIMER,
	!.

test( closeDoorsWhenNoRequests_startTimer ) :- %
	noRequest( NO_REQUEST ),
	fill( FloorsHasToBeServed, NO_REQUEST ),
	noTimer( NO_TIMER ),
	doorsCommandNONE( NONE ),
	Now is 123456789,
	closeDoorsWhenNoRequests( Now, FloorsHasToBeServed, false, NO_TIMER, DoorsCommand, InactivityTimer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	InactivityTimer = Now,
	!.

test( closeDoorsWhenNoRequests_notElapsed ) :- %
	noRequest( NO_REQUEST ),
	fill( FloorsHasToBeServed, NO_REQUEST ),
	inactivityTimeout( INACTIVITY_TIMEOUT ), % secondes
	LastInactivityTimer is 123456789,
	Now is LastInactivityTimer + INACTIVITY_TIMEOUT - 0.020,
	closeDoorsWhenNoRequests( Now, FloorsHasToBeServed, false, LastInactivityTimer, DoorsCommand, InactivityTimer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	InactivityTimer = LastInactivityTimer,
	!.

test( closeDoorsWhenNoRequests_elapsed ) :- %
	noRequest( NO_REQUEST ),
	fill( FloorsHasToBeServed, NO_REQUEST ),
	inactivityTimeout( INACTIVITY_TIMEOUT ), % secondes
	LastInactivityTimer is 123456789,
	Now is LastInactivityTimer + INACTIVITY_TIMEOUT + 0.020,
	closeDoorsWhenNoRequests( Now, FloorsHasToBeServed, false, LastInactivityTimer, DoorsCommand, InactivityTimer ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	DoorsCommand = CLOSE_DOORS,
	InactivityTimer = LastInactivityTimer,
	!.

test( closeDoorsWhenNoRequests_withRequests ) :- %
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 1606079400530 ),
		NO_REQUEST,
		NO_REQUEST ],
	noTimer( NO_TIMER ),
	LastInactivityTimer = NO_TIMER,
	closeDoorsWhenNoRequests( 123456.789, FloorsToBeServed, false, LastInactivityTimer, DoorsCommand, InactivityTimer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	InactivityTimer = LastInactivityTimer,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( closeDoorsWhenCabinIsMoving ) :-
	epsilon( EPSILON ),
	LastCabinLocation is 0.5 - EPSILON,
	CabinLocation     is 0.5,
	closeDoorsWhenCabinIsMoving( LastCabinLocation, CabinLocation, DoorsCommand ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	DoorsCommand = CLOSE_DOORS,
	!.

test( closeDoorsWhenCabinIsMoving_noMove ) :-
	LastCabinLocation is 0.5,
	CabinLocation     is 0.5,
	closeDoorsWhenCabinIsMoving( LastCabinLocation, CabinLocation, DoorsCommand ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( manageDoorsOpeningAndClosingAtEachStop_doorsOpen_openStarted ) :- % on commence à ouvrir les portes
	Now is 123456789,
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	LastCabinLocation is 1.0,
	CabinLocation     is 1.0,
	NextDestination is 6,
	DoorsAreOpen   = false,
	DoorsAreClosed = true,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandOPEN( OPEN_DOORS ),
	DoorsCommand = OPEN_DOORS,
	noTimer( NO_TIMER ),
	OpenDoorsTimer = NO_TIMER,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_openContinue ) :- % On continue d'ouvrir les portes
	Now is 123456789,
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	LastCabinLocation is 1.0,
	CabinLocation     is 1.0,
	NextDestination is 6,
	DoorsAreOpen   = false,
	DoorsAreClosed = false,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandOPEN( OPEN_DOORS ),
	DoorsCommand = OPEN_DOORS,
	noTimer( NO_TIMER ),
	OpenDoorsTimer = NO_TIMER,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_openEnded ) :- % Les portes sont totalement ouvertes, on lance le timer
	Now is 123456789,
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LastCabinLocation is 1.0,
	CabinLocation     is 1.0,
	NextDestination is 0,
	DoorsAreOpen   = true,
	DoorsAreClosed = false,
	noTimer( NO_TIMER ),
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, NO_TIMER, LastDirection,
		DoorsCommand, Timer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	Timer = Now,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_closeStarted ) :- % Le timer est expiré : on commence à fermer les portes 
	Now is 123456789,
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LastCabinLocation is 1.0,
	CabinLocation     is 1.0,
	NextDestination is 0,
	DoorsAreOpen   = true,
	DoorsAreClosed = false,
	openDoorsDuration( OPEN_DOORS_DURATION ),
	OpenDoorsTimer is Now - OPEN_DOORS_DURATION - 0.020,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination,
		DoorsAreOpen, DoorsAreClosed, OpenDoorsTimer, LastDirection,
		DoorsCommand, Timer ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	DoorsCommand = CLOSE_DOORS,
	noTimer( NO_TIMER ),
	Timer = NO_TIMER,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_closing ) :-
	Now is 123456789,
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LastCabinLocation is 0.32400000000000023,
	CabinLocation     is 0.32400000000000023,
	noIndex( NO_INDEX ),
	NextDestination is NO_INDEX,
	DoorsAreOpen   = false,
	DoorsAreClosed = false,
	LastOpenDoorsTimer is -1,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination,
		DoorsAreOpen, DoorsAreClosed, LastOpenDoorsTimer, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	DoorsCommand = CLOSE_DOORS,
	noTimer( NO_TIMER ),
	OpenDoorsTimer = NO_TIMER,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_closeEnded ) :- % Les portes sont fermées, on arrête de les piloter
	Now is 123456789,
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true, NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	LastCabinLocation is 1.0,
	CabinLocation     is 1.0,
	NextDestination is 0,
	DoorsAreOpen   = false,
	DoorsAreClosed = true,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection,
		DoorsCommand, Timer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	noTimer( NO_TIMER ),
	Timer = NO_TIMER,
	!.

% On ne doit pas ouvrir les portes car la cabine monte alors que l'utilisateur souhaite descendre
test( manageDoorsOpeningAndClosingAtEachStop_cabin_rising_when_user_will_descend ) :-
	Now is 123456789,
	intentionNONE( NONE ),
	intentionDOWN( DOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		request( true , NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true , DOWN, 120 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true , NONE,  80 ) ],
	epsilon( EPSILON ),
	LastCabinLocation is 0.5 - EPSILON,
	CabinLocation     is 0.5,
	NextDestination is 6,
	DoorsAreOpen   = false,
	DoorsAreClosed = true,
	directionUP( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandNONE( NONE ),
	DoorsCommand = NONE,
	noTimer( NO_TIMER ),
	OpenDoorsTimer = NO_TIMER,
	!.

test( manageDoorsOpeningAndClosingAtEachStop_bug_at_6 ) :-
	Now is 1606584612.2249079,
	intentionNONE( INONE ),
	intentionDOWN( IDOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		request( true , INONE, 1606584606209 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true , IDOWN, 1606584602187 )],
	LastCabinLocation is 0.9960000000000008,
	CabinLocation     is 1.0,
	NextDestination is 6,
	DoorsAreOpen   = false,
	DoorsAreClosed = true,
	noTimer( NO_TIMER ),
	LastOpenDoorsTimer is NO_TIMER,
	directionUP( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination,
		DoorsAreOpen, DoorsAreClosed, LastOpenDoorsTimer, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandOPEN( OPEN_DOORS ),
	DoorsCommand   = OPEN_DOORS,
	OpenDoorsTimer = NO_TIMER,
	!.
% -- 1606600157.861096 --
% LastFloorsHasToBeServed: [request(false,0,-1),request(false,0,-1),request(true,0,1606600140360),request(false,0,-1),request(false,0,-1),request(true,2,1606600148583),request(false,0,-1)] ; LastCabinLocation: 0.8360000000000006
% LastDoorsAreClosed: true ; LastInactivityTimer: -1 ; LastOpenDoorsTimer: -1 ; LastDirection: 0
% DoorsAreOpen: false ; DoorsAreClosed: false
% CabinRequests: [request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1)]
% CabinLocation: 0.8360000000000006
% LandingRequests: [request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1)]
% Requests: [request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1),request(false,0,-1)]
% FloorsHasToBeServed: [request(false,0,-1),request(false,0,-1),request(true,0,1606600140360),request(false,0,-1),request(false,0,-1),request(true,2,1606600148583),request(false,0,-1)]
% NextDestination: 2
% DoorsCommand1: 0 ; InactivityTimer: -1
% DoorsCommand2: 0
% DoorsCommand3: 2 ; OpenDoorsTimer: -1
% DoorsCommand: 2
% Direction1: -1
% Direction2: -1
% Direction3: -1
% Direction4: -1
% Direction: 0
% Message: [3,2,2,5,2,0]
test( manageDoorsOpeningAndClosingAtEachStop_bug_at_5 ) :-
	Now is 1606600157.861096,
	intentionNONE( INONE ),
	intentionDOWN( IDOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST, 
		NO_REQUEST,
		request( true , INONE, 1606600140360 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true , IDOWN, 1606600148583 ),
		NO_REQUEST ],
	LastCabinLocation is 0.8360000000000006,
	CabinLocation is 0.8360000000000006,
	NextDestination is 2,
	DoorsAreOpen   = false,
	DoorsAreClosed = false,
	noTimer( NO_TIMER ),
	LastOpenDoorsTimer is NO_TIMER,
	directionHALTED( LastDirection ),
	manageDoorsOpeningAndClosingAtEachStop(
		Now, Requests, LastCabinLocation, CabinLocation, NextDestination,
		DoorsAreOpen, DoorsAreClosed, LastOpenDoorsTimer, LastDirection,
		DoorsCommand, OpenDoorsTimer ),
	doorsCommandOPEN( OPEN_DOORS ),
	DoorsCommand   = OPEN_DOORS,
	OpenDoorsTimer = NO_TIMER,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( keepTheCabinStillWhenNoRequests_DirectionIsNone ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	keepTheCabinStillWhenNoRequests( Requests, Direction ),
	directionNONE( NONE ),
	Direction = NONE.

test( keepTheCabinStillWhenNoRequests ) :-
	noRequest( NO_REQUEST ),
	NoRequest = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	keepTheCabinStillWhenNoRequests( NoRequest, Direction ),
	directionHALTED( HALTED ),
	Direction = HALTED.

%------------------------------------------------------------------------------------------------------------------------------

test( manageCabinAtEachStop_HALTED_expected ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 150 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 100 ) ],
	CabinLocation      = 0.5,
	NextDestination    = 6,
	LastDoorsAreClosed = false,
	DoorsAreClosed     = false, % les portes ne sont pas fermées, on doit rester sur place
	directionUP( LastDirection ),
	manageCabinAtEachStop( Requests, CabinLocation, NextDestination, LastDoorsAreClosed, DoorsAreClosed, LastDirection,
		Direction ),
	directionHALTED( HALTED ),
	Direction = HALTED,
	!.

test( manageCabinAtEachStop_NONE_expected ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 150 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 100 ) ],
	CabinLocation      = 0.5,
	NextDestination    = 6,
	LastDoorsAreClosed = false,
	DoorsAreClosed     = true, % les portes viennent de se refermer, on doit repartir
	directionHALTED( LastDirection ),
	manageCabinAtEachStop( Requests, CabinLocation, NextDestination, LastDoorsAreClosed, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE,
	!.

% On ne doit pas arrêter la cabine car elle monte alors que l'utilisateur souhaite descendre
test( manageCabinAtEachStop_cabin_rising_when_user_will_descend ) :-
	intentionNONE( NONE ),
	intentionDOWN( DOWN ),
	noRequest( NO_REQUEST ),
	Requests = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, DOWN, 150 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 100 ) ],
	CabinLocation      = 0.5,
	NextDestination    = 6,
	LastDoorsAreClosed = true,
	DoorsAreClosed     = true,
	directionUP( LastDirection ),
	manageCabinAtEachStop( Requests, CabinLocation, NextDestination, LastDoorsAreClosed, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( DIRECTION_NONE ),
	Direction = DIRECTION_NONE,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( manageRisingOfTheCabin ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 150 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 100 ) ],
	CabinLocation   = 0.0,
	NextDestination = 6,
	DoorsAreClosed  = true,
	directionHALTED( LastDirection ),
	manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionUP( UP ),
	Direction = UP.

test( manageRisingOfTheCabin_stopover ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 150 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 100 ) ],
	CabinLocation   = 0.50,
	NextDestination = 6,
	DoorsAreClosed  = true,
	directionUP( LastDirection ),
	manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE.

test( manageRisingOfTheCabin_stopover_bug ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		NO_REQUEST,                              % 0.000
		NO_REQUEST,                              % 0.167
		NO_REQUEST,                              % 0.333
		NO_REQUEST,                              % 0.500
		request( true, INONE, 1606216763959 ),   % 0.667
		NO_REQUEST,                              % 0.833
		request( true, INONE, 1606216762603 ) ], % 1.000
	CabinLocation   = 0.6667,
	NextDestination = 6,
	DoorsAreClosed  = true,
	directionUP( LastDirection ),
	manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE.

test( manageRisingOfTheCabin_NONE_expected ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		NO_REQUEST,
 		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 250 ),
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 100 ) ],
	CabinLocation   = 1.0,
	NextDestination = 6,
	DoorsAreClosed  = true,
	directionUP( LastDirection ),
	manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE.

%------------------------------------------------------------------------------------------------------------------------------

test( manageTheDescentOfTheCabin ) :-
	intentionNONE( NONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		request( true, NONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, NONE, 150 ),
		NO_REQUEST,
		NO_REQUEST ],	% 6 - 1.00
	CabinLocation   = 1.0,
	NextDestination = 0,
	DoorsAreClosed  = true,
	directionHALTED( LastDirection ),
	manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionDOWN( DOWN ),
	Direction = DOWN.

test( manageTheDescentOfTheCabin_stopover ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		request( true, INONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 150 ),
		NO_REQUEST,
		NO_REQUEST ],
	CabinLocation   = 0.66667,
	NextDestination = 0,
	DoorsAreClosed  = true,
	directionDOWN( LastDirection ),
	manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE.

test( manageTheDescentOfTheCabin_NONE_expected ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		request( true, INONE, 100 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 150 ),
		NO_REQUEST,
		NO_REQUEST ],
	CabinLocation   = 0.0,
	NextDestination = 0,
	DoorsAreClosed  = true,
	directionDOWN( LastDirection ),
	manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( NONE ),
	Direction = NONE.

% On ne doit pas diriger la cabine vers le bas car elle monte alors que l'utilisateur souhaite descendre
test( manageTheDescentOfTheCabin_cabin_rising_when_user_will_descend ) :-
	intentionDOWN( IDOWN ),
	noRequest( NO_REQUEST ),
	FloorsHasToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, IDOWN, 150 ),
		request( true, IDOWN, 100 ) ],
	CabinLocation   = 0.8360000000000006,
	NextDestination = 6,
	DoorsAreClosed  = true,
	directionUP( LastDirection ),
	manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection,
		Direction ),
	directionNONE( DNONE ),
	Direction = DNONE.

%------------------------------------------------------------------------------------------------------------------------------

test( filterCommand ) :-
	filterCommand( [0, 1], 0, [1] ).

%------------------------------------------------------------------------------------------------------------------------------

test( elaborateDoorsCommand ) :-
	doorsCommandOPEN( OPEN_DOORS ),
	doorsCommandNONE( NONE ),
	elaborateDoorsCommand( [NONE, OPEN_DOORS, NONE, OPEN_DOORS], DoorsCommand ),
	DoorsCommand = OPEN_DOORS,
	!.

test( elaborateDirection ) :-
	directionNONE( NONE ),
	directionUP( UP ),
	elaborateDirection( [NONE, UP, NONE, NONE], Direction ),
	Direction = UP,
	!.

%------------------------------------------------------------------------------------------------------------------------------

test( encodeDestinations_empty ) :-
	noRequest( NO_REQUEST ),
	FloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	encodeDestinations( FloorsToBeServed, ExpectedMessage ),
	ExpectedMessage = [0],
	!.

test( encodeDestinations_3 ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 123456789 ),
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST ],
	encodeDestinations( FloorsToBeServed, ExpectedMessage ),
	ExpectedMessage = [1,3],
	!.

test( encodeDestinations_3_et_5 ) :-
	intentionNONE( INONE ),
	noRequest( NO_REQUEST ),
	FloorsToBeServed = [
		NO_REQUEST,
		NO_REQUEST,
		NO_REQUEST,
		request( true, INONE, 123456789 ),
		NO_REQUEST,
		request( true, INONE, 456789123 ),
		NO_REQUEST ], % 6
	encodeDestinations( FloorsToBeServed, ExpectedMessage ),
	ExpectedMessage = [2,3,5],
	!.

%openDoors( DatagramSocket ) :-
%	receiveMessages( DatagramSocket, DoorsAreOpen, _, _, _, _ ),
%	doorsCommandOPEN( OPEN_DOORS ),
%	directionHALTED( HALTED ),
%	sendElevatorControllerMessage( DatagramSocket, [false,false,false,false,false,false,false], OPEN_DOORS, HALTED ),
%	sleep( 0.04 ),
%	( DoorsAreOpen = true -> true ; openDoors( DatagramSocket )), % repeat until DoorsAreOpen
%	!.
%
%test( openDoors ) :-
%	msgCabinSize( MSG_CABIN_SIZE ),
%	msgElevatorShaftSize( MSG_ELEVATOR_SHAFT_SIZE ),
%	MsgMaxSize is max( MSG_CABIN_SIZE, MSG_ELEVATOR_SHAFT_SIZE ),
%	createAndConnectDatagramSocket( localhost, 2416, localhost, 2417, MsgMaxSize, DatagramSocket ),
%	( openDoors( DatagramSocket ) -> true ; true ),
%	closeDatagramSocket( DatagramSocket ).

%------------------------------------------------------------------------------------------------------------------------------

:- end_tests( elevator ).

:- run_tests, halt(0).
