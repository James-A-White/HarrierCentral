import 'package:harrier_central/imports_null_safe.dart';

class UserDetailsUi extends StatefulWidget {
  const UserDetailsUi({Key? key, this.firstName, this.lastName, this.email, this.hashName}) : super(key: key);

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? hashName;
  // Function updateUi;

  @override
  UserDetailsUiState createState() => UserDetailsUiState();
}

class UserDetailsUiState extends State<UserDetailsUi> with WidgetsBindingObserver {
  UserDetailsUiState();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode myFocusNodeHashName = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();

  TextEditingController signupEmailController = TextEditingController();
  TextEditingController signupFirstNameController = TextEditingController();
  TextEditingController signupLastNameController = TextEditingController();
  TextEditingController signupHashNameController = TextEditingController();

  late final UserDetailReturnValues _returnValues = UserDetailReturnValues();

  @override
  void initState() {
    super.initState();

    _returnValues.email = widget.email;
    _returnValues.firstName = widget.firstName;
    _returnValues.lastName = widget.lastName;
    _returnValues.hashName = widget.hashName;

    signupEmailController.text = widget.email ?? '';
    signupFirstNameController.text = widget.firstName ?? '';
    signupLastNameController.text = widget.lastName ?? '';
    signupHashNameController.text = widget.hashName ?? '';
    WidgetsBinding.instance.addObserver(this);
    // widget.updateUi = updateUi;
    // widget.validateForm = validateForm;
  }

  // void updateUi(String firstName, String lastName, String email) {
  //   setState(() {
  //     signupEmailController.text = email;
  //     signupFirstNameController.text = firstName;
  //     signupLastNameController.text = lastName;
  //   });
  // }

  @override
  void dispose() {
    myFocusNodeHashName.dispose();
    myFocusNodeEmail.dispose();
    myFocusNodeFirstName.dispose();
    myFocusNodeLastName.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool validateForm() {
    if (_formKey.currentState != null) {
      return _formKey.currentState!.validate();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicWidth(
    //     child:
    return Card(
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SizedBox(
        width: 300.0,
        //height: 225.0,
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  focusNode: myFocusNodeFirstName,
                  controller: signupFirstNameController,
                  onChanged: (String text) {
                    _returnValues.firstName = text;
                  },
                  keyboardType: TextInputType.text,
                  validator: (String? val) {
                    if ((val ?? '').isEmpty) {
                      return 'Please provide a first name';
                    } else {
                      return null;
                    }
                  },
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.user,
                      color: Colors.black,
                    ),
                    hintText: 'First Name',
                    hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    _returnValues.lastName = text;
                  },
                  focusNode: myFocusNodeLastName,
                  controller: signupLastNameController,
                  validator: (String? val) {
                    if ((val ?? '').isEmpty) {
                      return 'Please provide a last name';
                    } else {
                      return null;
                    }
                  },
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.user,
                      color: Colors.black,
                    ),
                    hintText: 'Last Name',
                    hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    _returnValues.email = text;
                  },
                  focusNode: myFocusNodeEmail,
                  controller: signupEmailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Utilities.validateEmail,
                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.envelope,
                      color: Colors.black,
                    ),
                    hintText: 'Email Address',
                    hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    _returnValues.hashName = text;
                  },
                  focusNode: myFocusNodeHashName,
                  controller: signupHashNameController,
                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      MaterialCommunityIcons.rabbit,
                      color: Colors.black,
                    ),
                    hintText: 'Hash Name (optional)',
                    hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserDetailReturnValues {
  String? firstName;
  String? lastName;
  String? email;
  String? hashName;
}
