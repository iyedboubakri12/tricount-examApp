import 'member.dart';

class Group {
  final String id;
  final String name;
  final List<Member> members;

  const Group({
    required this.id,
    required this.name,
    required this.members,
  });
}
