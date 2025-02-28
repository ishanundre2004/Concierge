import 'package:flutter/material.dart';

abstract class BaseChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final AnimationController animationController;

  BaseChatMessage({
    required this.text,
    required this.isUser,
    required this.animationController,
  });
}

class ChatMessage extends BaseChatMessage {
  ChatMessage({
    required String text,
    required bool isUser,
    required AnimationController animationController,
  }) : super(
          text: text,
          isUser: isUser,
          animationController: animationController,
        );

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: isUser ? 50.0 : 0.0,
          right: isUser ? 0.0 : 50.0,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class ChatMessageRoom extends BaseChatMessage {
  final List<RoomOption>? roomOptions;

  ChatMessageRoom({
    required String text,
    required bool isUser,
    this.roomOptions,
    required AnimationController animationController,
  }) : super(
          text: text,
          isUser: isUser,
          animationController: animationController,
        );

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: isUser ? 50.0 : 0.0,
          right: isUser ? 0.0 : 50.0,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Bot message text
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),

            // Display room options if available
            if (roomOptions != null) _buildRoomOptions(roomOptions!),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomOptions(List<RoomOption> roomOptions) {
    return Container(
      height: 313,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: roomOptions.length,
        itemBuilder: (context, index) {
          final room = roomOptions[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room image
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: AssetImage(room.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Room details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${room.price}/night",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room.description,
                        style: TextStyle(color: Colors.amber.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Select Room',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}