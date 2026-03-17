part of 'application_form_controller.dart';

extension UiDefinitions on ApplicationFormController {
  void tabAppDetails_buildControls() {
    uiControls['${AppTabKeyEnums.tabDescription.key}_title'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey: '${AppTabKeyEnums.tabDescription.key}_title',
            sidebarExitKey: '${AppTabKeyEnums.tabDescription.key}_generic',
            sidebarData: const SideBarData(
              'Title',
              MaterialCommunityIcons.format_title,
              'Provide a clear, memorable application title so reviewers can recognize your proposal quickly.',
            ),
            editedFieldValue: editedData.value?.title,
            originalFieldValue: originalData.title,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Application title',
            maxStringLength: 100,
            minStringLength: 3,
            includeOverrideButton: false,
            textController: textEditingController[
                    '${AppTabKeyEnums.tabDescription.key}_title'] =
                TextEditingController(),
            tabIndex: 0,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(title: value!);
              uiControls['${AppTabKeyEnums.tabDescription.key}_title']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabDescription.key}_shortDescription'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabDescription.key}_shortDescription',
            sidebarExitKey: '${AppTabKeyEnums.tabDescription.key}_generic',
            sidebarData: const SideBarData(
              'Short Description',
              Entypo.text,
              'Summarize your solution in 50-250 characters. Keep it concise and outcome focused.',
            ),
            editedFieldValue: editedData.value?.shortDescription,
            originalFieldValue: originalData.shortDescription,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Short description',
            maxStringLength: 250,
            minStringLength: 50,
            maxLines: 3,
            includeOverrideButton: false,
            textController: textEditingController[
                    '${AppTabKeyEnums.tabDescription.key}_shortDescription'] =
                TextEditingController(),
            tabIndex: 0,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(shortDescription: value!);
              uiControls[
                      '${AppTabKeyEnums.tabDescription.key}_shortDescription']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabDescription.key}_applicationImage'] =
        UiControlDefinition(
            controlType: UiControlType.imageUpload,
            fileType: DocumentType.applicationImage,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabDescription.key}_applicationImage',
            sidebarExitKey: '${AppTabKeyEnums.tabDescription.key}_generic',
            sidebarData: const SideBarData(
              'Application Image',
              Entypo.image_inverted,
              'Add an image that represents your solution. A visual hook helps reviewers remember your proposal. Max file size: 3Mb.',
            ),
            editedFieldValue: editedData.value?.applicationImageUrl,
            originalFieldValue: originalData.applicationImageUrl,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Image',
            tabIndex: 0,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(shortDescription: value!);
              uiControls[
                      '${AppTabKeyEnums.tabDescription.key}_applicationImage']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabProposals.key}_quadChart'] =
        UiControlDefinition(
            controlType: UiControlType.pdfUpload,
            fileType: DocumentType.quadChart,
            sidebarEntryKey: '${AppTabKeyEnums.tabProposals.key}_quadChart',
            sidebarExitKey: '${AppTabKeyEnums.tabProposals.key}_generic',
            sidebarData: const SideBarData(
              'Quad Chart',
              MaterialCommunityIcons.grid_large,
              "The quad chart is a one page summary of your application.\r\n\r\nIn order for your application to be accepted, you must use DIANA's quad chart template.",
            ),
            editedFieldValue: editedData.value?.quadChart?.documentUrl,
            originalFieldValue: originalData.quadChart?.documentUrl,
            globalKey: GlobalKey<FormFieldState>(),
            maxStringLength: 300,
            minStringLength: 20,
            label: 'Quad Chart',
            regex: BASE_UPLOAD_URL_REGEX,
            tabIndex: 1,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(
                  quadChart: editedData.value?.quadChart
                      ?.copyWith(documentUrl: value ?? ''));
              uiControls['${AppTabKeyEnums.tabProposals.key}_quadChart']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabProposals.key}_proposal'] =
        UiControlDefinition(
            controlType: UiControlType.pdfUpload,
            fileType: DocumentType.proposal,
            sidebarEntryKey: '${AppTabKeyEnums.tabProposals.key}_proposal',
            sidebarExitKey: '${AppTabKeyEnums.tabProposals.key}_generic',
            sidebarData: const SideBarData(
              'Proposal PDF',
              FontAwesome5Solid.file_pdf,
              'Upload your full proposal as a PDF. Please follow the DIANA template and keep the document within the allowed page limits.',
            ),
            editedFieldValue: editedData.value?.proposal?.documentUrl,
            originalFieldValue: originalData.proposal?.documentUrl,
            globalKey: GlobalKey<FormFieldState>(),
            maxStringLength: 300,
            minStringLength: 20,
            label: 'Proposal',
            regex: BASE_UPLOAD_URL_REGEX,
            tabIndex: 1,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(
                  proposal: editedData.value?.proposal
                      ?.copyWith(documentUrl: value ?? ''));
              uiControls['${AppTabKeyEnums.tabProposals.key}_proposal']
                  ?.editedFieldValue = value;
            });

    /////////////////   CV Fields   /////////////////

    uiControls['${AppTabKeyEnums.tabCvs.key}_cvCeo'] = UiControlDefinition(
        controlType: UiControlType.pdfUpload,
        fileType: DocumentType.cv,
        sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvCeo',
        sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
        sidebarData: const SideBarData(
          'CEO CV',
          FontAwesome5Solid.user_tie,
          "Upload the CEO's CV highlighting leadership experience and prior commercialization success.",
        ),
        editedFieldValue: editedData.value?.applicationCvCeo?.documentUrl,
        originalFieldValue: originalData.applicationCvCeo?.documentUrl,
        globalKey: GlobalKey<FormFieldState>(),
        label: 'CEO CV',
        tabIndex: AppTabKeyEnums.tabCvs.idx,
        updateEditedValue: (String? value) {
          editedData.value = editedData.value?.copyWith(
              proposal: editedData.value?.applicationCvCeo
                  ?.copyWith(documentUrl: value ?? ''));
          uiControls['${AppTabKeyEnums.tabCvs.key}_cvCeo']?.editedFieldValue =
              value;
        });

    uiControls['${AppTabKeyEnums.tabCvs.key}_cvTech'] = UiControlDefinition(
        controlType: UiControlType.pdfUpload,
        fileType: DocumentType.cv,
        sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvTech',
        sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
        sidebarData: const SideBarData(
          'Tech Lead CV',
          MaterialCommunityIcons.cog,
          "Provide the technical lead's CV focusing on relevant domain expertise and past implementations.",
        ),
        editedFieldValue: editedData.value?.applicationCvTech?.documentUrl,
        originalFieldValue: originalData.applicationCvTech?.documentUrl,
        globalKey: GlobalKey<FormFieldState>(),
        label: 'Tech Lead CV',
        tabIndex: AppTabKeyEnums.tabCvs.idx,
        updateEditedValue: (String? value) {
          editedData.value = editedData.value?.copyWith(
              proposal: editedData.value?.applicationCvTech
                  ?.copyWith(documentUrl: value ?? ''));
          uiControls['${AppTabKeyEnums.tabCvs.key}_cvTech']?.editedFieldValue =
              value;
        });

    uiControls['${AppTabKeyEnums.tabCvs.key}_cvAdmin'] = UiControlDefinition(
        controlType: UiControlType.pdfUpload,
        fileType: DocumentType.cv,
        sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvAdmin',
        sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
        sidebarData: const SideBarData(
          'Project Administrator CV',
          MaterialCommunityIcons.clipboard_account,
          "Upload the project administrator's CV showing delivery experience and coordination skills.",
        ),
        editedFieldValue: editedData.value?.applicationCvAdmin?.documentUrl,
        originalFieldValue: originalData.applicationCvAdmin?.documentUrl,
        globalKey: GlobalKey<FormFieldState>(),
        label: 'Project Administrator CV',
        tabIndex: AppTabKeyEnums.tabCvs.idx,
        updateEditedValue: (String? value) {
          editedData.value = editedData.value?.copyWith(
              proposal: editedData.value?.applicationCvAdmin
                  ?.copyWith(documentUrl: value ?? ''));
          uiControls['${AppTabKeyEnums.tabCvs.key}_cvAdmin']?.editedFieldValue =
              value;
        });

    uiControls['${AppTabKeyEnums.tabCvs.key}_cvComm'] = UiControlDefinition(
        controlType: UiControlType.pdfUpload,
        fileType: DocumentType.cv,
        sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvComm',
        sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
        sidebarData: const SideBarData(
          'Commercial Lead CV',
          MaterialCommunityIcons.briefcase,
          "Provide the commercial lead's CV to evidence business development and go-to-market experience.",
        ),
        editedFieldValue: editedData.value?.applicationCvComm?.documentUrl,
        originalFieldValue: originalData.applicationCvComm?.documentUrl,
        globalKey: GlobalKey<FormFieldState>(),
        label: 'Commercial Lead CV',
        tabIndex: AppTabKeyEnums.tabCvs.idx,
        updateEditedValue: (String? value) {
          editedData.value = editedData.value?.copyWith(
              proposal: editedData.value?.applicationCvComm
                  ?.copyWith(documentUrl: value ?? ''));
          uiControls['${AppTabKeyEnums.tabCvs.key}_cvComm']?.editedFieldValue =
              value;
        });

