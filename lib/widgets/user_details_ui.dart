import 'package:harrier_central/imports.dart';

class UserDetailsUi extends StatefulWidget {
  UserDetailsUi(
      {Key key, this.firstName, this.lastName, this.email, this.hashName})
      : super(key: key);

  String firstName;
  String lastName;
  String email;
  String hashName;
  Function updateUi;
  Function validateForm;

  @override
  _UserDetailsUiState createState() => _UserDetailsUiState();
}

class _UserDetailsUiState extends State<UserDetailsUi>
    with WidgetsBindingObserver {
  _UserDetailsUiState();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode myFocusNodeHashName = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();

  TextEditingController signupEmailController = TextEditingController();
  TextEditingController signupFirstNameController = TextEditingController();
  TextEditingController signupLastNameController = TextEditingController();
  TextEditingController signupHashNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    signupEmailController.text = widget.email;
    signupFirstNameController.text = widget.firstName;
    signupLastNameController.text = widget.lastName;
    signupHashNameController.text = widget.hashName;
    WidgetsBinding.instance.addObserver(this);
    widget.updateUi = updateUi;
    widget.validateForm = validateForm;
  }

  void updateUi(String firstName, String lastName, String email) {
    setState(() {
      signupEmailController.text = email;
      signupFirstNameController.text = firstName;
      signupLastNameController.text = lastName;
    });
  }

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
    return _formKey.currentState.validate();
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
      child: Container(
        width: 300.0,
        //height: 225.0,
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  focusNode: myFocusNodeFirstName,
                  controller: signupFirstNameController,
                  onChanged: (String text) {
                    widget.firstName = text;
                  },
                  keyboardType: TextInputType.text,
                  validator: (String val) {
                    if (val.isEmpty) {
                      return 'Please provide a first name';
                    } else {
                      return null;
                    }
                  },
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      fontFamily: 'WorkSansSemiBold',
                      fontSize: 16.0,
                      color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.user,
                      color: Colors.black,
                    ),
                    hintText: 'First Name',
                    hintStyle: TextStyle(
                        fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    widget.lastName = text;
                  },
                  focusNode: myFocusNodeLastName,
                  controller: signupLastNameController,
                  validator: (String val) {
                    if (val.isEmpty) {
                      return 'Please provide a last name';
                    } else {
                      return null;
                    }
                  },
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      fontFamily: 'WorkSansSemiBold',
                      fontSize: 16.0,
                      color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.user,
                      color: Colors.black,
                    ),
                    hintText: 'Last Name',
                    hintStyle: TextStyle(
                        fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    widget.email = text;
                  },
                  focusNode: myFocusNodeEmail,
                  controller: signupEmailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (String val) {
                    if (val.isEmpty) {
                      return 'Please provide an email address';
                    } else {
                      if (EmailValidator.validate(val)) {
                        return null;
                      } else {
                        return 'Please provide a valid email address';
                      }
                    }
                  },
                  style: const TextStyle(
                      fontFamily: 'WorkSansSemiBold',
                      fontSize: 16.0,
                      color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      FontAwesome.envelope,
                      color: Colors.black,
                    ),
                    hintText: 'Email Address',
                    hintStyle: TextStyle(
                        fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                  ),
                ),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 3.0, bottom: 3.0, left: 25.0, right: 25.0),
                child: TextFormField(
                  onChanged: (String text) {
                    widget.hashName = text;
                  },
                  focusNode: myFocusNodeHashName,
                  controller: signupHashNameController,
                  style: const TextStyle(
                      fontFamily: 'WorkSansSemiBold',
                      fontSize: 16.0,
                      color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      MaterialCommunityIcons.rabbit,
                      color: Colors.black,
                    ),
                    hintText: 'Hash Name (optional)',
                    hintStyle: TextStyle(
                        fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
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
  String firstName;
  String lastName;
  String email;
  String hashName;
}
