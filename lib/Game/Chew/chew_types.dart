import '../../constants/app_assets.dart';

enum ChewType { apple, berry, grape, peach }

enum ChewDirection { left, right }

class ChewAsset {
  const ChewAsset({
    required this.type,
    required this.itemFlamePath,
    required this.buttonFlamePath,
  });

  final ChewType type;
  final String itemFlamePath;
  final String buttonFlamePath;
}

const List<ChewAsset> chewAssets = <ChewAsset>[
  ChewAsset(
    type: ChewType.apple,
    itemFlamePath: AppAssets.chewAppleFlame,
    buttonFlamePath: AppAssets.chewButtonAppleFlame,
  ),
  ChewAsset(
    type: ChewType.berry,
    itemFlamePath: AppAssets.chewBerryFlame,
    buttonFlamePath: AppAssets.chewButtonBerryFlame,
  ),
  ChewAsset(
    type: ChewType.grape,
    itemFlamePath: AppAssets.chewGrapeFlame,
    buttonFlamePath: AppAssets.chewButtonGrapeFlame,
  ),
  ChewAsset(
    type: ChewType.peach,
    itemFlamePath: AppAssets.chewPeachFlame,
    buttonFlamePath: AppAssets.chewButtonPeachFlame,
  ),
];
