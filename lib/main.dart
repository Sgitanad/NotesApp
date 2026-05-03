import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'home_page.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://YOUR_DSN@sentry.io/YOUR_PROJECT';
      options.tracesSampleRate = 1.0;
      options.environment = 'development';
    },
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Three Pages Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}