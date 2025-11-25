import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/notes_service.dart';

class NewNoteScreen extends StatefulWidget {
  final List<String> availableCategories;
  final VoidCallback onNoteSaved;

  const NewNoteScreen({
    Key? key,
    required this.availableCategories,
    required this.onNoteSaved,
  }) : super(key: key);

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.availableCategories.contains('Personal')
        ? 'Personal'
        : (widget.availableCategories.isNotEmpty ? widget.availableCategories[1] : 'Personal');
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    try {
      await NotesService.createNote(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
      );

      widget.onNoteSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating note: $e')),
        );
      }
    }
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
          onPressed: _onBackPressed,
        ),
        title: Text(
          'New Note',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: themeProvider.primaryColor, // THEME: Dynamic accent color
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Note Title',
                hintStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic hint
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.white,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                items: widget.availableCategories.where((cat) => cat != 'All').map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Start writing your note...',
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic hint
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // THEME: Dynamic text
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // Formatting Toolbar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                spacing: 4,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFormatButton('B', 'Bold', _applyBoldFormatting),
                      _buildFormatButton('I', 'Italic', _applyItalicFormatting),
                      _buildFormatButton('U', 'Underline', _applyUnderlineFormatting),
                      _buildFormatButton('•', 'Bullets', _applyListFormatting),
                      Expanded(child: Container()),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveNote,
                        icon: const Icon(Icons.check),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(String label, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        tooltip: tooltip,
      ),
    );
  }

  void _applyBoldFormatting() {
    _applyTextStyle('\u0001', '\u0002');
  }

  void _applyItalicFormatting() {
    _applyTextStyle('\u0003', '\u0004');
  }

  void _applyUnderlineFormatting() {
    _applyTextStyle('\u0005', '\u0006');
  }

  void _applyListFormatting() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start == -1) return;

    if (start == end) {
      final newText = text.substring(0, start) + '• ' + text.substring(start);
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(TextPosition(offset: start + 2));
    } else {
      final selectedText = text.substring(start, end);
      final lines = selectedText.split('\n');
      final formattedLines = lines.map((line) {
        if (line.isEmpty) return line;
        return line.startsWith('• ') ? line.substring(2) : '• $line';
      }).toList();
      final newText = text.substring(0, start) + formattedLines.join('\n') + text.substring(end);
      _contentController.text = newText;
      _contentController.selection = TextSelection(baseOffset: start, extentOffset: start + formattedLines.join('\n').length);
    }

    setState(() {});
  }

  void _applyTextStyle(String openMarker, String closeMarker) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start == -1) return;

    if (start == end) {
      final newText = text.substring(0, start) + openMarker + closeMarker + text.substring(start);
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(TextPosition(offset: start + 1));
    } else {
      final selectedText = text.substring(start, end);
      final newText = text.substring(0, start) + openMarker + selectedText + closeMarker + text.substring(end);
      _contentController.text = newText;
      _contentController.selection = TextSelection(baseOffset: start + 1, extentOffset: end + 1);
    }

    setState(() {});
  }
}