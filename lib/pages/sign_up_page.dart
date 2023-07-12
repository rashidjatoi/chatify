import 'package:chatify/models/user_model.dart';
import 'package:chatify/pages/complete_profile_page.dart';
import 'package:chatify/utils/utils.dart';
import 'package:chatify/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController cpasswordController;
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    cpasswordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    cpasswordController.dispose();
  }

  final formKey = GlobalKey<FormState>();

  void checkValues() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final cpassword = cpasswordController.text.trim();
    if (password != cpassword) {
      Utils.showToast(message: "Password do not match");
    } else {
      createUserAccount(email, password);
    }
  }

  void createUserAccount(String email, String password) async {
    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      Utils.showToast(message: e.code.toString());
    }

    if (userCredential != null) {
      String uid = userCredential.user!.uid;
      UserModel userModel = UserModel(
        uid: uid,
        email: email,
        fullname: "",
        profilepic: "",
      );

      await FirebaseFirestore.instance.collection("users").doc(uid).set(
            userModel.toMap(),
          );
      Utils.showToast(message: "User Created", bgColor: Colors.green);
      // ignore: use_build_context_synchronously
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompleteProfilePage(userModel: userModel)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Chatify Logo
                Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Sizebox
                const SizedBox(height: 10),

                // Form Validation
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Email Address",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),

                      // Sizebox
                      const SizedBox(height: 10),

                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Password",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),

                      // Sizebox
                      const SizedBox(height: 10),

                      //Confirm Password Field
                      TextFormField(
                        controller: cpasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Confirm Password",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // Sizebox
                const SizedBox(height: 20),

                // Cupertino Button
                CustomButton(
                  title: "Sign Up",
                  onPressed: () {
                    // Checking textfields
                    if (formKey.currentState!.validate()) {
                      checkValues();
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),

      // Bottom navigation for already account users
      bottomNavigationBar: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Already have an account?",
              style: TextStyle(fontSize: 16),
            ),
            CupertinoButton(
                child: const Text(
                  "Sign in",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }
}
