import 'package:harrier_central/imports.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({
    Key? key,
    required this.eventId,
    this.receiptItem,
  }) : super(key: key);

  final String eventId;
  final Map<String, dynamic>? receiptItem;

  @override
  ReceiptDetailPageState createState() => ReceiptDetailPageState();
}

class ReceiptDetailPageState extends State<ReceiptDetailPage> {
  // String firstName = getStringPref(StringPrefsEnum.firstName);
  // String lastName = getStringPref(StringPrefsEnum.lastName);
  // String email = getStringPref(StringPrefsEnum.email);
  // String hashName = getStringPref(StringPrefsEnum.hashName);

  final GlobalKey<FormState> _receiptFormKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  String? _shortDescription;
  String? _receiptAmount;

  File? _imageFromCamera;
  File? _imageFromCache;

  bool _isLoading = false;

  CachedNetworkImage? _receiptImageFromWeb;

  @override
  void initState() {
    if (widget.receiptItem != null) {
      _imageFromCamera = null;

      if ((widget.receiptItem!['imageUrl'] ?? '') != '') {
        _receiptImageFromWeb = CachedNetworkImage(imageUrl: widget.receiptItem!['imageUrl'], fadeInDuration: const Duration(milliseconds: 0));
        DefaultCacheManager().getSingleFile(widget.receiptItem!['imageUrl']).then((File file) {
          _imageFromCache = file;
        });
      }
      _shortDescription = widget.receiptItem!['receiptShortDesc'];
      _receiptAmount = widget.receiptItem!['receiptAmount'].toString();
    }
    super.initState();
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(
          'Uploading receipt details',
          style: headingStyle,
          textAlign: TextAlign.center,
        ),
        Container(height: 30),
        SpinKitCircle(
          size: 75.0,
          itemBuilder: (_, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.grey[50] : Colors.red.shade900,
              ),
            );
          },
        ),
      ]),
    );
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 22.0, height: 1.0);

  TextStyle buttonTextStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _upload(File imageFile, String fileName) {
    final Uri uri = Uri.parse('$BASE_RECEIPTS_URL$fileName?st=2019-04-30T18%3A08%3A40Z&se=2050-05-01T18%3A08%3A00Z&sp=rw&sv=2018-03-28&sr=c&sig=8f8DFDrH7Eq2Jv1JLQ9%2Bh4igcvEZEqE1zcFvUAxsXwY%3D');

    final Request request = Request('PUT', uri);

    final Map<String, String> headers = <String, String>{'content-type': 'image/jpeg', 'x-ms-blob-type': 'BlockBlob'};

    request.headers.addAll(headers);

    FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      // minWidth: 2300,
      // minHeight: 1500,
      quality: 1,
      rotate: 0,
    ).then((List<int>? compressed) {
      if (compressed != null) {
        request.bodyBytes = compressed;
        request.send().then((StreamedResponse response) {
          //print('Receipt upload response = ${response.statusCode}');
        });
      }
    });

    return '$BASE_RECEIPTS_URL$fileName';
  }

  Future<void> _uploadReceipt() async {
    if (_receiptFormKey.currentState != null) {
      if (_receiptFormKey.currentState!.validate()) {
//    If all data are correct then save data to out variables
        _receiptFormKey.currentState!.save();

        String receiptImageUrl = '';

        if (_imageFromCamera != null) {
          receiptImageUrl = _upload(_imageFromCamera!, '${widget.eventId.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        }

        final String userId = getStringPref(StringPrefsEnum.userId)!;

        final ReceiptsModel item = ReceiptsModel(
            userId: userId,
            receiptId: widget.receiptItem == null ? GUID_EMPTY : widget.receiptItem!['receiptId'],
            eventId: widget.eventId,
            receiptShortDescription: _shortDescription,
            receiptAmount: double.parse(_receiptAmount ?? '0.0'),
            notes: '',
            reimbursedBy: GUID_EMPTY,
            reimbursedAmount: -1,
            reimbursedOn: '1999/1/1',
            reimbursedNotes: '',
            imageUrl: receiptImageUrl,
            removed: 0);

        setState(() {
          _isLoading = true;
        });

        final ReceiptsService srv = ReceiptsService();
        final String responseBody = await srv.uploadReceipt(item);
        if (!responseBody.startsWith(ERROR_PREFIX)) {
          await G0<TableModel>().baseService.bulkUpdateDatabase(
                G0<TableModel>().receiptsTableHelper,
                G0<TableModel>().receiptsTableHelper.getTableName(AppDomainType.event),
                responseBody,
                G0<Database>(),
              );

          if (!mounted) return;
          Navigator.of(context).pop();
        } else {
          await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Error uploading receipt',
              'There was an error uploading the receipt. Check your Internet connection and try again.\r\n\r\nSorry for the inconvenience!', 'OK');
        }
      } else {
//    If all data are not valid then start auto validation.
        setState(() {
          _autoValidate = true;
        });
      }
    }
  }

  Widget formUi() {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          initialValue: _shortDescription,
          decoration: const InputDecoration(labelText: 'Short description'),
          keyboardType: TextInputType.text,
          validator: (String? arg) {
            if ((arg != null) || (arg!.length < 4)) {
              return 'Description must be more than 3 charaters';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            _shortDescription = val ?? '';
          },
        ),
        TextFormField(
          autocorrect: false,
          initialValue: _receiptAmount,
          decoration: const InputDecoration(labelText: 'Receipt amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // validator: (String arg) {
          //   // if (arg.length < 1)
          //   //   return 'Name must be more than 2 charaters';
          //   // else
          //   //   return null;
          // },
          onSaved: (String? val) {
            val = (val ?? '').replaceAll(',', '.'); // TODO(James): Investigate how to better handle cases where numeric keyboards have commas instead of decimals
            _receiptAmount = val;
          },
        ),
        const SizedBox(
          height: 10.0,
        ),
      ],
    );
  }

  Future<File?> onImageButtonPressed() async {
    //final PickedFile image = await ImagePicker().getImage(source: ImageSource.camera);

    final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null) {
      final ImageCropper ic = ImageCropper();

      final CroppedFile? croppedFile = await ic.cropImage(sourcePath: image.path, compressFormat: ImageCompressFormat.jpg, compressQuality: 70);

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Run Receipt',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    return Scaffold(
        key: _scaffoldKey,
        appBar: appBar,
        body: _isLoading
            ? Container(height: MediaQuery.of(context).size.height - appBar.preferredSize.height, decoration: Backgrounds.defaultHcBackground(), child: _buildCircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: Backgrounds.defaultHcBackground(),
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  //minHeight: viewportConstraints.maxHeight,
                                  ),
                              child: IntrinsicHeight(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Receipt details',
                                        style: headingStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                      //),
                                      // Positioned(
                                      //   top: 40,
                                      //   //bottom: 20,
                                      //   width: MediaQuery.of(context).size.width,
                                      //   child:
                                      Container(
                                        padding: const EdgeInsets.all(30.0),
                                        child: Center(
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                padding: const EdgeInsets.all(10.0),
                                                margin: const EdgeInsets.only(bottom: 45),
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow[100],
                                                  borderRadius: BorderRadius.circular(5.0),
                                                ),
                                                child: Form(
                                                  key: _receiptFormKey,
                                                  autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                                                  child: formUi(),
                                                ),
                                              ),
                                              const FancyDivider(key: Key('121678443'), innerColor: Colors.white),
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                onPressed: () {
                                                  onImageButtonPressed().then((File? imageFile) {
                                                    setState(() {
                                                      _imageFromCamera = imageFile;
                                                    });
                                                  });
                                                },
                                                child: Text('Scan Receipt', style: textStyleButton),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      //),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),

                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push<void>(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (BuildContext context) => ZoomableImagePage2(
                                                key: const Key('66610301'),
                                                file: _imageFromCamera ?? _imageFromCache,
                                                pageTitle: 'Zoomable Receipt',
                                                appBarBackgroundColor: themeAppBarBackground,
                                                background: Backgrounds.defaultHcBackground(),
                                              ),
                                            ),
                                          );
                                        },
                                        child: _imageFromCamera != null
                                            ? Container(
                                                //height: 220,
                                                color: Colors.white,
                                                padding: const EdgeInsets.all(10.0),
                                                margin: const EdgeInsets.only(top: 20, bottom: 30),
                                                child: Image.file(_imageFromCamera!, width: MediaQuery.of(context).size.width))
                                            : _receiptImageFromWeb != null
                                                ? Container(
                                                    //height: 220,
                                                    color: Colors.white,
                                                    padding: const EdgeInsets.all(10.0),
                                                    margin: const EdgeInsets.only(top: 20, bottom: 30),
                                                    child: _receiptImageFromWeb)
                                                : Container(),
                                      ),
                                      const SizedBox(width: 40, height: 40),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                      // padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        // border: new Border.all(width: 1.0, color: Colors.black),
                        //shape: BoxShape.circle,
                        color: Colors.yellow[100],
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color.fromARGB(70, 0, 0, 0),
                            offset: Offset(0.0, 6.0),
                            blurRadius: 10.0,
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            //margin: const EdgeInsets.only(right: 15),
                            width: 200,
                            child: ElevatedButton(
                              onPressed: _uploadReceipt,
                              child: Text('Save receipt', style: textStyleButton),
                            ),
                          ),
                        ],
                      )),
                ],
              ));
  }
}
