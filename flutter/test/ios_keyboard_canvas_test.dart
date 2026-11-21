import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/common.dart' show SessionID, isMobile;
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _Session extends Fake implements FFI {
  @override
  final SessionID sessionId = const Uuid().v4obj();

  @override
  late final canvasModel = CanvasModel(WeakReference(this));

  @override
  late final cursorModel = CursorModel(WeakReference(this));

  @override
  late final ffiModel = FfiModel(WeakReference(this));
}

void main() {
  testWidgets('iOS keyboard keeps the remote image and touch aligned',
      (tester) async {
    final wasMobile = isMobile;
    isMobile = true;
    addTearDown(() => isMobile = wasMobile);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    final session = _Session();
    final canvas = session.canvasModel..update(-55, -140, 1.25);
    final cursor = session.cursorModel;
    final originalTouch = cursor.getRemotePosInRect(const Offset(180, 200));
    final originalHeight = canvas.getSize().height;
    expect(originalTouch, isNotNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 395);
    cursor.keyHelpToolsVisibilityChanged(
        const Rect.fromLTWH(0, 40, 400, 90), true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(canvas.x, -55);
    expect(canvas.y + canvas.getAdjustY(), -140);
    expect(canvas.scale, 1.25);
    expect(canvas.size.height, lessThan(originalHeight));
    expect(cursor.getRemotePosInRect(const Offset(180, 200)), originalTouch);

    canvas.panY(-25);
    tester.view.viewInsets = const FakeViewPadding();
    cursor.keyHelpToolsVisibilityChanged(null, false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(canvas.y + canvas.getAdjustY(), -165);
    expect(canvas.size.height, originalHeight);
    expect(canvas.scale, 1.25);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
