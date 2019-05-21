import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/pages/menu_pages/get_reset_code_popup.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';

class LegalPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const LegalPage({Key key}) : super(key: key);

  @override
  LegalPageState createState() => LegalPageState();
}

class LegalPageState extends State<LegalPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              title: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              child: const LegalPageContent(),
            ),
          ),
        ),
         const OfflineModeRibbon(),
      ],
    );
  }
}

class LegalPageContent extends StatefulWidget {
  const LegalPageContent({Key key}) : super(key: key);

  @override
  _LegalPageContentState createState() => _LegalPageContentState();
}

class _LegalPageContentState extends State<LegalPageContent> {
  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

  int tapCounter = 0;
  void backdoorTap() {
    Future<dynamic>.delayed(const Duration(milliseconds: 2500)).then((void dummy) {
      print('Tapcounter reset = $tapCounter');
      tapCounter = 0;
    });

    tapCounter++;
    if (tapCounter == 6) {
      getResetCode();
    }
  }

  void getResetCode() {
    const GetResetCodePopup getResetCode = GetResetCodePopup();

    final Future<void> dlg = showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return getResetCode;
        });

    dlg.then((void dummy) {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              //minHeight: viewportConstraints.maxHeight,
              ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Terms of Service for the use of the websites and mobile phone services of InnoVet Europe',
                    style: headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    height: 1.0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                  ),
                  Text('\r\n1. Your Acceptance', style: headingStyle),
                  Text(
                    'This is an agreement between InnoVet Europe ("InnoVet"), the owner and operator of www.harriercentral.com (the “Harrier Central Site"), the Harrier Central app software the “Harrier Central", or the "Service", or "App" and you ("you" or "You"), a user of the Service. BY USING THE SERVICE, YOU ACKNOWLEDGE AND AGREE TO THESE TERMS OF SERVICE, AND INNOVET’S PRIVACY POLICY, WHICH CAN BE FOUND AT',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(
                    child: Text(
                      'http://www.harriercentral.com/assets/pdf/privacyPolicy.pdf',
                      style: bodyStyle,
                      textAlign: TextAlign.justify,
                    ),
                    margin: const EdgeInsets.all(10),
                  ),
                  Text(
                    'AND WHICH ARE INCORPORATED HEREIN BY REFERENCE. If you do not agree to any of these terms, you may not use the Service.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(child: Text('\r\n2. Harrier Central Service', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  Text(
                    'These Terms of Service apply to all users of the Harrier Central Service. The Harrier Central provided status information may contain links to third party websites that are not owned or controlled by Harrier Central. Harrier Central has no control over and assumes no responsibility for, the content, privacy policies, or practices of any third party websites. In addition, Harrier Central will not and cannot censor or edit the content of any third-party site. By using the Service, you expressly acknowledge and agree that Harrier Central shall not be responsible for any damages, claims or other liability arising from or related to your use of any third-party website.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(child: Text('\r\n3. Harrier Central Access', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  Container(
                      child: Text(
                        '(1) Subject to your compliance with these Terms of Service, Harrier Central hereby grants you a non-exclusive, non-transferable license to download, install and Use the App on Your mobile device. This license is in respect of Your Use of the App only, provided that: (i) your use of the Service as permitted is solely for your personal, non-commercial use; (ii) you will not duplicate, transfer, give access to, copy or distribute any part of the Service in any medium without Innovet’s prior written authorization; (iii) you will not attempt to reverse engineer, alter or modify any part of the Service; and (iv) you will otherwise comply with the terms and conditions of these Terms of Service.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 5, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(2) In order to access and use the features of the Service, you acknowledge and agree that you will allow InnoVet to share your run information with Hash House Harriers groups that you run with (e.g. run counts) and, when applicable, payment information regarding your participation in Hash runs.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(3) We will use our reasonable endeavors to make the App available to You at all times, but We cannot guarantee an uninterrupted or fault free service.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(4) We reserve the right to make changes to the App or part thereof from time to time including without limitation, the removal, modification and/or variation of any elements, features, and functionalities of the App.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(5) You acknowledge You will not be able to access and Use certain functionalities of the App unless You have internet access through a GPRS, 3G or Wi-Fi globalConnectionStatus mobile device. All traffic charges or access charges incurred due to the Use of the App are subject to Your agreed terms with your mobile network provider.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(6) Without prejudice to our other rights and remedies, We reserve the right to temporarily or permanently suspend or disable your access to the App at any time without notice to You in the event you breach any of the provisions herein.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(7) In the event that We, in Our sole discretion, consider that you are making any illegal and/or unauthorised use of the App, and/or your Use of the App is in breach of these Terms, We reserve the right to take any action that it deems necessary, including terminating without notice Your Use of the App and, in the case of illegal use, instigating legal proceedings.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(8) We reserve the right to make any changes to the App or to discontinue any aspect or feature of the App without notice to You.',
                        style: bodyStyle,
                        textAlign: TextAlign.justify,
                      ),
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20)),
                  Container(child: Text('\r\n4. Claims of Copyright Infringement', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  Text(
                    'If you believe that your work has been copied and is accessible on the Site in a way that constitutes copyright infringement, please contact us to report possible copyright infringement and include the following information required by the Online Copyright Infringement Liability Limitation Act of the Digital Millennium Copyright Act, 17 U.S.C.§ 512:',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(
                      child: Text(
                        '(1) A physical or electronic signature of a person authorized to act on behalf of the owner of an exclusive right that is allegedly infringed;',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(2) Identification of the copyrighted work claimed to have been infringed, or if multiple copyrighted works at a single online site are covered by a single notification, a representative list of such works at that site;',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(3) Identification of the material that is claimed to be infringing or to be the subject of infringing activity and that is to be removed or access to which is to be disabled, and information reasonably sufficient to permit us to locate the material;',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(4) Information reasonably sufficient to permit us to contact the complaining party;',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(5) A statement that the complaining party has a good-faith belief that use of the material in the manner complained of is not authorized by the copyright owner, its agent, or the law; and',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(6) A statement that the information in the notification is accurate, and under penalty of perjury, that the complaining party is authorized to act on behalf of the owner of an exclusive right that is allegedly infringed.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10)),
                  Text(
                    'Send this information to:\r\nInnoVet Europe\r\nFluwelen Burgwal 58\r\n2511 CJ, Den Haag\r\nNetherlands',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(child: Text('\r\n5. Warranties and Liabilities', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  Container(
                      child: Text(
                        '(1) We provide Users with access to some features of the App free of charge and other features based on an annual subscription fee. And, to the maximum extent permitted by law, We shall not be liable for any loss, injury or damage of whatever kind caused in whole or in part by Use of the App or the Content, or by any failure, delay, interruption or otherwise of the provision of the App or the Content, or by Our failure to perform any of Our obligations under these Terms. The Content is provided to Us by third parties and We do not guarantee that details on the dates, times, locations and other details of events are accurate or valid. You are advised to check the details of events directly with the Hash organizations that are arranging them. Furthermore, with respect to run count information, We do not guarantee that run counts for any Harrier Central user are accurate beyond the information that is contained within the Harrier Central system.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(2) In no event shall We be liable to You for any special, indirect, incidental or consequential damages, including loss of profits and goodwill, business or business benefit.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(3) To the maximum extent permitted by law, We expressly exclude all representations, warranties, obligations, and liabilities in connection with the App, and the information provided therein.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(4) Links to third party websites, Hash House Harriers organizations and companies may appear on the App. We accept no responsibility for the availability, suitability, reliability or content of such third party websites and does not necessarily endorse the views expressed within them.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  GestureDetector(
                    onTap: backdoorTap,
                    child: Container(child: Text('\r\n6. Indemnity', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  ),
                  Text(
                    'You agree to defend, indemnify and hold harmless Harrier Central, its parent corporation, officers, directors, employees and agents, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney\'s fees) arising from: (i) your use of and access to the Harrier Central Service; (ii) your violation of any term of these Terms of Service; (iii) your violation of any third party right, including without limitation any copyright, property, or privacy right. This defense and indemnification obligation will survive these Terms of Service and your use of the Harrier Central Service.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(child: Text('\r\n7. General', style: headingStyle), margin: const EdgeInsets.only(top: 15)),
                  Container(
                      child: Text(
                        '(1) You may print and keep a copy of these Terms, which form the entire agreement between You and Us and supersede any other communications or advertising with respect to the App. These Terms may only be modified with Our prior written consent. We may alter or amend these Terms at any time, with immediate effect and without notice. By continuing to use the App after such alteration, you will be deemed to have accepted any amendment to these Terms.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(2) Subject to your compliance with these Terms of Service, InnoVet hereby grants you a non-exclusive, non-transferable license to download, install and Use the App on Your mobile device. This licence is in respect of Your Use of the App only, provided that: (i) your use of the Service as permitted is solely for your personal, non-commercial use; (ii) you will not duplicate, transfer, give access to, copy or distribute any part of the Service in any medium without InnoVet\'s prior written authorization; (iii) you will not attempt to reverse engineer, alter or modify any part of the Service; and (iv) you will otherwise comply with the terms and conditions of these Terms of Service.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(3) These Terms and their performance shall be governed by and construed in accordance with the laws of The Netherlands and the parties hereby submit to the exclusive jurisdiction of the courts of The Netherlands.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(4) You agree that because of the unique nature of the App and Our proprietary rights therein, a demonstrated breach of these Terms by you would irreparably harm Us and monetary damages would be inadequate compensation. Therefore, you agree that We shall be entitled to preliminary and permanent injunctive relief, as determined by any court of competent jurisdiction to enforce the provisions of these Terms.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(5) If any provision of these Terms is declared void, illegal, or unenforceable, the remainder of these Terms will be valid and enforceable to the extent permitted by applicable law. In such event, the parties agree to use their best efforts to replace the invalid or unenforceable provision by a provision that, to the extent permitted by the applicable law, achieves the purposes intended under the invalid or unenforceable provision.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(6) Any failure by any party to these Terms to enforce at any time any term or condition under these Terms will not be considered a waiver of that party\'s right thereafter to enforce each and every term and condition of these Terms.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20)),
                  Container(
                      child: Text(
                        '(7) Neither party will be responsible for delays resulting from circumstances beyond the reasonable control of such party, provided that the nonperforming party uses reasonable efforts to avoid or remove such causes of non-performance and continues performance hereunder with reasonable dispatch whenever such causes are removed.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                      margin: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 15)),
                  Text(
                    'If you feel that any materials appearing on the App are in objection to your copyright please contact us by e-mailing at connect@harriercentral.com providing full details of the nature of your complaint and the materials to which the complaint relates.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(
                    height: 50,
                    width: 30,
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
