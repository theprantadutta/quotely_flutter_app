import 'package:flutter/material.dart';

import '../components/shared/not_implemented.dart';

class CommonService {
  static showNotImplementedDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return const Dialog(
          child: NotImplemented(),
        );
      },
    );
  }
}
