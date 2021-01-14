package hpms.study.elevator.view;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.Set;
import java.util.TreeSet;

import hpms.study.elevator.messages.MsgCabin;
import hpms.study.elevator.messages.MsgElevatorController;
import hpms.study.elevator.messages.MsgElevatorShaft;
import hpms.study.elevator.model.Constants;
import hpms.study.elevator.types.Destination;
import hpms.study.elevator.types.Direction;
import hpms.study.elevator.types.Intention;
import hpms.study.elevator.types.LandingCall;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.CheckBox;
import javafx.scene.control.RadioButton;
import javafx.scene.paint.Color;

public class ElevatorCtrl extends Thread {

   private static final long PERIOD =   40; // ms, 25 images / secondes
// private static final long PERIOD = 1000; // ms, en mise au point

   @FXML private Canvas      _canvas;
   @FXML private RadioButton _doorsIndeterminated;
   @FXML private RadioButton _doorsOpen;
   @FXML private RadioButton _doorsClosed;
   @FXML private CheckBox    _ctrlPanel0;
   @FXML private CheckBox    _ctrlPanel1;
   @FXML private CheckBox    _ctrlPanel2;
   @FXML private CheckBox    _ctrlPanel3;
   @FXML private CheckBox    _ctrlPanel4;
   @FXML private CheckBox    _ctrlPanel5;
   @FXML private CheckBox    _ctrlPanel6;

   private final long             _atStart          = System.currentTimeMillis();
   private final MsgElevatorShaft _msgElevatorShaft = new MsgElevatorShaft();
   private final MsgCabin         _msgCabin         = new MsgCabin();
   private /* */ INetwork         _network;
   private final Set<LandingCall> _newCalls         = new TreeSet<>();
   private final Set<Destination> _newDestinations  = new TreeSet<>();
   private /* */ double           _ouverturePorte   = 0.0; // Fermée
   private /* */ double           _location         = 0.0; // Etage n°0, Rez-de-chaussée
   private /* */ PrintStream      _scenario         = null;

   public void setNetwork( INetwork network ) {
//      System.err.println( getClass().getName() + ".setNetwork|network = " + network );
      _network = network;
      setName( getClass().getSimpleName());
      setDaemon( true );
      start();
   }

   public void recordUserActionsTo( File scenarioPath ) throws FileNotFoundException {
      _scenario = new PrintStream( scenarioPath );
   }

   public void endRecord() {
      if( _scenario != null ) {
         _scenario.close();
      }
   }

   private void landingCall( int floor, Intention intention ) {
      final long ts = System.currentTimeMillis();
      _newCalls.add( new LandingCall( floor, intention , ts ));
      if( _scenario != null ) {
         _scenario.printf( "%5d ; Elevator_Shaft ; %d ; %s\n", ts - _atStart, floor, intention );
      }
   }

   @FXML final void landingDown6() { landingCall( 6, Intention.DOWN ); }
   @FXML final void landingUp5()   { landingCall( 5, Intention.UP   ); }
   @FXML final void landingDown5() { landingCall( 5, Intention.DOWN ); }
   @FXML final void landingUp4()   { landingCall( 4, Intention.UP   ); }
   @FXML final void landingDown4() { landingCall( 4, Intention.DOWN ); }
   @FXML final void landingUp3()   { landingCall( 3, Intention.UP   ); }
   @FXML final void landingDown3() { landingCall( 3, Intention.DOWN ); }
   @FXML final void landingUp2()   { landingCall( 2, Intention.UP   ); }
   @FXML final void landingDown2() { landingCall( 2, Intention.DOWN ); }
   @FXML final void landingUp1()   { landingCall( 1, Intention.UP   ); }
   @FXML final void landingDown1() { landingCall( 1, Intention.DOWN ); }
   @FXML final void landingUp0()   { landingCall( 0, Intention.UP   ); }

   private void cabin( int floor ) {
      final long ts = System.currentTimeMillis();
      _newDestinations.add( new Destination( floor, ts ));
      if( _scenario != null ) {
         _scenario.printf( "%5d ; Cabin ; %d\n", ts - _atStart, floor );
      }
   }

   @FXML final void cabin6() { cabin( 6 ); }
   @FXML final void cabin5() { cabin( 5 ); }
   @FXML final void cabin4() { cabin( 4 ); }
   @FXML final void cabin3() { cabin( 3 ); }
   @FXML final void cabin2() { cabin( 2 ); }
   @FXML final void cabin1() { cabin( 1 ); }
   @FXML final void cabin0() { cabin( 0 ); }

