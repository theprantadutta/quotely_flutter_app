import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'q_pills.dart';

const kComposerSuggestions = [
  'courage',
  'an anime line about friendship',
  'starting over',
  'deep work',
  'a movie line about hope',
];

/// "Ask for a quote about…" pill input with suggestion chips above it.
class Composer extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final bool busy;
  final List<String> suggestions;

  const Composer({
    super.key,
    required this.onSubmit,
    this.busy = false,
    this.suggestions = kComposerSuggestions,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final prompt = (text ?? _controller.text).trim();
    if (prompt.isEmpty || widget.busy) return;
    HapticFeedback.lightImpact();
    widget.onSubmit(prompt);
    _controller.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final canSend = _controller.text.trim().isNotEmpty && !widget.busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => Center(
              child: SuggestionChip(
                label: widget.suggestions[i],
                onTap: () => _send(widget.suggestions[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
            decoration: BoxDecoration(
              color: t.surf,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 3,
                    style: context.qt.chip.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask for a quote about…',
                      hintStyle: context.qt.body.copyWith(color: t.mute),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  enabled: canSend,
                  label: 'Send',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: canSend ? _send : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: canSend || widget.busy ? 1 : 0.55,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.acc,
                          shape: BoxShape.circle,
                        ),
                        child: widget.busy
                            ? Padding(
                                padding: const EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: t.onAcc,
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                size: 20,
                                color: t.onAcc,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
