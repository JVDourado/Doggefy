import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isLoginButtonEnabled =>
      _emailOrUsernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.black54,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big Logo Icon (replace with your logo asset)
                  Image.asset(
                    'assets/images/dog_icon.jpg',  // Correct path to the image in the assets folder
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Faça seu Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email or Username Field
                  _buildTextField(_emailOrUsernameController, 'Nome de Usuário ou Email', false),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildPasswordField(),
                  const SizedBox(height: 20),

                  // Conditional Button: Login or Sign Up
                  ElevatedButton(
                    onPressed: _isLoginButtonEnabled
                        ? _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    String email = _emailOrUsernameController.text.trim();

                                    // Check if the input is an email or username
                                    if (email.contains('@')) {
                                      // It's an email
                                      await _auth.signInWithEmailAndPassword(
                                        email: email,
                                        password: _passwordController.text.trim(),
                                      );
                                    } else {
                                      // It's a username, retrieve email from Firestore
                                      var userDoc = await _firestore
                                          .collection('users')
                                          .where('username', isEqualTo: email)
                                          .limit(1)
                                          .get();

                                      if (userDoc.docs.isNotEmpty) {
                                        String userEmail = userDoc.docs.first['email'];

                                        // Sign in with the email retrieved from Firestore
                                        await _auth.signInWithEmailAndPassword(
                                          email: userEmail,
                                          password: _passwordController.text.trim(),
                                        );
                                      } else {
                                        throw FirebaseAuthException(
                                            code: 'user-not-found', message: 'Usuário não encontrado');
                                      }
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Login efetuado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pushNamed(context, '/home');
                                  } on FirebaseAuthException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro: ${e.message}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                        : null, // Disable button if fields are empty
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoginButtonEnabled ? Colors.black54 : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),

                  // Forgot Password Button
                  TextButton(
                    onPressed: () async {
                      // Forgot Password functionality
                      String email = _emailOrUsernameController.text.trim();
                      if (email.isNotEmpty) {
                        try {
                          await _auth.sendPasswordResetEmail(email: email);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-mail de recuperação enviado!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: ${e.message}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, insira um e-mail válido para recuperar a senha.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),

                  // Sign Up Button (always visible)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'Não tem uma conta? Cadastre-se',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TextField builder for form fields
  Widget _buildTextField(TextEditingController controller, String label, bool isNumber) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira $label';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Password field with visibility toggle
  Widget _buildPasswordField() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira sua senha';
            } else if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
      ),
    );
  }
}
