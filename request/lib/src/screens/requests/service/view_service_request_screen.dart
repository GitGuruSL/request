import 'package:flutter/material.dart';
import '../../common/view_request_screen.dart';

class ViewServiceRequestScreen extends StatelessWidget {
  final String requestId;

  const ViewServiceRequestScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return ViewRequestScreen(
      requestId: requestId,
      requestType: 'service',
    );
  }
}