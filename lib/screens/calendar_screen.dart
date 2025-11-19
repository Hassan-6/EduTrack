import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'new_entry_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<CalendarEvent> _events = [
    CalendarEvent(
      id: '1',
      title: 'Math Assignment 3 Due',
      description: 'Complete chapters 5-7',
      date: DateTime(2024, 11, 15),
      startTime: '11:59 PM',
      endTime: '',
      type: EventType.assignment,
      color: const Color(0xFF4E9FEC),
    ),
    CalendarEvent(
      id: '2',
      title: 'Study Group Meeting',
      description: 'Library room 302',
      date: DateTime(2024, 11, 15),
      startTime: '3:00 PM',
      endTime: '5:00 PM',
      type: EventType.event,
      color: const Color(0xFF5CD6C0),
    ),
    CalendarEvent(
      id: '3',
      title: 'Biology Quiz',
      description: 'Chapters 1-4',
      date: DateTime(2024, 11, 5),
      startTime: '10:00 AM',
      endTime: '11:00 AM',
      type: EventType.exam,
      color: const Color(0xFFFB923C),
    ),
    CalendarEvent(
      id: '4',
      title: 'English Essay Due',
      description: 'Minimum 1000 words',
      date: DateTime(2024, 11, 12),
      startTime: '11:59 PM',
      endTime: '',
      type: EventType.assignment,
      color: const Color(0xFF4E9FEC),
    ),
    CalendarEvent(
      id: '5',
      title: 'Physics Lab',
      description: 'Experiment #5',
      date: DateTime(2024, 11, 18),
      startTime: '2:00 PM',
      endTime: '4:00 PM',
      type: EventType.event,
      color: const Color(0xFF5CD6C0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => isSameDay(event.date, day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _addNewEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );

    if (result != null && result is CalendarEvent) {
      setState(() {
        _events.add(result);
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event "${result.title}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return const Color(0xFF4E9FEC); // Blue
      case EventType.event:
        return const Color(0xFF5CD6C0); // Green
      case EventType.exam:
        return const Color(0xFFFB923C); // Orange
      default:
        return const Color(0xFF4E9FEC);
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Calendar Widget
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: _onFormatChanged,
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    final events = _getEventsForDay(day);
                    return events;
                  },
                  
                  // Custom day builder for colored dots
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      
                      // Filter out null events and get unique event types
                      final validEvents = events.whereType<CalendarEvent>();
                      final eventTypes = validEvents.map((e) => e.type).toSet();
                      
                      if (eventTypes.isEmpty) return const SizedBox.shrink();
                      
                      // If only one event type, show single dot
                      if (eventTypes.length == 1) {
                        final eventType = eventTypes.first;
                        return Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getEventColor(eventType),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      
                      // If multiple event types, show multiple dots
                      return Positioned(
                        bottom: 1,
                        right: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: eventTypes.take(3).map((type) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: _getEventColor(type),
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  
                  // Styling
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                      fontSize: 14,
                    ),
                    titleTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
                      size: 20,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
                      size: 20,
                    ),
                  ),
                  
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 14,
                    ),
                    weekendTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 14,
                    ),
                    outsideTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic text
                      fontSize: 14,
                    ),
                    selectedTextStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    todayTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 1), // THEME: Dynamic border
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor, // THEME: Dynamic selection
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Event Legend
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(const Color(0xFF4E9FEC), 'Assignment'),
                    _buildLegendItem(const Color(0xFF5CD6C0), 'Event'),
                    _buildLegendItem(const Color(0xFFFB923C), 'Exam'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Selected Date Events
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDay != null 
                          ? '${_getMonthName(_selectedDay!.month)} ${_selectedDay!.day}, ${_selectedDay!.year}'
                          : 'Select a date',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No events for this day',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      ...selectedEvents.map((event) => _buildEventItem(event)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCalendarFloatingActionButton(themeProvider),
    );
  }

  Widget _buildCalendarFloatingActionButton(ThemeProvider themeProvider) {
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
        gradient: themeProvider.gradient, // THEME: Dynamic gradient
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: _addNewEvent,
          child: Center(
            child: Image.network(
              'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F1acf3707-fc14-48b1-a087-6a99c88d6baa.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Icon(
              _getEventIcon(event.type),
              color: event.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.endTime.isEmpty 
                      ? 'Due: ${event.startTime}'
                      : '${event.startTime} - ${event.endTime}',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEventTypeText(event.type),
                    style: GoogleFonts.inter(
                      color: event.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.assignment:
        return Icons.assignment;
      case EventType.event:
        return Icons.event;
      case EventType.exam:
        return Icons.quiz;
      default:
        return Icons.calendar_today;
    }
  }

  String _getEventTypeText(EventType type) {
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}