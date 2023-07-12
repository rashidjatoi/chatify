import 'dart:developer';

import 'package:chatify/main.dart';
import 'package:chatify/models/message_model.dart';
import 'package:chatify/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/chat_room_model.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel? targetUser;
  final UserModel? userModel;
  final ChatRoomModel chatroom;
  const ChatRoomPage(
      {super.key, this.targetUser, required this.chatroom, this.userModel});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  void sendMessage() async {
    String message = messageController.text.trim();
    messageController.clear();
    if (message != "") {
      // Send Message
      MessageModel newMessage = MessageModel(
        messageid: uuid.v1(),
        sender: widget.userModel!.uid,
        text: message,
        seen: false,
        createdon: DateTime.now().toString(),
      );

      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .collection("messages")
          .doc(newMessage.messageid)
          .set(newMessage.toMap());

      widget.chatroom.lastMessage = message;
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .set(widget.chatroom.toMap());

      log("message Sent!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  NetworkImage(widget.targetUser!.profilepic.toString()),
            ),
            const SizedBox(width: 10),
            Text(widget.targetUser!.fullname.toString())
          ],
        ),
      ),
      body: Column(
        children: [
          // Chats
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("chatrooms")
                  .doc(widget.chatroom.chatroomid)
                  .collection("messages")
                  .orderBy("createdon", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    QuerySnapshot querySnapshot =
                        snapshot.data as QuerySnapshot;

                    return ListView.builder(
                      reverse: true,
                      itemCount: querySnapshot.docs.length,
                      itemBuilder: (context, index) {
                        MessageModel currentMessage = MessageModel.fromMap(
                            querySnapshot.docs[index].data()
                                as Map<String, dynamic>);
                        return Row(
                          mainAxisAlignment:
                              (currentMessage.sender == widget.userModel!.uid)
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  color: (currentMessage.sender ==
                                          widget.userModel!.uid)
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                                child: Text(
                                  currentMessage.text.toString(),
                                  style: const TextStyle(color: Colors.white),
                                )),
                          ],
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text("Please check your internet"),
                    );
                  } else {
                    return const Center(
                      child: Text("Say! hi to your new friend"),
                    );
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          )),

          // Container
          Container(
            color: Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      maxLines: null,
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Enter message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        sendMessage();
                      },
                      splashRadius: 20,
                      color: Colors.white,
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
