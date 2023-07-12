import 'dart:developer';
import 'package:chatify/main.dart';
import 'package:chatify/models/chat_room_model.dart';
import 'package:chatify/models/user_model.dart';
import 'package:chatify/pages/chat_room_page.dart';
import 'package:chatify/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final UserModel? userModel;
  const SearchPage({super.key, required this.userModel});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Future<ChatRoomModel?> getChatRoomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${widget.userModel!.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Fetch the Existing Conversation
      log("Chatroom existed");

      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChat =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChat;
    } else {
      // Create a new Conversation
      log("New Chatroom Created");

      ChatRoomModel newChatRoom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel!.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatRoom.chatroomid)
          .set(newChatRoom.toMap());
      chatRoom = newChatRoom;

      log("New Chatroom Created");
    }

    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chatify"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut().then((value) => log("succes"));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            // Sizebox
            const SizedBox(height: 10),

            // Search TextField
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Enter Email Address",
                border: OutlineInputBorder(),
              ),
            ),

            // Sizebox
            const SizedBox(height: 10),

            // CustomButton
            CustomButton(
                title: "Search",
                onPressed: () {
                  setState(() {});
                }),

            // Stream Builder
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("email", isEqualTo: searchController.text.trim())
                  .where("email", isNotEqualTo: widget.userModel!.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                    if (dataSnapshot.docs.isNotEmpty) {
                      Map<String, dynamic> userMap =
                          dataSnapshot.docs[0].data() as Map<String, dynamic>;

                      UserModel userModel = UserModel.fromMap(userMap);

                      return Card(
                        margin: const EdgeInsets.only(top: 10),
                        child: ListTile(
                          onTap: () async {
                            ChatRoomModel? chatRoomModel =
                                await getChatRoomModel(userModel);
                            if (chatRoomModel != null) {
                              // Removing this page from stack
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                              // moving to next page
                              // ignore: use_build_context_synchronously
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoomPage(
                                    targetUser: userModel,
                                    userModel: widget.userModel,
                                    chatroom: chatRoomModel,
                                  ),
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                NetworkImage(userModel.profilepic.toString()),
                          ),
                          title: Text(userModel.fullname.toString()),
                          subtitle: Text(userModel.email.toString()),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                        ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text("No Results found"),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return const Text("An Error Occurred");
                  } else {
                    return const Text("No Results Found");
                  }
                } else {
                  return const CircularProgressIndicator();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
