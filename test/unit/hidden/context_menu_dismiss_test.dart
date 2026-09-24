import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/ui/overlays/context_menu.dart';
import 'package:myexplorer/ui/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.build(), home: child);

  testWidgets('context menu closes when tapping outside', (tester) async {
    var selected = 'none';
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    showContextMenu(
                      context: context,
                      position: const Offset(200, 200),
                      items: [
                        ContextMenuItem(
                          icon: Icons.copy,
                          label: 'Copy',
                          action: 'copy',
                        ),
                        ContextMenuItem(
                          icon: Icons.delete,
                          label: 'Delete',
                          action: 'delete',
                        ),
                      ],
                      onSelect: (action) => selected = action,
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
    expect(find.text('Copy'), findsOneWidget);

    // Tap far outside the menu (top-left corner).
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsNothing, reason: 'menu should dismiss');
    expect(selected, 'none');
  });

  testWidgets('context menu closes after selecting a leaf item', (
    tester,
  ) async {
    var selected = 'none';
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    showContextMenu(
                      context: context,
                      position: const Offset(200, 200),
                      items: [
                        ContextMenuItem(
                          icon: Icons.copy,
                          label: 'Copy',
                          action: 'copy',
                        ),
                      ],
                      onSelect: (action) => selected = action,
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
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(selected, 'copy');
    expect(find.text('Copy'), findsNothing, reason: 'menu should dismiss');
  });
}
