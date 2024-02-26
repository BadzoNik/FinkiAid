import 'package:flutter/material.dart';

class FullScreenImageView extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _FullScreenImageViewState createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  double _scale = 1.0;
  late TransformationController viewTransformationController;

  @override
  void initState() {
    super.initState();
    viewTransformationController = TransformationController();
    setInitialScale();
  }

  void setInitialScale() {
    final zoomFactor = 0.5; // Adjust this value to set the initial zoom level
    viewTransformationController.value = Matrix4.identity()..scale(zoomFactor);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewing Image'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.cyan.shade200, Colors.cyan.shade200],
            ),
          ),
        ),
      ), // Add an app bar if needed
      body: Center(
        child: Container(
          color: Colors.white, // Set background color to black to fill any white space
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            panEnabled: true,
            transformationController: viewTransformationController,
            scaleEnabled: true,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(12.0),
            minScale: 0.5,
            maxScale: 18.0,
            child: Image.network(
              widget.imageUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return const Text('Error loading image');
              },
              fit: BoxFit.cover, // Ensure the image fills the entire container
            ),
          ),
        ),
      )
    );
  }
}
