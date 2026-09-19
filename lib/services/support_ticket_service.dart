import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/support_ticket_model.dart';

/// Service managing support ticket creation, real-time message streams, and status updates in Firestore.
class SupportTicketService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'support_tickets';

  /// Creates a new support ticket and adds the initial user message into the messages sub-collection.
  static Future<String> createTicket({
    required String userId,
    required String userRole,
    required String userName,
    required String category,
    required String subject,
    required String initialMessage,
    String? relatedTaskId,
    String priority = 'medium',
  }) async {
    try {
      final docRef = _db.collection(_collection).doc();
      final ticket = SupportTicketModel(
        id: docRef.id,
        userId: userId,
        userRole: userRole,
        userName: userName,
        category: category,
        subject: subject,
        description: initialMessage,
        status: 'open',
        priority: priority,
        relatedTaskId: relatedTaskId?.trim().isEmpty == true ? null : relatedTaskId?.trim(),
      );

      await docRef.set(ticket.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      return '';
    }
  }

  /// Streams real-time support tickets belonging to a specific user.
  static Stream<List<SupportTicketModel>> streamUserTickets(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db 
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => SupportTicketModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tickets;
    });
  }

  /// Streams real-time chat messages for a specific support ticket thread.
  static Stream<List<TicketMessageModel>> streamTicketMessages(String ticketId) {
    if (ticketId.isEmpty) return Stream.value([]);
    return _db
        .collection(_collection)
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => TicketMessageModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      return messages;
    });
  }

  /// Sends a reply message within a ticket thread and updates the ticket's updatedAt timestamp.
  static Future<bool> sendReplyMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    String? senderName,
    required String body,
  }) async {
    if (ticketId.isEmpty || body.trim().isEmpty) return false;

    try {
      final msgRef = _db.collection(_collection).doc(ticketId).collection('messages').doc();
      final newMsg = TicketMessageModel(
        id: msgRef.id,
        senderId: senderId,
        senderRole: senderRole,
        senderName: senderName ?? 'User',
        body: body.trim(),
      );

      await msgRef.set(newMsg.toMap());

      // Update parent ticket's timestamps and reset status if pending reply
      await _db.collection(_collection).doc(ticketId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      return true;
    } catch (e) {
      debugPrint('Error sending ticket reply: $e');
      return false;
    }
  }
}
