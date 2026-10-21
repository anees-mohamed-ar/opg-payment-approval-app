class User {
  final int id;
  final String userId;
  final String name;
  final String password;
  final String department;
  final String supervisor;
  final String manager;
  final dynamic poRes;
  final dynamic role;

  User({
    required this.id,
    required this.userId,
    required this.name,
    required this.password,
    required this.department,
    required this.supervisor,
    required this.manager,
    this.poRes,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // Default to 0 if null
      userId: json['userId'] ?? '', // Default to empty string if null
      name: json['name'] ?? '', // Default to empty string if null
      password: json['password'] ?? '', // Default to empty string if null
      department: json['department'] ?? '', // Default to empty string if null
      supervisor: json['supervisor'] ?? '', // Default to empty string if null
      manager: json['manager'] ?? '', // Default to empty string if null
      poRes: json['po_res'], // Allow null
      role: json['role'], // Allow null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'password': password,
      'department': department,
      'supervisor': supervisor,
      'manager': manager,
      'po_res': poRes,
      'role': role,
    };
  }
}
