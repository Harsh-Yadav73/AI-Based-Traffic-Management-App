import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
    _loadContacts();
  }

  /// ✨ LOAD ALL USERS (except current logged in user)
  Future<void> _loadAllUsers() async {
    final currentUser = supabase.auth.currentUser;
    final res = await supabase
        .from("profiles")
        .select()
        .neq("id", currentUser!.id);

    setState(() {
      allUsers = res;
    });
  }

  /// ✨ LOAD PREVIOUSLY ADDED CONTACTS
  Future<void> _loadContacts() async {
    final currentUser = supabase.auth.currentUser;

    final res = await supabase
        .from("user_contacts")
        .select(
        "id, contact_user_id, profiles!user_contacts_contact_user_id_fkey(id,email)"
    )
        .eq("user_id", currentUser!.id);

    setState(() => contacts = res);
  }

  /// ✨ ADD CONTACT
  Future<void> _addContact(String contactUserId) async {
    final currentUser = supabase.auth.currentUser;

    bool exists = contacts.any((c) => c["contact_user_id"] == contactUserId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already added!")),
      );
      return;
    }

    await supabase.from("user_contacts").insert({
      "user_id": currentUser!.id,
      "contact_user_id": contactUserId,
    });

    _loadContacts();
  }

  /// ✨ DELETE CONTACT
  Future<void> _removeContact(String id) async {
    await supabase.from("user_contacts").delete().eq("id", id);
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const Text(
            "Your Contacts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          ...contacts.map((c) {
            final profile = c["profiles"];
            return Card(
              child: ListTile(
                title: Text(profile["email"]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeContact(c["id"]),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          const Text(
            "Add New Contact",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          ...allUsers.map((u) {
            return Card(
              child: ListTile(
                title: Text(u["email"]),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addContact(u["id"]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
