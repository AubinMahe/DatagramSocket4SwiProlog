package hpms.study.chronograms;

import javafx.beans.property.BooleanProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.cell.CheckBoxTableCell;
import javafx.util.Callback;

public class CheckBoxTableCellFactory<S,T> implements Callback<TableColumn<S, T>, TableCell<S, T>> {

   private final BooleanProperty _disable = new SimpleBooleanProperty();

   public BooleanProperty disableProperty() { return _disable; }

   public boolean getDisable() { return _disable.get(); }

   public void setDisable( boolean d ) { _disable.set( d ); }

   @Override
   public TableCell<S, T> call(TableColumn<S, T> param) {
      final CheckBoxTableCell<S,T> cbtc = new CheckBoxTableCell<>();
      cbtc.setDisable( disableProperty().get());
      return cbtc;
  }
}
