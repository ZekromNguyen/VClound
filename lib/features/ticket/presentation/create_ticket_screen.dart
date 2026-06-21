import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/primary_button.dart';
import '../application/ticket_controller.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool goBack}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final t = await ref.read(ticketActionsProvider).create(
            title: _title.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          );
      if (mounted) {
        if (goBack) {
          context.pop();
        } else {
          context.go('/tickets');
        }
      }
      // ignore: unused_local_variable
      // t to suppress unused warning
      // ignore: unused_local_variable
      final _ = t;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New ticket')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _desc,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Save',
                  icon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : () => _submit(goBack: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
