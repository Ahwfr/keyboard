import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KeyboardApp());

class KeyboardApp extends StatelessWidget {
  const KeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const KeyboardPage(),
    );
  }
}

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  String _text = '';
  bool _shifted = false;
  List<String> _clipboard = [
    'Meeting notes',
    'https://example.com',
    'Thank you!',
  ];

  void _insert(String value) => setState(() => _text += value);

  void _delete() {
    if (_text.isEmpty) return;
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  Future<void> _refreshClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim();
    if (!mounted || value == null || value.isEmpty) return;
    setState(() {
      _clipboard = [
        value,
        ..._clipboard.where((item) => item != value),
      ].take(8).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f2f7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _text.isEmpty ? 'Start typing' : _text,
                      style: const TextStyle(
                        color: Color(0xff25252a),
                        fontSize: 21,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            KeyboardSurface(
              clipboard: _clipboard,
              shifted: _shifted,
              onText: _insert,
              onDelete: _delete,
              onShift: () => setState(() => _shifted = !_shifted),
              onClipboard: _refreshClipboard,
            ),
          ],
        ),
      ),
    );
  }
}

class KeyboardSurface extends StatelessWidget {
  const KeyboardSurface({
    super.key,
    required this.clipboard,
    required this.shifted,
    required this.onText,
    required this.onDelete,
    required this.onShift,
    required this.onClipboard,
  });

  final List<String> clipboard;
  final bool shifted;
  final ValueChanged<String> onText;
  final VoidCallback onDelete;
  final VoidCallback onShift;
  final VoidCallback onClipboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffd1d3d8),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipboardTray(
            items: clipboard,
            onSelect: onText,
            onRefresh: onClipboard,
          ),
          const SizedBox(height: 7),
          NumberRow(onSelect: onText),
          const SizedBox(height: 7),
          LetterKeyboard(
            shifted: shifted,
            onText: onText,
            onDelete: onDelete,
            onShift: onShift,
          ),
        ],
      ),
    );
  }
}

class ClipboardTray extends StatelessWidget {
  const ClipboardTray({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onRefresh,
  });

  final List<String> items;
  final ValueChanged<String> onSelect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AccessoryButton(
              key: const Key('clipboard-button'),
              icon: Icons.content_paste_rounded,
              label: 'Clipboard',
              onTap: onRefresh,
            );
          }
          final item = items[index - 1];
          return _ClipboardItem(
            key: Key('clipboard-$item'),
            text: item,
            onTap: () => onSelect(item),
          );
        },
      ),
    );
  }
}

class NumberRow extends StatelessWidget {
  const NumberRow({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(10, (index) {
        final value = index == 9 ? '0' : '${index + 1}';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: KeyboardKey(
              label: value,
              onTap: () => onSelect(value),
              semanticLabel: 'Number $value',
            ),
          ),
        );
      }),
    );
  }
}

class LetterKeyboard extends StatelessWidget {
  const LetterKeyboard({
    super.key,
    required this.shifted,
    required this.onText,
    required this.onDelete,
    required this.onShift,
  });

  final bool shifted;
  final ValueChanged<String> onText;
  final VoidCallback onDelete;
  final VoidCallback onShift;

  @override
  Widget build(BuildContext context) {
    const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                for (final letter in row.split(''))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: KeyboardKey(
                        label: shifted ? letter.toUpperCase() : letter,
                        onTap: () =>
                            onText(shifted ? letter.toUpperCase() : letter),
                        semanticLabel: 'Letter ${letter.toUpperCase()}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: KeyboardKey(
                  label: '⇧',
                  onTap: onShift,
                  active: shifted,
                  semanticLabel: 'Shift',
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: KeyboardKey(
                  label: 'space',
                  onTap: () => onText(' '),
                  semanticLabel: 'Space',
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: KeyboardKey(
                  icon: Icons.backspace_outlined,
                  onTap: onDelete,
                  semanticLabel: 'Backspace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class KeyboardKey extends StatefulWidget {
  const KeyboardKey({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.active = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool active;

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.active ? const Color(0xffaeb0b5) : Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: widget.icon != null
                ? Icon(widget.icon, color: const Color(0xff343438), size: 19)
                : Text(
                    widget.label!,
                    style: TextStyle(
                      color: const Color(0xff25252a),
                      fontSize: widget.label == 'space' ? 15 : 21,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccessoryButton extends StatelessWidget {
  const _AccessoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffb9bbc0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xff343438)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xff343438), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipboardItem extends StatelessWidget {
  const _ClipboardItem({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff343438), fontSize: 13),
          ),
        ),
      ),
    );
  }
}
