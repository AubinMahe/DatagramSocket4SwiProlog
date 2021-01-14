package hpms.study.elevator.view;

import hpms.study.elevator.messages.MsgCabin;
import hpms.study.elevator.messages.MsgElevatorController;
import hpms.study.elevator.messages.MsgElevatorShaft;

public interface INetwork {

   boolean shouldTrace();

   MsgElevatorController getElevatorMsg();
   MsgElevatorShaft      getElevatorShaftMsg();
   MsgCabin              getCabinMsg();

   void publishElevatorShaft( MsgElevatorShaft msg );
   void publishCabin        ( MsgCabin         msg );
}
