import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';
import 'package:noxxi/core/theme/app_theme.dart';
import 'package:noxxi/splash_screen.dart';
import 'package:noxxi/core/services/memory_manager.dart';
import 'package:noxxi/core/services/image_cache_manager.dart';
import 'package:noxxi/features/home/screens/category_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance optimizations
  ImageCacheManager().init();
  MemoryManager().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => authStateProvider,
      child: MaterialApp(
        title: 'Noxxi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/category') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CategoryPage(
                categoryId: args['categoryId'],
                categoryName: args['categoryName'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
