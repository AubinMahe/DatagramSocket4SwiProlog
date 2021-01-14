package hpms.study.chronograms;

import java.io.File;
import java.io.IOException;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.prefs.Preferences;

import javax.imageio.ImageIO;

import javafx.application.Platform;
import javafx.collections.ObservableList;
import javafx.embed.swing.SwingFXUtils;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.scene.SnapshotParameters;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.SplitPane;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.image.WritableImage;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.stage.FileChooser;
import javafx.stage.FileChooser.ExtensionFilter;

public class ChronogramsCtrl {

   @FXML private SplitPane                     _splitPane;
   @FXML private TableView<Samples>            _variablesVw;
   @FXML private ListView<Samples>             _chronogramsVw;
   @FXML private TableColumn<Samples, String>  _nameClmn;
   @FXML private TableColumn<Samples, Type>    _typeClmn;
   @FXML private TableColumn<Samples, Boolean> _displayedClmn;
   @FXML private StackPane                     _timeMarkContainer;
   @FXML private VBox                          _timeMark;
   @FXML private Label                         _times;

   private final FileChooser                _fileChooser = new FileChooser();
   private final SortedMap<String, Samples> _chronograms = new TreeMap<>();

   @FXML
   private void initialize() {
      _fileChooser.setInitialDirectory( new File( System.getProperty( "user.home" )));
      final Preferences prefs = Preferences.userNodeForPackage( getClass());
      final double nameWidth = prefs.getDouble( "name.widht", -1.0 );
      if( nameWidth > 0.0 ) {
         _nameClmn.setPrefWidth( nameWidth );
      }
      final double typeWidth = prefs.getDouble( "type.widht", -1.0 );
      if( typeWidth > 0.0 ) {
         _typeClmn.setPrefWidth( typeWidth );
      }
      _displayedClmn.setPrefWidth( 24 );
      final double div = prefs.getDouble( "div.pos", 0.5 );
      Platform.runLater(() -> Platform.runLater(() -> _splitPane.setDividerPosition( 0, div )));
   }

   @FXML
   private void moveTimeMark( MouseEvent e ) {
      final double x = e.getX();
      final Insets leftMargin = new Insets( 0.0, 0.0, 0.0, -_timeMarkContainer.getWidth() + 2.0*x );
      StackPane.setMargin( _timeMark , leftMargin );
      _times.setText( String.format( "%15.4f\n%15.4f",
         Samples._first + x / Samples._scaleX - 0.74,
         x / Samples._scaleX - 0.74 ));
      StackPane.setMargin( _times, leftMargin );
   }

   void savePreferences() {
      final double nameWidth = _nameClmn.getWidth();
      final double div = _splitPane.getDividerPositions()[0];
      final Preferences prefs = Preferences.userNodeForPackage( getClass());
      prefs.putDouble( "name.widht", nameWidth );
      prefs.putDouble( "div.pos"   , div );
   }

   void backgroundLoading( File statesPath ) {
      try {
         StatesParser.parse( statesPath, _chronograms );
         Platform.runLater(() -> {
            _variablesVw  .setPlaceholder( new Label( "Le fichier ne contient aucune variable." ));
            _chronogramsVw.setPlaceholder( new Label( "Aucun chronogramme." ));
            _variablesVw.getItems().setAll( _chronograms.values());
            final ObservableList<Samples> chronogramList = _chronogramsVw.getItems();
            chronogramList.clear();
            for( final Samples chronogram : _chronograms.values()) {
               if( chronogram._displayed.get()) {
                  chronogramList.add( chronogram );
               }
            }
         });
      }
      catch( final Throwable t ) {
         t.printStackTrace();
      }
   }

   void load( File statesPath ) {
      if( statesPath.canRead()) {
         _chronograms.clear();
         _variablesVw  .getItems().clear();
         _chronogramsVw.getItems().clear();
         _variablesVw  .setPlaceholder( new Label( "Loading in progress, please wait..." ));
         _chronogramsVw.setPlaceholder( new Label( "Loading in progress, please wait..." ));
         final Thread background = new Thread(() -> backgroundLoading( statesPath ), "Chronograms-Parser" );
         background.setDaemon( true );
         background.start();
      }
      else {
         _chronogramsVw.setPlaceholder( new Label( statesPath + " doesn't exists..." ));
      }
   }

   @FXML
   private void open() {
      _fileChooser.setSelectedExtensionFilter( null );
      final File statesPath = _fileChooser.showOpenDialog( _splitPane.getScene().getWindow());
      if( statesPath != null ) {
         load( statesPath );
      }
   }

   @FXML
   private void exportAsPng() {
      final WritableImage image = _chronogramsVw.snapshot( new SnapshotParameters(), null );
      _fileChooser.setSelectedExtensionFilter( new ExtensionFilter( "PNG image", "*.png" ));
      File imageFile = _fileChooser.showSaveDialog( _splitPane.getScene().getWindow());
      if( imageFile != null ) {
         try {
            if( ! imageFile.getName().toLowerCase().endsWith( ".png" )) {
               imageFile = new File( imageFile.getPath() + ".png" );
            }
            ImageIO.write( SwingFXUtils.fromFXImage( image, null ), "png", imageFile );
         }
         catch( final IOException e ) {
            e.printStackTrace();
         }
      }
   }

   @FXML private void exit() {
      _variablesVw.getScene().getWindow().hide();
   }
}
