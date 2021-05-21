import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:ive_flutter_core/widgets/offline_mode_ribbon.dart';

import 'package:ive_flutter_core/util/connection.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:harrier_central/util/enums.dart';

class FaqPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const FaqPage({Key key}) : super(key: key);

  @override
  FaqPageState createState() => FaqPageState();
}

class FaqPageState extends State<FaqPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width),
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
              'FAQs',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            height: MediaQuery.of(context).size.height,
            child: const FaqPageContent(),
          ),
        ),
      ),
      OfflineModeRibbon(
        showRibbon: globalConnectionStatus == connectionStatus_notConnected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
      ),
    ]);
  }
}

class FaqPageContent extends StatefulWidget {
  const FaqPageContent({Key key}) : super(key: key);

  @override
  _FaqPageContentState createState() => _FaqPageContentState();
}

class _FaqPageContentState extends State<FaqPageContent> {
  TextStyle sectionStyle = const TextStyle(
      fontFamily: 'AvenirNextDemiBold',
      fontStyle: FontStyle.normal,
      color: Colors.orange,
      fontSize: 24.0,
      height: 1.2);

  TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 22.0,
      height: 1.2);

  TextStyle bodyStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 16.0,
      height: 1.2);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
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
                    'Frequently Asked Questions',
                    style: headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    height: 1.0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                  ),
                  Text('\r\n1. General', style: sectionStyle),
                  Text('\r\n1.1. What is the Hash House Harriers?',
                      style: headingStyle),
                  Text(
                    'The Hash House Harriers (H3) are social / athletic organizations throughout the world that engage in \'hound and hare\' style runs and usually end with a party when the run is finished. H3 groups are sometimes refered to as \'drinking clubs with a running problem\'. You can find H3 groups throughout the world; to find the H3 group nearest you, you can use the Harrier Central app or search the Web by putting your city name followed by \'Hash House Harriers\'',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n1.2. What is a Hash Kennel?', style: headingStyle),
                  Text(
                    'A Hash Kennel is a group of people (usually) in a specific geographic area who like to Hash. You can think of a Kennel as being like a club. Before Harrier Central, the best way to find Hash events (and their Kennels) in a given area was to search the Web. Now you have one easy place to go look to find Hash Kennels throughout the world and see when they run.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n1.3. What is Harrier Central?',
                      style: headingStyle),
                  Text(
                    'Harrier Central is an online service and mobile app to help you manage all aspects of your Hash Life and to allow Hash Kennel mismanagement to improve how they run their Hash organizations. It is intended to be a fun way to use technology to maximize your enjoyment of Hashing activities.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n1.4. What are Hash Points?', style: headingStyle),
                  Text(
                    'It\'s traditional for many Hash Kennels to record how many runs each Hasher has and to give rewards based on this. However, many Kennels have either lost track of run counts or never started in the first place. Hash Points are awarded for good Hash behavior (such as haring a run). Hash Points get reset at the beginning of each year to give newxomers a chance to achieve greatness quickly!',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n2. Your Data', style: sectionStyle),
                  Text('\r\n2.1. What personal data do we store?',
                      style: headingStyle),
                  Text(
                    'We have to hold certain data relating to you in order for us to provide you with a positive user experience. Currently, we hold the following personal information about you in our system:',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 5),
                    child: Text(
                      '• First Name\r\n• Last Name\r\n• Email address\r\n• Hash name (optionl)\r\n• Profile photo (optional) or avatar\r\n• Run attendence information\r\n• Facebook ID (optional)\r\n• Phone number (optional)\r\n• Friend list (optional)',
                      style: bodyStyle,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  Text(
                      '\r\n2.2. Do we share our information about you with any other parties?',
                      style: headingStyle),
                  Text(
                    'No! The only way to access information in Harrier Central is through our mobile app and (eventually) through the user interface of our website. Harrier Central data is not shared with any third parties and is not accessible to third parties through APIs (Application Programmer Interfaces). Your run attendence information is available to participating House House Harriers organizations through the App and Website.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n2.3. Do you share data with Facebook?',
                      style: headingStyle),
                  Text(
                    'No. Our system has a one-way data exchange with Facebook that allows us to automatically download and update information on Hash runs held in Facebook events. We do not share any of our data with Facebook (or any other third party provider).',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                      '\r\n2.4. Can I have my information deleted from the Harrier Central service?',
                      style: headingStyle),
                  Text(
                    'Yes. Simply send a request to connect@harriercentral.com and we will remove your information from our system. Some information about your activities will be retained to enable Hash organizations to keep accurate accounts of runs (such as the fact that a payment was made at a run). In these cases, your information will be completely anonymized.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n2.5. Where is my data stored?',
                      style: headingStyle),
                  Text(
                    'Your data is safely stored in Microsoft Azure data centers located in The Netherlands and Ireland. When we end our beta test period and go into full production, we plan to replicate our data in the United States and Shanghai to provide superior global performance for our users.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n3. App usage and Membership', style: sectionStyle),
                  Text('\r\n3.1. What can I get for free?',
                      style: headingStyle),
                  Text(
                    'Basic run information such as dates, times and locations of runs will always be provided for free.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n3.2. What is Membership?', style: headingStyle),
                  Text(
                    'We offer enhanced services to our users, including keeping track of your run counts and, over time, many other exciting features. Once we are out of our beta test period, these will be made available for a small annual membership fee that is (not coincidentally) about the same as the cost of buying us a beer. We are exploring ways to keep the cost as low as possible, but we also feel like the cost of our service will be well justified by the value you receive from it.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n3.3. When will you start charging Membership fees?',
                      style: headingStyle),
                  Text(
                    'We will start charging membership fees once we are out of our beta period. If you sign up during the beta, you will receive one year of free membership as our way of thanking you for your support.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n3.4. How do I sign up?', style: headingStyle),
                  Text(
                    'Currently, the app is free while we are in beta. Once we release the app for general availability, you will be able to enjoy enhanced features through an in-app purchase option.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n3.5. Why can\'t Harrier Central be free?',
                      style: headingStyle),
                  Text(
                    'Nothing in life is truly free. In order to provide the Harrier Central service, we have our own costs to cover, including software development and maintenance, cloud service provision and administrative costs. There are generally three ways companies cover these costs: 1) by selling your private data to third parties (the Facebook & Google models), 2) by putting advertisements in the app, or 3) by charging a fee directly to users. Above all, we value your privacy and we aim to provide the best user experience, uninterrupted by ads. Accordingly, we have chosen to charge a fee for our services. We welcome your comments on our business model and fee structure.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                      '\r\n4. Information for Hash House Harriers organizations',
                      style: sectionStyle),
                  Text('\r\n4.1. How can our Hash Kennel join?',
                      style: headingStyle),
                  Text(
                    'To create a Kennel account, please contact us at connect@harriercentral.com. We do not yet have an interface that allows you to do this directly.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                      '\r\n4.2. Is there a fee for our Kennel to be on the app?',
                      style: headingStyle),
                  Text(
                    'Currently, no there is not. However, in the future, we may have to charge an annual fee to Hash Kennels to help us offset our operations costs. We are evaluating different business models and will have more information on fees when our beta period is finished. We do guarantee, however, that Hash Kennels that join during our beta period will not be charged any fees for the first three years that the Harrier Central service is in full production.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                      '\r\n4.3. What is Facebook integration and how does it help us?',
                      style: headingStyle),
                  Text(
                    'Harrier Central has the ability to automatically download run information from Facebook events into the Harrier Central Service. This is a huge benefit for you because it means you do not have to enter the information more than once. We currently use a 5-minute polling mechanism, so any changes you make to your run event in Facebook will be automatically incorporated into the Harrier Central Service within 5 minutes.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  Text('\r\n5. Other', style: sectionStyle),
                  Text(
                      '\r\n5.1. I have other questions, how can I get them answered?',
                      style: headingStyle),
                  Text(
                    'The best way to get your questions answered is to contact us at connect@harriercentral.com. We\'d be delighted to hear from you, get your thoughts on our App and Service and answer any questions you might have. We hope you enjoy Harrier Central!',
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
