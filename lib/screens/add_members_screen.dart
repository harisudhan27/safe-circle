import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/member_card.dart';

class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({super.key});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();
  String? _familyId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      _familyId = await AppDataService.instance.familyId;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load family: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a member name')));
      return;
    }
    final familyId = _familyId;
    if (familyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a family before adding members')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AppDataService.instance.addFamilyMember(
        familyId: familyId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relation: _relation.text.trim().isEmpty
            ? 'Member'
            : _relation.text.trim(),
      );
      _name.clear();
      _phone.clear();
      _relation.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add member: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Family Members')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'This adds a profile without connecting a SafeCircle account. To connect another SafeCircle account, share the invite code from Family Safety.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Member name',
                    icon: Icons.person_outline,
                    controller: _name,
                  ),
                  AppTextField(
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  AppTextField(
                    label: 'Relation (e.g. Son)',
                    icon: Icons.favorite_border,
                    controller: _relation,
                  ),
                  AppButton(
                    label: _saving ? 'Adding...' : 'Add Member',
                    icon: Icons.person_add_alt_1,
                    outlined: true,
                    onPressed: _saving ? null : _add,
                  ),
                  const SizedBox(height: 20),
                  if (_familyId case final familyId?)
                    StreamBuilder(
                      stream: AppDataService.instance.familyMembers(familyId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Could not load members: ${snapshot.error}',
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final members = snapshot.data!.docs
                            .map(Member.fromDocument)
                            .toList(growable: false);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Members (${members.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (members.isEmpty)
                              const Text('No family members added yet.'),
                            ...members.map(
                              (member) => MemberCard(member: member),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    const Text('No family yet. Create one to add members.'),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Continue',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/member-tracking'),
                  ),
                ],
              ),
            ),
    );
  }
}
