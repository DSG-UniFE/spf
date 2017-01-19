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
    
    //System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
    
    //Explicit library loading
    System.load("/usr/local/lib/libopencv_java310.so");
  }

  public static String doFaceRec(byte[] img_stream, String res_abs_path) {
    
    System.out.println("Inside doFaceRec java method..\n");
    
    Mat frame = Imgcodecs.imdecode(new MatOfByte(img_stream), Imgcodecs.IMREAD_UNCHANGED);
    
    CascadeClassifier faceDetector1 = new CascadeClassifier(res_abs_path+"/haarcascade_profileface.xml");
    System.out.println(faceDetector1.load(res_abs_path+"/haarcascade_profileface.xml"));
    CascadeClassifier faceDetector2 = new CascadeClassifier(res_abs_path+"/haarcascade_frontalface_alt.xml");
    System.out.println(faceDetector2.load(res_abs_path+"/haarcascade_frontalface_alt.xml"));
    
    MatOfRect faceDetections = new MatOfRect();
    MatOfRect faceDetections2 = new MatOfRect();
    faceDetector1.detectMultiScale(frame, faceDetections, 1.3, 3, 0, new Size(), new Size());
    faceDetector2.detectMultiScale(frame, faceDetections2, 1.1, 3, 0, new Size(), new Size());

    for (Rect rect : faceDetections.toArray()) {
      Imgproc.rectangle(frame, new Point(rect.x, rect.y),
          new Point(rect.x + rect.width, rect.y + rect.height),
          new Scalar(110, 220, 0), 4);
    }
    faceDetections.release();

    for (Rect rect : faceDetections2.toArray()) {
      Imgproc.rectangle(frame, new Point(rect.x, rect.y),
          new Point(rect.x + rect.width, rect.y + rect.height),
          new Scalar(0, 0, 255), 4);
    }
    faceDetections2.release(); 
    frame.release();
    
    //String filenameOut = a + "-facerecognition.jpg";
    //Imgcodecs.imwrite(filenameOut, frame);
    //frame.release();

    int found = faceDetections.toArray().length + faceDetections2.toArray().length;
    return "" + found;
  }

}
