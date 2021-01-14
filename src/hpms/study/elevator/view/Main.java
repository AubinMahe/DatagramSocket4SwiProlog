package hpms.study.elevator.view;

import java.io.File;
import java.util.Map;
import java.util.prefs.Preferences;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

   private static final String ARG_HOST         = "host";
   private static final String ARG_PORT         = "port";
   private static final String ARG_SHOULD_TRACE = "should-trace";

   public static void main( String[] args ) {
      launch( Main.class, args );
   }

   private Network      _network;
   private ElevatorCtrl _uiCtrl;

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
      try {
         _uiCtrl.endRecord();
         _network.halt();
      }
      catch( final Throwable t ) {/**/}
   }

   @Override
   public void start( Stage primaryStage ) throws Exception {
      final FXMLLoader  loader = new FXMLLoader( getClass().getResource( "Elevator.fxml" ));
      final Parent      view   = loader.load();
      _uiCtrl = loader.getController();
      final Preferences prefs  = Preferences.userNodeForPackage( getClass());
      final double      x      = prefs.getDouble( "x", Double.NaN );
      primaryStage.setTitle( "Ascenseur" );
      primaryStage.setScene( new Scene( view ));
      primaryStage.setOnCloseRequest( e -> saveSizeAndLocation( primaryStage ));
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
      if( ! getParameters().getRaw().isEmpty()) {
         final Map<String, String> named = getParameters().getNamed();
         final String host = named.get( ARG_HOST );
         final int    port = Integer.parseInt( named.get( ARG_PORT ));
         final boolean shouldTrace = Boolean.parseBoolean( named.get( ARG_SHOULD_TRACE ));
         _network = new Network( host, port, shouldTrace );
         _uiCtrl.setNetwork( _network );
         final File scenarioPath = named.containsKey( "scenario" ) ? new File( named.get( "scenario" )) : null;
         final String action = named.get( "scenario-action" );
         if( scenarioPath != null && scenarioPath.canRead() && action.equals( "execute" )) {
            new Scenario( _uiCtrl, scenarioPath, shouldTrace ).start();
         }
         else if( scenarioPath != null && action.equals( "record" )) {
            _uiCtrl.recordUserActionsTo( scenarioPath );
         }
      }
   }
}
