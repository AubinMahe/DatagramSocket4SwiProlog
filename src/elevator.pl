%------------------------------------------------------------------------------------------------------------------------------
% Ajout postérieur à l'établissement de la spécification Stimulus :
%------------------------------------------------------------------
% A chaque étage, on présente deux boutons permettant à l'utilisateur d'exprimer son intention : monter ou descendre.
% Si la cabine descend et que l'utilisateur souhaite monter, sa demande ne provoque pas l'arrêt de la cabine
% qui poursuit sa descente. 
%------------------------------------------------------------------------------------------------------------------------------
:- module( elevator, [
%-- functions --
	fill/2,
	floorLocations/1,
	stopIsRequired/5,
	nextDestination/2,
%-- requirements --
	mergeRequests/3,
	listFloorsToBeServed/5,
	closeDoorsWhenNoRequests/6,
	closeDoorsWhenCabinIsMoving/3,
	manageDoorsOpeningAndClosingAtEachStop/11,
	keepTheCabinStillWhenNoRequests/2,
	manageCabinAtEachStop/7,
	manageRisingOfTheCabin/6,
	manageTheDescentOfTheCabin/6,
	filterCommand/3,
	elaborateDoorsCommand/2,
	elaborateDirection/2,
%-- run-time --
	run/7 ]).
:- use_module( elevatorConstants ).

%#######################################################.. Functions ..########################################################

becomes( true, PreviousValue, true ) :-
	must_be( boolean, PreviousValue ),
	PreviousValue = false.

becomes( false, PreviousValue, false ) :-
	must_be( boolean, PreviousValue ),
	PreviousValue = true.

%------------------------------------------------------------------------------------------------------------------------------

fill( 0, [], _ ) :- !. % Without cut, backtracking leads to infinite recursion after giving a correct production.
fill( Index, [Value|List], Value ) :-
	Index > 0,
	NextIndex is Index - 1,
	fill( NextIndex, List, Value ).
fill( List, Value ) :-
	floorsMax( FLOOR_MAX ),
	FloorsCount is FLOOR_MAX + 1,
	fill( FloorsCount, List, Value ),
	!.

%------------------------------------------------------------------------------------------------------------------------------

floorLocations(           0, TmpLocs, [0.0 | TmpLocs ] ) :- !.
floorLocations( FloorsCount, TmpLocs, Locs ) :-
	floorsMax( FLOOR_MAX ),
	FloorsCount > 0,
	Loc is FloorsCount / FLOOR_MAX,
	Count is FloorsCount - 1,
	floorLocations( Count, [Loc|TmpLocs], Locs ).
floorLocations( Locs ) :-
	floorsMax( FLOOR_MAX ),
	floorLocations( FLOOR_MAX, [], Locs ).

%------------------------------------------------------------------------------------------------------------------------------
% For each floor_has_to_be_served in floor_has_to_be_served_list
%    and each floor_location in floor_locations
%    accumulator acc: {low;high} lowest false highest result
% do
%    When cabinLocation is equal to floor_location ± EPSILON and floor_has_to_be_served	
%       Define acc.high as true
%    otherwise	
%       Define acc.high as acc.low
%----------------------------------

stopIsRequired( [request( true, Intention, _ )|_], CabinLocation, [FloorLocation|_], LastDirection ) :-
	intentionNONE( NONE ),
	directionHALTED( HALTED ),
	( Intention = NONE ; LastDirection = HALTED ; Intention = LastDirection ),
	Distance is abs( CabinLocation - FloorLocation ),
	epsilon( EPSILON ),
	Distance =< EPSILON, % On est en face d'un étage et il est demandé
	!.
stopIsRequired( [NO_REQUEST|_], CabinLocation, [FloorLocation|_], _ ) :-
	noRequest( NO_REQUEST ),
	Distance is abs( CabinLocation - FloorLocation ),
	epsilon( EPSILON ),
	Distance =< EPSILON, % On est en face d'un étage et il n'est pas demandé
	fail, 
	!.
