import 'package:chat_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "CHAT_SCREEN";

  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  late String messageText;

  late DateTime now;
  late String formattedDate;

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser!;
      loggedInUser = user;
      print(loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.forum),
        actions: [
          IconButton(
            onPressed: () {
              //TODO: Log out
              _auth.signOut();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        title: const Text('Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageStream(scrollController: scrollController),
            Container(
              decoration: kMessageContainerDecoration,
              /* User Input */
              child: TextField(
                controller: messageController,
                focusNode: focusNode,
                onChanged: (value) {
                  // TODO: For user Input (Chatting)
                  messageText = value;
                },
                decoration: kMessageTextFieldDecoration,
              ),
            ),
            /* Send Button */
            TextButton(
              onPressed: () {
                // TODO: To send
                // setState(() {
                //   now = DateTime.now();
                //   formattedDate = DateFormat("kk:mm:ss").format(now);
                // });

                messageController.clear();
                var nowText = messageText;
                messageText = "";
                if (nowText.isEmpty || nowText.trim().isEmpty) return;

                _firestore.collection("messages").add(
                  {
                    'sender': loggedInUser.email,
                    "text": nowText,
                    "time": DateTime.now(),
                    // "time": formattedDate,
                  },
                );

                /// To Exit Keyboard mode
                // focusNode.unfocus();

                /// Add Animation
                /// to travel to the latest chat.
                // scrollController.animateTo(
                //   0,
                //   duration: const Duration(seconds: 0, milliseconds: 700),
                //   curve: Curves.easeInOut,
                // );

                // scrollController.jumpTo(0);
              },
              child: const Text(
                'Send',
                style: kSendButtonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  final ScrollController scrollController;
  const MessageStream({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("messages")
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
            ),
          );
        }

        final messages = snapshot.data!.docs;
        List<MessageBubble> messageBubbles = [];

        for (var message in messages) {
          final messageText = message['text'];
          final messageSender = message['sender'];
          final messageTime = message['time'] as Timestamp;

          final currentUserEmail = loggedInUser.email;

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            time: messageTime,
            isMe: currentUserEmail == messageSender,
          );

          messageBubbles.add(messageBubble);

          // final messageWidget = Text("$messageText from $messageSender");

          // messageWidgets.add(messageWidget);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 20.0,
            ),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final Timestamp time;
  final bool isMe;

  const MessageBubble({
    Key? key,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(color: Colors.black54, fontSize: 12.0),
          ),

          /// Was added to make a little bit of constraint for the bubble chat
          // const SizedBox(height: 5.0),
          // Padding(
          //   padding: EdgeInsets.only(
          //     left: isMe ? 50.0 : 0,
          //     right: isMe ? 0 : 50.0,
          //   ),
          //   child:
          // ),

          Material(
            borderRadius: BorderRadius.only(
              topLeft:
                  isMe ? const Radius.circular(30) : const Radius.circular(0),
              topRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(30),
              bottomLeft: const Radius.circular(30),
              bottomRight: const Radius.circular(30),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlue : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),

          /// Was added to show sent date
          // const SizedBox(height: 10.0),
          // Text(
          //   DateFormat("kk:mm").format(time.toDate()),
          //   style: const TextStyle(color: Colors.black54, fontSize: 14.0),
          // ),
        ],
      ),
    );
  }
}
