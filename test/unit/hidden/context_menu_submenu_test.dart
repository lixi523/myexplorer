import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/ui/overlays/context_menu.dart';
import 'package:myexplorer/ui/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.build(), home: child);

  Future<void> openMenu(WidgetTester tester) async {
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
                          icon: Icons.folder,
                          label: 'Tags',
                          action: 'tags',
                          children: [
                            ContextMenuItem(
                              icon: Icons.label,
                              label: 'Work',
                              action: 'tag_toggle:1',
                            ),
                            ContextMenuItem(
                              icon: Icons.label,
                              label: 'Home',
                              action: 'tag_toggle:2',
                            ),
                            ContextMenuItem.divider,
                            ContextMenuItem(
                              icon: Icons.add,
                              label: 'New Tag',
                              action: 'tag_new',
                            ),
                          ],
                        ),
                        ContextMenuItem(
                          icon: Icons.copy,
                          label: 'Copy',
                          action: 'copy',
                        ),
                      ],
                      onSelect: (action) {},
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
  }

  testWidgets('submenu item click dismisses both menus', (tester) async {
    await openMenu(tester);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);

    // Open the submenu by hovering over the parent item.
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);

    // Click a submenu leaf.
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsNothing, reason: 'submenu should dismiss');
    expect(
      find.text('Tags'),
      findsNothing,
      reason: 'parent menu should dismiss',
    );
  });

  testWidgets('tapping outside with submenu open dismisses everything', (
    tester,
  ) async {
    await openMenu(tester);
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsNothing, reason: 'submenu should dismiss');
    expect(find.text('Tags'), findsNothing, reason: 'parent should dismiss');
  });
}
