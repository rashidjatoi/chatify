import 'dart:io';
import 'package:chatify/models/user_model.dart';
import 'package:chatify/pages/home_page.dart';
import 'package:chatify/utils/utils.dart';
import 'package:chatify/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:image_picker/image_picker.dart';

class CompleteProfilePage extends StatefulWidget {
  final UserModel? userModel;
  const CompleteProfilePage({super.key, required this.userModel});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  late TextEditingController fullNameController;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    fullNameController.dispose();
  }

  File? image;
  final picker = ImagePicker();

  // final firebaseDatabase = FirebaseDatabase.instance.ref('notifications');

  Future getImageGalley(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 60);
    setState(
      () {
        if (pickedFile != null) {
          image = File(pickedFile.path);
        } else {
          debugPrint("No image picked");
        }
      },
    );
  }

  void showPhotoOptions() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Upload Profile Picture"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    getImageGalley(ImageSource.gallery);
                  },
                  leading: const Icon(Icons.photo_album),
                  title: const Text("Select from Gallery"),
                ),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);

                    getImageGalley(ImageSource.camera);
                  },
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take a Photo"),
                )
              ],
            ),
          );
        });
  }

  void checkValues() {
    String fullName = fullNameController.text.trim();

    if (fullName == "" || image == null) {
      Utils.showToast(message: "Plaese fill all fields");
    } else {
      uploadData();
    }
  }

  void uploadData() async {
    final fileName = Timestamp.now().millisecondsSinceEpoch;
    firebase_storage.Reference ref =
        FirebaseStorage.instance.ref("profilepictures$fileName");

    firebase_storage.UploadTask uploadTask = ref.putFile(image!.absolute);

    Future.value(uploadTask).then(
      (value) async {
        String newUrl = await ref.getDownloadURL();
        String name = fullNameController.text.trim();

        widget.userModel!.fullname = name;
        widget.userModel!.profilepic = newUrl;

        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userModel!.uid)
            .set(
              widget.userModel!.toMap(),
            )
            .then(
              (value) => Utils.showToast(
                  message: "Profile Updated", bgColor: Colors.green),
            )
            .then((value) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HomePage(userModel: widget.userModel))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // SizeBox
              const SizedBox(height: 20),

              // Avatar
              CupertinoButton(
                onPressed: () {
                  showPhotoOptions();
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: (image != null) ? FileImage(image!) : null,
                  child: (image == null)
                      ? const Icon(
                          Icons.person,
                          size: 50,
                        )
                      : null,
                ),
              ),

              // SizeBox
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Full Name",
                ),
              ),

              // SizeBox
              const SizedBox(height: 20),

              // Custom Button
              CustomButton(
                title: "Save",
                onPressed: () {
                  checkValues();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
