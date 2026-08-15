import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramz_save/models/vault_model.dart';
import 'package:ramz_save/views/widgets/tag_selector.dart';

void main() {
  testWidgets('TagChip renders without throwing assertion errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TagChip(
            tag: VaultTag.browser,
            selected: true,
          ),
        ),
      ),
    );

    expect(find.text(VaultTag.browser.label), findsOneWidget);
    expect(find.byType(TagChip), findsOneWidget);
  });

  testWidgets('TagSelector renders all tags and toggles selection', (
    tester,
  ) async {
    List<VaultTag> selected = [VaultTag.browser];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TagSelector(
                selected: selected,
                onChanged: (next) {
                  setState(() {
                    selected = next;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(TagSelector), findsOneWidget);
    expect(find.byType(TagChip), findsNWidgets(VaultTag.values.length));

    // Tap on mobileApp tag chip to select it
    await tester.tap(find.text(VaultTag.mobileApp.label));
    await tester.pumpAndSettle();

    expect(selected.contains(VaultTag.mobileApp), isTrue);
  });
}
