
enum UserRole {
  user,
  admin,
}

class UserFinki {
  final String name;
  final String surname;
  final String email;
  final String password;
  final UserRole userRole;

  UserFinki({
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.userRole
  });
}
