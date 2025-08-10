import 'package:flutter/material.dart';
import '../../common/view_request_screen.dart';

class ViewItemRequestScreen extends StatelessWidget {
  final String requestId;

  const ViewItemRequestScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return ViewRequestScreen(
      requestId: requestId,
      requestType: 'item',
    );
  }
}