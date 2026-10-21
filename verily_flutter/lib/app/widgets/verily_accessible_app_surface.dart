import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Interaction defaults shared by every Verily route.
///
/// Passive copy such as headings, labels, button captions, descriptions, and
/// metadata deliberately remains non-selectable. Text inputs provide their own
/// editing selection, while diagnostics opt in through
/// `VerilyCopyableErrorText`. Reading-order traversal gives keyboard users a
/// predictable route through controls without changing local focus groups.
class VerilyAccessibleAppSurface extends HookWidget {
  const VerilyAccessibleAppSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentChild = useRef<Widget>(child)..value = child;
    final isFocusReady = useState(false);
    final overlayEntry = useMemoized(
      () => OverlayEntry(
        builder: (context) => ExcludeFocusTraversal(
          excluding: !isFocusReady.value,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: currentChild.value,
          ),
        ),
      ),
    );

    useEffect(() {
      var disposed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) isFocusReady.value = true;
      });
      return () => disposed = true;
    }, const []);
    useEffect(() {
      overlayEntry.markNeedsBuild();
      return null;
    }, [child, isFocusReady.value, overlayEntry]);

    // Flutter web can deliver its initial view-focus event before the root
    // overlay has completed layout. Keep content visible, but exclude it from
    // traversal until the next frame so no unlaid-out bounds are inspected.
    return Overlay(initialEntries: [overlayEntry]);
  }
}
