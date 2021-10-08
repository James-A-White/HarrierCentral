// @dart=2.11
import 'package:harrier_central/imports.dart';

class VideoTutorialPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const VideoTutorialPage({Key key, this.title, this.videoUrl}) : super(key: key);

  final String title;
  final String videoUrl;

  @override
  VideoTutorialPageState createState() => VideoTutorialPageState();
}

class VideoTutorialPageState extends State<VideoTutorialPage> {
  VideoPlayerController _controller;
  ChewieController _chewieController;
  VoidCallback listener;

  @override
  void initState() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..addListener(listener)
      ..initialize().then((void _) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            aspectRatio: 1080 / 1920,
            autoPlay: true,
            looping: false,
          );
        });
      });
    // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    setState(() {});

    super.initState();
    listener = () {
      setState(() {});
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       _controller.value.isPlaying ? _controller.pause() : _controller.play().then((void _) {});
      //     });
      //   },
      //   child: Icon(
      //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //   ),
      // ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Container(
              margin: const EdgeInsets.all(20.0),
              child: _chewieController == null
                  ? Container()
                  : Chewie(
                      controller: _chewieController,
                    )),
        ),
      ),
    );
  }
}

// class VideoTutorialPageState extends State<VideoTutorialPage> {
//   VideoPlayerController _controller;
//   VoidCallback listener;

//   @override
//   void initState() {
//     _controller = VideoPlayerController.network(widget.videoUrl)
//       ..addListener(listener)
//       ..initialize().then((void _) {
//         _controller.play().then((void _){

//         });
//         // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
//         setState(() {});
//       });
//     super.initState();
//     listener = () {
//       setState(() {});
//     };
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _controller.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return

//     Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: themeAppBarBackground,
//         title: Text(
//           widget.title,
//           style: TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//           onPressed: () {
//             setState(() {
//               _controller.value.isPlaying
//                   ? _controller.pause()
//                   : _controller.play().then((void _){

//                   });
//             });
//           },
//           child: Icon(
//             _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//           ),
//         ),
//       body: Container(
//         decoration: Backgrounds.defaultHcBackground(),
//         height: MediaQuery.of(context).size.height,
//         child: Center(
//           child: Container(
//             margin: const EdgeInsets.all(20.0),
//             child: _controller.value.initialized
//                 ? AspectRatio(
//                     aspectRatio: _controller.value.aspectRatio,
//                     child: VideoPlayer(_controller),
//                   )
//                 : Container(),
//           ),
//         ),
//       ),
//     );
//   }
// }
