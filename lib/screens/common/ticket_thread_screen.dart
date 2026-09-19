import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/support_ticket_model.dart';
import '../../providers/app_state.dart';
import '../../services/support_ticket_service.dart';
import '../../theme/app_theme.dart';

/// Screen displaying real-time chat messages for a specific support ticket thread and allowing user replies.
class TicketThreadScreen extends StatefulWidget {
  final SupportTicketModel ticket;

  const TicketThreadScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends State<TicketThreadScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late Stream<List<TicketMessageModel>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = SupportTicketService.streamTicketMessages(widget.ticket.id);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends a reply message from the current authenticated user and scrolls to the bottom of the message thread.
  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    final appState = Provider.of<CareDropAppState>(context, listen: false);
    final userName = appState.currentUserModel?.fullName ??
        (user.displayName?.isNotEmpty == true ? user.displayName! : 'User');

    final success = await SupportTicketService.sendReplyMessage(
      ticketId: widget.ticket.id,
      senderId: user.uid,
      senderRole: 'user',
      senderName: userName,
      body: text,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (success) {
        _replyController.clear();
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply. Please try again.')),
        );
      }
    }
  }

  /// Scrolls the message list view to the latest message entry at the bottom.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Resolves status background color based on current support ticket state.
  Color _getStatusBgColor() {
    switch (widget.ticket.status) {
      case 'open':
        return CareDropTheme.pendingBg;
      case 'in_progress':
        return const Color(0xFFE0F2FE);
      case 'resolved':
        return CareDropTheme.paidBg;
      case 'closed':
      default:
        return CareDropTheme.normalBg;
    }
  }

  /// Resolves status text color based on current support ticket state.
  Color _getStatusTextColor() {
    switch (widget.ticket.status) {
      case 'open':
        return CareDropTheme.pendingText;
      case 'in_progress':
        return const Color(0xFF0369A1);
      case 'resolved':
        return CareDropTheme.paidText;
      case 'closed':
      default:
        return CareDropTheme.normalText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.ticket.status == 'resolved' || widget.ticket.status == 'closed';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject),
      ),
      body: Column(
        children: [
          // Ticket Overview Header Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: CareDropTheme.cardBorderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category: ${widget.ticket.categoryDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CareDropTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.ticket.relatedTaskId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Related Task: #${widget.ticket.relatedTaskId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CareDropTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.ticket.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusTextColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Chat Thread
          Expanded(
            child: StreamBuilder<List<TicketMessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: CareDropTheme.royalBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                List<TicketMessageModel> messages = List<TicketMessageModel>.from(snapshot.data ?? []);
                
                final initialBody = widget.ticket.description.isNotEmpty
                    ? widget.ticket.description
                    : widget.ticket.subject;
                    
                if (initialBody.isNotEmpty) {
                  messages.insert(0, TicketMessageModel(
                    id: 'MSG-INIT-${widget.ticket.id}',
                    senderId: widget.ticket.userId,
                    senderRole: widget.ticket.userRole,
                    senderName: widget.ticket.userName,
                    body: initialBody,
                    createdAt: widget.ticket.createdAt,
                  ));
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages in this ticket yet.',
                      style: TextStyle(color: CareDropTheme.textMuted),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.isAdmin;
                    final dateStr =
                        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
                    final senderLabel = isAdmin
                        ? 'CareDrop Support'
                        : (msg.senderName.isNotEmpty && msg.senderName != 'User'
                            ? msg.senderName
                            : 'You');

                    return Align(
                      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.white : CareDropTheme.royalBlue,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isAdmin ? 2 : 12),
                            bottomRight: Radius.circular(isAdmin ? 12 : 2),
                          ),
                          border: isAdmin
                              ? Border.all(color: CareDropTheme.cardBorderColor)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Text(
                              senderLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? CareDropTheme.royalBlue : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: isAdmin ? CareDropTheme.textPrimary : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: isAdmin ? CareDropTheme.textMuted : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Reply Input Bar / Closed Notice
          if (!isClosed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: CareDropTheme.cardBorderColor),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type your reply...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _handleSendReply,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CareDropTheme.royalBlue,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: CareDropTheme.royalBlue),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: CareDropTheme.normalBg,
              child: const SafeArea(
                child: Text(
                  'This support ticket is resolved/closed. Create a new ticket if you need further help.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CareDropTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
