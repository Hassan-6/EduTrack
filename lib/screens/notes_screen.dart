import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/route_manager.dart';
import 'new_note_screen.dart';
import '../utils/theme_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _selectedSegment = 0;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Math', 'Physics', 'Personal', 'Projects'];
  
  final List<Note> _notes = [
    Note(
      id: '1',
      title: 'Calculus Chapter 5',
      content: 'Integration by parts formula and examples. Remember u-dv = uv - ∫v du...',
      category: 'Math',
      timeAgo: '2h ago',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
    ),
    Note(
      id: '2',
      title: 'Physics Lab Report',
      content: 'Experiment on pendulum motion. Data analysis shows period is proportional to square root of length.',
      category: 'Physics',
      timeAgo: '1d ago',
      categoryColor: const Color(0xFFDCFCE7),
      textColor: const Color(0xFF16A34A),
    ),
    Note(
      id: '3',
      title: 'Study Schedule',
      content: 'Week 10 planning: Math exam on Friday, Physics assignment due Monday.',
      category: 'Personal',
      timeAgo: '3d ago',
      categoryColor: const Color(0xFFF3E8FF),
      textColor: const Color(0xFF9333EA),
    ),
  ];

  List<Note> get _filteredNotes {
    if (_selectedFilter == 'All') {
      return _notes;
    }
    return _notes.where((note) => note.category == _selectedFilter).toList();
  }

  void _navigateToNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewNoteScreen()),
    );
  }

  void _viewNoteDetail(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
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
                  onAddEntry: _addNewJournalEntry,
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

  void _addNewJournalEntry() {}

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
            child: Container(
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
          
          Container(
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
                        color: _selectedSegment == 0 ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        color: _selectedSegment == 1 ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? themeProvider.primaryColor : Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildNoteCard(Note note) {
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
                note.timeAgo,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            note.content,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: note.categoryColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  note.category,
                  style: GoogleFonts.inter(
                    color: note.textColor,
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

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                title: Text('Edit Note', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                onTap: () {
                  Navigator.pop(context);
                  _viewNoteDetail(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).primaryColor),
                title: Text('Delete Note', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Theme.of(context).primaryColor),
                title: Text('Share Note', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
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

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Delete Note', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        content: Text('Are you sure you want to delete this note?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notes.remove(note);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Journal Content Widget (Always Editable)
class JournalContent extends StatefulWidget {
  final VoidCallback onAddEntry;

  const JournalContent({super.key, required this.onAddEntry});

  @override
  State<JournalContent> createState() => _JournalContentState();
}

class _JournalContentState extends State<JournalContent> {
  int _currentPage = 0;
  final List<JournalEntry> _journalEntries = [
    JournalEntry(
      id: '1',
      title: 'Lorem Ipsum',
      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      createdAt: DateTime(2025, 10, 5, 11, 24),
      isFavorited: false,
    ),
    JournalEntry(
      id: '2',
      title: 'Reflections',
      content: 'Today was a productive day. I completed my math assignment and started working on the physics project. Need to remember to review chapter 5 for the upcoming exam.',
      createdAt: DateTime(2025, 10, 4, 14, 30),
      isFavorited: true,
    ),
    JournalEntry(
      id: '3',
      title: 'Weekend Plans',
      content: 'Planning for the weekend:\n• Complete physics lab report\n• Study for math quiz\n• Work on programming project\n• Exercise routine',
      createdAt: DateTime(2025, 10, 3, 9, 15),
      isFavorited: false,
    ),
    JournalEntry(
      id: '4',
      title: 'Book Recommendations',
      content: 'Books to read:\n- "Clean Code" by Robert Martin\n- "Design Patterns" by Gang of Four\n- "The Pragmatic Programmer"',
      createdAt: DateTime(2025, 10, 2, 16, 45),
      isFavorited: false,
    ),
    JournalEntry(
      id: '5',
      title: 'Project Ideas',
      content: 'Mobile app development ideas:\n1. Student productivity tracker\n2. AI-powered study assistant\n3. Collaborative note-taking platform',
      createdAt: DateTime(2025, 10, 1, 13, 20),
      isFavorited: true,
    ),
    JournalEntry(
      id: '6',
      title: 'Learning Goals',
      content: 'Skills to learn this semester:\n• Flutter advanced concepts\n• Firebase integration\n• UI/UX design principles\n• API development',
      createdAt: DateTime(2025, 9, 30, 10, 0),
      isFavorited: false,
    ),
  ];

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  // Text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEntry();
  }

  void _loadCurrentEntry() {
    if (_journalEntries.isNotEmpty) {
      _titleController.text = _journalEntries[_currentPage].title;
      _contentController.text = _journalEntries[_currentPage].content;
    }
  }

  void _saveChanges() {
    if (_journalEntries.isNotEmpty) {
      setState(() {
        _journalEntries[_currentPage].title = _titleController.text;
        _journalEntries[_currentPage].content = _contentController.text;
        _journalEntries[_currentPage].createdAt = DateTime.now();
      });
    }
  }

  void _addNewEntry() {
    final newEntry = JournalEntry(
      id: '${_journalEntries.length + 1}',
      title: 'New Journal Entry',
      content: 'Start writing your thoughts here...',
      createdAt: DateTime.now(),
      isFavorited: false,
    );
    
    setState(() {
      _journalEntries.insert(0, newEntry);
      _currentPage = 0;
      _loadCurrentEntry();
    });
  }

  void _toggleFavorite() {
    if (_journalEntries.isNotEmpty) {
      setState(() {
        _journalEntries[_currentPage].isFavorited = !_journalEntries[_currentPage].isFavorited;
      });
    }
  }

  void _deleteCurrentEntry() {
    if (_journalEntries.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        title: Text('Delete Journal Entry', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        content: Text('Are you sure you want to delete this journal entry? This action cannot be undone.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
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

  void _performDelete() {
    if (_journalEntries.isEmpty) return;

    setState(() {
      _journalEntries.removeAt(_currentPage);
      
      if (_journalEntries.isEmpty) {
        _currentPage = 0;
        _titleController.clear();
        _contentController.clear();
      } else if (_currentPage >= _journalEntries.length) {
        _currentPage = _journalEntries.length - 1;
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
  }

  void _applyBoldFormatting() {
    _applyFormatting('**', '**');
  }

  void _applyItalicFormatting() {
    _applyFormatting('*', '*');
  }

  void _applyUnderlineFormatting() {
    _applyFormatting('<u>', '</u>');
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
  }

  void _applyFormatting(String prefix, String suffix) {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      // Insert formatting at cursor position
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_journalEntries.isEmpty) {
      return _buildEmptyState(themeProvider);
    }

    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: () {
                    _saveChanges();
                    setState(() {
                      _currentPage--;
                      _loadCurrentEntry();
                    });
                  },
                  child: Icon(Icons.chevron_left, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic icon
                )
              else
                const SizedBox(width: 20),
                
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _journalEntries.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _saveChanges();
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
                              ? themeProvider.primaryColor // THEME: Dynamic active color
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            color: _currentPage == index ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic text
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              if (_currentPage < _journalEntries.length - 1)
                GestureDetector(
                  onTap: () {
                    _saveChanges();
                    setState(() {
                      _currentPage++;
                      _loadCurrentEntry();
                    });
                  },
                  child: Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic icon
                )
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
        
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // THEME: Dynamic card color
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.3) 
                      : const Color(0xFF000000).withOpacity(0.08), // THEME: Adaptive shadow
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: _buildJournalEntry(),
          ),
        ),
        
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // THEME: Dynamic background
            border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
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
                  _buildCompactToolbarButton(
                    _journalEntries[_currentPage].isFavorited ? Icons.favorite : Icons.favorite_border,
                    _toggleFavorite,
                    color: _journalEntries[_currentPage].isFavorited ? Colors.red : null,
                  ),
                  _buildCompactToolbarButton(Icons.add, _addNewEntry),
                  _buildCompactToolbarButton(Icons.delete_outline, _deleteCurrentEntry, color: Colors.red),
                  _buildCompactToolbarButton(Icons.more_vert, () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // THEME: Dynamic icon
          const SizedBox(height: 16),
          Text(
            'No Journal Entries',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing your first journal entry',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addNewEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor, // THEME: Dynamic button color
              foregroundColor: Colors.white,
            ),
            child: const Text('Create First Entry'),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry() {
    final entry = _journalEntries[_currentPage];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            onChanged: (value) => _saveChanges(),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Journal Entry Title',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // THEME: Dynamic hint
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            height: 1,
            color: Theme.of(context).dividerColor, // THEME: Dynamic divider
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: TextField(
              controller: _contentController,
              onChanged: (value) => _saveChanges(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // THEME: Dynamic text color
                fontSize: 14,
                height: 1.4,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing your journal entry...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // THEME: Dynamic hint
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            height: 1,
            color: Theme.of(context).dividerColor, // THEME: Dynamic divider
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Entry ${_currentPage + 1} of ${_journalEntries.length} • Created: ${_formatDate(entry.createdAt)}',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic text
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolbarButton(IconData icon, VoidCallback onTap, {Color? color, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : const Color(0xFFF3F4F6), // THEME: Adaptive background
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: Theme.of(context).primaryColor) : null, // THEME: Dynamic border
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? (isActive ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic icon color
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

// Note Detail Screen (No Bottom Nav Bar)
class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _applyFormatting(String format) {
    final currentText = _contentController.text;
    switch (format) {
      case 'bold':
        _contentController.text = '$currentText **bold text**';
        break;
      case 'italic':
        _contentController.text = '$currentText *italic text*';
        break;
      case 'underline':
        _contentController.text = '$currentText __underlined text__';
        break;
      case 'list':
        _contentController.text = '$currentText\n• List item';
        break;
    }
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _contentController.text.length),
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, '/notes');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // THEME: Dynamic app bar
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.black.withOpacity(0.3) 
                        : const Color(0x0C000000), // THEME: Adaptive shadow
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
                    child: Container(
                      width: 86,
                      height: 32,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic icon
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleEdit,
                    icon: Icon(
                      _isEditing ? Icons.save : Icons.edit,
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic icon
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : const Color(0xFF000000).withOpacity(0.1), // THEME: Adaptive shadow
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
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Note Title',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // THEME: Dynamic hint
                          ),
                        )
                      else
                        Text(
                          widget.note.title,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.note.categoryColor,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          widget.note.category,
                          style: GoogleFonts.inter(
                            color: widget.note.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _contentController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // THEME: Dynamic text
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Start writing your note...',
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // THEME: Dynamic hint
                                ),
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  widget.note.content,
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // THEME: Dynamic text
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
            
            if (_isEditing)
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic background
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFormatButton(Icons.format_bold, () => _applyFormatting('bold'), themeProvider),
                    _buildFormatButton(Icons.format_italic, () => _applyFormatting('italic'), themeProvider),
                    _buildFormatButton(Icons.format_underlined, () => _applyFormatting('underline'), themeProvider),
                    _buildFormatButton(Icons.format_list_bulleted, () => _applyFormatting('list'), themeProvider),
                    _buildFormatButton(Icons.bookmark_border, () {}, themeProvider),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, VoidCallback onTap, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black.withOpacity(0.2) 
              : const Color(0xFFF3F4F6), // THEME: Adaptive background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
        ),
      ),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final String timeAgo;
  final Color categoryColor;
  final Color textColor;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.timeAgo,
    required this.categoryColor,
    required this.textColor,
  });
}

class JournalEntry {
  String id;
  String title;
  String content;
  DateTime createdAt;
  bool isFavorited;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isFavorited,
  });
}