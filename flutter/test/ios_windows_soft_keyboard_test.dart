import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/ios_windows_soft_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue editingValue(String text,
        {TextRange composing = TextRange.empty}) =>
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: composing,
    );

void main() {
  const padding = '1111';

  testWidgets('Windows receives one Han character when iOS unmarks it',
      (tester) async {
    final controller = TextEditingController(text: padding);
    addTearDown(controller.dispose);
    var previous = padding;
    final sent = <({int backspaces, String text, String? key})>[];
    controller.addListener(() {
      final edit = iosWindowsSoftKeyboardEdit(previous, controller.value);
      if (edit == null) return;
      previous = edit.committedText;
      sent.add((backspaces: edit.backspaces, text: edit.text, key: edit.key));
    });
    await tester.pumpWidget(MaterialApp(
      home: Material(child: TextField(controller: controller)),
    ));
    await tester.showKeyboard(find.byType(TextField));

    final input = tester.testTextInput;
    const marked = TextRange(start: 4, end: 5);
    input.updateEditingValue(editingValue('${padding}n', composing: marked));
    input.updateEditingValue(editingValue('$padding你', composing: marked));
    expect(sent, isEmpty);

    input.updateEditingValue(editingValue('$padding你'));
    expect(sent, [(backspaces: 0, text: '你', key: null)]);
  });

  test('a confirmed candidate is sent while the next syllable is composing',
      () {
    final edit = iosWindowsSoftKeyboardEdit(
      padding,
      editingValue('$padding你hao',
          composing: const TextRange(start: 5, end: 8)),
    )!;
    expect(edit.text, '你');
    expect(edit.backspaces, 0);

    final next = iosWindowsSoftKeyboardEdit(
      edit.committedText,
      editingValue('$padding你好'),
    )!;
    expect(next.text, '好');
    expect(next.backspaces, 0);
  });

  test('recomposing a sent character only replaces it when committed', () {
    const previous = '$padding你好';
    expect(
      iosWindowsSoftKeyboardEdit(
        previous,
        editingValue('$padding你hao',
            composing: const TextRange(start: 5, end: 8)),
      ),
      isNull,
    );
    final edit =
        iosWindowsSoftKeyboardEdit(previous, editingValue('$padding你号'))!;
    expect(edit.backspaces, 1);
    expect(edit.text, '号');
  });
}
