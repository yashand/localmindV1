import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/llm_service.dart';
import 'services/voice_service.dart';
import 'services/privacy_service.dart';
import 'services/automation_service.dart';
import 'services/offline_knowledge_service.dart';
import 'models/user_profile.dart';
import 'models/app_state.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/privacy_dashboard_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Initialize offline knowledge base
  await OfflineKnowledgeService.initialize();

  runApp(LocalMindApp(storage: storage));
}

class LocalMindApp extends StatelessWidget {
  final FlutterSecureStorage storage;

  const LocalMindApp({Key? key, required this.storage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserProfile()),
        Provider<FlutterSecureStorage>.value(value: storage),
        ProxyProvider<FlutterSecureStorage, LLMService>(
          update: (_, storage, __) => LLMService(storage),
        ),
        Provider(create: (_) => VoiceService()),
        ProxyProvider<FlutterSecureStorage, PrivacyService>(
          update: (_, storage, __) => PrivacyService(storage),
        ),
        Provider(create: (_) => AutomationService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'LocalMind',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            debugShowCheckedModeBanner: false,
            home: const MainNavigator(),
          );
        },
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const PrivacyDashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.privacy_tip),
            label: 'Privacy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}