

class controllerState {

 //page 1
 int Temperature_State;
 int Travel_Mode_State;
 int System_State;
 int Gear_State;
 int LEV_Error= 0;
 int Speed= 0;
 int Assist_Level;
 int Regen_Level;

 //page 2
 int Odometer= 0;
 int Remaining_range= 0;

 //page 3
 int Battery_SOC= 0;
 int Percentage_Assist= 0;

 //page 4
 int Charging_Cycle= 0;
 int Fuel_Consuption= 0;
 int Battery_Voltage= 0;
 int Distance_On_Recent_Charge= 0;

 //page 5
 int Travel_Modes_Supported= 0;
 int Wheel_Circumference= 0;

 //page 16

 int Display_Command= 0;
 int Manufacturer_ID= 0;


 controllerState(this.LEV_Error);

}

List prepare_Ant_Message (int Page, controllerState State ){
State.Travel_Mode_State = State.Regen_Level|State.Assist_Level<<3;
 List <int> message = new List<int>(12);

 message[0] = 164; //Sync binary 10100100;
 message[1] = 12;  //MsgLength
 message[2] = 0x4E; // MsgID for 0x4E for "broadcast Data"

 message[3] = Page;

 switch (Page) {
  case 16:
   {
    message[4] = State.Wheel_Circumference & 0xFF; //Low Byte
    message[5] = State.Wheel_Circumference >> 8 & 0xFF; // HiByte
    message[6] = State.Travel_Mode_State;
    message[7] = State.Display_Command & 0xFF; //Low Byte
    message[8] = State.Display_Command >> 8 & 0xFF; // HiByte
    message[9] = State.Manufacturer_ID & 0xFF; //Low Byte
    message[10] = State.Manufacturer_ID >> 8 & 0xFF; //Hi Byte
   }
   break;
  default:
   {

   }
 }
 message[11]=0;

 for (var i = 0; i < 11; i++) {
  message[11] ^= message[i];
 }

 return (message);
}


controllerState processRxAnt(List RxAnt, controllerState State){

 int chkSum = 0;
 int page = RxAnt[3];
 for (var i = 0; i < 11; i++) {
  chkSum ^= RxAnt[i];
 }
 if(chkSum==RxAnt[11]) {
  switch (page) {
   case 1:
    {
      State.Temperature_State=RxAnt[4];
      State.Travel_Mode_State=RxAnt[5];
      State.System_State=RxAnt[6];
      State.Gear_State=RxAnt[7];
      State.LEV_Error=RxAnt[8];
      State.Speed=RxAnt[10]<<8|RxAnt[9];
      State.Assist_Level = State.Travel_Mode_State>>3 & 0x07;
      State.Regen_Level = State.Travel_Mode_State & 0x07;
    }
    break;
   default:
    {

    }
  }
 }


 return (State);
}
