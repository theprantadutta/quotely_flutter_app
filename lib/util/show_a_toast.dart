import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';

const kTitleTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);

const kDescriptionTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: Colors.white,
);

showSuccessToast({
  required BuildContext context,
  required String title,
  required String description,
}) =>
    MotionToast.success(
      title: Text(
        title,
        style: kTitleTextStyle,
      ),
      description: Text(
        description,
        style: kDescriptionTextStyle,
      ),
      toastDuration: const Duration(seconds: 3),
      barrierColor: Theme.of(context).primaryColor,
    ).show(context);

showWarningToast({
  required BuildContext context,
  required String title,
  required String description,
}) =>
    MotionToast.warning(
      title: Text(
        title,
        style: kTitleTextStyle,
      ),
      description: Text(
        description,
        style: kDescriptionTextStyle,
      ),
      toastDuration: const Duration(seconds: 3),
    ).show(context);

showErrorToast({
  required BuildContext context,
  required String title,
  required String description,
}) =>
    MotionToast.error(
      title: Text(
        title,
        style: kTitleTextStyle,
      ),
      description: Text(
        description,
        style: kDescriptionTextStyle,
      ),
      toastDuration: const Duration(seconds: 5),
    ).show(context);
