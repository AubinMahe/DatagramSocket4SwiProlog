package hpms.study.elevator.types;

public class Destination implements Comparable<Destination> {

   public final byte   floor;
   public final long   timestamp;

   public Destination( int floor_, long ts ) {
      floor     = (byte)floor_;
      timestamp = ts;
   }

   @Override
   public String toString() {
      return String.format( "floor: %d,timestamp: %6d", floor, timestamp );
   }

   @Override
   public int compareTo( Destination right ) {
      final int diff = floor - right.floor;
      return diff;
   }
}
