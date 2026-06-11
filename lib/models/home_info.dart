/// 家庭信息模型
///
/// 对应后端 /home/list 响应中的家庭项。
class HomeInfo {
  final int homeId;
  final String name;
  final String? avatar;
  final int ownerId;
  final String role;
  final String? nickname;
  final String? joinTime;

  HomeInfo({
    required this.homeId,
    required this.name,
    this.avatar,
    required this.ownerId,
    required this.role,
    this.nickname,
    this.joinTime,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManage => isOwner || isAdmin;

  factory HomeInfo.fromJson(Map<String, dynamic> json) {
    return HomeInfo(
      homeId: json['homeId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      ownerId: json['ownerId'] as int? ?? json['owner_id'] as int? ?? 0,
      role: json['role'] as String? ?? 'member',
      nickname: json['nickname'] as String?,
      joinTime: json['joinTime'] as String? ?? json['join_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'homeId': homeId,
        'name': name,
        'avatar': avatar,
        'ownerId': ownerId,
        'role': role,
        'nickname': nickname,
        'joinTime': joinTime,
      };

  @override
  String toString() => 'HomeInfo(id: $homeId, name: $name, role: $role)';
}
