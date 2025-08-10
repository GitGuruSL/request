import 'package:flutter/material.dart';
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final timeAgo = timeago.format(request.createdAt.toDate());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  // In a real app, you'd fetch user data to show their avatar
                  child: Text(request.userId.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Posted $timeAgo',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(request.type.toString().split('.').last),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            if (request.imageUrls.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          request.imageUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${request.budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to request details screen
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
