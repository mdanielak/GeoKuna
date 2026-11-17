import 'package:material_ui/material_ui.dart';

/// The „Nieprzykunowanie” token: a gold coin with the kuna (v2.5 pack).
/// A bundled picture, not an emoji: the app stays offline.
class TokenIcon extends StatelessWidget {
  const TokenIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/v2/token_nieprzykunowanie.webp',
      width: size,
      height: size,
      cacheWidth: 192,
    ),
  );
}