stopIsRequired( [_|FloorsHasToBeServed], CabinLocation, [_|FloorLocations], LastDirection ) :-
	stopIsRequired( FloorsHasToBeServed, CabinLocation, FloorLocations, LastDirection ), % On a pas encore testé le bon étage
	!.
stopIsRequired( FloorsHasToBeServed, CabinLocation, NextDestination, LastDirection, false ) :-
	must_be( list, FloorsHasToBeServed ),
	must_be( between( 0.0, 1.0 ), CabinLocation ),
	floorsMax( FLOOR_MAX ),
	noIndex( NO_INDEX ),
	must_be( between( NO_INDEX, FLOOR_MAX ), NextDestination ),
	NextLocation is NextDestination / FLOOR_MAX,
	Distance is abs( CabinLocation - NextLocation ),
	epsilon( EPSILON ),
	floorLocations( FloorLocations ),
	( Distance =< EPSILON -> true ; stopIsRequired( FloorsHasToBeServed, CabinLocation, FloorLocations, LastDirection )),
	!.

%------------------------------------------------------------------------------------------------------------------------------
% For each timestamp in timestamps
%    index i
%    accumulator ts       : {low;high} lowest NO_TIMESTAMP highest lowestTS
%    accumulator min_index: {low;high} lowest NO_INDEX     highest result
% do
%    When (timestamp is not NO_TIMESTAMP),	
%       Define ts.high as
%          (1) timestamp if ts.low is NO_TIMESTAMP or timestamp < ts.low
%          ts.low otherwise
%       Define min_index.high as
%          (1) i if ts.low is NO_TIMESTAMP or timestamp < ts.low
%          min_index.low otherwise
%    otherwise	
%       Define min_index.high as min_index.low
%       Define ts.high as ts.low
%--------------------------------

olderRequest( _, MinIndex, _, [], Result ) :-
	Result is MinIndex,
	!.
olderRequest( Index, MinIndex, MinTS   , [NO_REQUEST|Requests], Result ) :-
	noRequest( NO_REQUEST ),
	olderRequest( Index + 1, MinIndex, MinTS, Requests, Result ),
	!.
olderRequest( Index,     _   , NO_INDEX, [request( _, _, Timestamp    )|Requests], Result ) :-
	noIndex( NO_INDEX ),
	olderRequest( Index + 1, Index, Timestamp, Requests, Result ),
	!.
olderRequest( Index, MinIndex, MinTS   , [request( _, _, Timestamp    )|Requests], Result ) :-
	( Timestamp <  MinTS -> olderRequest( Index + 1, Index   , Timestamp, Requests, Result )
	; Timestamp >= MinTS -> olderRequest( Index + 1, MinIndex, Timestamp, Requests, Result )),
	!.
olderRequest( Requests, OlderIndex ) :-
	must_be( list, Requests ),
	noIndex( NO_INDEX ),
	noTimestamp( NO_TIMESTAMP ),
	olderRequest( 0, NO_INDEX, NO_TIMESTAMP, Requests, OlderIndex ),
	!.

%####################################################.. Analyze requests ..####################################################
% For    each cabinRequest       in floorRequestsFromCabin
%    and each landingRequest     in floorRequestsFromLandings
%    and each request            in floorRequests.floor
%    and each resquest_timestamp in floorRequests.timestamp
% do
%    Define request as cabinRequest.floor or landingRequest.floor
%    Define resquest_timestamp as
%       (1) (minimum of cabinRequest.timestamp and landingRequest.timestamp) if (cabinRequest.floor and landingRequest.floor)
%       (2) cabinRequest.timestamp if cabinRequest.floor
%       (3) landingRequest.timestamp if landingRequest.floor
%       NO_TIMESTAMP otherwise
%------------------------------

mergeRequests(
	[NO_REQUEST|  CabinRequests],
	[NO_REQUEST|LandingRequests],
	[NO_REQUEST|       Requests] )
