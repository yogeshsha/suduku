import 'package:upgrader/upgrader.dart';

/// Update-prompt copy in Cubby's voice, replacing `upgrader`'s generic
/// defaults ("Update App?" / "UPDATE NOW" / "IGNORE") so the prompt reads
/// like part of the app rather than a plugin.
///
/// Supports the same `{{appName}}` / `{{currentAppStoreVersion}}` /
/// `{{currentInstalledVersion}}` template tokens as the base class — see
/// [UpgraderMessages.body].
class CubbyUpdateMessages extends UpgraderMessages {
  @override
  String get title => 'Update available! 🎉';

  @override
  String get body =>
      'A new version of {{appName}} is out (v{{currentAppStoreVersion}}) — '
      "you're on v{{currentInstalledVersion}}. Update your app to enhance "
      'your experience!';

  @override
  String get buttonTitleUpdate => 'Update now';

  @override
  String get buttonTitleLater => 'Later';

  @override
  String get buttonTitleIgnore => 'Not now';
}
