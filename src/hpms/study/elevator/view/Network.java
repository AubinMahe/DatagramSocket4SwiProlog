package hpms.study.elevator.view;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.util.HashSet;
import java.util.Set;

import hpms.study.elevator.messages.MsgCabin;
import hpms.study.elevator.messages.MsgElevatorController;
import hpms.study.elevator.messages.MsgElevatorShaft;
import hpms.study.elevator.messages.NetworkConstants;
import hpms.study.elevator.types.Destination;
import hpms.study.elevator.types.Direction;
import hpms.study.elevator.types.DoorsCommand;
import hpms.study.elevator.types.LandingCall;

final class Network extends Thread implements INetwork {

   private final boolean               _shouldTrace;
   private final MsgElevatorController _msgElevatorCtrl  = new MsgElevatorController();
   private final DatagramChannel       _channel          = DatagramChannel.open();
   private final Set<Byte>             _lastDestinations = new HashSet<>();
   private /* */ DoorsCommand          _lastDoorsCommand = DoorsCommand.NONE;
   private /* */ Direction             _lastDirection    = Direction.HALTED;
   private final SocketAddress         _target;

   @SuppressWarnings("resource")
   public Network( String host, int port, boolean shouldTrace ) throws IOException {
      _shouldTrace = shouldTrace;
      _target      = new InetSocketAddress( host, port );
      _channel.bind( new InetSocketAddress( host, port + 1 ));
      setName( "Inetwork" );
      setDaemon( true );
      start();
   }

   @Override
   public boolean shouldTrace() {
      return _shouldTrace;
   }

   @Override
   public MsgElevatorController getElevatorMsg() {
      return _msgElevatorCtrl;
   }

   @Override
   public MsgElevatorShaft getElevatorShaftMsg() {
      return null;
   }

   @Override
   public MsgCabin getCabinMsg() {
      return null;
   }

   private void send( MsgElevatorShaft msg, DatagramChannel channel, SocketAddress target ) {
      try {
         final ByteBuffer bb = ByteBuffer.allocate( MsgElevatorShaft.SIZE );
         bb.put( MsgElevatorShaft.ID );
         bb.putDouble( msg.cabinLocation );
         bb.put((byte)msg.newCalls.size());
         for( final LandingCall call : msg.newCalls ) {
            bb.put( call.floor );
            bb.put((byte)call.intention.ordinal());
            bb.putLong( call.timestamp );
         }
         bb.flip();
         channel.send( bb, target );
         if( _shouldTrace ) {
            System.err.printf( "ElevatorShaft message sent: %s\n", msg.toString());
         }
      }
      catch( final Throwable t ) {
         t.printStackTrace();
      }
   }

   @Override
   public void publishElevatorShaft( MsgElevatorShaft msg ) {
      send( msg, _channel, _target );
   }

   private boolean prevOpen   = false;
   private boolean prevClosed = true;

   private void send( MsgCabin msg, DatagramChannel channel, SocketAddress target ) {
      try {
         final ByteBuffer bb = ByteBuffer.allocate( MsgCabin.SIZE );
         bb.put( MsgCabin.ID );
         bb.put((byte)msg.newDestinations.size());
         for( final Destination destination : msg.newDestinations ) {
            bb.put( destination.floor );
            bb.putLong( destination.timestamp );
         }
         bb.put( msg.doorsAreOpen   ? NetworkConstants.TRUE : NetworkConstants.FALSE );
         bb.put( msg.doorsAreClosed ? NetworkConstants.TRUE : NetworkConstants.FALSE );
         bb.flip();
         channel.send( bb, target );
         if( _shouldTrace ) {
            System.err.printf( "Cabin message sent: %s\n", msg.toString());
         }
         if( !prevOpen && msg.doorsAreOpen && prevClosed && !msg.doorsAreClosed ) {
            throw new IllegalStateException( "Les mouvements de portes sont continus !" );
         }
         if( prevOpen && !msg.doorsAreOpen && !prevClosed && msg.doorsAreClosed ) {
            throw new IllegalStateException( "Les mouvements de portes sont continus !" );
         }
         prevOpen   = msg.doorsAreOpen;
         prevClosed = msg.doorsAreClosed;
      }
      catch( final Throwable t ) {
         t.printStackTrace();
      }
   }

   @Override
   public void publishCabin( MsgCabin msg ) {
      send( msg, _channel, _target );
   }

   public void halt() {
      final MsgCabin msg = new MsgCabin();
      msg.doorsAreOpen   = true;
      msg.doorsAreClosed = true;
      send( msg, _channel, _target );
   }

   @Override
   public void run() {
      final ByteBuffer src = ByteBuffer.allocate( 64*1024 );
      for(;;) {
         try {
            src.clear();
            _channel.receive( src );
            src.flip();
            final byte id = src.get();
            if( _shouldTrace ) {
               System.err.printf( "message received, %d bytes, ID is %d\n", src.remaining(), id );
            }
            switch( id ) {
            default: break;
            case MsgElevatorController.ID:
               for( int i = 0, count = src.get(); i < count; ++i ) {
                  _msgElevatorCtrl.destinations.add( src.get());
               }
               _msgElevatorCtrl.doorsCommand = DoorsCommand.values()[src.get()];
               _msgElevatorCtrl.direction    = Direction   .values()[src.get()];
               if(  ( _msgElevatorCtrl.destinations.size() != _lastDestinations.size())
                  ||( _msgElevatorCtrl.doorsCommand        != _lastDoorsCommand       )
                  ||( _msgElevatorCtrl.direction           != _lastDirection          ))
               {
                  if( _shouldTrace ) {
                     System.err.printf( "ElevatorController message received: %s\n", _msgElevatorCtrl.toString());
                  }
                  _lastDestinations.clear();
                  _lastDestinations.addAll( _msgElevatorCtrl.destinations );
                  _lastDoorsCommand = _msgElevatorCtrl.doorsCommand;
                  _lastDirection    = _msgElevatorCtrl.direction;
               }
            break;
            }
         }
         catch( final IOException e ) {
            e.printStackTrace();
         }
      }
   }
}
