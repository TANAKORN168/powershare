import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:powershare/preloadPage.dart';
import 'package:powershare/services/notificationService.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // สำคัญมากๆ

  await Firebase.initializeApp();

  // await Supabase.initialize(url: ApiConfig.baseUrl, anonKey: ApiConfig.apiKey);

  try {
    await NotificationService.init();
  } catch (e) {
    // ถ้ายังไม่ได้ตั้งค่า Firebase (google-services.json / GoogleService-Info.plist)
    // จะ init ไม่ผ่าน แต่ยังให้แอปเปิดได้ตามปกติ
  }
  // 🔒 ล็อกเฉพาะแนวตั้ง
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyStateLessWidget());
}

class MyStateLessWidget extends StatelessWidget {
  const MyStateLessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PowerShare',
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(fontFamily: 'Prompt', primaryColor: Color(0xFF3ABDC5)),
      home: PreloadPage(),
    );
  }
}

class MyStateFulWidget extends StatefulWidget {
  const MyStateFulWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyState();
  }
}

class MyState extends State<MyStateFulWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('This is appBar')),
      body: Center(child: Text('This id body')),
    );
  }
}