:-
	noRequest( NO_REQUEST ),
	mergeRequests( CabinRequests, LandingRequests, Requests ),
	!.
mergeRequests(
	[request( true, NO_INTENTION, CReqTS )|  CabinRequests],
	[request( true, LIntention  , LReqTS )|LandingRequests],
	[request( true,  Intention  ,  MinTS )|       Requests] )
:-
	intentionNONE( NO_INTENTION ),
	MinTS is min( CReqTS, LReqTS ),
	( MinTS = CReqTS -> Intention = NO_INTENTION ; Intention = LIntention ),
	mergeRequests( CabinRequests, LandingRequests, Requests ),
	!.
mergeRequests(
	[request(  true, NO_INTENTION, CReqTS )|  CabinRequests],
	[                           NO_REQUEST |LandingRequests],
	[request(  true, NO_INTENTION, CReqTS )|       Requests] )
:-
	intentionNONE( NO_INTENTION ),
	noRequest( NO_REQUEST ),
	mergeRequests( CabinRequests, LandingRequests, Requests ),
	!.
mergeRequests(
	[                          NO_REQUEST|  CabinRequests],
	[request(  true, LIntention, LReqTS )|LandingRequests],
	[request(  true, LIntention, LReqTS )|       Requests] )
:-
	noRequest( NO_REQUEST ),
	mergeRequests( CabinRequests, LandingRequests, Requests ),
	!.
mergeRequests( [], [], [] ).

%------------------------------------------------------------------------------------------------------------------------------

equals( FloatValue, FloatRef ) :-
	must_be( between( 0.0, 1.0 ), FloatValue ),
	must_be( between( 0.0, 1.0 ), FloatRef ),
	epsilon( EPSILON ),
	abs( FloatValue - FloatRef ) =< EPSILON.

diff( FloatValue, FloatRef ) :-
	must_be( between( 0.0, 1.0 ), FloatValue ),
	must_be( between( 0.0, 1.0 ), FloatRef ),
	epsilon( EPSILON ),
	abs( FloatValue - FloatRef ) > EPSILON.

%------------------------------------------------------------------------------------------------------------------------------
% For    each request                in floorRequests
%    and each floor_has_to_be_served in floorsToBeServedList
%    and each location               in floorLocations
% do
%    Define floor_has_to_be_served as
%       (1) false if cabinLocation is equal to location ± EPSILON and Last( doorsAreOpen )
%       (2) true if request.floor
%       Last( floor_has_to_be_served ) otherwise
%------------------------------------------------

listFloorsToBeServed(
	[_|Requests],                                                   % Peu importe la demande actuelle,
	[_|LastFloorsToBeServed],                                       % ou la demande passée
	[Location|FloorLocations],
	CabinLocation,
	true,                                                           % Les portes sont ouvertes au bon étage
	[NO_REQUEST|FloorsToBeServed])                                  % On consomme la requête en cours,
:-
	noRequest( NO_REQUEST ),
	equals( CabinLocation, Location ),                              % puisque la position de la cabine est celle de cet étage
	listFloorsToBeServed( Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, true, FloorsToBeServed ),
	!.

listFloorsToBeServed(
	[                                    _ |Requests            ],  % Peu importe si une nouvelle requête existe,
	[request( true , Intention, Timestamp )|LastFloorsToBeServed],  % on privilégie la plus ancienne.
	[_|FloorLocations],
	CabinLocation,
	DoorsAreOpen,                                                   % Les portes ne sont pas ouvertes au bon étage
	[request( true , Intention, Timestamp )|    FloorsToBeServed] )
