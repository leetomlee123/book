import 'package:battery_plus/battery_plus.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';

/// Reader chrome prefs: menu visibility, left-tap advance, battery sample.
class ReaderChromeController {
  ReaderChromeController({
    required this.setElectricQuantity,
    required this.notify,
  });

  final void Function(double value) setElectricQuantity;
  final void Function() notify;

  bool showMenu = false;

  bool tapLeftToAdvance =
      SpUtil.getBool(PrefsKeys.leftClickNext, defValue: false);

  void toggleShowMenu() {
    showMenu = !showMenu;
    notify();
  }

  void toggleTapLeftToAdvance() {
    tapLeftToAdvance = !tapLeftToAdvance;
    SpUtil.putBool(PrefsKeys.leftClickNext, tapLeftToAdvance);
    notify();
  }

  /// Sample battery after a short delay (page-turn path).
  void refreshBattery() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        setElectricQuantity((await Battery().batteryLevel) / 100);
      } catch (_) {
        // Desktop / unsupported platforms: keep previous value.
      }
    });
  }
}
