import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../models/people_model.dart';
import '../../providers/person_provider.dart';
import '../../core/utils/toast_helper.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  Future<void> _pickContact() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (status == PermissionStatus.granted) {
      final pickedContact = await FlutterContacts.native.showPicker();
      if (pickedContact != null) {
        final contact = await FlutterContacts.get(
          pickedContact as String,
          properties: {ContactProperty.phone},
        );
        if (contact != null) {
          setState(() {
            nameController.text = contact.displayName ?? '';
            if (contact.phones.isNotEmpty) {
              phoneController.text = contact.phones.first.number;
            }
          });
        }
      }
    } else {
      if (mounted) {
        ToastHelper.showToast(
          context,
          "Permission to access contacts is required.",
          isError: true,
        );
      }
    }
  }

  void _savePerson() {
    final String name = nameController.text.trim();
    final String phone = phoneController.text.trim();

    if (name.isEmpty) {
      ToastHelper.showToast(
        context,
        "Please enter a person's name",
        isError: true,
      );
      return;
    }

    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    final newPerson = PersonModel(
      id: 'person_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      balance: 0.0,
    );

    personProvider.addPerson(newPerson);

    ToastHelper.showToast(context, "Person added successfully!");

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Add Person",
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            _buildLabel("Person Name"),
            const SizedBox(height: 10),
            _buildTextField(
              controller: nameController,
              hint: "Enter person name",
              icon: Icons.person_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.contacts,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: _pickContact,
              ),
            ),

            const SizedBox(height: 24),

            _buildLabel("Phone Number (Optional)"),
            const SizedBox(height: 10),
            _buildTextField(
              controller: phoneController,
              hint: "Enter phone number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _savePerson,
                child: Text(
                  "Save Person",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(),
          icon: Icon(icon),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