:-
	listFloorsToBeServed( Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	!.

listFloorsToBeServed(
	[request( true , Intention, Timestamp )|Requests            ],  % Il existe une nouvelle requête est recopiée puisque Les portes ne sont pas ouvertes, on doit la conserver
	[                            NO_REQUEST|LastFloorsToBeServed],
	[_|FloorLocations],
	CabinLocation,
	DoorsAreOpen,                                                   % Les portes ne sont pas ouvertes au bon étage
	[request( true , Intention, Timestamp )|    FloorsToBeServed] )
:-
	noRequest( NO_REQUEST ),
	listFloorsToBeServed( Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	!.

listFloorsToBeServed(
	[                            NO_REQUEST|Requests            ],  % Il n'y a pas de nouvelle requête et
	[                            NO_REQUEST|LastFloorsToBeServed],  % il n'y en avait pas non plus au cycle précédent 
	[_|FloorLocations],
	CabinLocation,
	DoorsAreOpen,                                                   % Les portes ne sont pas ouvertes au bon étage
	[NO_REQUEST                            |    FloorsToBeServed] ) % On stocke donc une requête "ne-rien-faire"
:-
	noRequest( NO_REQUEST ),
	listFloorsToBeServed( Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	!.

listFloorsToBeServed(
	[                            NO_REQUEST|Requests            ],  % Il n'y a pas de nouvelle requête mais
	[request( true , Intention, Timestamp )|LastFloorsToBeServed],  % il y en avait une au cycle précédent
	[_|FloorLocations],
	CabinLocation,
	DoorsAreOpen,
	[request( true , Intention, Timestamp )|    FloorsToBeServed] ) % on conserve la requête du cycle précédent
:-
	noRequest( NO_REQUEST ),
	listFloorsToBeServed( Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	!.

listFloorsToBeServed( [], [], [], _, _, [] ).

listFloorsToBeServed( Requests, LastFloorsToBeServed, CabinLocation, DoorsAreOpen, FloorsToBeServed ) :-
	floorLocations( FloorLocations ),
	listFloorsToBeServed(
		Requests, LastFloorsToBeServed, FloorLocations, CabinLocation, DoorsAreOpen, FloorsToBeServed ),
	!.

%------------------------------------------------------------------------------------------------------------------------------
% Define nextDestination as
%    (1) olderRequest( floorRequestsTimestamps ) if olderRequest( floorRequestsTimestamps ) is not NO_INDEX
%    (Last nextDestination) otherwise
%-------------------------------------

nextDestination( FloorsHasToBeServed, NextDestination ) :-
	olderRequest( FloorsHasToBeServed, NextDestination ).

%######################################################.. Manage doors ..######################################################

allFalse( [NO_REQUEST|Requests] ) :-
	noRequest( NO_REQUEST ),
	allFalse( Requests ).
allFalse( [] ).

%------------------------------------------------------------------------------------------------------------------------------
% When no element of floorsToBeServedList is true for more than INACTIVITY_CLOSE_DOORS_TIMEOUT	
%    doorsCommand shall be 'CLOSE_DOORS
%---------------------------------------

% On reset le timer car les portes sont fermées
closeDoorsWhenNoRequests( _, _, true, _, NONE, NO_TIMER ) :-
	doorsCommandNONE( NONE ),
	noTimer( NO_TIMER ),
	!.
% On démarre le timer car les portes ne sont pas fermées et que le timer ne tourne pas, sans commander les portes
closeDoorsWhenNoRequests( Now, FloorsToBeServed, false, NO_TIMER, NONE, Now ) :-
	allFalse( FloorsToBeServed ),
	noTimer( NO_TIMER ),
	doorsCommandNONE( NONE ),
	!.
% On laisse tourner le timer car les portes ne sont pas fermées, sans commander les portes car la tempo n'a pas expiré
closeDoorsWhenNoRequests( Now, FloorsToBeServed, false, InactivityTimer, NONE, InactivityTimer ) :-
	allFalse( FloorsToBeServed ),
	timerIsRunning( InactivityTimer ),
	inactivityTimeout( INACTIVITY_TIMEOUT ),
	Elapsed is Now - InactivityTimer,
	Elapsed =< INACTIVITY_TIMEOUT,
	doorsCommandNONE( NONE ),
	!.
% On laisse tourner le timer car les portes ne sont pas fermées, mais on ferme les portes car la tempo a expiré
closeDoorsWhenNoRequests( Now, FloorsToBeServed, false, InactivityTimer, CLOSE_DOORS, InactivityTimer ) :-
	allFalse( FloorsToBeServed ),
	timerIsRunning( InactivityTimer ),
	inactivityTimeout( INACTIVITY_TIMEOUT ),
	Elapsed is Now - InactivityTimer,
	Elapsed > INACTIVITY_TIMEOUT,
	doorsCommandCLOSE( CLOSE_DOORS ),
	!.
% On ne pilote pas les portes quand il existe des requêtes
closeDoorsWhenNoRequests( _, FloorsToBeServed, _, _, NONE, NO_TIMER ) :-
	( allFalse( FloorsToBeServed ) -> fail /* Unreachable */ ; true ),
	doorsCommandNONE( NONE ),
	noTimer( NO_TIMER ).

%------------------------------------------------------------------------------------------------------------------------------
% When cabinLocation is unstable or direction is not 'HALTED	
%    doorsCommand shall be 'CLOSE_DOORS
%---------------------------------------

closeDoorsWhenCabinIsMoving( LastCabinLocation, CabinLocation, CLOSE_DOORS ) :-
 	diff( CabinLocation, LastCabinLocation ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	!.

closeDoorsWhenCabinIsMoving( LastCabinLocation, CabinLocation, NONE ) :-
	equals( LastCabinLocation, CabinLocation ),
	doorsCommandNONE( NONE ),
	!.

%------------------------------------------------------------------------------------------------------------------------------
% Keep doors closed between each cabin stop
%    Until the time stopIsRequired( cabinLocation, floorsToBeServedList, floorLocations )	
%       doorsCommand shall be 'CLOSE_DOORS
%------------------------------------------

% Useless requirement?

%------------------------------------------------------------------------------------------------------------------------------
% After each time stopIsRequired( cabinLocation, floorsToBeServedList, floorLocations )
%    From the time cabinLocation is stable and direction is 'HALTED
%       Do
%          For OPEN_DOORS_DURATION,
%             doorsCommand shall be 'OPEN_DOORS
%       afterwards
%          doorsCommand shall be 'CLOSE_DOORS
%---------------------------------------------

% Portes fermées, on est arrivé à l'étage à desservir : il faut ouvrir les portes
manageDoorsOpeningAndClosingAtEachStop(
	_, Requests, LastCabinLocation, CabinLocation, NextDestination, _, DoorsAreClosed, _, LastDirection, OPEN_DOORS, NO_TIMER )
:-
	DoorsAreClosed = true,
	stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ),
	equals( LastCabinLocation, CabinLocation ), % Cabine à l'arrêt
	noTimer( NO_TIMER ),
	doorsCommandOPEN( OPEN_DOORS ),
	!.
% Il faut continuer d'ouvrir les portes tant que le capteur "portes ouvertes" est faux
manageDoorsOpeningAndClosingAtEachStop(
	_, Requests, _, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection, OPEN_DOORS, NO_TIMER )
:-
	DoorsAreOpen   = false,
	DoorsAreClosed = false,
	stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ),
	noTimer( NO_TIMER ),
	doorsCommandOPEN( OPEN_DOORS ),
	!.
% Les portes sont complètement ouvertes : il faut lancer le timer
manageDoorsOpeningAndClosingAtEachStop(
	Now, _, _, _, _, DoorsAreOpen, DoorsAreClosed, NO_TIMER, _, NONE, Now )
:-
	DoorsAreOpen   = true,
	DoorsAreClosed = false,
	noTimer( NO_TIMER ),
	doorsCommandNONE( NONE ),
	!.
% Les portes sont complètement ouvertes et le timer n'est pas expiré : on ne commande pas les portes
manageDoorsOpeningAndClosingAtEachStop(
	Now, _, _, _, _, DoorsAreOpen, DoorsAreClosed, OpenDoorsTimer, _, NONE, OpenDoorsTimer )
:-
	DoorsAreOpen   = true,
	DoorsAreClosed = false,
	timerIsRunning( OpenDoorsTimer ),
	openDoorsDuration( OPEN_DOORS_DURATION ),
	Duration is Now - OpenDoorsTimer,
	Duration =< OPEN_DOORS_DURATION,
	doorsCommandNONE( NONE ),
	!.
% Les portes sont complètement ouvertes et le timer est expiré : on commande la fermeture des portes et on reset le timer
manageDoorsOpeningAndClosingAtEachStop(
	Now, _, _, _, _, DoorsAreOpen, DoorsAreClosed, OpenDoorsTimer, _, CLOSE_DOORS, NO_TIMER )
:-
	DoorsAreOpen   = true,
	DoorsAreClosed = false,
	timerIsRunning( OpenDoorsTimer ),
	openDoorsDuration( OPEN_DOORS_DURATION ),
	Duration is Now - OpenDoorsTimer,
	Duration > OPEN_DOORS_DURATION,
	doorsCommandCLOSE( CLOSE_DOORS ),
	noTimer( NO_TIMER ),
	!.
% Pas d'arrêt prévu à cet endroit, portes en cours de fermeture : on commande la fermeture des portes et on reset le timer
manageDoorsOpeningAndClosingAtEachStop(
	_, Requests, _, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection, CLOSE_DOORS, NO_TIMER )
:-
	DoorsAreOpen   = false,
	DoorsAreClosed = false,
	( stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ) -> fail ; true ),
	doorsCommandCLOSE( CLOSE_DOORS ),
	noTimer( NO_TIMER ),
	!.
% Pas d'arrêt prévu à cet endroit, portes fermées : pas de commande de porte et on reset le timer
manageDoorsOpeningAndClosingAtEachStop(
	_, Requests, _, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed, _, LastDirection, NONE, NO_TIMER )
:-
	DoorsAreOpen   = false,
	DoorsAreClosed = true,
	( stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ) -> fail ; true ),
	doorsCommandNONE( NONE ),
	noTimer( NO_TIMER ),
	!.

%#######################################################.. Move cabin ..#######################################################
% When (no element of floorsToBeServedList is true),	
%    direction shall be 'HALTED
%-------------------------------

keepTheCabinStillWhenNoRequests( FloorsToBeServed, Direction ) :-
	directionHALTED( HALTED ),
	directionNONE( NONE ),
	( allFalse( FloorsToBeServed ) -> Direction = HALTED ; Direction = NONE ),
	!.

%------------------------------------------------------------------------------------------------------------------------------
% After the time stopIsRequired( cabinLocation, floorsToBeServedList, floorLocations ),
%    Until the time doorsAreClosed becomes true
%          and cabinLocation is not equal to indexToLocation( nextDestination, floorLocations ) ± EPSILON
%       direction shall be 'HALTED
%----------------------------------

manageCabinAtEachStop( Requests, CabinLocation, NextDestination, LastDoorsAreClosed, DoorsAreClosed, LastDirection, HALTED ) :-
	directionHALTED( HALTED ),
	stopIsRequired( Requests, CabinLocation, NextDestination, LastDirection, false ),
	noIndex( NO_INDEX ),
	NextDestination \= NO_INDEX,
	floorsMax( FLOOR_MAX ),
	NextLocation is NextDestination / FLOOR_MAX,
	\+(( becomes( true, LastDoorsAreClosed, DoorsAreClosed ), diff( CabinLocation, NextLocation ))),
	!.

manageCabinAtEachStop( _, _, _, _, _, _, Direction ) :-
	directionNONE( NONE ),
	Direction = NONE,
	!.

%------------------------------------------------------------------------------------------------------------------------------
% After the time doorsAreClosed becomes true
%       and cabinLocation is not equal to indexToLocation( nextDestination, floorLocations ) ± EPSILON	
%    Until the time stopIsRequired( cabinLocation, floorsToBeServedList, floorLocations )	
%       If cabinLocation is less than indexToLocation( nextDestination, floorLocations ) then	
%          direction shall be 'UP
%---------------------------------

manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection, UP ) :-
	noIndex( NO_INDEX ),
	NextDestination \= NO_INDEX,
	( stopIsRequired( FloorsHasToBeServed, CabinLocation, NextDestination, LastDirection, false ) -> fail ; true ),
	floorsMax( FLOOR_MAX ),
	NextLocation is NextDestination / FLOOR_MAX,
	CabinLocation < NextLocation,
	DoorsAreClosed = true,
	directionUP( UP ),
	!.

