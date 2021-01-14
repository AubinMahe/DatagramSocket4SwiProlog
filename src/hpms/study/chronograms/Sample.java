package hpms.study.chronograms;

final class Sample {

   final double _timestamp;
   final double _value;

   Sample( double time, double v ) {
      _timestamp = time;
      _value     = v;
   }

   public boolean hasSameValue( Sample other, double epsilon ) {
      return Math.abs( _value - other._value ) < epsilon;
   }
}
