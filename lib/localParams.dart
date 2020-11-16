

class localParams {
  int trip;
  String deviceName;
  int LP_Error;
  localParams(this.LP_Error);
}

localParams assignJSON_LP(Map<String, dynamic> mapJSON, localParams LP){
  LP.deviceName = mapJSON['deviceName'];
  LP.trip = mapJSON['trip'];

  return (LP);
}

Map<String, dynamic> assignMap_LP(Map<String, dynamic> mapJSON, localParams LP){
  mapJSON['deviceName'] = LP.deviceName;
  mapJSON['trip'] = LP.trip;

return (mapJSON);
}