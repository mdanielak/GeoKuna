import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// Placeholder for the „Nieprzykunowanie” token art: a gold coin icon.
/// Not an emoji: the web build would download an emoji font at runtime,
/// and the app stays offline.
class TokenIcon extends StatelessWidget {
  const TokenIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(Icons.toll, size: size, color: GeoColors.of(context).gold),
  );
}
