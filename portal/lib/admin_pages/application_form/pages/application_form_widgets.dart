part of '../application_form_ui.dart';

extension ApplicationFormWidgets on TestFormPage {
  // this field is here only to allow us to take advantage of some of the
  // functions avialble for setting tab status and other features associated
  // with UI controls, but where we don't want to have any user interation
  List<Widget> buildInvisibleField(
    int tabIndex,
    String fieldName,
  ) {
    try {
      if (applicationGetxController.uiControls[fieldName] != null) {
        return <Widget>[Container()];
      }
    } catch (ex) {
      rethrow;
    }
    return <Widget>[Container()]; // should never reach here
  }

  List<Widget> buildCheckbox(
    int tabIndex,
    String fieldName,
  ) {
    try {
      if (applicationGetxController.uiControls[fieldName] != null) {
        final UiControlDefinition uiControl =
            applicationGetxController.uiControls[fieldName]!;
        return <Widget>[
          TriStateCheckboxField(
            controller: applicationGetxController,
            uiControl: uiControl,
            onChanged: (_) => applicationGetxController.checkIfFormIsDirty(),
          ),
          const SizedBox(height: 20),
        ];
      }
    } catch (ex) {
      rethrow;
    }
    return <Widget>[Container()]; // should never reach here
  }

  List<Widget> buildEditableTextField(
    int tabIndex,
    String fieldName,
  ) {
    try {
      if (applicationGetxController.uiControls[fieldName] != null) {
        final UiControlDefinition uiControl =
            applicationGetxController.uiControls[fieldName]!;
        return <Widget>[
          EditableOverrideTextField(
            controller: applicationGetxController,
            uiControl: uiControl,
            onChanged: (_) => applicationGetxController.checkIfFormIsDirty(),
          ),
          const SizedBox(height: 20),
        ];
      }
    } catch (ex) {
      rethrow;
    }
    return <Widget>[Container()]; // should never reach here
  }

  List<Widget> buildDocumentManagerField(
    int tabIndex,
    String fieldName, {
    required Function onUploadComplete,
    required Function onRemoveDocument,
    String? defaultImageAsset,
    double? height,
    double? width,
  }) {
    applicationGetxController.uploading[fieldName] ??= false.obs;

    try {
      if (applicationGetxController.uiControls[fieldName] != null) {
        final UiControlDefinition uiControl =
            applicationGetxController.uiControls[fieldName]!;

        return <Widget>[
          DocumentManagerField(
            controller: applicationGetxController,
            uiControl: uiControl,
            fieldName: fieldName,
            recordId: applicationGetxController
                .editedData.value!.applicationPublicId
                .toString(),
            uploading: applicationGetxController.uploading[fieldName]!,
            defaultImageAsset: defaultImageAsset,
            height: height,
            width: width,
            onRemoveDocument: () {
              onRemoveDocument();
            },
            onAfterRemove: () =>
                applicationGetxController.checkUiControlValidationStates(),
            onUploadComplete: (fileName) {
              onUploadComplete(fileName);
              applicationGetxController.checkIfFormIsDirty();
            },
          ),
          const SizedBox(height: 20),
        ];
      }
    } catch (ex) {
      rethrow;
    }
    return <Widget>[
      Container(color: Colors.red, width: 50, height: 50)
    ]; // should never reach here
  }
}
