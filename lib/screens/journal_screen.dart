import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
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
      title: 'Weekly Goals',
      content: 'Goals for this week:\n1. Complete calculus assignment\n2. Prepare for physics lab\n3. Work on app development project\n4. Exercise 3 times this week',
      createdAt: DateTime(2025, 10, 3, 9, 15),
      isFavorited: false,
    ),
  ];

  final List<JournalEntry> _favoriteEntries = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showFavorites = false;
  bool _isSearching = false;
  List<JournalEntry> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _updateFavorites();
  }

  void _updateFavorites() {
    _favoriteEntries.clear();
    _favoriteEntries.addAll(_journalEntries.where((entry) => entry.isFavorited));
  }

  void _toggleFavorite(int index) {
    setState(() {
      _journalEntries[index].isFavorited = !_journalEntries[index].isFavorited;
      _updateFavorites();
    });
  }

  void _deleteEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journal Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _journalEntries.removeAt(index);
                if (_currentPage >= _journalEntries.length) {
                  _currentPage = _journalEntries.length - 1;
                }
                _updateFavorites();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addNewEntry() {
    final newEntry = JournalEntry(
      id: '${_journalEntries.length + 1}',
      title: 'New Entry',
      content: '',
      createdAt: DateTime.now(),
      isFavorited: false,
    );
    
    setState(() {
      _journalEntries.insert(0, newEntry);
      _currentPage = 0;
      _updateFavorites();
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _searchResults.clear();
      } else {
        _isSearching = true;
        _searchResults = _journalEntries.where((entry) =>
          entry.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.content.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _toggleFavoritesView() {
    setState(() {
      _showFavorites = !_showFavorites;
    });
  }

  List<JournalEntry> get _displayEntries {
    if (_isSearching) return _searchResults;
    if (_showFavorites) return _favoriteEntries;
    return _journalEntries;
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Page Viewer or List View
            Expanded(
              child: _isSearching || _showFavorites 
                  ? _buildListView()
                  : _buildPageView(),
            ),
            
            // Formatting Tools and Timestamp
            _buildToolbar(),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _onBackPressed,
            child: Container(
              width: 86,
              height: 32,
              child: Row(
                children: [
                  Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F846d4b3b-6d2d-4f40-83da-58332d835dd3.png',
                    width: 11,
                    height: 11,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1E1E1E),
                      fontSize: 16,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Screen Title
          Text(
            _showFavorites ? 'Favorites' : 'Journal',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // Search and Favorite Toggle
          Row(
            children: [
              // Search Icon
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchResults.clear();
                    }
                  });
                },
                child: Container(
                  width: 28,
                  height: 36,
                  child: Center(
                    child: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Favorite Toggle
              GestureDetector(
                onTap: _toggleFavoritesView,
                child: Container(
                  width: 28,
                  height: 36,
                  child: Center(
                    child: Icon(
                      _showFavorites ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: _showFavorites ? const Color(0xFF4E9FEC) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Column(
      children: [
        // Page Indicator
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Page
              if (_currentPage > 0)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage--;
                    });
                  },
                  child: const Icon(Icons.chevron_left, size: 24),
                )
              else
                const SizedBox(width: 24),
              
              // Page Numbers
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_journalEntries.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? const Color(0xFF4E9FEC) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: _currentPage == index ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              
              // Next Page
              if (_currentPage < _journalEntries.length - 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage++;
                    });
                  },
                  child: const Icon(Icons.chevron_right, size: 24),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        ),
        
        // Page Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.1),
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: _buildJournalEntry(_journalEntries[_currentPage]),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Search Bar (when searching)
          if (_isSearching) ...[
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search journal entries...',
                  hintStyle: GoogleFonts.inter(color: Theme.of(context).hintColor),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
            ),
          ],
          
          // Entries List
          Expanded(
            child: ListView.builder(
              itemCount: _displayEntries.length,
              itemBuilder: (context, index) {
                final entry = _displayEntries[index];
                return _buildJournalCard(entry, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(JournalEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          entry.title,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.content.length > 100 
                  ? '${entry.content.substring(0, 100)}...' 
                  : entry.content,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(entry.createdAt)}',
              style: GoogleFonts.inter(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          entry.isFavorited ? Icons.favorite : Icons.favorite_border,
          color: entry.isFavorited ? Colors.red : Theme.of(context).hintColor,
        ),
        onTap: () {
          if (_isSearching || _showFavorites) {
            final originalIndex = _journalEntries.indexWhere((e) => e.id == entry.id);
            if (originalIndex != -1) {
              setState(() {
                _currentPage = originalIndex;
                _isSearching = false;
                _showFavorites = false;
                _searchController.clear();
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildJournalEntry(JournalEntry entry) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            entry.title,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                entry.content,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4B5563),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          
          const SizedBox(height: 16),
          
          // Created Date
          Text(
            'Created on:\\n${_formatDate(entry.createdAt)}',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    if (_journalEntries.isEmpty) return const SizedBox();
    
    final currentEntry = _journalEntries[_currentPage];
    
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Formatting Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Bold
              _buildToolbarButton(Icons.format_bold, () {}),
              
              // Italic
              _buildToolbarButton(Icons.format_italic, () {}),
              
              // Underline
              _buildToolbarButton(Icons.format_underlined, () {}),
              
              // List
              _buildToolbarButton(Icons.format_list_bulleted, () {}),
              
              // Favorite
              _buildToolbarButton(
                currentEntry.isFavorited ? Icons.favorite : Icons.favorite_border,
                () => _toggleFavorite(_currentPage),
                color: currentEntry.isFavorited ? Colors.red : null,
              ),
              
              // Delete
              _buildToolbarButton(Icons.delete, () => _deleteEntry(_currentPage)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Timestamp
          Text(
            'Last edited: ${_formatDate(DateTime.now())}',
            style: GoogleFonts.inter(
              color: Theme.of(context).hintColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 77,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', () {
            Navigator.pushReplacementNamed(context, '/main_menu');
          }),
          _buildNavItem(Icons.checklist, 'Tasks', () {
            Navigator.pushReplacementNamed(context, '/todo');
          }),
          _buildNavItem(Icons.question_answer, 'Q&A', () {
            Navigator.pushReplacementNamed(context, '/qna');
          }),
          _buildNavItem(Icons.person, 'Profile', () {
            Navigator.pushReplacementNamed(context, '/profile');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).hintColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

class JournalEntry {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  bool isFavorited;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isFavorited,
  });
}