import 'package:flutter/material.dart';

/// A persistent error message that can be selected for support or diagnosis.
///
/// Ordinary app copy must use [Text]. This explicit component keeps selection
/// limited to messages a person may reasonably need to copy elsewhere.
class VerilyCopyableErrorText extends StatelessWidget {
  const VerilyCopyableErrorText(
    this.data, {
    this.style,
    this.textAlign,
    this.maxLines,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: SelectableText(
        data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}
