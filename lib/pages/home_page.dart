import 'package:chatify/models/chat_room_model.dart';
import 'package:chatify/models/user_model.dart';
import 'package:chatify/pages/chat_room_page.dart';
import 'package:chatify/pages/login_page.dart';
import 'package:chatify/pages/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_helper_service.dart';

class HomePage extends StatefulWidget {
  final UserModel? userModel;
  const HomePage({super.key, required this.userModel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // late TextEditingController searchController;

  // @override
  // void initState() {
  //   super.initState();
  //   searchController = TextEditingController();
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  //   searchController.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Chatify"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Container(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("chatrooms")
              .where("participants.${widget.userModel!.uid}", isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;

                return ListView.builder(
                  itemCount: chatRoomSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                        chatRoomSnapshot.docs[index].data()
                            as Map<String, dynamic>);

                    Map<String, dynamic> partcipants =
                        chatRoomModel.participants!;
                    List<String> participantKeys = partcipants.keys.toList();
                    participantKeys.remove(widget.userModel!.uid);

                    return FutureBuilder(
                      future: FirebaseHelperService.getUserModelById(
                          participantKeys[0]),
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          UserModel targetUser = snapshot.data as UserModel;
                          return Card(
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return ChatRoomPage(
                                      chatroom: chatRoomModel,
                                      userModel: widget.userModel,
                                      targetUser: targetUser,
                                    );
                                  }),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    targetUser.profilepic.toString()),
                              ),
                              title: Text(targetUser.fullname.toString()),
                              subtitle: (chatRoomModel.lastMessage.toString() !=
                                      "")
                                  ? Text(chatRoomModel.lastMessage.toString())
                                  : Text(
                                      "Say hi to your new friend!",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    );
                  },
                );
              } else if (snapshot.hasError) {
                Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                return const Text("No Chats");
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Container();
          },
        ),
      ),

      // FloatingActionButton
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(userModel: widget.userModel),
            ),
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}
