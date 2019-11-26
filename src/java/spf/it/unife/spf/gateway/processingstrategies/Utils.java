package it.unife.spf.gateway.processingstrategies;

import org.bytedeco.opencv.opencv_core.Mat;

import org.bytedeco.javacv.CanvasFrame;
import org.bytedeco.javacv.OpenCVFrameConverter;
import org.bytedeco.javacv.Java2DFrameUtils;

import javax.swing.*;


public class Utils {

    public static void display(Mat image, String caption) {
    // Create image window named "My Image".
    final CanvasFrame canvas = new CanvasFrame(caption, 1.0);

    // Request closing of the application when the image window is closed.
    canvas.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);

    // Convert from OpenCV Mat to Java Buffered image for display
    final OpenCVFrameConverter converter = new OpenCVFrameConverter.ToMat();
    // Show image on window.
    canvas.showImage(converter.convert(image));
  }
}
