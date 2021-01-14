package hpms.study.elevator.messages;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import hpms.study.elevator.model.Constants;
import hpms.study.elevator.types.Direction;
import hpms.study.elevator.types.DoorsCommand;

public final class MsgElevatorController {

   public static final byte ID   = 3;
   public static final int  SIZE =
      Byte.BYTES +                                 // ID
      Byte.BYTES +                                 // destinations.size
      Byte.BYTES * ( Constants.MAX_FLOOR + 1 ) +   // destinations
      Byte.BYTES +                                 // doorsCommand
      Byte.BYTES;                                  // direction

   public final Set<Byte>    destinations = new HashSet<>();
   public /* */ DoorsCommand doorsCommand = DoorsCommand.NONE;
   public /* */ Direction    direction    = Direction.HALTED;

   @Override
   public String toString() {
      return String.format( "newDestinations: %s, doorsCommand: %s, direction: %s",
         destinations.stream().map( d -> d.toString()).collect( Collectors.joining( ", ", "{", "}" )),
         doorsCommand,
         direction );
   }
}
