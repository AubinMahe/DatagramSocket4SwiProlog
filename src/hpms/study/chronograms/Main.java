package hpms.study.chronograms;

import java.io.File;
import java.util.prefs.Preferences;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

   private static final String ARG_INPUT = "states-path";

   private ChronogramsCtrl _ui;

   private void saveSizeAndLocation( Stage primaryStage ) {
      final double x = primaryStage.getX();
      final double y = primaryStage.getY();
      final double w = primaryStage.getWidth();
      final double h = primaryStage.getHeight();
      final Preferences prefs = Preferences.userNodeForPackage( getClass());
      prefs.putDouble( "x", x );
      prefs.putDouble( "y", y );
      prefs.putDouble( "w", w );
      prefs.putDouble( "h", h );
      _ui.savePreferences();
      System.exit( 0 );
   }

   @Override
   public void start( Stage primaryStage ) throws Exception {
      Thread.currentThread().setContextClassLoader( ClassLoader.getSystemClassLoader());
      final FXMLLoader loader = new FXMLLoader( getClass().getResource( "Chronograms.fxml" ));
      final Parent     view   = loader.load();
      _ui = loader.getController();
      primaryStage.setTitle( "Chronograms" );
      primaryStage.setScene( new Scene( view ));
      primaryStage.setOnCloseRequest( e -> saveSizeAndLocation( primaryStage ));
      primaryStage.setOnHidden( e -> saveSizeAndLocation( primaryStage ));
      final Preferences prefs = Preferences.userNodeForPackage( getClass());
      final double x = prefs.getDouble( "x", Double.NaN );
      if( ! Double.isNaN( x )) {
         final double y = prefs.getDouble( "y", 0.0 );
         final double w = prefs.getDouble( "w", 0.0 );
         final double h = prefs.getDouble( "h", 0.0 );
         primaryStage.setX( x );
         primaryStage.setY( y );
         primaryStage.setWidth( w );
         primaryStage.setHeight( h );
      }
      primaryStage.show();
      final String statesPath = getParameters().getNamed().get( ARG_INPUT );
      if( statesPath != null ) {
         Platform.runLater(() -> _ui.load( new File( statesPath )));
      }
   }
}
