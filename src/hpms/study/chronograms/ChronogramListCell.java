package hpms.study.chronograms;

import javafx.geometry.VPos;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.ListCell;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.FontSmoothingType;
import javafx.scene.transform.Transform;

public final class ChronogramListCell extends ListCell<Samples> {

   public static final double MARGIN = 4.0;

   private final Canvas _canvas = new Canvas( 1500, 80 );

   private void draw( Samples samples ) {
      final GraphicsContext gc = _canvas.getGraphicsContext2D();
      gc.save();
      final double w = _canvas.getWidth();
      final double h = _canvas.getHeight();
      Samples._scaleX = ( w - 2.0*MARGIN ) / ( Samples._last - Samples._first );
      final double scaleY = ( h - 2.0*MARGIN ) / Math.abs( samples._max -samples._min );
      final double penWidth = 1.0/Math.max( Samples._scaleX, scaleY );
      gc.setStroke( Color.LIGHTGRAY );
      gc.setTextBaseline( VPos.TOP );
      gc.setFont( Font.font( "sans-serif", 10.0 ));
      gc.setFontSmoothingType( FontSmoothingType.GRAY );
      gc.strokeText( samples._name.get(), 20.0, 0.0 );
      gc.setTransform( Transform.affine( Samples._scaleX, 0.0, 0.0, -scaleY, MARGIN, h - MARGIN ));
      gc.beginPath();
      gc.setLineWidth( penWidth );
      gc.setStroke( Color.DARKGRAY );
      gc.moveTo( -MARGIN/Samples._scaleX, 0 );
      gc.lineTo( w/Samples._scaleX, 0 );
      gc.moveTo( 0, -MARGIN/scaleY );
      gc.lineTo( 0, h/scaleY );
      for( int t = 1, last = (int)(Samples._last - Samples._first); t < last; ++t ) {
         gc.moveTo( t, -MARGIN*scaleY );
         if(( t % 10 ) == 0 ) {
            gc.lineTo( t, h/scaleY );
         }
         else {
            gc.lineTo( t, +MARGIN/scaleY );
         }
      }
      gc.stroke();
      gc.beginPath();
      gc.setStroke( Color.BLUE );
      double px = 0.0;
      double py = Double.NaN;
      for( final Sample sample : samples._values ) {
         final double timestamp = sample._timestamp - Samples._first;
         final double y = sample._value;
         if( Double.isNaN( py )) {
            gc.moveTo( timestamp, y );
         }
         else if( Math.abs( y - py ) < 0.000001 ) {
            gc.lineTo( timestamp, y );
         }
         else {
            gc.lineTo( px, y );
            gc.lineTo( timestamp, y );
         }
         px = timestamp;
         py = y;
      }
      gc.stroke();
      gc.restore();
   }

   @Override
   protected void updateItem( Samples item, boolean empty) {
      super.updateItem( item, empty );
      setText( null );
      if( empty ) {
         setText( null );
      }
      else if( item == null ) {
         setText( "No sample." );
      }
      else {
         setText( null );
         setGraphic( _canvas );
         draw( item );
      }
   }
}
