import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:ictu_community_org/app.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();

  await SupabaseBootstrap.initialize();
   runApp(
     ChangeNotifierProvider<AuthController>(
       create: (_) => AuthController(),
       child: const IctuCommunityApp(),
     ),
   );
}
