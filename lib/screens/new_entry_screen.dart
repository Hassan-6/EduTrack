import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'calendar_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/calendar_event.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  bool _isAllDay = false;
  EventType _selectedEventType = EventType.assignment;
  
  bool _isStartAM = true;
  bool _isEndAM = true;
  int _startHour = 8;
  int _startMinute = 0;
  int _endHour = 10;
  int _endMinute = 30;

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startHour = picked.hourOfPeriod;
        _isStartAM = picked.period == DayPeriod.am;
      });
    }
  }

  void _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endHour = picked.hourOfPeriod;
        _isEndAM = picked.period == DayPeriod.am;
      });
    }
  }

  void _createEntry() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      date: _selectedDate,
      startTime: _isAllDay ? 'All Day' : _startTime.format(context),
      endTime: _isAllDay ? '' : _endTime.format(context),
      type: _selectedEventType,
      color: _getEventColor(_selectedEventType),
    );

    Navigator.pop(context, event);
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return const Color(0xFF4E9FEC);
      case EventType.event:
        return const Color(0xFF5CD6C0);
      case EventType.exam:
        return const Color(0xFFFB923C);
      default:
        return const Color(0xFF4E9FEC);
    }
  }

  String _getEventTypeName(EventType type) {
    switch (type) {
      case EventType.assignment:
        return 'Assignment';
      case EventType.event:
        return 'Event';
      case EventType.exam:
        return 'Exam';
      default:
        return 'Event';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // THEME: Dynamic header
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  
                  // Title
                  Text(
                    'New Entry',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Placeholder for alignment
                  const SizedBox(width: 86),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Date Selection Card
                    _buildDateCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Time Selection
                    _buildTimeSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Event Details Card
                    _buildEventDetailsCard(),
                  ],
                ),
              ),
            ),

            // Create Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: themeProvider.gradient, // THEME: Dynamic gradient
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
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _createEntry,
                  child: Center(
                    child: Text(
                      'Create Entry',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  Widget _buildDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select date',
            style: GoogleFonts.roboto(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(_selectedDate),
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 16,
                        letterSpacing: 1,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All Day Toggle at the top
          Row(
            children: [
              Switch(
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor, // THEME: Dynamic switch color
              ),
              const SizedBox(width: 8),
              Text(
                'All Day',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (!_isAllDay) ...[
            const SizedBox(height: 20),
            
            // Time Selection Header
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Start Time',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'End Time',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Compact Time Pickers
            Row(
              children: [
                // Start Time Picker
                Expanded(
                  child: _buildCompactTimePicker(
                    time: _startTime,
                    onTap: _selectStartTime,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // End Time Picker
                Expanded(
                  child: _buildCompactTimePicker(
                    time: _endTime,
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactTimePicker({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black.withOpacity(0.2) 
              : const Color(0xFFF8FAFC), // THEME: Adaptive background
          border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                time.format(context),
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.access_time_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildFormField(
            label: 'Title',
            hintText: 'Enter title...',
            controller: _titleController,
          ),
          
          const SizedBox(height: 24),
          
          // Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.2) 
                      : const Color(0x7FFFFFFF), // THEME: Adaptive background
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EventType>(
                    value: _selectedEventType,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
                    ),
                    items: EventType.values.map((EventType type) {
                      return DropdownMenuItem<EventType>(
                        value: type,
                        child: Text(
                          _getEventTypeName(type),
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (EventType? newValue) {
                      setState(() {
                        _selectedEventType = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Description
          _buildFormField(
            label: 'Reminder Message',
            hintText: 'Enter message...',
            controller: _descriptionController,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2) 
                : const Color(0x7FFFFFFF), // THEME: Adaptive background
            border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic hint
                fontSize: 16,
                height: 1.5,
              ),
            ),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}