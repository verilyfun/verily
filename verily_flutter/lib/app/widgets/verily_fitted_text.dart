import 'package:flutter/widgets.dart';

/// A single line that always shows all of its text.
///
/// Screen titles and headings must never be clipped or end in an ellipsis.
/// When the text fits it renders at [style]'s size; when the space is too
/// narrow, as on a small phone or with large accessibility text, the whole
/// line scales down until it fits rather than losing words.
///
/// Use it for short, fixed titles: a header bar, an app bar, a section
/// heading. Content people write, such as an action title, should wrap instead
/// so it never shrinks to an unreadable size.
class VerilyFittedText extends StatelessWidget {
  const VerilyFittedText(
    this.text, {
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
    this.textAlign,
    super.key,
  });

  final String text;
  final TextStyle? style;

  /// Where the line sits when it is narrower than the space, and the anchor
  /// it shrinks towards.
  final AlignmentGeometry alignment;

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
    ),
  );
}
