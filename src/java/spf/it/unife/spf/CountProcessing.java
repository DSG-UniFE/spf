package it.unife.spf;

import java.io.File;
import java.io.IOException;
import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.MatOfRect;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;        // for opencv3.0.0
import org.opencv.objdetect.CascadeClassifier;
import org.opencv.imgcodecs.Imgcodecs;      // for opencv3.0.0
import org.opencv.core.MatOfByte;


public class CountProcessing {

  static{
    
    //System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
    System.load("/usr/local/lib/libopencv_java310.so");

  }

  public static String CountObject(byte[] img_stream, String res_abs_path) {
    try {
    
      CascadeClassifier objDetector = new CascadeClassifier(res_abs_path+"/cars.xml");
      objDetector.load(res_abs_path+"/cars.xml");
      
      Mat image = Imgcodecs.imdecode(new MatOfByte(img_stream), Imgcodecs.IMREAD_UNCHANGED);
    
      MatOfRect objDetections = new MatOfRect();
      objDetector.detectMultiScale(image, objDetections);
      objDetector.detectMultiScale(image, objDetections, 1.2, 3, 0, new Size(), new Size());
      for (Rect rect : objDetections.toArray()) {
        if (rect.x > 50 && rect.y > 50)
          Imgproc.rectangle(image, new Point(rect.x, rect.y),
              new Point(rect.x + rect.width, rect.y + rect.height), new Scalar(0, 0, 255), 4);
      }
      //Imgcodecs.imwrite("recognized-" + name, image);

      image.release();
      return "" + objDetections.toArray().length;
    }
    catch (Exception e) {
      System.out.println("Eccezione Core Processing: " + e);
      return "";
    }
  }

}