   private void updateControlPanel() {
      final MsgElevatorController cmd = _network.getElevatorMsg();
      synchronized( cmd ) {
         _ctrlPanel0.setSelected( false );
         _ctrlPanel1.setSelected( false );
         _ctrlPanel2.setSelected( false );
         _ctrlPanel3.setSelected( false );
         _ctrlPanel4.setSelected( false );
         _ctrlPanel5.setSelected( false );
         _ctrlPanel6.setSelected( false );
         for( final byte dest : cmd.destinations ) {
            switch( dest ) {
            case 0: _ctrlPanel0.setSelected( true ); break;
            case 1: _ctrlPanel1.setSelected( true ); break;
            case 2: _ctrlPanel2.setSelected( true ); break;
            case 3: _ctrlPanel3.setSelected( true ); break;
            case 4: _ctrlPanel4.setSelected( true ); break;
            case 5: _ctrlPanel5.setSelected( true ); break;
            case 6: _ctrlPanel6.setSelected( true ); break;
            }
         }
         cmd.destinations.clear();
      }
   }

   private void redraw() {
      if( _canvas == null ) {
         return;
      }
      final boolean closed = _ouverturePorte < Constants.DOORS_MOVE_STEP;
      final boolean open   = _ouverturePorte > 1.0 - Constants.DOORS_MOVE_STEP;
      _doorsClosed.setSelected( closed );
      _doorsOpen  .setSelected( open );
      _doorsIndeterminated.setSelected(( ! closed )&&( ! open ));
      final GraphicsContext ctxt     = _canvas.getGraphicsContext2D();
      final double          width    = _canvas.getWidth();
      final double          height   = _canvas.getHeight();
      final double          yCabine  = height - width * ( Constants.MAX_FLOOR * _location + 1 );
      ctxt.setFill( Color.LIGHTBLUE );
      ctxt.clearRect( 0, 0, width, height );
      ctxt.fillRect( 0, yCabine, width, width );
      ctxt.strokeRect( 0, 0, width, height );
      if( _ouverturePorte > 0.0 ) {
         ctxt.setFill( Color.DARKBLUE );
         final double doorWidth = (width-20.0)*_ouverturePorte;
         ctxt.fillRect(( width - doorWidth ) / 2.0, yCabine, doorWidth, width );
      }
      else {
         ctxt.setStroke( Color.DARKBLUE );
         ctxt.strokeLine( width/2, yCabine, width/2, yCabine+width );
      }
   }

   private void openDoors() {
      _ouverturePorte += Constants.DOORS_MOVE_STEP;
      if( _ouverturePorte > 1.0 ) {
         _ouverturePorte = 1.0;
      }
   }

   private void closeDoors() {
      _ouverturePorte -= Constants.DOORS_MOVE_STEP;
      if( _ouverturePorte < 0.0 ) {
         _ouverturePorte = 0.0;
      }
   }

   private void publishElevatorShaft() {
      _msgElevatorShaft.cabinLocation = _location;
      _msgElevatorShaft.newCalls.clear();
      _msgElevatorShaft.newCalls.addAll( _newCalls );
      _network.publishElevatorShaft( _msgElevatorShaft );
      _newCalls.clear();
   }

   private void publishCabin() {
      final boolean closed = _ouverturePorte < Constants.DOORS_MOVE_STEP;
      final boolean open   = _ouverturePorte > 1.0 - Constants.DOORS_MOVE_STEP;
      _msgCabin.newDestinations.clear();
      _msgCabin.newDestinations.addAll( _newDestinations );
      _msgCabin.doorsAreOpen   = open;
      _msgCabin.doorsAreClosed = closed;
      _network.publishCabin( _msgCabin );
      _newDestinations.clear();
   }

   @Override
   public void run() {
      for(;;) {
         final long atStart = System.currentTimeMillis();
         final MsgElevatorController cmd = _network.getElevatorMsg();
         synchronized( cmd ) {
            if( cmd.direction == Direction.UP ) {
               if( _ouverturePorte > Constants.DOORS_MOVE_STEP ) {
                  throw new IllegalStateException( "L'ascenseur ne doit pas bouger portes ouvertes (" + _ouverturePorte + ") !" );
               }
               _location += Constants.CABIN_MOVE_STEP;
               if( _location > 1.0 ) {
                  _location  = 1.0;
               }
               Platform.runLater( this::updateControlPanel );
            }
            else if( cmd.direction == Direction.DOWN ) {
               if( _ouverturePorte > Constants.DOORS_MOVE_STEP ) {
                  throw new IllegalStateException( "L'ascenseur ne doit pas bouger portes ouvertes (" + _ouverturePorte + ") !" );
               }
               _location -= Constants.CABIN_MOVE_STEP;
               if( _location < 0.0 ) {
                  _location  = 0.0;
               }
               Platform.runLater( this::updateControlPanel );
            }
            switch( cmd.doorsCommand ) {
            default:
            case NONE: break;
            case OPEN:
               openDoors();
               Platform.runLater( this::updateControlPanel );
               break;
            case CLOSE:
               closeDoors();
               Platform.runLater( this::updateControlPanel );
               break;
            }
         }
         Platform.runLater( this::redraw );
         publishCabin();
         publishElevatorShaft();
         final long duration = PERIOD - ( System.currentTimeMillis() - atStart );
         try { Thread.sleep( Math.max( 0, duration ) ); }
         catch( final InterruptedException x ) {/**/}
      }
   }
}
