package hpms.study.chronograms;

import java.util.ArrayList;
import java.util.List;

import javafx.beans.property.BooleanProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;

public final class Samples {

   static double _first;
   static double _last;
   static double _scaleX;

   final StringProperty       _name      = new SimpleStringProperty();
   final ObjectProperty<Type> _type      = new SimpleObjectProperty<>();
   final BooleanProperty      _displayed = new SimpleBooleanProperty();

   final List<Sample> _values = new ArrayList<>( 10_000 );
   /* */ double        _min;
   /* */ double        _max;

   public Samples( String name, Type type ) {
      _name.set( name );
      _type.set( type );
   }

   public StringProperty       nameProperty()      { return _name; }
   public ObjectProperty<Type> typeProperty()      { return _type; }
   public BooleanProperty      displayedProperty() { return _displayed; }

   void addSample( double time, String value ) {
      final double v;
      switch( _type.get()) {
      case BOOLEAN: v = Boolean.parseBoolean( value ) ? 1.0 : 0.0; break;
      default: // user defined enums
      case INTEGER: v = Integer.parseInt    ( value ); break;
      case FLOAT  : v = Double .parseDouble ( value ); break;
      case LIST   : v = 0.0; break;
      }
      _min = Math.min( _min, v );
      _max = Math.max( _max, v );
      _values.add( new Sample( time, v ));
   }

   public void compact() {
      Sample s1 = null;
      Sample s2 = null;
      final List<Sample> compacted = new ArrayList<>( 5_000 );
      for( final Sample sample : _values ) {
         if( s1 == null ) {
            s1 = sample;
            compacted.add( s1 );
         }
         else if( s2 == null ) {
            s2 = sample;
         }
         else {
            final Sample s3 = sample;
            if( ! ( s1.hasSameValue( s2, 1.11E-16 ) && s2.hasSameValue( s3, 1.11E-16 ))) {
               compacted.add( s2 );
            }
            s1 = s2;
            s2 = s3;
         }
      }
      _values.clear();
      _values.addAll( compacted );
   }
}