manageRisingOfTheCabin( _, _, _, _, _, NONE ) :-
	directionNONE( NONE ),
	!.

%------------------------------------------------------------------------------------------------------------------------------
% After the time doorsAreClosed becomes true
%       and cabinLocation is not equal to indexToLocation( nextDestination, floorLocations ) ± EPSILON	
%    Until the time stopIsRequired( cabinLocation, floorsToBeServedList, floorLocations )	
%       If initially cabinLocation is greater than indexToLocation( nextDestination, floorLocations ) then	
%          direction shall be 'DOWN
%-----------------------------------

manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection, DOWN ) :-
	noIndex( NO_INDEX ),
	NextDestination \= NO_INDEX,
	( stopIsRequired( FloorsHasToBeServed, CabinLocation, NextDestination, LastDirection, false ) -> fail ; true ),
	floorsMax( FLOOR_MAX ),
	NextLocation is NextDestination / FLOOR_MAX,
	CabinLocation > NextLocation,
	DoorsAreClosed = true,
	directionDOWN( DOWN ),
	!.

manageTheDescentOfTheCabin( _, _, _, _, _, NONE ) :-
	directionNONE( NONE ),
	!.

%------------------------------------------------------------------------------------------------------------------------------

filterCommand( [Filtered|SortedCommands], Filtered, FilteredCommands ) :-
	filterCommand( SortedCommands, Filtered, FilteredCommands ),
	!.
