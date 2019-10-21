package it.unife.spf;

import org.bytedeco.javacpp.BytePointer;
import org.bytedeco.opencv.opencv_core.IplImage;
import org.bytedeco.opencv.opencv_core.Mat;
import org.bytedeco.opencv.opencv_core.Rect;
import org.bytedeco.opencv.opencv_core.RectVector;
import org.bytedeco.opencv.opencv_objdetect.CascadeClassifier;

import org.opencv.core.CvType;

import org.bytedeco.javacv.CanvasFrame;
import org.bytedeco.javacv.OpenCVFrameConverter;
import org.bytedeco.javacv.Java2DFrameUtils;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.image.BufferedImage;
import java.awt.image.ColorModel;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.InputStream;
import java.nio.ByteBuffer;

import static org.bytedeco.opencv.global.opencv_core.CV_8UC1;
import static org.bytedeco.opencv.global.opencv_core.cvMat;
import static org.bytedeco.opencv.global.opencv_imgcodecs.*;


public class FaceDetection {

  /*static void display(Mat image, String caption) {
    // Create image window named "My Image".
    final CanvasFrame canvas = new CanvasFrame(caption, 1.0);

    // Request closing of the application when the image window is closed.
    canvas.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);

    // Convert from OpenCV Mat to Java Buffered image for display
    final OpenCVFrameConverter converter = new OpenCVFrameConverter.ToMat();
    // Show image on window.
    canvas.showImage(converter.convert(image));
  }*/

  public static String doFaceDet(byte[] img_stream, String res_abs_path) {
    try {

      CascadeClassifier fd1 = new CascadeClassifier(res_abs_path+"/haarcascade_frontalface_alt.xml");
      if (fd1 == null) {
        return -1 + "";
      }

      if (fd1.empty()) {
        fd1.load(res_abs_path + "/haarcascade_frontalface_alt.xml");
      }

      CascadeClassifier fd2 = new CascadeClassifier(res_abs_path + "/haarcascade_frontalface_default.xml");
      if (fd1 == null) {
        return -1 + "";
      }

      if (fd2.empty()) {
        fd2.load(res_abs_path + "/haarcascade_frontalface_default.xml");
      }

      // init BufferedImage from byte_array
      BufferedImage buf = ImageIO.read(new ByteArrayInputStream(img_stream));
      ColorModel model = buf.getColorModel();
      int height = buf.getHeight();
      int width = buf.getWidth();
      Mat frame = Java2DFrameUtils.toMat(buf);

      //display(frame, "Loaded image");

      if (fd1.empty() || fd2.empty()) {
        fd1 = null;
        frame.release();
        System.err.println("fd1 is empty");
        return "-1";
      }

      // apply first detector
      RectVector rv1 = new RectVector();
      fd1.detectMultiScale(frame, rv1);
      
      // apply second detector
      RectVector rv2 = new RectVector();
      fd2.detectMultiScale(frame, rv2);

      long found = rv1.size() + rv2.size();
      rv1.clear();
      rv1.close();
      rv2.clear();
      rv2.close();

      fd1 = null;
      fd2 = null;
      // release resources
      frame.release();
      
      return "Found " + found;
    }
    catch (Exception e) {
      System.err.println("Exception: " + e);
      e.printStackTrace();
      return "-1";
    }
  }

}
