import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/contact_provider.dart';
import 'package:women_safety/services/emergency_service.dart';
import 'package:women_safety/theme/app_theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency Guardians'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _showAddContactDialog(context, contactProvider),
            child: const Text('Add', style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These people will be notified in an emergency.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: contactProvider.contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: contactProvider.contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contactProvider.contacts[index];
                        return _buildContactCard(context, contact, index, contactProvider);
                      },
                    ),
            ),
            const SizedBox(height: 20),
            _buildPriorityAlertCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No contacts added yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    EmergencyContact contact,
    int index,
    ContactProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  contact.phone,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: () => _showEditContactDialog(context, contact, provider),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppTheme.primaryBlue),
            onPressed: () {
              if (contact.phone.isNotEmpty) {
                EmergencyService.makeEmergencyCall(contact.phone);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final error = await provider.deleteContact(contact.id);
              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete contact: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact removed')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority Alerting',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Guardians will receive your location and a live alert when an SOS is triggered.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, ContactProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Guardian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'Full Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+1234567890'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both name and phone number')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              final error = await provider.addContact(name, phone);
              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contact: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact added successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(
    BuildContext context,
    EmergencyContact contact,
    ContactProvider provider,
  ) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Guardian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both name and phone number')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              final error = await provider.editContact(contact.id, name, phone);
              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update contact: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