filterCommand( FilteredCommands, _, FilteredCommands ).

%------------------------------------------------------------------------------------------------------------------------------

elaborateCommand( Name, Commands, None, Default, Command ) :-
	sort( Commands, SortedCommands ),                           % Enlever les doublons
	filterCommand( SortedCommands, None, FilteredCommands ),    % Enlever les 'NONE'
	( FilteredCommands = [] -> Command = Default                % Si la liste est vide, la commande est Default
	; ( list_to_set( FilteredCommands, CommandSet ),
		( length( CommandSet, 1 ) -> CommandSet = [Command] % La commande à passer doit être unique 
		; debug( semantic_error,
			"~w: ~w", [Name, CommandSet]), fail ))    % En cas d'incohérence on s'arrête avec un message explicite
	),
	!.

%------------------------------------------------------------------------------------------------------------------------------

elaborateDoorsCommand( DoorsCommands, DoorsCommand ) :-
	doorsCommandNONE( NONE ),
	elaborateCommand( 'DoorCommands', DoorsCommands, NONE, NONE  , DoorsCommand ).

%------------------------------------------------------------------------------------------------------------------------------

elaborateDirection( Directions, Direction ) :-
	directionNONE( NONE ),
	directionHALTED( HALTED ),
	elaborateCommand( 'Direction'   , Directions   , NONE, HALTED, Direction ).

