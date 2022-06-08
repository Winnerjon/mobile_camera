import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class CameraPage extends StatefulWidget {
  static const String id = "/camera_page";
  final List<CameraDescription>? cameras;

  const CameraPage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController cameraController;
  bool isRearCameraSelected = true;
  double minAvailableZoom = 1.0;
  double maxAvailableZoom = 1.0;
  double currentZoomLevel = 1.0;


  Future initCamera(CameraDescription cameraDescription) async {
    cameraController = CameraController(cameraDescription, ResolutionPreset.high);
    print(widget.cameras!.length);

    try {
      await cameraController.initialize().then((_) {
        setState(() {});
      });

      await Future.wait([
        cameraController
            .getMaxZoomLevel()
            .then((value) => maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => minAvailableZoom = value),
      ]);

    } on CameraException catch (e) {
      debugPrint("camera error $e");
    }
  }

  Future takePicture() async {
    if(!cameraController.value.isInitialized) return null;
    if(cameraController.value.isTakingPicture) return null;

    try {
      await cameraController.setFlashMode(FlashMode.off);
      XFile picture = await cameraController.takePicture();
      print(picture.path);


    } on CameraException catch(e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCamera(widget.cameras![0]);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = cameraController;

    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      initCamera(controller.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Center(child: _cameraPreviewWidget()),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Spacer(),
                      _cameraControlWidget(context),
                      _cameraToggleRowWidget(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (!cameraController.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: 1 / cameraController.value.aspectRatio,
      child: GestureDetector(
        onScaleStart: (ScaleStartDetails details) {
          print(details);

          minAvailableZoom = currentZoomLevel;
          setState(() {});
        },

        onScaleUpdate: (ScaleUpdateDetails details) async {
          print(details);
          currentZoomLevel = minAvailableZoom * details.scale;
          setState(() {});
        },

        onScaleEnd: (ScaleEndDetails details) async {
          print(details);
          minAvailableZoom = currentZoomLevel;
          setState(() {});
          await cameraController.setZoomLevel(minAvailableZoom);
        },
        child: Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.diagonal3(Vector3(currentZoomLevel,currentZoomLevel,currentZoomLevel)),
            child: CameraPreview(cameraController),
        ),
      ),
    );
  }

  Widget _cameraControlWidget(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Icons.camera,
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              onPressed: takePicture,
            )
          ],
        ),
      ),
    );
  }

  Widget _cameraToggleRowWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: MaterialButton(
          child: Icon(CupertinoIcons.arrow_2_circlepath,color: Colors.white,size: 55,),
          onPressed: (){
            setState(() => isRearCameraSelected = !isRearCameraSelected);
            initCamera(widget.cameras![isRearCameraSelected ? 0 : 1]);
          },
        ),
      ),
    );
  }
}
