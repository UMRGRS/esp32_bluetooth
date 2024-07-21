import 'package:serialbt/config/config.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.purple,
          primarySwatch: Colors.deepPurple,
          useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
