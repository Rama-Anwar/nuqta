import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat('d MMM yyyy', locale).format(date);
}

String formatDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat('d MMM yyyy, HH:mm', locale).format(date);
}
