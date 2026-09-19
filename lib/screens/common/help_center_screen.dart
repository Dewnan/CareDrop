import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/support_ticket_model.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/support_ticket_service.dart';
import '../../services/task_service.dart';
import '../../components/support_ticket_card_tile.dart';
import '../../theme/app_theme.dart';
import 'ticket_thread_screen.dart';

/// Screen providing the Help Center interface with options to submit support tickets and view ticket history.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'payment_issue';
  String? _selectedTaskId;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = const [
    {'value': 'payment_issue', 'label': 'Payment Issue'},
    {'value': 'task_dispute', 'label': 'Task Dispute'},
    {'value': 'account_problem', 'label': 'Account Problem'},
    {'value': 'helper_complaint', 'label': 'Helper Complaint'},
    {'value': 'other', 'label': 'Other / General Query'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Submits the support ticket form and redirects to the My Tickets tab upon successful creation.
  Future<void> _handleSubmitTicket() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a support ticket.')),
      );
      return;
    }

    final appState = Provider.of<CareDropAppState>(context, listen: false);
    final userModel = appState.currentUserModel;

    final userRole = userModel?.role ??
        (appState.currentRole == AppRole.helper ? 'helper' : 'patient');
    final userName = userModel?.fullName ??
        (userModel?.email.isNotEmpty == true ? userModel!.email : 'User');

    setState(() {
      _isSubmitting = true;
    });

    final ticketId = await SupportTicketService.createTicket(
      userId: user.uid,
      userRole: userRole,
      userName: userName,
      category: _selectedCategory,
      subject: _subjectController.text.trim(),
      initialMessage: _descriptionController.text.trim(),
      relatedTaskId: _selectedTaskId,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (ticketId.isNotEmpty) {
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedTaskId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created successfully!')),
        );

        // Switch to "My Tickets" tab
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit ticket. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appState = Provider.of<CareDropAppState>(context);
    final isHelper = appState.currentRole == AppRole.helper ||
        appState.currentUserModel?.role.toLowerCase() == 'helper';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CareDropTheme.royalBlue,
          unselectedLabelColor: CareDropTheme.textSecondary,
          indicatorColor: CareDropTheme.royalBlue,
          tabs: const [
            Tab(text: 'Create Ticket'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Create Ticket Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need assistance with your task or account? Submit a ticket to our support team.',
                    style: TextStyle(
                      color: CareDropTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
                  const Text(
                    'ISSUE CATEGORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat['value'],
                              child: Text(cat['label']!),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject Input
                  const Text(
                    'SUBJECT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _subjectController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      hintText: 'Brief summary of the issue',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a subject.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description Input
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Provide detailed information about your inquiry...',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a detailed description.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Select Recent Task Dropdown
                  const Text(
                    'SELECT RECENT TASK (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  user == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<List<TaskModel>>(
                          stream: isHelper
                              ? TaskService.streamHelperTasks(user.uid)
                              : TaskService.streamPatientTasks(user.uid),
                          builder: (context, snapshot) {
                            final tasks = snapshot.data ?? [];
                            final items = <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None / Not Task Specific'),
                              ),
                              ...tasks.map((task) {
                                final shortId = task.id.length > 8
                                    ? task.id.substring(0, 8)
                                    : task.id;
                                final label =
                                    '${task.title.isNotEmpty ? task.title : "Task"} (#$shortId)';
                                return DropdownMenuItem<String?>(
                                  value: task.id,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ];

                            // Ensure selected value exists in dropdown items list
                            final validValue = items.any((i) => i.value == _selectedTaskId)
                                ? _selectedTaskId
                                : null;

                            return DropdownButtonFormField<String?>(
                              initialValue: validValue,
                              isExpanded: true,
                              decoration: const InputDecoration(),
                              items: items,
                              onChanged: (val) {
                                setState(() {
                                  _selectedTaskId = val;
                                });
                              },
                            );
                          },
                        ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmitTicket,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Support Ticket'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: My Tickets List
          user == null
              ? const Center(
                  child: Text(
                    'Please sign in to view your tickets.',
                    style: TextStyle(color: CareDropTheme.textSecondary),
                  ),
                )
              : StreamBuilder<List<SupportTicketModel>>(
                  stream: SupportTicketService.streamUserTickets(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: CareDropTheme.royalBlue),
                      );
                    }

                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) {
                      return const Center(
                        child: Text(
                          'You have no support tickets.',
                          style: TextStyle(color: CareDropTheme.textMuted),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return SupportTicketCardTile(
                          ticket: ticket,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketThreadScreen(ticket: ticket),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
