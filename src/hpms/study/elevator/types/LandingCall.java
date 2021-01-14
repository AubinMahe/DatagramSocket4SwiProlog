package hpms.study.elevator.types;

public class LandingCall extends Destination {

   public final Intention intention;

   public LandingCall( int floor_, Intention intention_, long ts ) {
      super( floor_, ts );
      intention = intention_;
   }

   @Override
   public String toString() {
      return String.format( "floor: %d, timestamp: %6d, intention: %s", floor, timestamp, intention );
   }

   @Override
   public int compareTo( Destination right ) {
      int diff = floor - right.floor;
      if( diff == 0 ) {
         diff = intention.ordinal() - ((LandingCall)right).intention.ordinal();
      }
      return diff;
   }
}
