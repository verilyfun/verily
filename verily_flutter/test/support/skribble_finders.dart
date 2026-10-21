import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart';

/// Finds hand-drawn icons by their drawing, as `find.byIcon` does for
/// Material font icons.
Finder findSkribbleIcon(WiredSvgIconData data) => find.byWidgetPredicate(
  (widget) => widget is SkribbleIcon && identical(widget.data, data),
  description: 'SkribbleIcon($data)',
);
