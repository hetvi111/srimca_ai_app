import 'package:flutter/material.dart';

// Navy Blue Theme Colors
const Color navyBlue = Color(0xFF001F3F);
const Color navyBlueLight = Color(0xFF1A237E);
const Color accentBlue = Color(0xFF1E88E5);
const Color lightGrey = Color(0xFFF5F5F5);

class FacultyEventManagementPage extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  
  const FacultyEventManagementPage({
    super.key,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  State<FacultyEventManagementPage> createState() => _FacultyEventManagementPageState();
}

class _FacultyEventManagementPageState extends State<FacultyEventManagementPage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        events = _getDemoEvents();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDemoEvents() {
    return [
      {
        'id': '1',
        'title': 'Tech Fest 2024',
        'description': 'Annual technology festival with coding competitions, workshops, and tech talks.',
        'date': '2024-03-15',
        'time': '10:00 AM',
        'venue': 'Main Auditorium',
        'organizer': widget.facultyName,
        'status': 'upcoming',
        'participants': 150,
      },
      {
        'id': '2',
        'title': 'Guest Lecture: Future of AI',
        'description': 'Dr. Sarah Johnson from MIT will discuss the latest trends in Artificial Intelligence.',
        'date': '2024-02-28',
        'time': '2:00 PM',
        'venue': 'Conference Hall A',
        'organizer': widget.facultyName,
        'status': 'upcoming',
        'participants': 80,
      },
      {
        'id': '3',
        'title': 'Workshop: Web Development',
        'description': 'Hands-on workshop on modern web development technologies.',
        'date': '2024-02-20',
        'time': '11:00 AM',
        'venue': 'Computer Lab 1',
        'organizer': widget.facultyName,
        'status': 'completed',
        'participants': 45,
      },
    ];
  }

  Future<void> _createEvent() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final venueController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Event',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyBlue),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: venueController,
                      decoration: InputDecoration(
                        labelText: 'Venue',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (date != null) setModalState(() => selectedDate = date);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: selectedTime);
                              if (time != null) setModalState(() => selectedTime = time);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(selectedTime.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            Navigator.pop(context);
                            setState(() {
                              events.insert(0, {
                                'id': DateTime.now().toString(),
                                'title': titleController.text,
                                'description': descriptionController.text,
                                'date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                'time': selectedTime.format(context),
                                'venue': venueController.text,
                                'organizer': widget.facultyName,
                                'status': 'upcoming',
                                'participants': 0,
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully!')));
                          }
                        },
                        child: const Text('Create Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cancelEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text('Are you sure you want to cancel this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        events = events.where((e) => e['id'] != eventId).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event cancelled')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Event Management"),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        backgroundColor: accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Event", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(event);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Tap + to create your first event", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['status'] ?? 'upcoming';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event, color: _getStatusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyBlue)),
                      Text('By ${event['organizer']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['description'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${event['date']} at ${event['time']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(event['venue'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${event['participants']} participants', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                if (status == 'upcoming') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelEvent(event['id']),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send),
                          label: const Text('Send Notification'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return accentBlue;
    }
  }
}
