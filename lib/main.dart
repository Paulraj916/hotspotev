// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/hotspot_viewmodel.dart';
import 'repository/hotspot_repository.dart';
import 'api_client/api_client.dart';
import 'screens/splash_screen.dart';
import 'viewmodels/nearby_chargers_viewmodel.dart'; // Import new view model
import 'repository/nearby_chargers_repository.dart'; // Import new repository

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        Provider(create: (context) => HotspotRepository(context.read<ApiClient>())),
        Provider(create: (context) => NearbyChargersRepository(context.read<ApiClient>())),
        ChangeNotifierProvider(
          create: (context) => HotspotViewModel(context.read<HotspotRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NearbyChargersViewModel(context.read<NearbyChargersRepository>()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS SPOT',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(
      //   primarySwatch: Colors.amber,
      //   useMaterial3: true,
      //   scaffoldBackgroundColor: Colors.white,
      // ),
      home: const SplashScreen(), // Set SplashScreen as home
    );
  }
}