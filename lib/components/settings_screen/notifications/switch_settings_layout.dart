// import 'package:flutter/material.dart';

// import '../../../constants/selectors.dart';

// class SwitchSettingsLayout extends StatelessWidget {
//   final String title;
//   final bool value;
//   final Function(bool value) onSwitchChanged;

//   const SwitchSettingsLayout({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.onSwitchChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final kPrimaryColor = Theme.of(context).primaryColor;
//     return Container(
//       height: MediaQuery.sizeOf(context).height * 0.07,
//       padding: const EdgeInsets.symmetric(horizontal: 5),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         gradient: kGetDefaultGradient(context),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 12,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Switch(
//             activeColor: kPrimaryColor,
//             inactiveThumbColor: kPrimaryColor.withValues(alpha: 0.3),
//             inactiveTrackColor: kPrimaryColor.withValues(alpha: 0.3),
//             trackColor: WidgetStateProperty.all(
//               kPrimaryColor.withValues(alpha: 0.1),
//             ),
//             trackOutlineColor: WidgetStateProperty.all(
//               kPrimaryColor.withValues(alpha: 0.2),
//             ),
//             value: value,
//             onChanged: onSwitchChanged,
//           ),
//           const SizedBox(width: 10),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class SwitchSettingsLayout extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool value) onSwitchChanged;

  const SwitchSettingsLayout({
    super.key,
    required this.title,
    required this.value,
    required this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Replaced the custom layout with SwitchListTile for a perfect, standard implementation.
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value,
      onChanged: onSwitchChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
