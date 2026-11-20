import 'package:flutter/widgets.dart';

({String committedText, int backspaces, String text, String? key})?
    iosWindowsSoftKeyboardEdit(String previous, TextEditingValue value) {
  var committed = value.text;
  final composing = value.composing;
  if (value.isComposingRangeValid && !composing.isCollapsed) {
    if (composing.end != committed.length) return null;
    committed = committed.substring(0, composing.start);
    // During recomposition, keep the text already sent to the remote intact.
    if (!committed.startsWith(previous)) return null;
  }
  if (committed == previous) return null;

  final oldCharacters = previous.characters.iterator;
  final newCharacters = committed.characters.iterator;
  var common = 0;
  while (oldCharacters.moveNext() &&
      newCharacters.moveNext() &&
      oldCharacters.current == newCharacters.current) {
    common += oldCharacters.current.length;
  }

  final insertion = committed.substring(common);
  final key = switch (insertion) {
    '\n' => 'VK_RETURN',
    ' ' => 'VK_SPACE',
    _ when insertion.length == 1 && insertion.codeUnitAt(0) <= 0x7f =>
      insertion,
    _ => null,
  };
  return (
    committedText: committed,
    backspaces: previous.substring(common).characters.length,
    // Even a single confirmed Chinese character is sent as Unicode text.
    text: key == null ? insertion : '',
    key: key,
  );
}
