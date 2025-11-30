import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/notes_service.dart';
import '../utils/theme_provider.dart';

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
  final FocusNode _contentFocusNode = FocusNode();
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
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      resizeToAvoidBottomInset: true,
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
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // THEME: Dynamic card
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
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
            ),
            // Formatting Toolbar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // List formatting button
                  _buildFormatButton(Icons.format_list_bulleted, 'Bullets', _applyListFormatting),
                  // Save button - right aligned
                  GestureDetector(
                    onTap: _saveNote,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: Provider.of<ThemeProvider>(context).gradient,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            spreadRadius: 0,
                            offset: Offset(0, 10),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Color(0x19000000),
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _applyListFormatting() {
    final selection = _contentController.selection;
    final text = _contentController.text;
    
    if (!selection.isValid) return;
    
    if (selection.isCollapsed) {
      // Add bullet at cursor position
      final cursorPos = selection.baseOffset;
      final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
      final newText = text.substring(0, lineStart) + '• ' + text.substring(lineStart);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2);
    } else {
      // Add bullets to selected lines
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      final lines = selectedText.split('\n');
      final bulletedLines = lines.map((line) {
        if (line.trim().isEmpty) return line;
        if (line.trimLeft().startsWith('• ')) {
          // Remove bullet
          return line.replaceFirst(RegExp(r'^\s*• '), '');
        }
        // Add bullet
        return '• $line';
      }).join('\n');
      
      final newText = text.substring(0, start) + bulletedLines + text.substring(end);
      _contentController.text = newText;
      _contentController.selection = TextSelection(
        baseOffset: start,
        extentOffset: start + bulletedLines.length,
      );
    }
    
    setState(() {});
  }
}