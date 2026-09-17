class PaymentPlan {
  final int id;
  final String planName;
  final String stripePriceId;
  final String monthlyPrice;
  final int maxScreens;
  final int isActive;
  final int durationValue;
  final String durationUnit;

  PaymentPlan({
    required this.id,
    required this.planName,
    required this.stripePriceId,
    required this.monthlyPrice,
    required this.maxScreens,
    required this.isActive,
    required this.durationValue,
    required this.durationUnit,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      planName: json['plan_name']?.toString() ?? '',
      stripePriceId: json['stripe_price_id']?.toString() ?? '',
      monthlyPrice: json['monthly_price']?.toString() ?? '0',
      maxScreens: json['max_screens'] is int ? json['max_screens'] : int.tryParse(json['max_screens']?.toString() ?? '') ?? 1,
      isActive: json['is_active'] is int ? json['is_active'] : int.tryParse(json['is_active']?.toString() ?? '') ?? 0,
      durationValue: json['duration_value'] is int ? json['duration_value'] : int.tryParse(json['duration_value']?.toString() ?? '') ?? 1,
      durationUnit: json['duration_unit']?.toString() ?? 'month',
    );
  }
}
