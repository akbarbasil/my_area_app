import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import '../models/props.dart';
import 'package:geolocator/geolocator.dart';

class MainScreen extends StatefulWidget {
  static const routename = "/MainScreen";

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _lat, _long;
  var _locationPermission = false, _isloading = false;

  Future<Map> _getCurrentWeatherInfo() async {
    var apikey = dotenv.env["API_KEY"]!;
    var url = Uri.parse("${Props.currentWeatherApi}key=$apikey&q=$_lat,$_long");
    var res = await get(url);
    Map map = jsonDecode(res.body.trim());
    print(map);
    return map;
  }

  Future _latlong() async {
    setState(() {
      _isloading = true;
      _locationPermission = false;
    });
    LocationPermission checkPermission = await Geolocator.requestPermission();
    print(checkPermission);
    if (checkPermission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Enable Location Permission"),
          backgroundColor: Colors.red,
        ),
      );
    } else if (checkPermission == LocationPermission.deniedForever) {
      _isloading = false;
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

        print("latitude : ${position.latitude}");
        print("longitude : ${position.longitude}");

        _lat = position.latitude;
        _long = position.longitude;

        _isloading = false;
        _locationPermission = true;
      } catch (e) {
        _isloading = false;
        print(e.toString());
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _latlong();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome to ${Props.appName} App",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[100]!,
              Colors.blue[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isloading
            ? _buildloading()
            : !_locationPermission
                ? _buildPermissionError()
                : FutureBuilder(
                    future: _getCurrentWeatherInfo(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildloading();
                      } else if (snapshot.hasData) {
                        return _buildWeatherCard(snapshot.data);
                      } else {
                        return _buildFetchError();
                      }
                    },
                  ),
      ),
    );
  }

  Widget _buildloading() {
    return Center(
      child: Container(
        color: Colors.black54,
        child: const SpinKitFadingFour(
          color: Colors.white,
          size: 40.0,
        ),
      ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 50,
          ),
          Text(
            'Location permission not granted.\nPlease enable it in the app settings.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${data['location']['name']}, ${data['location']['region']}, ${data['location']['country']}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Latitude: ${data['location']['lat']} | Longitude: ${data['location']['lon']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    "${DateFormat("yyyy-MM-dd hh:mm a").format(DateTime.now())}",
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Card(
                        elevation: 5,
                        child: CachedNetworkImage(
                          imageUrl: "https:${data['current']['condition']['icon']}",
                          width: 80,
                          height: 80,
                          errorWidget: (_, __, ___) {
                            return const Icon(
                              Icons.sunny,
                              size: 60,
                              color: Colors.yellow,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status : ${data['current']['condition']['text']}",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Temperature: ${data['current']['temp_c']}°C",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Feels Like: ${data['current']['feelslike_c']}°C",
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Wind Speed: ${data['current']['wind_kph']} km/h",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        Icons.wind_power,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 50,
          ),
          Text(
            'Error fetching weather data.\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
