import 'package:flutter/material.dart';
import '../../common/view_request_screen.dart';

class ViewRentRequestScreen extends StatelessWidget {
  final String requestId;

  const ViewRentRequestScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return ViewRequestScreen(
      requestId: requestId,
      requestType: 'rental',
    );
  }
}