/// 发现的网络设备模型
class DiscoveredDevice {
  final String ipAddress;
  final String? hostName;
  final bool isReachable;
  final List<int> openPorts;
  final DateTime discoveredAt;

  DiscoveredDevice({
    required this.ipAddress,
    this.hostName,
    required this.isReachable,
    this.openPorts = const [],
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  /// 是否有可用的TCP服务端口
  bool get hasOpenPorts => openPorts.isNotEmpty;

  /// 获取显示名称
  String get displayName => hostName ?? ipAddress;

  @override
  String toString() => '$displayName ($ipAddress)';
}
