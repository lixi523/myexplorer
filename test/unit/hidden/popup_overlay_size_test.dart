import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/ui/overlays/popup_overlay.dart';
import 'package:myexplorer/ui/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.build(), home: child);

  testWidgets('popup overlay backdrop covers the whole screen', (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    showPopup(
                      context: context,
                      position: const Offset(300, 300),
                      builder: (_) => const SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final popup = tester.renderObject<RenderBox>(find.byType(PopupOverlay));
    // The PopupOverlay's Stack must be full-screen so the auto-dismiss
    // backdrop receives taps anywhere outside the menu.
    expect(
      popup.size.width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
    expect(
      popup.size.height,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
    );

    // Tapping the very corner should dismiss.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(PopupOverlay), findsNothing);
  });
}
