import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../utils/category_color_helper.dart';
import '../services/notes_service.dart';
import '../utils/text_formatter.dart';
import '../services/firebase_service.dart';
import '../models/note.dart' as note_model;
import '../models/journal_entry.dart';
import 'new_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _selectedSegment = 0;
  String _selectedFilter = 'All';
  List<String> _availableCategories = ['All', 'Personal'];
  List<note_model.Note> _notes = [];
  List<note_model.Note> _filteredNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCategories();
    _loadNotes();
  }

  Future<void> _loadAvailableCategories() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final instructorCourses = await FirebaseService.getInstructorCourses(userId);
      final studentCourses = await FirebaseService.getStudentEnrolledCourses(userId);

      final courseNames = <String>{};
      for (var course in instructorCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }
      for (var course in studentCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }

      if (mounted) {
        setState(() {
          _availableCategories = ['All', 'Personal', ...courseNames.toList()];
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await NotesService.getNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredNotes = _notes;
    } else {
      _filteredNotes = _notes.where((note) => note.category == _selectedFilter).toList();
    }
  }

  void _navigateToNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewNoteScreen(
          availableCategories: _availableCategories,
          onNoteSaved: () {
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _viewNoteDetail(note_model.Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: note,
          availableCategories: _availableCategories,
          onNoteSaved: () {
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    String searchCategory = 'All';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Search Notes',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                decoration: InputDecoration(
                  hintText: 'Search by title or content...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: searchCategory,
                isExpanded: true,
                items: _availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category, style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      searchCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final results = await NotesService.searchNotes(
                  query: searchController.text,
                  category: searchCategory == 'All' ? null : searchCategory,
                );
                if (mounted) {
                  setState(() {
                    _notes = results;
                    _selectedFilter = searchCategory;
                    _applyFilter();
                  });
                }
              },
              child: Text('Search', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSegmentedControl(themeProvider),
            if (_selectedSegment == 0) ...[
              _buildFilterChips(themeProvider),
              Expanded(child: _buildNotesList()),
            ] else ...[
              Expanded(
                child: JournalContent(
                  onAddEntry: _loadNotes,
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedSegment == 0
          ? _buildFloatingActionButton(themeProvider)
          : null,
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBackPressed,
            child: SizedBox(
              width: 86,
              height: 32,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 11,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Notes & Journal',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_selectedSegment == 0)
            GestureDetector(
              onTap: _showSearchDialog,
              child: SizedBox(
                width: 28,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.2)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedSegment = 0;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedSegment == 0
                        ? themeProvider.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Notes',
                      style: GoogleFonts.inter(
                        color: _selectedSegment == 0
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedSegment = 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedSegment == 1
                        ? themeProvider.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Journal',
                      style: GoogleFonts.inter(
                        color: _selectedSegment == 1
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeProvider themeProvider) {
    return SizedBox(
      height: 76,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: _availableCategories.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                    _applyFilter();
                  });
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeProvider.primaryColor
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.2)
                            : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Provider.of<ThemeProvider>(context).primaryColor,
          ),
        ),
      );
    }

    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes found',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return GestureDetector(
          onTap: () => _viewNoteDetail(note),
          child: _buildNoteCard(note),
        );
      },
    );
  }

  Widget _buildNoteCard(note_model.Note note) {
    final categoryColor = CategoryColorHelper.getCategoryBackgroundColor(note.category);
    final textColor = CategoryColorHelper.getCategoryTextColor(note.category);
    final timeAgo = _getTimeAgo(note.updatedAt);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FormattedTextWidget(
            text: note.content,
            baseStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  note.category,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showNoteOptions(note);
                },
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeProvider themeProvider) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
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
        gradient: themeProvider.gradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: _navigateToNewNote,
          child: const Center(
            child: Icon(
              Icons.add,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteOptions(note_model.Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                title: Text(
                  'Edit Note',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewNoteDetail(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).primaryColor),
                title: Text(
                  'Delete Note',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Theme.of(context).primaryColor),
                title: Text(
                  'Share Note',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNote(note_model.Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Note',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await NotesService.deleteNote(note.id);
                _loadNotes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting note: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

// ==================== JOURNAL CONTENT WIDGET ====================

class JournalContent extends StatefulWidget {
  final VoidCallback onAddEntry;

  const JournalContent({super.key, required this.onAddEntry});

  @override
  State<JournalContent> createState() => _JournalContentState();
}

class _JournalContentState extends State<JournalContent> {
  int _currentPage = 0;
  List<JournalEntry> _journalEntries = [];
  List<JournalEntry> _displayedEntries = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  // Formatting states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _loadJournalEntries();
  }

  Future<void> _loadJournalEntries() async {
    try {
      final entries = await NotesService.getJournalEntries();
      if (mounted) {
        setState(() {
          _journalEntries = entries;
          _updateDisplayedEntries();
          _currentPage = _displayedEntries.isEmpty ? 0 : _displayedEntries.length - 1;
          _isLoading = false;
          _loadCurrentEntry();
        });
      }
    } catch (e) {
      print('Error loading journal entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplayedEntries() {
    if (_showFavoritesOnly) {
      _displayedEntries = _journalEntries.where((entry) => entry.isFavorited).toList();
    } else {
      _displayedEntries = _journalEntries;
    }
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      _updateDisplayedEntries();
      _currentPage = _displayedEntries.isEmpty ? 0 : 0;
      _loadCurrentEntry();
    });
  }

  void _loadCurrentEntry() {
    if (_displayedEntries.isNotEmpty && _currentPage < _displayedEntries.length) {
      _titleController.text = _displayedEntries[_currentPage].title;
      _contentController.text = _displayedEntries[_currentPage].content;
    } else {
      _titleController.clear();
      _contentController.clear();
    }
  }

  Future<void> _saveChanges() async {
    if (_displayedEntries.isEmpty || _currentPage >= _displayedEntries.length) return;

    final displayedEntry = _displayedEntries[_currentPage];
    final actualEntry = _journalEntries.firstWhere(
      (entry) => entry.id == displayedEntry.id,
      orElse: () => displayedEntry,
    );
    try {
      await NotesService.updateJournalEntry(
        entryId: actualEntry.id,
        title: _titleController.text,
        content: _contentController.text,
      );
    } catch (e) {
      print('Error saving journal entry: $e');
    }
  }

  Future<void> _addNewEntry() async {
    try {
      await NotesService.createJournalEntry(
        title: '',
        content: '',
      );
      _loadJournalEntries();
      widget.onAddEntry();
    } catch (e) {
      print('Error creating journal entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating entry: $e')),
      );
    }
  }

  void _toggleFavorite() async {
    if (_displayedEntries.isEmpty || _currentPage >= _displayedEntries.length) return;

    final entry = _displayedEntries[_currentPage];
    try {
      await NotesService.toggleJournalFavorite(entry.id, entry.isFavorited);
      setState(() {
        final idx = _journalEntries.indexOf(entry);
        _journalEntries[idx] = entry.copyWith(isFavorited: !entry.isFavorited);
        _updateDisplayedEntries();
      });
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _deleteCurrentEntry() {
    if (_displayedEntries.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Journal Entry',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    if (_displayedEntries.isEmpty || _currentPage >= _displayedEntries.length) return;

    try {
      final entryToDelete = _displayedEntries[_currentPage];
      await NotesService.deleteJournalEntry(entryToDelete.id);

      setState(() {
        _journalEntries.remove(entryToDelete);
        _updateDisplayedEntries();

        if (_displayedEntries.isEmpty) {
          _currentPage = 0;
          _titleController.clear();
          _contentController.clear();
        } else if (_currentPage >= _displayedEntries.length) {
          _currentPage = _displayedEntries.length - 1;
          _loadCurrentEntry();
        } else {
          _loadCurrentEntry();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  void _applyBoldFormatting() {
    final selection = _contentController.selection;
    final text = _contentController.text;
    
    if (!selection.isValid) return;
    
    if (selection.isCollapsed) {
      // Toggle state for future typing
      setState(() {
        _isBold = !_isBold;
      });
      // Insert markers at cursor if activating
      if (_isBold) {
        final cursorPos = selection.baseOffset;
        final newText = text.substring(0, cursorPos) + '**' + text.substring(cursorPos);
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2);
      }
    } else {
      // Wrap selected text
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      
      // Check if already wrapped
      final beforeStart = start >= 2 ? text.substring(start - 2, start) : '';
      final afterEnd = end + 2 <= text.length ? text.substring(end, end + 2) : '';
      
      String newText;
      int newCursorPos;
      
      if (beforeStart == '**' && afterEnd == '**') {
        // Remove bold
        newText = text.substring(0, start - 2) + selectedText + text.substring(end + 2);
        newCursorPos = start - 2;
        setState(() {
          _isBold = false;
        });
      } else {
        // Add bold
        newText = text.substring(0, start) + '**' + selectedText + '**' + text.substring(end);
        newCursorPos = end + 4;
        setState(() {
          _isBold = true;
        });
      }
      
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: newCursorPos);
    }
    _saveChanges();
  }

  void _applyItalicFormatting() {
    final selection = _contentController.selection;
    final text = _contentController.text;
    
    if (!selection.isValid) return;
    
    if (selection.isCollapsed) {
      // Toggle state for future typing
      setState(() {
        _isItalic = !_isItalic;
      });
      // Insert markers at cursor if activating
      if (_isItalic) {
        final cursorPos = selection.baseOffset;
        final newText = text.substring(0, cursorPos) + '*' + text.substring(cursorPos);
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(offset: cursorPos + 1);
      }
    } else {
      // Wrap selected text
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      
      // Check if already wrapped
      final beforeStart = start >= 1 ? text.substring(start - 1, start) : '';
      final afterEnd = end + 1 <= text.length ? text.substring(end, end + 1) : '';
      
      String newText;
      int newCursorPos;
      
      if (beforeStart == '*' && afterEnd == '*') {
        // Remove italic
        newText = text.substring(0, start - 1) + selectedText + text.substring(end + 1);
        newCursorPos = start - 1;
        setState(() {
          _isItalic = false;
        });
      } else {
        // Add italic
        newText = text.substring(0, start) + '*' + selectedText + '*' + text.substring(end);
        newCursorPos = end + 2;
        setState(() {
          _isItalic = true;
        });
      }
      
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: newCursorPos);
    }
    _saveChanges();
  }

  void _applyUnderlineFormatting() {
    final selection = _contentController.selection;
    final text = _contentController.text;
    
    if (!selection.isValid) return;
    
    if (selection.isCollapsed) {
      // Toggle state for future typing
      setState(() {
        _isUnderline = !_isUnderline;
      });
      // Insert markers at cursor if activating
      if (_isUnderline) {
        final cursorPos = selection.baseOffset;
        final newText = text.substring(0, cursorPos) + '__' + text.substring(cursorPos);
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2);
      }
    } else {
      // Wrap selected text
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      
      // Check if already wrapped
      final beforeStart = start >= 2 ? text.substring(start - 2, start) : '';
      final afterEnd = end + 2 <= text.length ? text.substring(end, end + 2) : '';
      
      String newText;
      int newCursorPos;
      
      if (beforeStart == '__' && afterEnd == '__') {
        // Remove underline
        newText = text.substring(0, start - 2) + selectedText + text.substring(end + 2);
        newCursorPos = start - 2;
        setState(() {
          _isUnderline = false;
        });
      } else {
        // Add underline
        newText = text.substring(0, start) + '__' + selectedText + '__' + text.substring(end);
        newCursorPos = end + 4;
        setState(() {
          _isUnderline = true;
        });
      }
      
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: newCursorPos);
    }
    _saveChanges();
  }

  Widget _buildStyledContentField() {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      onChanged: (value) => _saveChanges(),
      maxLines: null,
      expands: true,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      style: GoogleFonts.inter(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        fontSize: 14,
        height: 1.4,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: _contentController.text.isEmpty ? 'Start writing your journal entry...' : '',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  void _applyListFormatting() {
    final selection = _contentController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final text = _contentController.text;
      final selectedText = selection.textInside(text);
      final lines = selectedText.split('\n');
      final formattedLines = lines.map((line) => '• $line').join('\n');

      final newText = text.replaceRange(selection.start, selection.end, formattedLines);
      _contentController.text = newText;

      final newSelection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + formattedLines.length,
      );
      _contentController.selection = newSelection;
    } else {
      final cursorPosition = _contentController.selection.baseOffset;
      final text = _contentController.text;
      final newText = '${text.substring(0, cursorPosition)}\n• ${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPosition + 3);
    }
    _saveChanges();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
        ),
      );
    }

    if (_journalEntries.isEmpty) {
      return _buildEmptyState(themeProvider);
    }

    return Column(
      children: [
        _buildJournalHeader(),
        _buildPageIndicator(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF000000).withOpacity(0.08),
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: _buildJournalEntry(),
          ),
        ),
        _buildToolbar(),
      ],
    );
  }

  Widget _buildJournalHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 40),
          Text(
            'Journal Entries',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: _toggleFavoritesFilter,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_outline,
                size: 18,
                color: _showFavoritesOnly ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final entries = _displayedEntries;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: () async {
                await _saveChanges();
                setState(() {
                  _currentPage--;
                  _loadCurrentEntry();
                });
              },
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            const SizedBox(width: 20),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final actualIndex = _journalEntries.indexOf(entries[index]);
                return GestureDetector(
                  onTap: () async {
                    await _saveChanges();
                    setState(() {
                      _currentPage = index;
                      _loadCurrentEntry();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Provider.of<ThemeProvider>(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${actualIndex + 1}',
                      style: GoogleFonts.inter(
                        color: _currentPage == index
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_currentPage < entries.length - 1)
            GestureDetector(
              onTap: () async {
                await _saveChanges();
                setState(() {
                  _currentPage++;
                  _loadCurrentEntry();
                });
              },
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildJournalEntry() {
    if (_displayedEntries.isEmpty) {
      return Center(
        child: Text(
          'No entries',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }
    final entry = _displayedEntries[_currentPage];
    final actualIndex = _journalEntries.indexOf(entry);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (value) => _saveChanges(),
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Journal Entry Title',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  onChanged: (value) => _saveChanges(),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start writing your journal entry...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    final currentEntry = _displayedEntries.isNotEmpty && _currentPage < _displayedEntries.length
        ? _displayedEntries[_currentPage]
        : null;
    
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactToolbarButton(Icons.format_bold, _applyBoldFormatting, isActive: _isBold),
              _buildCompactToolbarButton(Icons.format_italic, _applyItalicFormatting, isActive: _isItalic),
              _buildCompactToolbarButton(Icons.format_underlined, _applyUnderlineFormatting, isActive: _isUnderline),
              _buildCompactToolbarButton(Icons.format_list_bulleted, _applyListFormatting),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (currentEntry != null)
                _buildCompactToolbarButton(
                  currentEntry.isFavorited ? Icons.favorite : Icons.favorite_border,
                  _toggleFavorite,
                  color: currentEntry.isFavorited ? Colors.red : null,
                )
              else
                _buildCompactToolbarButton(Icons.favorite_border, () {}),
              _buildCompactToolbarButton(Icons.add, _addNewEntry),
              _buildCompactToolbarButton(Icons.delete_outline, _deleteCurrentEntry, color: Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolbarButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive 
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.2))
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: isActive 
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive 
              ? Colors.blue
              : (color ?? Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Journal Entries',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing your first journal entry',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addNewEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create First Entry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}

// ==================== NOTE DETAIL SCREEN ====================

class NoteDetailScreen extends StatefulWidget {
  final note_model.Note note;
  final List<String> availableCategories;
  final VoidCallback onNoteSaved;

  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.availableCategories,
    required this.onNoteSaved,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  late String _selectedCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _selectedCategory = widget.note.category;
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    try {
      await NotesService.updateNote(
        noteId: widget.note.id,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
      );

      widget.onNoteSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save when exiting edit mode
      _saveNote();
    } else {
      // Enter edit mode
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColorHelper.getCategoryBackgroundColor(_selectedCategory);
    final textColor = CategoryColorHelper.getCategoryTextColor(_selectedCategory);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : const Color(0x0C000000),
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  )
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _onBackPressed,
                    child: SizedBox(
                      width: 86,
                      height: 32,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Note Details',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleEdit,
                    icon: Icon(
                      _isEditing ? Icons.save : Icons.edit,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : const Color(0xFF000000).withOpacity(0.1),
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: _titleController,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Note Title',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        )
                      else
                        Text(
                          _titleController.text,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        DropdownButton<String>(
                          value: _selectedCategory,
                          items: widget.availableCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _isEditing
                            ? Column(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _contentController,
                                      maxLines: null,
                                      expands: true,
                                      textAlignVertical: TextAlignVertical.top,
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Start writing your note...',
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildNoteFormattingToolbar(),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  _contentController.text,
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyNoteFormatting(String prefix, String suffix) {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      final cursorPosition = _contentController.selection.baseOffset;
      final text = _contentController.text;
      final newText = '${text.substring(0, cursorPosition)}$prefix$suffix${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPosition + prefix.length);
      return;
    }

    final text = _contentController.text;
    final selectedText = selection.textInside(text);

    if (selectedText.startsWith(prefix) && selectedText.endsWith(suffix)) {
      final unformattedText = selectedText.substring(prefix.length, selectedText.length - suffix.length);
      final newText = text.replaceRange(selection.start, selection.end, unformattedText);
      _contentController.text = newText;
      _contentController.selection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + unformattedText.length,
      );
    } else {
      final formattedText = '$prefix$selectedText$suffix';
      final newText = text.replaceRange(selection.start, selection.end, formattedText);
      _contentController.text = newText;
      _contentController.selection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + formattedText.length,
      );
    }
  }

  Widget _buildNoteFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildFormatButton(Icons.format_bold, () => _applyNoteFormatting('**', '**')),
          const SizedBox(width: 8),
          _buildFormatButton(Icons.format_italic, () => _applyNoteFormatting('*', '*')),
          const SizedBox(width: 8),
          _buildFormatButton(Icons.format_underlined, () => _applyNoteFormatting('__', '__')),
        ],
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.2)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
