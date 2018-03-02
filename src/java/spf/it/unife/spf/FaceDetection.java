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


public class FaceDetection {

  static{

    // System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

    // Explicit library loading
    System.load("/usr/local/lib/libopencv_java310.so");
  }

  public static String doFaceDet(byte[] img_stream, String res_abs_path) {
    Mat frame = Imgcodecs.imdecode(new MatOfByte(img_stream), Imgcodecs.IMREAD_UNCHANGED);
    CascadeClassifier faceDetector1 = new CascadeClassifier(res_abs_path+"/haarcascade_profileface.xml");
    if (faceDetector1.empty()) {
      faceDetector1.load(res_abs_path + "/haarcascade_profileface.xml");
    }
    // CascadeClassifier faceDetector2 = new CascadeClassifier(res_abs_path+"/haarcascade_frontalface_alt.xml");
    CascadeClassifier faceDetector2 = new CascadeClassifier(res_abs_path+"/haarcascade_frontalface_default.xml");
    if (faceDetector2.empty()) {
      faceDetector2.load(res_abs_path + "/haarcascade_frontalface_default.xml");
      // faceDetector2.load(res_abs_path + "/haarcascade_frontalface_alt.xml");    }
    if (faceDetector1.empty() || faceDetector2.empty()) {
      faceDetector1 = null;
      faceDetector2 = null;
      frame.release();
      System.out.println("faceDetector is empty");
      return "0";
    }

    MatOfRect faceDetections = new MatOfRect();
    MatOfRect faceDetections2 = new MatOfRect();
    // faceDetector1.detectMultiScale(frame, faceDetections, scaleFactor=1.3, minNeighbors=3, flags=0, minSize=new Size(), new maxSize=Size());
    // faceDetector2.detectMultiScale(frame, faceDetections2, scaleFactor=1.1, minNeighbors=3, flags=0, minSize=new Size(), new maxSize=Size());
    faceDetector1.detectMultiScale(frame, faceDetections, scaleFactor=1.2, minNeighbors=5, minSize=(20, 20));
    faceDetector2.detectMultiScale(frame, faceDetections2, scaleFactor=1.2, minNeighbors=5, minSize=(20, 20));


    // for (Rect rect : faceDetections.toArray()) {
    //   Imgproc.rectangle(frame, new Point(rect.x, rect.y),
    //       new Point(rect.x + rect.width, rect.y + rect.height),
    //       new Scalar(110, 220, 0), 4);
    // }


    // for (Rect rect : faceDetections2.toArray()) {
    //   Imgproc.rectangle(frame, new Point(rect.x, rect.y),
    //       new Point(rect.x + rect.width, rect.y + rect.height),
    //       new Scalar(0, 0, 255), 4);
    // }

    // String filenameOut = a + "-faceDetection.jpg";
    // Imgcodecs.imwrite(filenameOut, frame);
    // frame.release();

    int found = faceDetections.toArray().length + faceDetections2.toArray().length;
    faceDetections.release();
    faceDetections2.release();
    faceDetector1 = null;
    faceDetector2 = null;
    frame.release();

    return ""+found;
  }

}
