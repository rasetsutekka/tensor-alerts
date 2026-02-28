class CollectionAlert {
  final String slug;
  final String? displayName;
  final double floorPrice;
  final bool enabled;
  final bool salesAlerts;
  final bool bidAlerts;
  final bool floorDropAlerts;
  final double minSalePrice;
  final double floorDropThreshold;
  final String traitContains;

  // Notification-first cadence/rate controls
  final double floorMovePercentThreshold;
  final double floorMoveSolThreshold;
  final int minIntervalMinutes;
  final int maxAlertsPerHour;

  const CollectionAlert({
    required this.slug,
    this.displayName,
    this.floorPrice = 0,
    this.enabled = true,
    this.salesAlerts = true,
    this.bidAlerts = true,
    this.floorDropAlerts = true,
    this.minSalePrice = 0,
    this.floorDropThreshold = 5,
    this.traitContains = '',
    this.floorMovePercentThreshold = 2,
    this.floorMoveSolThreshold = 0.2,
    this.minIntervalMinutes = 30,
    this.maxAlertsPerHour = 4,
  });

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'displayName': displayName,
        'floorPrice': floorPrice,
        'enabled': enabled,
        'salesAlerts': salesAlerts,
        'bidAlerts': bidAlerts,
        'floorDropAlerts': floorDropAlerts,
        'minSalePrice': minSalePrice,
        'floorDropThreshold': floorDropThreshold,
        'traitContains': traitContains,
        'floorMovePercentThreshold': floorMovePercentThreshold,
        'floorMoveSolThreshold': floorMoveSolThreshold,
        'minIntervalMinutes': minIntervalMinutes,
        'maxAlertsPerHour': maxAlertsPerHour,
      };

  factory CollectionAlert.fromMap(Map<String, dynamic> map) => CollectionAlert(
        slug: map['slug'] as String,
        displayName: map['displayName'] as String?,
        floorPrice: (map['floorPrice'] ?? 0).toDouble(),
        enabled: map['enabled'] ?? true,
        salesAlerts: map['salesAlerts'] ?? true,
        bidAlerts: map['bidAlerts'] ?? true,
        floorDropAlerts: map['floorDropAlerts'] ?? true,
        minSalePrice: (map['minSalePrice'] ?? 0).toDouble(),
        floorDropThreshold: (map['floorDropThreshold'] ?? 5).toDouble(),
        traitContains: map['traitContains'] ?? '',
        floorMovePercentThreshold: (map['floorMovePercentThreshold'] ?? 2).toDouble(),
        floorMoveSolThreshold: (map['floorMoveSolThreshold'] ?? 0.2).toDouble(),
        minIntervalMinutes: (map['minIntervalMinutes'] ?? 30).toInt(),
        maxAlertsPerHour: (map['maxAlertsPerHour'] ?? 4).toInt(),
      );

  CollectionAlert copyWith({
    double? floorPrice,
    bool? enabled,
    bool? salesAlerts,
    bool? bidAlerts,
    bool? floorDropAlerts,
    double? minSalePrice,
    double? floorDropThreshold,
    String? traitContains,
    double? floorMovePercentThreshold,
    double? floorMoveSolThreshold,
    int? minIntervalMinutes,
    int? maxAlertsPerHour,
  }) {
    return CollectionAlert(
      slug: slug,
      displayName: displayName,
      floorPrice: floorPrice ?? this.floorPrice,
      enabled: enabled ?? this.enabled,
      salesAlerts: salesAlerts ?? this.salesAlerts,
      bidAlerts: bidAlerts ?? this.bidAlerts,
      floorDropAlerts: floorDropAlerts ?? this.floorDropAlerts,
      minSalePrice: minSalePrice ?? this.minSalePrice,
      floorDropThreshold: floorDropThreshold ?? this.floorDropThreshold,
      traitContains: traitContains ?? this.traitContains,
      floorMovePercentThreshold: floorMovePercentThreshold ?? this.floorMovePercentThreshold,
      floorMoveSolThreshold: floorMoveSolThreshold ?? this.floorMoveSolThreshold,
      minIntervalMinutes: minIntervalMinutes ?? this.minIntervalMinutes,
      maxAlertsPerHour: maxAlertsPerHour ?? this.maxAlertsPerHour,
    );
  }
}
