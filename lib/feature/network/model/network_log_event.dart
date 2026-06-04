import 'package:akillisletme/product/enum/network_event_type.dart';
import 'package:equatable/equatable.dart';

/// A single persisted network event (drop, recovery or connection change).
class NetworkLogEvent extends Equatable {
  const NetworkLogEvent({
    required this.timestamp,
    required this.type,
    required this.connectionType,
    required this.details,
  });

  factory NetworkLogEvent.fromJson(Map<String, dynamic> json) {
    return NetworkLogEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: NetworkEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NetworkEventType.typeChanged,
      ),
      connectionType: json['connectionType'] as String? ?? 'Unknown',
      details: json['details'] as String? ?? '',
    );
  }

  final DateTime timestamp;
  final NetworkEventType type;
  final String connectionType;
  final String details;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'connectionType': connectionType,
    'details': details,
  };

  @override
  List<Object?> get props => [timestamp, type, connectionType, details];
}
