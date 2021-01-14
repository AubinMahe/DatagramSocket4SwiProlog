package hpms.study.chronograms;

import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.util.Callback;

public final class ChronogramCellFactory implements Callback<ListView<Samples>, ListCell<Samples>> {

   @Override
   public ListCell<Samples> call( ListView<Samples> param ) {
      return new ChronogramListCell();
   }
}
