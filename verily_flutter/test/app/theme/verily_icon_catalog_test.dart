import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_icon_catalog.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';

void main() {
  setUp(registerVerilyIconCatalog);
  tearDown(clearWiredIconCatalog);

  test("draws the map's zoom buttons from Verily's icons", () {
    expect(lookupMaterialRoughIconByIdentifier('add'), VerilyIcons.plus);
    expect(lookupMaterialRoughIconByIdentifier('remove'), VerilyIcons.minus);
  });

  test('knows no other names and translates no font icons', () {
    expect(lookupMaterialRoughIconByIdentifier('search'), isNull);
    expect(lookupMaterialRoughIcon(Icons.add), isNull);
    expect(lookupMaterialRoughFontIcon('add'), isNull);
  });
}
