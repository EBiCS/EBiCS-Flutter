

class controllerState {

 //page 1
 int Temperature_State;
 int Travel_Mode_State;
 int System_State;
 int Gear_State;
 int LEV_Error;
 int Speed;
 int Assist_Level;
 int Regen_Level;

 //page 2
 int Odometer;
 int Remaining_range;

 //page 3
 int Battery_SOC;
 int Percentage_Assist;

 //page 4
 int Charging_Cycle;
 int Fuel_Consuption;
 int Battery_Voltage;
 int Distance_On_Recent_Charge;

 //page 5
 int Travel_Modes_Supported;
 int Wheel_Circumference;

 //page 16

 int Display_Command;
 int Manufacturer_ID;


 controllerState(this.LEV_Error);

}

List prepare_Ant_Message (int Page, controllerState State ){
 List <int> message = new List<int>();
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



