import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/user_provider.dart';

class AddGuardianDialog extends StatefulWidget {
  const AddGuardianDialog({super.key});

  @override
  State<AddGuardianDialog> createState() => _AddGuardianDialogState();
}

class _AddGuardianDialogState extends State<AddGuardianDialog> {
  final TextEditingController _targetController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Guardian',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your Guardian\'s unique User ID to send a linking request.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              hintText: 'Guardian User ID',
              prefixIcon: const Icon(Icons.person_search_rounded),
              filled: true,
              fillColor: Colors.blue.shade50.withOpacity(0.3),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending
              ? null
              : () async {
                  if (_targetController.text.isEmpty) return;
                  setState(() => _isSending = true);

                  final provider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  bool success = await provider.sendRequestByGuardianId(
                    _targetController.text.trim(),
                  );

                  if (mounted) {
                    setState(() => _isSending = false);
                    if (success) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Request Sent! Waiting for approval.'),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Guardian ID not found or invalid.'),
                        ),
                      );
                    }
                  }
                },
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
}