/////////////////   Stakeholder Images   /////////////////

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo'] =
        UiControlDefinition(
            controlType: UiControlType.imageUpload,
            fileType: DocumentType.stakeholderImage,
            sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'CEO Image',
              MaterialCommunityIcons.account_circle,
              'Add a clear headshot of the CEO so reviewers can associate a face with the proposal.',
            ),
            editedFieldValue: editedData.value?.applicationPicCeo,
            originalFieldValue: originalData.applicationPicCeo,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'CEO Image',
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(applicationPicCeo: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm'] =
        UiControlDefinition(
            controlType: UiControlType.imageUpload,
            fileType: DocumentType.stakeholderImage,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Commercial Lead Image',
              MaterialCommunityIcons.account_circle,
              'Add a clear headshot of the commercial lead.',
            ),
            editedFieldValue: editedData.value?.applicationPicComm,
            originalFieldValue: originalData.applicationPicComm,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Commercial Lead Image',
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(applicationPicComm: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin'] =
        UiControlDefinition(
            controlType: UiControlType.imageUpload,
            fileType: DocumentType.stakeholderImage,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Project Administrator Image',
              MaterialCommunityIcons.account_circle,
              'Add a clear headshot of the project administrator.',
            ),
            editedFieldValue: editedData.value?.applicationPicAdmin,
            originalFieldValue: originalData.applicationPicAdmin,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Project Administrator Image',
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(applicationPicAdmin: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech'] =
        UiControlDefinition(
            controlType: UiControlType.imageUpload,
            fileType: DocumentType.stakeholderImage,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Tech Lead Image',
              MaterialCommunityIcons.account_circle,
              'Add a clear headshot of the technical lead.',
            ),
            editedFieldValue: editedData.value?.applicationPicTech,
            originalFieldValue: originalData.applicationPicTech,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Tech Lead Image',
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(applicationPicTech: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech']
                  ?.editedFieldValue = value;
            });

    /////////////////   Stakeholder Names   /////////////////

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'CEO Name',
              Ionicons.person,
              "Enter the CEO's full name as it should appear in your submission.",
            ),
            editedFieldValue: editedData.value?.nameCeo,
            originalFieldValue: originalData.nameCeo,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'CEO Name',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(nameCeo: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Project Administrator Name',
              Ionicons.person,
              "Enter the project administrator's full name.",
            ),
            editedFieldValue: editedData.value?.nameAdmin,
            originalFieldValue: originalData.nameAdmin,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Project Administrator Name',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(nameAdmin: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Commercial Lead Name',
              Ionicons.person,
              "Enter the commercial lead's full name.",
            ),
            editedFieldValue: editedData.value?.nameComm,
            originalFieldValue: originalData.nameComm,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Commercial Lead Name',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(nameComm: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Tech Lead Name',
              Ionicons.person,
              "Enter the technical lead's full name.",
            ),
            editedFieldValue: editedData.value?.nameTech,
            originalFieldValue: originalData.nameTech,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Tech Lead Name',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(nameTech: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech']
                  ?.editedFieldValue = value;
            });

