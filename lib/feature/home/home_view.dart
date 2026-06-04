import 'package:akillisletme/feature/home/home_view_mode.dart';
import 'package:akillisletme/feature/home/widget/home_background.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/navigation/app_router.dart';
import 'package:flutter/material.dart';

const String _mono = 'monospace';
const Color _neon = HomeBackground.neon;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends HomeViewMode
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursor;

  @override
  void initState() {
    super.initState();
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = <_Module>[
      _Module(
        index: '01',
        title: 'SECURITY SCAN',
        subtitle: 'root · vpn · proxy · spyware',
        accent: _neon,
        icon: Icons.shield_outlined,
        onTap: () => const SecurityRoute().push<void>(context),
      ),
      _Module(
        index: '02',
        title: 'RISKY APPS',
        subtitle: 'permission & spyware risk per app',
        accent: const Color(0xFFFF5C7A),
        icon: Icons.apps_rounded,
        onTap: () => const AppScanRoute().push<void>(context),
      ),
      _Module(
        index: '03',
        title: 'NETWORK MONITOR',
        subtitle: 'live latency · outage log',
        accent: const Color(0xFF00E5FF),
        icon: Icons.network_check_rounded,
        onTap: () => const NetworkRoute().push<void>(context),
      ),
      _Module(
        index: '04',
        title: 'PRIVACY GUIDE',
        subtitle: 'manual spyware audit checklist',
        accent: const Color(0xFFFFB000),
        icon: Icons.privacy_tip_outlined,
        onTap: () => const PrivacyGuideRoute().push<void>(context),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          '~/security-scanner',
          style: TextStyle(
            fontFamily: _mono,
            fontSize: 15,
            letterSpacing: 0.5,
            color: _neon,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal_rounded),
            onPressed: () => const SettingsRoute().push<void>(context),
          ),
        ],
      ),
      body: ListView(
        padding: AppPaddings.allL,
        children: [
          _Console(cursor: _cursor, moduleCount: modules.length),
          const SizedBox(height: AppPaddings.xl),
          const _SectionLabel('// MODULES'),
          const SizedBox(height: AppPaddings.m),
          ...modules.map((m) => _ModuleCard(module: m)),
        ],
      ),
    );
  }
}

/// Terminal console panel with a blinking cursor.
class _Console extends StatelessWidget {
  const _Console({required this.cursor, required this.moduleCount});

  final AnimationController cursor;
  final int moduleCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPaddings.allL,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _neon.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _neon.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window chrome.
          Row(
            children: [
              _dot(const Color(0xFFFF5F56)),
              _dot(const Color(0xFFFFBD2E)),
              _dot(const Color(0xFF27C93F)),
              const Spacer(),
              Text(
                'bash — 80×24',
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPaddings.l),
          const _Line(prompt: r'root@device:~$', command: './scan --device'),
          const SizedBox(height: AppPaddings.s),
          _out('▸ $moduleCount modules loaded'),
          _out('▸ engine: native + heuristic'),
          const SizedBox(height: AppPaddings.s),
          AnimatedBuilder(
            animation: cursor,
            builder: (context, _) {
              final show = cursor.value < 0.5;
              return Row(
                children: [
                  const Text(
                    'status: ',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const Text(
                    'READY',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _neon,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Opacity(
                    opacity: show ? 1 : 0,
                    child: Container(width: 8, height: 15, color: _neon),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 11,
    height: 11,
    margin: const EdgeInsets.only(right: 6),
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _out(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: _mono,
        fontSize: 13,
        color: _neon.withValues(alpha: 0.75),
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.prompt, required this.command});

  final String prompt;
  final String command;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: _mono, fontSize: 13, height: 1.4),
        children: [
          TextSpan(
            text: '$prompt ',
            style: const TextStyle(color: _neon, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: command,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _mono,
        fontSize: 12,
        letterSpacing: 2,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}

class _Module {
  const _Module({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String index;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _Module module;

  @override
  Widget build(BuildContext context) {
    final accent = module.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPaddings.m),
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: module.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: AppPaddings.allL,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Text(
                  '[${module.index}]',
                  style: TextStyle(
                    fontFamily: _mono,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppPaddings.m),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(module.icon, color: accent, size: 20),
                ),
                const SizedBox(width: AppPaddings.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontFamily: _mono,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        module.subtitle,
                        style: TextStyle(
                          fontFamily: _mono,
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppPaddings.s),
                _StatusDot(color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'ONLINE',
          style: TextStyle(
            fontFamily: _mono,
            fontSize: 10,
            letterSpacing: 1,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
