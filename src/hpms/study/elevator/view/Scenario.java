package hpms.study.elevator.view;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.LinkedList;
import java.util.List;

import hpms.study.elevator.types.Intention;

public class Scenario extends Thread {

   private enum Role {
      CABIN,
      ELEVATOR_SHAFT
   }

   private final class Event {

      final long      _timestamp;
      final Role      _role;
      final Byte      _floor;
      final Intention _intention;

      Event( long timestamp, Role role, byte floor, Intention intention ) {
         _role      = role;
         _timestamp = timestamp;
         _floor     = floor;
         _intention = intention;
      }
   }

   private final ElevatorCtrl _ui;
   private final File         _scenarioPath;
   private final boolean      _shouldTrace;

   public Scenario( ElevatorCtrl ui, File scenarioPath, boolean shouldTrace ) {
      _ui           = ui;
      _scenarioPath = scenarioPath;
      _shouldTrace  = shouldTrace;
   }

   @Override
   public void run() {
      final List<Event> events = new LinkedList<>();
      try( BufferedReader br = new BufferedReader( new FileReader( _scenarioPath ))) {
         String line;
         while(( line = br.readLine()) != null ) {
            if( line.isEmpty() || line.charAt( 0 ) == '#' ) {
               continue;
            }
            final String[] parts = line.split( ";" );
            if( parts.length < 3 ) {
               continue;
            }
            final long      ts    = Long.parseLong( parts[0].trim());
            final Role      role  = Role.valueOf  ( parts[1].trim().toUpperCase());
            final byte      floor = Byte.parseByte( parts[2].trim());
            final Intention intention;
            if( role == Role.ELEVATOR_SHAFT ) {
               intention = Intention.valueOf( parts[3].trim().toUpperCase());
            }
            else {
               intention = null;
            }
            events.add( new Event( ts, role , floor, intention ));
         }
         final Runnable[] cabinGui = {
            _ui::cabin0,
            _ui::cabin1,
            _ui::cabin2,
            _ui::cabin3,
            _ui::cabin4,
            _ui::cabin5,
            _ui::cabin6
         };
         final Runnable[][] landingGui = {
            { _ui::landingUp0, null              },
            { _ui::landingUp1, _ui::landingDown1 },
            { _ui::landingUp2, _ui::landingDown2 },
            { _ui::landingUp3, _ui::landingDown3 },
            { _ui::landingUp4, _ui::landingDown4 },
            { _ui::landingUp5, _ui::landingDown5 },
            { null           , _ui::landingDown6 }
         };
         long previous = 0;
         for( final Event event : events ) {
            final long remaining = event._timestamp - previous;
            Thread.sleep( remaining );
            previous = event._timestamp;
            if( event._role == Role.CABIN ) {
               if( _shouldTrace ) {
                  System.err.printf( "Cabin bouton pressed : %d\n", event._floor );
               }
               cabinGui[event._floor].run();
            }
            else {
               if( _shouldTrace ) {
                  System.err.printf( "Landing bouton pressed : %d to go %s\n", event._floor, event._intention );
               }
               landingGui[event._floor][event._intention.ordinal() - 1].run();
            }
         }
      }
      catch( final Exception x ) {
         x.printStackTrace();
      }
   }
}
