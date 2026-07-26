import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'scanning_overlay.dart';
import 'settings_screen.dart';
import 'vault_screen.dart';

/// The app frame: a body that switches between Home / Vault / Settings, plus a
/// bottom bar whose centre "Scan" action runs the gallery scan.
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  Future<void> _scan() async {
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final n = await state.scanFromGallery();
    if (!mounted) return;
    if (n > 0) {
      setState(() => _index = 1);
      messenger.showSnackBar(SnackBar(content: Text('Sorted $n screenshot${n == 1 ? '' : 's'}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context); // depend on scanning/progress
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [HomeScreen(), VaultScreen(), SettingsScreen()],
          ),
          bottomNavigationBar: _BottomBar(
            index: _index,
            onHome: () => setState(() => _index = 0),
            onVault: () => setState(() => _index = 1),
            onScan: _scan,
            onSettings: () => setState(() => _index = 2),
          ),
        ),
        if (state.scanning)
          ScanningOverlay(done: state.scanDone, total: state.scanTotal),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onHome,
    required this.onVault,
    required this.onScan,
    required this.onSettings,
  });
  final int index;
  final VoidCallback onHome, onVault, onScan, onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.only(top: 6, bottom: MediaQuery.of(context).padding.bottom + 6),
      child: Row(
        children: [
          _item(c, Icons.search, 'Home', index == 0, onHome),
          _item(c, Icons.lock_outline, 'Vault', index == 1, onVault),
          _item(c, Icons.add_a_photo_outlined, 'Scan', false, onScan),
          _item(c, Icons.settings_outlined, 'Settings', index == 2, onSettings),
        ],
      ),
    );
  }

  Widget _item(PicColors c, IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? c.accent : c.inkFaint;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
