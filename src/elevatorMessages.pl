#!/usr/bin/swipl

:- module( elevatorMessages, [
	% Classée par ordre alphabétique
	closeDatagramSocket/1,
	createAndConnectDatagramSocket/6,
	encodeDestinations/2,
	encodeElevatorControllerMessage/4,
	msgCabinSize/1,
	msgElevatorShaftSize/1,
	receiveMessages/6,
	sendElevatorControllerMessage/4
]).

:- use_foreign_library( '../Debug/libDatagramSocket' ).
:- use_module( elevatorConstants ).

msgCabinSize( Size ) :-
	floorsMax( FLOOR_MAX ),
	Size is
		1 +                             % ID
		1 +                             % newDestinations.size
		( 1 + 8 ) * ( FLOOR_MAX + 1 ) + % newDestinations: {floor, timestamp}{6+1}
		1 +                             % doorsAreOpen
		1.                              % doorsAreClosed

msgElevatorShaftSize( Size ) :-
	floorsMax( FLOOR_MAX ),
	Size is
	1 +                                % ID
	8 +                                % cabinLocation
	1 +                                % newCalls.size
	( 1 + 1 + 8 ) * ( FLOOR_MAX + 1 ). % newCalls: {floor, intention, timestamp}{6+1}

elevatorShaftMessageID(      1 ).
cabinMessageID(              2 ).
elevatorControllerMessageID( 3 ).

decodeLandingCall( DatagramSocket, landingCall( Floor, Intention, Timestamp )) :-
	getByteFromDatagramSocket( DatagramSocket, Floor ),
	getByteFromDatagramSocket( DatagramSocket, Intention ),
	getLongFromDatagramSocket( DatagramSocket, Timestamp );
	!.

decodeLandingCalls( _, 0, [] ).
decodeLandingCalls( DatagramSocket, Count, [LandingCall|LandingCalls] ) :-
	decodeLandingCall( DatagramSocket, LandingCall ),
	NC is Count - 1,
	decodeLandingCalls( DatagramSocket, NC, LandingCalls ),
	!.

decodeLandingCalls( DatagramSocket, LandingCalls ) :-
	getByteFromDatagramSocket( DatagramSocket, Count ),
	decodeLandingCalls( DatagramSocket, Count, LandingCalls ),
	!.

getLandingCall( [landingCall( Index, Intention, Timestamp )|_], landingCall( Index, Intention, Timestamp )) :-
	true, !.
getLandingCall( [], _ ) :-
	fail, !.
getLandingCall( [_|LandingCalls], LandingCall ) :-
	getLandingCall( LandingCalls, LandingCall ),
	!.

landingCallsToRequests( Index, _, [] ) :-
	floorsMax( FLOOR_MAX ),
	Index > FLOOR_MAX.
landingCallsToRequests( Index, LandingCalls, [Request|Requests] ) :-
	noRequest( NO_REQUEST ),
	( getLandingCall( LandingCalls, landingCall( Index, Intention, Timestamp ))
	-> Request = request( true, Intention, Timestamp )
	;  Request = NO_REQUEST
	),
	NI is Index + 1,
	landingCallsToRequests( NI, LandingCalls, Requests ),
	!.

landingCallsToRequests( LandingCalls, Requests ) :-
	landingCallsToRequests( 0, LandingCalls, Requests ).

decodeElevatorShaftMessage( DatagramSocket, CabinLocation, LandingRequests ) :-
	getDoubleFromDatagramSocket( DatagramSocket, CabinLocation ),
	decodeLandingCalls( DatagramSocket, LandingCalls ),
	landingCallsToRequests( LandingCalls, LandingRequests ),
	!.

decodeDestination( DatagramSocket, destination( Floor, Timestamp )) :-
	getByteFromDatagramSocket( DatagramSocket, Floor ),
	getLongFromDatagramSocket( DatagramSocket, Timestamp );
	!.

decodeDestinations( _, 0, [] ).
decodeDestinations( DatagramSocket, Count, [Destination|Destinations] ) :-
	decodeDestination( DatagramSocket, Destination ),
	NC is Count - 1,
	decodeDestinations( DatagramSocket, NC, Destinations ),
	!.

decodeDestinations( DatagramSocket, Destinations ) :-
	getByteFromDatagramSocket( DatagramSocket, Count ),
	decodeDestinations( DatagramSocket, Count, Destinations ),
	!.

