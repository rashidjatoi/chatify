// ignore_for_file: use_build_context_synchronously
import 'package:chatify/models/user_model.dart';
import 'package:chatify/pages/home_page.dart';
import 'package:chatify/pages/sign_up_page.dart';
import 'package:chatify/utils/utils.dart';
import 'package:chatify/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool isloading = false;
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void logInUser(String email, String password) async {
    UserCredential? userCredential;

    try {
      userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      Utils.showToast(message: e.code.toString());
      setState(() {
        isloading = false;
      });
    }

    if (userCredential != null) {
      String uid = userCredential.user!.uid;

      DocumentSnapshot userData =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      UserModel userModel =
          UserModel.fromMap(userData.data() as Map<String, dynamic>);

      debugPrint(userModel.email);

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(userModel: userModel)));

      Utils.showToast(message: "Welcome", bgColor: Colors.green);
      setState(() {
        isloading = false;
      });
    }
  }

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Chatify Logo
                Text(
                  "Chatify",
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
                    ],
                  ),
                ),

                // Sizebox
                const SizedBox(height: 20),

                // CupertinoButton
                CustomButton(
                  isLoading: isloading,
                  onPressed: () {
                    // Checking textfields
                    if (formKey.currentState!.validate()) {
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();
                      setState(() {
                        isloading = true;
                      });

                      logInUser(email, password);
                    }
                  },
                  title: "Sign in",
                )
              ],
            ),
          ),
        ),
      ),

      // BottomNavigatorBar for non users
      bottomNavigationBar: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(fontSize: 16),
            ),
            CupertinoButton(
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
