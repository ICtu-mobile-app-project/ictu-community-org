import 'package:flutter/material.dart';
import 'package:ictu_community_org/core/navigation/app_router.dart';
import 'package:ictu_community_org/core/theme/app_theme.dart';

class IctuCommunityApp extends StatefulWidget {
  const IctuCommunityApp({super.key});

  @override
  State<IctuCommunityApp> createState() => _IctuCommunityAppState();
}

class _IctuCommunityAppState extends State<IctuCommunityApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ICTU Community',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}
