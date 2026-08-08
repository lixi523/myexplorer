import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/settings/color_rule_store.dart';

void main() {
  group('ColorRuleStore', () {
    test('default rules include common types', () {
      final store = ColorRuleStore.instance;
      expect(store.colorFor('exe'), isNotNull);
      expect(store.colorFor('pdf'), isNotNull);
      expect(store.colorFor('PNG'), isNotNull); // case-insensitive
    });

    test('colorFor returns null for unknown extension', () {
      expect(ColorRuleStore.instance.colorFor('zzz_unknown'), isNull);
      expect(ColorRuleStore.instance.colorFor(''), isNull);
    });

    test('addRule replaces existing rule for the same extension', () {
      final store = ColorRuleStore.instance;
      store.addRule('exe', const Color(0xFF123456));
      final rules = store.rules.value.where((r) => r.matches('exe'));
      expect(rules, hasLength(1));
      expect(rules.single.color, const Color(0xFF123456));
    });

    test('addRule strips leading dots', () {
      final store = ColorRuleStore.instance;
      store.addRule('.custom_ext', const Color(0xFF000000));
      expect(store.colorFor('custom_ext'), isNotNull);
      store.removeRule('custom_ext');
    });

    test('removeRule deletes the rule', () {
      final store = ColorRuleStore.instance;
      store.addRule('zzz', const Color(0xFF000000));
      expect(store.colorFor('zzz'), isNotNull);
      store.removeRule('ZZZ'); // case-insensitive
      expect(store.colorFor('zzz'), isNull);
    });

    test('resetDefaults restores the built-in set', () {
      final store = ColorRuleStore.instance;
      store.addRule('zzz', const Color(0xFF000000));
      store.resetDefaults();
      expect(store.colorFor('zzz'), isNull);
      expect(store.colorFor('exe'), isNotNull);
    });
  });
}
