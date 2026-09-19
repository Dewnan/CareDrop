import 'package:flutter_test/flutter_test.dart';
import 'package:caredrop/models/support_ticket_model.dart';

void main() {
  group('SupportTicketModel & TicketMessageModel Tests', () {
    test('SupportTicketModel toMap and fromMap serialization', () {
      final now = DateTime.now();
      final ticket = SupportTicketModel(
        id: 'ticket_123',
        userId: 'user_abc',
        userRole: 'patient',
        userName: 'John Doe',
        category: 'payment_issue',
        subject: 'Payment double charged',
        status: 'open',
        priority: 'high',
        relatedTaskId: 'task_99',
        createdAt: now,
        updatedAt: now,
      );

      expect(ticket.id, 'ticket_123');
      expect(ticket.categoryDisplay, 'Payment Issue');

      final map = ticket.toMap();
      expect(map['id'], 'ticket_123');
      expect(map['category'], 'payment_issue');
      expect(map['subject'], 'Payment double charged');

      final deserialized = SupportTicketModel.fromMap(map, docId: 'ticket_123');
      expect(deserialized.id, 'ticket_123');
      expect(deserialized.userId, 'user_abc');
      expect(deserialized.userRole, 'patient');
      expect(deserialized.subject, 'Payment double charged');
      expect(deserialized.status, 'open');
      expect(deserialized.priority, 'high');
      expect(deserialized.relatedTaskId, 'task_99');
    });

    test('TicketMessageModel toMap and fromMap serialization', () {
      final msg = TicketMessageModel(
        id: 'msg_1',
        senderId: 'admin_1',
        senderRole: 'admin',
        body: 'Hello, we are investigating your issue.',
      );

      expect(msg.isAdmin, isTrue);

      final map = msg.toMap();
      expect(map['senderRole'], 'admin');

      final deserialized = TicketMessageModel.fromMap(map, docId: 'msg_1');
      expect(deserialized.id, 'msg_1');
      expect(deserialized.senderId, 'admin_1');
      expect(deserialized.isAdmin, isTrue);
      expect(deserialized.body, 'Hello, we are investigating your issue.');
    });
  });
}
