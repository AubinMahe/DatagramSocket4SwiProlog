package hpms.study.elevator.messages;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import hpms.study.elevator.model.Constants;
import hpms.study.elevator.types.Destination;

public class MsgCabin {

   public static final byte ID   = 2;
   public static final int  SIZE =
      Byte  .BYTES +                                              // ID
      Byte  .BYTES +                                              // newDestinations.size
      ( Byte.BYTES + Long.BYTES ) * ( Constants.MAX_FLOOR + 1 ) + // {floor, timestamp}{7}
      Byte  .BYTES +                                              // doorsAreOpen
      Byte  .BYTES;                                               // doorsAreClosed

   public final Set<Destination> newDestinations = new HashSet<>();
   public /* */ boolean          doorsAreOpen;
   public /* */ boolean          doorsAreClosed;

   @Override
   public String toString() {
      return String.format( "newDestinations: %s, doorsAreOpen: %s, doorsAreClosed: %s",
         newDestinations.stream().map( d -> d.toString()).collect( Collectors.joining( ", ", "{", "}" )),
         Boolean.toString( doorsAreOpen ), Boolean.toString( doorsAreClosed ));
   }
}
