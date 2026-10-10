import 'package:flutter/material.dart';
import '../widgets/qibla_compass_widget.dart';
import '../widgets/tasbih_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('tools')),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            labelColor: AppTheme.accentGold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppTheme.accentGold,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                text: AppLocalizations.of(context).translate('tasbih'),
                icon: const Icon(Icons.fingerprint),
              ),
              Tab(
                text: AppLocalizations.of(context).translate('qibla'),
                icon: const Icon(Icons.explore),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TasbihWidget(), QiblaCompassWidget()],
        ),
      ),
    );
  }
}