getDestination( [destination( Index, Timestamp )|_], destination( Index, Timestamp )) :-
	true, !.
getDestination( [], _ ) :-
	fail, !.
getDestination( [_|Destinations], Destination ) :-
	getDestination( Destinations, Destination ),
	!.

destinationsToRequests( Index, _, [] ) :-
	floorsMax( FLOOR_MAX ),
	Index > FLOOR_MAX.
destinationsToRequests( Index, Destinations, [Request|Requests] ) :-
	noRequest( NO_REQUEST ),
	intentionNONE( NO_INTENTION ),
	( getDestination( Destinations, destination( Index, Timestamp ))
	-> Request = request( true, NO_INTENTION, Timestamp )
	;  Request = NO_REQUEST
	),
	NI is Index + 1,
	destinationsToRequests( NI, Destinations, Requests ),
	!.

destinationsToRequests( Destinations, Requests ) :-
	destinationsToRequests( 0, Destinations, Requests ).

decodeCabinMessage( DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed ) :-
	decodeDestinations( DatagramSocket, Destinations ),
	destinationsToRequests( Destinations, CabinRequests ),
	getBooleanFromDatagramSocket( DatagramSocket, DoorsAreOpen ),
	getBooleanFromDatagramSocket( DatagramSocket, DoorsAreClosed ),
	!.

decodeMessage( CABIN_MSG_ID, DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed, _, _ ) :-
	cabinMessageID( CABIN_MSG_ID ),
	decodeCabinMessage( DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed ),
	(( DoorsAreOpen = true, DoorsAreClosed = true ) -> halt(0) ; true ), % Astuce pour stopper l'exécution
	!.

decodeMessage( ELEVATOR_SHAFT_MSG_ID, DatagramSocket, _, _, _, CabinLocation, LandingRequests ) :-
	elevatorShaftMessageID( ELEVATOR_SHAFT_MSG_ID ),
	decodeElevatorShaftMessage( DatagramSocket, CabinLocation, LandingRequests ),
	!.

decodeMessage( ID, _, _, _, _, _, _ ) :-
	elevatorShaftMessageID( ELEVATOR_SHAFT_MSG_ID ),
	cabinMessageID( CABIN_MSG_ID ),
	ID \= ELEVATOR_SHAFT_MSG_ID,
	ID \= CABIN_MSG_ID,
	debug( semantic_error, "Unexpected message ID: ~w", ID ),
	!.

receiveMessage( DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed, CabinLocation, LandingRequests ) :-
	receiveDatagram( DatagramSocket ),
	getByteFromDatagramSocket( DatagramSocket, ID ),
	decodeMessage( ID, DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed, CabinLocation, LandingRequests ),
	!.

receiveMessages( DatagramSocket, DoorsAreOpen, DoorsAreClosed, CabinRequests, CabinLocation, LandingRequests ) :-
	receiveMessage( DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed, CabinLocation, LandingRequests ),
	receiveMessage( DatagramSocket, CabinRequests, DoorsAreOpen, DoorsAreClosed, CabinLocation, LandingRequests ),
	!.

encodeDestinations( _, [], [], 0 ).
encodeDestinations( Index, [request( true , _, _)|FloorsHasToBeServed], [Index|Data], Size ) :-
	Ndx is Index + 1,
	encodeDestinations( Ndx, FloorsHasToBeServed, Data, S ),
	Size is S + 1.
encodeDestinations( Index, [request( false, _, _)|FloorsHasToBeServed],    Data , Size ) :-
	Ndx is Index + 1,
	encodeDestinations( Ndx, FloorsHasToBeServed, Data, Size ).
encodeDestinations( FloorsHasToBeServed, [Size|Data] ) :-
	encodeDestinations( 0, FloorsHasToBeServed, Data, Size ),
	!.

encodeElevatorControllerMessage( FloorsHasToBeServed, DoorsCommand, Direction, Message ) :-
	elevatorControllerMessageID( ID ),
	encodeDestinations( FloorsHasToBeServed, DestinationsAsCodes ),
	flatten( [ID, DestinationsAsCodes, DoorsCommand, Direction], Message ),
	!.

sendElevatorControllerMessage( DatagramSocket, FloorsHasToBeServed, DoorsCommand, Direction ) :-
	encodeElevatorControllerMessage( FloorsHasToBeServed, DoorsCommand, Direction, Message ),
	debug( log, "Message: ~w", [Message]),
	sendDatagram( DatagramSocket, Message ),
	!.
