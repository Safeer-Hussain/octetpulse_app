import 'package:equatable/equatable.dart';

class ShiftSwapNotification extends Equatable {
  final String id;
  final String proposalId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ShiftSwapNotification({
    required this.id,
    required this.proposalId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proposalId': proposalId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory ShiftSwapNotification.fromMap(Map<String, dynamic> map) {
    return ShiftSwapNotification(
      id: map['id'] as String,
      proposalId: map['proposalId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] as int? ?? 0) == 1,
    );
  }

  ShiftSwapNotification copyWith({
    String? id,
    String? proposalId,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ShiftSwapNotification(
      id: id ?? this.id,
      proposalId: proposalId ?? this.proposalId,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    proposalId,
    title,
    message,
    timestamp,
    isRead,
  ];
}
