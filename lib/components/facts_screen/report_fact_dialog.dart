import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dtos/ai_fact_dto.dart'; // For sending email

class ReportFactDialog extends StatefulWidget {
  final AiFactDto fact;

  const ReportFactDialog({
    super.key,
    required this.fact,
  });

  @override
  State<ReportFactDialog> createState() => _ReportFactDialogState();
}

class _ReportFactDialogState extends State<ReportFactDialog> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _correctFactController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  String? _selectedReason;
  final List<String> _reasons = [
    'Factually Incorrect',
    'Offensive/Inappropriate',
    'Duplicate Fact',
    'Grammar/Spelling Error',
    'Other (Please specify below)',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _issueController.dispose();
    _correctFactController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    final int reportedFactId = widget.fact.id;
    final String reportedFactContent = widget.fact.content;
    final String selectedReason = _selectedReason ?? 'No reason selected';
    final String issueDetails = _issueController.text.trim();
    final String correctFact = _correctFactController.text.trim();
    final String contactEmail = _contactEmailController.text.trim();

    final String subject = 'Fact Report: $reportedFactId...';
    final String body = '''
--- Fact Report ---
Fact ID: $reportedFactId
Reported Fact: "$reportedFactContent"
Category: ${widget.fact.aiFactCategory}

Reason: $selectedReason
Issue Details: ${issueDetails.isNotEmpty ? issueDetails : 'N/A'}
Suggested Correct Fact: ${correctFact.isNotEmpty ? correctFact : 'N/A'}

Contact Email (Optional): ${contactEmail.isNotEmpty ? contactEmail : 'N/A'}
--- End Report ---
''';

    // final Uri emailLaunchUri = Uri(
    //   scheme: 'mailto',
    //   path: 'prantadutta1997@gmail.com',
    //   queryParameters: {
    //     'subject': subject,
    //     'body': body,
    //   },
    // );

    // Create mailto URL with proper encoding that preserves spaces as %20
    final String encodedSubject =
        Uri.encodeComponent(subject).replaceAll('+', '%20');
    final String encodedBody = Uri.encodeComponent(body).replaceAll('+', '%20');

    final Uri emailLaunchUri = Uri.parse(
        'mailto:prantadutta1997@gmail.com?subject=$encodedSubject&body=$encodedBody');

    try {
      if (await launchUrl(emailLaunchUri)) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fact reported successfully! Thank you.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not open email client. Please send manually to prantadutta1997@gmail.com'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'An error occurred. Please ensure you have an email app configured.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      debugPrint('Error launching email: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Report This Fact',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fact info section
                    Text(
                      'You are reporting the fact:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),

                    // Fact display container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '"${widget.fact.content}"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reason selection
                    Text(
                      'Why are you reporting this fact?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      hint: const Text('Select a reason'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _reasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedReason = newValue;
                        });
                      },
                    ),

                    // Conditional "Other" text field
                    if (_selectedReason == 'Other (Please specify below)') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _issueController,
                        decoration: InputDecoration(
                          labelText: 'Specify Issue',
                          hintText:
                              'e.g., This fact is outdated, misleading, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Correction field
                    Text(
                      'What is the correct fact (optional)?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _correctFactController,
                      decoration: InputDecoration(
                        labelText: 'Correct Fact / Additional Info',
                        hintText:
                            'Provide the accurate information if you know it.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 20),

                    // Email field
                    Text(
                      'Your Contact Email (optional):',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@email.com (for follow-up if needed)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedReason == null
                          ? null
                          : _submitReport,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label:
                          Text(_isSubmitting ? 'Sending...' : 'Submit Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
