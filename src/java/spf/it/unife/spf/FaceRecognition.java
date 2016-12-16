package it.unife.spf;

import java.io.IOException;

import org.opencv.core.Mat;
import org.opencv.core.MatOfRect;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;        // for opencv3.0.0
import org.opencv.imgcodecs.Imgcodecs;      // for opencv3.0.0
import org.opencv.objdetect.CascadeClassifier;


public class FaceRecognition {

  public static String doFaceRec(String a) {
    Mat frame = Imgcodecs.imread(a, 0);
    CascadeClassifier faceDetector1 = new CascadeClassifier("haarcascade_profileface.xml");
    System.out.println(faceDetector1.load("haarcascade_profileface.xml"));
    CascadeClassifier faceDetector2 = new CascadeClassifier("haarcascade_frontalface_alt.xml");
    System.out.println(faceDetector2.load("haarcascade_frontalface_alt.xml"));
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

    String filenameOut = a + "-facerecognition.jpg";
    Imgcodecs.imwrite(filenameOut, frame);
    frame.release();

    int found = faceDetections.toArray().length + faceDetections2.toArray().length;
    return "" + found;
  }

}
