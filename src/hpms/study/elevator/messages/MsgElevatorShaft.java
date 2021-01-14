package hpms.study.elevator.messages;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import hpms.study.elevator.model.Constants;
import hpms.study.elevator.types.LandingCall;

public final class MsgElevatorShaft {


   public static final byte ID   = 1;
   public static final int  SIZE =
      Byte  .BYTES +                            // ID
      Double.BYTES +                            // cabinLocation
      Byte  .BYTES +                            // newCalls.size
      ( Byte.BYTES + Byte.BYTES + Long.BYTES )  // {floor, intention, timestamp}
      * ( Constants.MAX_FLOOR + 1 );            // * 7

   public /* */ double           cabinLocation = 0.0;
   public final Set<LandingCall> newCalls = new HashSet<>();

   @Override
   public String toString() {
      return String.format( "cabinLocation: %4.2f, newCalls: %s",
         cabinLocation,
         newCalls.stream().map( d -> d.toString()).collect( Collectors.joining( ", ", "{", "}" )));
   }
}