/////////////////   Stakeholder Emails   /////////////////

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'CEO Email',
              Ionicons.mail,
              'Provide a valid email for the CEO so we can reach them during evaluation.',
            ),
            editedFieldValue: editedData.value?.emailCeo,
            originalFieldValue: originalData.emailCeo,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'CEO Email',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
            regexErrorString: 'Please enter a valid email address',
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(emailCeo: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Project Administrator Email',
              Ionicons.mail,
              'Provide a valid email for the project administrator.',
            ),
            editedFieldValue: editedData.value?.emailAdmin,
            originalFieldValue: originalData.emailAdmin,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Project Administrator Email',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
            regexErrorString: 'Please enter a valid email address',
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(emailAdmin: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Commercial Lead Email',
              Ionicons.mail,
              'Provide a valid email for the commercial lead.',
            ),
            editedFieldValue: editedData.value?.emailComm,
            originalFieldValue: originalData.emailComm,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Commercial Lead Email',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
            regexErrorString: 'Please enter a valid email address',
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(emailComm: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech'] =
        UiControlDefinition(
            controlType: UiControlType.string,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech',
            sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}_generic',
            sidebarData: const SideBarData(
              'Tech Lead Email',
              Ionicons.mail,
              'Provide a valid email for the technical lead.',
            ),
            editedFieldValue: editedData.value?.emailTech,
            originalFieldValue: originalData.emailTech,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Tech Lead Email',
            regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
            regexErrorString: 'Please enter a valid email address',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabCvs.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value?.copyWith(emailTech: value!);
              uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabTags.key}_tags'] = UiControlDefinition(
        controlType: UiControlType.invisible,
        sidebarEntryKey: '${AppTabKeyEnums.tabTags.key}_generic',
        sidebarExitKey: '${AppTabKeyEnums.tabTags.key}_generic',
        sidebarData: SideBarData(
          'Experience Tags',
          FontAwesome.tags,
          'Select between $MINIMUM_TAGS_REQUIRED and $MAXIMUM_TAGS_ALLOWWED experience tags that best match your solution.',
        ),
        editedFieldValue: editedData.value?.tagsValid,
        originalFieldValue: originalData.tagsValid,
        globalKey: GlobalKey<FormFieldState>(),
        label: 'Experience Tags',
        regex: r"^true$",
        regexErrorString: 'Please ensure you have selected enough tags',
        textController:
            textEditingController['${AppTabKeyEnums.tabTags.key}_tags'] =
                TextEditingController(),
        tabIndex: AppTabKeyEnums.tabTags.idx,
        updateEditedValue: (String? value) {
          value ??= '';
          editedData.value = editedData.value?.copyWith(tagsValid: value);
          uiControls['${AppTabKeyEnums.tabTags.key}_tags']?.editedFieldValue =
              value;
        });

    uiControls[
            '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}'] =
        UiControlDefinition(
            controlType: UiControlType.invisible,
            sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarExitKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarData: SideBarData(
              AppFormTypes.formOverivew.title,
              AppFormTypes.formOverivew.icon,
              'Target ${AppFormTypes.formOverivew.minFormWordCount}-${AppFormTypes.formOverivew.maxFormWordCount} words to give a compelling overview of your product and outcomes.',
            ),
            editedFieldValue: editedData.value?.formOverviewValid,
            originalFieldValue: originalData.formOverviewValid,
            globalKey: GlobalKey<FormFieldState>(),
            minStringLength: 4,
            maxStringLength:
                5, // this control will only hold the values "true,false, or null"
            label: AppFormTypes.formOverivew.title,
            regex: r"^true$",
            regexErrorString:
                'Please ensure you have met the minimum word count',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabForms.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(formOverviewValid: value!);
              uiControls[
                      '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}']
                  ?.editedFieldValue = value;
            });

    uiControls[
            '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}'] =
        UiControlDefinition(
            controlType: UiControlType.invisible,
            sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarExitKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarData: SideBarData(
              AppFormTypes.formCommercial.title,
              AppFormTypes.formCommercial.icon,
              'Describe commercial viability, market pathways, and partnerships in ${AppFormTypes.formCommercial.minFormWordCount}-${AppFormTypes.formCommercial.maxFormWordCount} words.',
            ),
            editedFieldValue: editedData.value?.formCommercialroposalValid,
            originalFieldValue: originalData.formCommercialroposalValid,
            globalKey: GlobalKey<FormFieldState>(),
            minStringLength: 4,
            maxStringLength:
                5, // this control will only hold the values "true,false, or null"
            label: AppFormTypes.formCommercial.title,
            regex: r"^true$",
            regexErrorString:
                'Please ensure you have met the minimum word count',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabForms.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value
                  ?.copyWith(formCommercialroposalValid: value!);
              uiControls[
                      '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}']
                  ?.editedFieldValue = value;
            });

    uiControls[
            '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}'] =
        UiControlDefinition(
            controlType: UiControlType.invisible,
            sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarExitKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarData: SideBarData(
              AppFormTypes.formProject.title,
              AppFormTypes.formProject.icon,
              'Outline how you will use EUR 100k to advance the project in ${AppFormTypes.formProject.minFormWordCount}-${AppFormTypes.formProject.maxFormWordCount} words.',
            ),
            editedFieldValue: editedData.value?.formProjectPlanValid,
            originalFieldValue: originalData.formProjectPlanValid,
            globalKey: GlobalKey<FormFieldState>(),
            label: AppFormTypes.formProject.title,
            minStringLength: 4,
            maxStringLength:
                5, // this control will only hold the values "true,false, or null"
            regex: r"^true$",
            regexErrorString:
                'Please ensure you have met the minimum word count',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabForms.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(formProjectPlanValid: value!);
              uiControls[
                      '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}']
                  ?.editedFieldValue = value;
            });

    uiControls[
            '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}'] =
        UiControlDefinition(
            controlType: UiControlType.invisible,
            sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarExitKey: '${AppTabKeyEnums.tabForms.key}_generic',
            sidebarData: SideBarData(
              AppFormTypes.formTechnical.title,
              AppFormTypes.formTechnical.icon,
              'Explain the technical innovation in ${AppFormTypes.formTechnical.minFormWordCount}-${AppFormTypes.formTechnical.maxFormWordCount} words, including dual-use relevance.',
            ),
            editedFieldValue: editedData.value?.formTechnicalDescriptionValid,
            originalFieldValue: originalData.formTechnicalDescriptionValid,
            globalKey: GlobalKey<FormFieldState>(),
            label: AppFormTypes.formTechnical.title,
            minStringLength: 4,
            maxStringLength:
                5, // this control will only hold the values "true,false, or null"
            regex: r"^true$",
            regexErrorString:
                'Please ensure you have met the minimum word count',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabForms.idx,
            updateEditedValue: (String? value) {
              editedData.value = editedData.value
                  ?.copyWith(formTechnicalDescriptionValid: value!);
              uiControls[
                      '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}'] =
        UiControlDefinition(
            controlType: UiControlType.checkbox,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabConsent.key}_termsAndConditions',
            sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}_generic',
            sidebarData: const SideBarData(
              'Terms and Conditions',
              Ionicons.document_text,
              'You must accept the DIANA terms and conditions before submitting.',
            ),
            editedFieldValue: editedData.value?.agreeTsAndCs,
            originalFieldValue: originalData.agreeTsAndCs,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'Accept terms and conditions',
            minStringLength: 1,
            maxStringLength: 1, // the default value is null for Ts and Cs
            regex: r"^1$",
            regexErrorString:
                'Please ensure you have accepted the Terms and Conditions',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabConsent.idx,
            updateEditedValue: (String? value) {
              String details = '';
              if ((value ?? '0') == '0') {
                details = '';
              } else {
                details = '<user name> + ${DateTime.now()}';
              }

              editedData.value =
                  editedData.value?.copyWith(agreeTsAndCs: value!);
              editedData.value =
                  editedData.value?.copyWith(agreeTsAndCsDetails: details);
              uiControls['${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}']
                  ?.editedFieldValue = value;
            });

    //==========

    uiControls['${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}'] =
        UiControlDefinition(
            controlType: UiControlType.checkbox,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations',
            sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}_generic',
            sidebarData: const SideBarData(
              'Share with NATO nations',
              Ionicons.people,
              'Check to allow us to share your submission with NATO nation government users; leave unchecked to restrict sharing.',
            ),
            editedFieldValue: editedData.value?.optOutToShareWithNations,
            originalFieldValue: originalData.optOutToShareWithNations,
            globalKey: GlobalKey<FormFieldState>(),
            label:
                'I agree to share our data with NATO nation government users',
            minStringLength: 1,
            maxStringLength: 1, // the default value is null for Ts and Cs
            regex: r"^[1,0]$",
            regexErrorString:
                'If you see this message, please contact us as this is an error.',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabConsent.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(optOutToShareWithNations: value!);
              uiControls[
                      '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}']
                  ?.editedFieldValue = value;
            });

    uiControls['${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}'] =
        UiControlDefinition(
            controlType: UiControlType.checkbox,
            sidebarEntryKey:
                '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions',
            sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}_generic',
            sidebarData: const SideBarData(
              'Partner communications',
              Ionicons.mail,
              'Choose whether you would like to receive information from DIANA partners.',
            ),
            editedFieldValue: editedData.value?.optInToReceivePromotions,
            originalFieldValue: originalData.optInToReceivePromotions,
            globalKey: GlobalKey<FormFieldState>(),
            label: 'I would like to receive information from DIANA partners',
            minStringLength: 1,
            maxStringLength: 1, // the default value is null for Ts and Cs
            regex: r"^[1,0]$",
            regexErrorString:
                'If you see this message, please contact us as this is an error.',
            textController: textEditingController[
                    '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}'] =
                TextEditingController(),
            tabIndex: AppTabKeyEnums.tabConsent.idx,
            updateEditedValue: (String? value) {
              editedData.value =
                  editedData.value?.copyWith(optInToReceivePromotions: value!);
              uiControls[
                      '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}']
                  ?.editedFieldValue = value;
            });
  }
}
