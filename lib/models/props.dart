import 'package:fluttertoast/fluttertoast.dart';

class Props {
  static Uri currentWeatherApi = Uri.parse("http://api.weatherapi.com/v1/current.json?");

  static String appName = "My Area";
}

toast(msg) {
  print(msg);
  Fluttertoast.cancel();
  Fluttertoast.showToast(msg: msg);
}
