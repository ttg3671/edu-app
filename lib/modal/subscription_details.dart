class SubscriptionDetails {
  final String? subId;
  final String? plan;
  final int? maxDevices;
  final String? expiry;
  final String? status;
  final String? amount;
  final int? planDurationValue;
  final String? planDurationType;

  SubscriptionDetails({
    this.subId,
    this.plan,
    this.maxDevices,
    this.expiry,
    this.status,
    this.amount,
    this.planDurationValue,
    this.planDurationType,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      subId: json['stripe_sub_id']?.toString() ?? json['sub_id']?.toString() ?? json['stripe_subscription_id']?.toString() ?? json['subId']?.toString(),
      plan: json['plan']?.toString() ?? json['plan_name']?.toString(),
      maxDevices: json['max_devices'] != null
          ? int.tryParse(json['max_devices'].toString())
          : (json['maxDevices'] != null
              ? int.tryParse(json['maxDevices'].toString())
              : (json['max_device'] != null
                  ? int.tryParse(json['max_device'].toString())
                  : (json['deviceLimit'] != null
                      ? int.tryParse(json['deviceLimit'].toString())
                      : (json['devices'] != null
                          ? int.tryParse(json['devices'].toString())
                          : null)))),
      expiry: json['expiry']?.toString() ?? json['current_period_end']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount']?.toString() ?? json['monthly_price']?.toString(),
      planDurationValue: json['plan_duration_value'] != null
          ? int.tryParse(json['plan_duration_value'].toString())
          : (json['duration_value'] != null ? int.tryParse(json['duration_value'].toString()) : null),
      planDurationType: json['plan_duration_type']?.toString() ?? json['duration_unit']?.toString(),
    );
  }

  SubscriptionDetails copyWith({
    String? subId,
    String? plan,
    int? maxDevices,
    String? expiry,
    String? status,
    String? amount,
    int? planDurationValue,
    String? planDurationType,
  }) {
    return SubscriptionDetails(
      subId: subId ?? this.subId,
      plan: plan ?? this.plan,
      maxDevices: maxDevices ?? this.maxDevices,
      expiry: expiry ?? this.expiry,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      planDurationValue: planDurationValue ?? this.planDurationValue,
      planDurationType: planDurationType ?? this.planDurationType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub_id': subId,
      'plan': plan,
      'max_devices': maxDevices,
      'expiry': expiry,
      'status': status,
      'amount': amount,
      'plan_duration_value': planDurationValue,
      'plan_duration_type': planDurationType,
    };
  }
}
