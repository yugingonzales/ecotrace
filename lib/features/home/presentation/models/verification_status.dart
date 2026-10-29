class VerificationStatus {
  const VerificationStatus({
    required this.id,
    required this.type,
    required this.status,
    required this.treeName,
    this.treeCode,
    this.eventTitle,
    this.submittedAt,
    this.reviewedAt,
    this.reason,
    this.note,
  });

  final int id;
  final String type;
  final String status;
  final String treeName;
  final String? treeCode;
  final String? eventTitle;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reason;
  final String? note;

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      id: (json['submission_id'] as num?)?.toInt() ?? 0,
      type: json['submission_type'] as String? ?? 'verification',
      status: json['submission_status'] as String? ?? 'pending',
      treeName: json['tree_name'] as String? ?? 'Tree record',
      treeCode: json['tree_code'] as String?,
      eventTitle: json['event_title'] as String?,
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      reason: json['decline_reason'] as String?,
      note: json['reviewer_note'] as String?,
    );
  }
}