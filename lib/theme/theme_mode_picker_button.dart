import 'package:flutter/material.dart';

import 'theme_settings.dart';

/// Opens appearance options: system, light, dark.
class ThemeModePickerButton extends StatelessWidget {
  const ThemeModePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = InheritedThemeSettings.of(context);
    final mode = settings.themeMode;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(_iconFor(mode)),
      onSelected: (mode) {
        settings.setThemeMode(mode);
      },
      itemBuilder: (context) => [
        _item(
          context,
          value: ThemeMode.system,
          selected: mode == ThemeMode.system,
          icon: Icons.brightness_auto_rounded,
          title: 'System',
          subtitle: 'Match device',
        ),
        _item(
          context,
          value: ThemeMode.light,
          selected: mode == ThemeMode.light,
          icon: Icons.light_mode_rounded,
          title: 'Light',
          subtitle: 'Always light',
        ),
        _item(
          context,
          value: ThemeMode.dark,
          selected: mode == ThemeMode.dark,
          icon: Icons.dark_mode_rounded,
          title: 'Dark',
          subtitle: 'Always dark',
        ),
      ],
    );
  }

  static IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  static PopupMenuEntry<ThemeMode> _item(
    BuildContext context, {
    required ThemeMode value,
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return PopupMenuItem<ThemeMode>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