%------------------------------------------------------------------------------------------------------------------------------

run( DatagramSocket,
	LastFloorsHasToBeServed, LastCabinLocation, LastDoorsAreClosed, LastInactivityTimer, LastOpenDoorsTimer, LastDirection )
:-
	get_time( AtStartCycle ), % Utilisé pour les timers
		debug( log, "-- ~w --", [AtStartCycle] ),
		debug( log, "LastFloorsHasToBeServed: ~w ; LastCabinLocation: ~w", [LastFloorsHasToBeServed, LastCabinLocation]),
		debug( log, "LastDoorsAreClosed: ~w ; LastInactivityTimer: ~w ; LastOpenDoorsTimer: ~w ; LastDirection: ~w",
			[LastDoorsAreClosed, LastInactivityTimer, LastOpenDoorsTimer, LastDirection] ),
	%-- Réception UDP blocante
	receiveMessages( DatagramSocket, DoorsAreOpen, DoorsAreClosed, CabinRequests, CabinLocation, LandingRequests ),
		debug( log, "DoorsAreOpen: ~w ; DoorsAreClosed: ~w", [DoorsAreOpen, DoorsAreClosed]),
		debug( log, "CabinRequests: ~w", [CabinRequests]),
		debug( log, "CabinLocation: ~w", [CabinLocation]),
		debug( log, "LandingRequests: ~w", [LandingRequests]),

	%-- Analyze requests
	mergeRequests( CabinRequests, LandingRequests, Requests ),
		debug( log, "Requests: ~w", [Requests]),
	listFloorsToBeServed( Requests, LastFloorsHasToBeServed, CabinLocation, DoorsAreOpen, FloorsHasToBeServed ),
		debug( log, "FloorsHasToBeServed: ~w", [FloorsHasToBeServed]),
	nextDestination( FloorsHasToBeServed, NextDestination ),
		debug( log, "NextDestination: ~w", [NextDestination]),
		
	%-- Manage Doors
	closeDoorsWhenNoRequests( AtStartCycle, FloorsHasToBeServed, DoorsAreClosed, LastInactivityTimer,
		DoorsCommand1, InactivityTimer ),
		debug( log, "DoorsCommand1: ~w ; InactivityTimer: ~w", [DoorsCommand1, InactivityTimer]),
	closeDoorsWhenCabinIsMoving( LastCabinLocation, CabinLocation, DoorsCommand2 ),
		debug( log, "DoorsCommand2: ~w", [DoorsCommand2]),
	manageDoorsOpeningAndClosingAtEachStop(
		AtStartCycle, FloorsHasToBeServed, LastCabinLocation, CabinLocation, NextDestination, DoorsAreOpen, DoorsAreClosed,
		LastOpenDoorsTimer, LastDirection, DoorsCommand3, OpenDoorsTimer ),
		debug( log, "DoorsCommand3: ~w ; OpenDoorsTimer: ~w", [DoorsCommand3, OpenDoorsTimer]),
	elaborateDoorsCommand( [DoorsCommand1, DoorsCommand2, DoorsCommand3], DoorsCommand ),
		debug( log, "DoorsCommand: ~w", [DoorsCommand]),

	%-- Move cabin
	keepTheCabinStillWhenNoRequests( FloorsHasToBeServed, Direction1 ),
		debug( log, "Direction1: ~w", [Direction1]),
	manageCabinAtEachStop(
		FloorsHasToBeServed, CabinLocation, NextDestination, LastDoorsAreClosed, DoorsAreClosed, LastDirection, Direction2 ),
		debug( log, "Direction2: ~w", [Direction2]),
	manageRisingOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection, Direction3 ),
		debug( log, "Direction3: ~w", [Direction3]),
	manageTheDescentOfTheCabin( FloorsHasToBeServed, CabinLocation, NextDestination, DoorsAreClosed, LastDirection, Direction4 ),
		debug( log, "Direction4: ~w", [Direction4]),
	elaborateDirection( [Direction1, Direction2, Direction3, Direction4], Direction ),
		debug( log, "Direction: ~w", [Direction]),

	%-- Publish results
	sendElevatorControllerMessage( DatagramSocket, FloorsHasToBeServed, DoorsCommand, Direction ),

	%-- Loop
	run( DatagramSocket, FloorsHasToBeServed, CabinLocation, DoorsAreClosed, InactivityTimer, OpenDoorsTimer, Direction ).

%-- EOF
