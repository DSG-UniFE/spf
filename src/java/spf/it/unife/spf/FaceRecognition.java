package it.unife.spf;

import java.io.IOException;
import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.MatOfRect;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;        // for opencv3.0.0
import org.opencv.imgcodecs.Imgcodecs;      // for opencv3.0.0
import org.opencv.objdetect.CascadeClassifier;
import org.opencv.core.MatOfByte;


public class FaceRecognition {

  static{

    // System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

    // Explicit library loading
    System.load("/usr/local/lib/libopencv_java310.so");
  }

  public static String doFaceRec(byte[] img_stream, String res_abs_path) {
    Mat frame = Imgcodecs.imdecode(new MatOfByte(img_stream), Imgcodecs.IMREAD_UNCHANGED);
    CascadeClassifier faceDetector1 = new CascadeClassifier(res_abs_path+"/haarcascade_profileface.xml");
    faceDetector1.load(res_abs_path+"/haarcascade_profileface.xml");
     if (faceDetector1.empty()) {
      System.out.println("faceDetector is empty");
      return "0";
    }

    MatOfRect faceDetections = new MatOfRect();
    faceDetector1.detectMultiScale(frame, faceDetections, 1.3, 3, 0, new Size(), new Size());

    int found = faceDetections.toArray().length;
    faceDetections.release();
    frame.release();

    return ""+found;
  }

}
