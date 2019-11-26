package it.unife.spf;


import it.unife.spf.gateway.processingstrategies.Utils;
import org.bytedeco.opencv.opencv_core.*;
import org.bytedeco.opencv.opencv_objdetect.CascadeClassifier;

import org.bytedeco.javacv.CanvasFrame;
import org.bytedeco.javacv.OpenCVFrameConverter;
import org.bytedeco.javacv.Java2DFrameUtils;


import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.nio.ByteBuffer;

import static org.bytedeco.opencv.global.opencv_imgproc.rectangle;
import static org.bytedeco.opencv.helper.opencv_imgcodecs.cvSaveImage;

public class CountProcessing {


  public static String countObject(byte[] img_stream, String res_abs_path) {
    try {

      CascadeClassifier objDetector = new CascadeClassifier(res_abs_path + "/cars.xml");
      objDetector.load(res_abs_path + "/cars.xml");
      if (objDetector.empty()) {
        objDetector.load(res_abs_path + "/cars.xml");
      }

      if (objDetector.empty()) {
        objDetector.close();
        return "-1";
      }
      // before with standard opencv
      //Mat image = Imgcodecs.imdecode(new MatOfByte(img_stream), Imgcodecs.IMREAD_UNCHANGED);

      // init BufferedImage from byte_array
      BufferedImage buf = ImageIO.read(new ByteArrayInputStream(img_stream));
      /*
      ColorModel model = buf.getColorModel();
      int height = buf.getHeight();
      int width = buf.getWidth();
      */
      Mat image = Java2DFrameUtils.toMat(buf);

      RectVector detectedRect = new RectVector();
      int detected = 0;

      objDetector.detectMultiScale(image, detectedRect);
      objDetector.detectMultiScale(image, detectedRect, 1.2, 3, 0, new Size(), new Size());
      System.out.println("Detected " + detectedRect.size());
      detected += detectedRect.size();

      for (Rect rect : detectedRect.get()) {
        if (rect.x() > 50 && rect.y() > 50)
          rectangle(image, rect, new Scalar(0, 0, 255, 1));
          //Imgproc.rectangle(image, new Point(rect.x(), rect.y()),
                  //new Point(rect.x + rect.width, rect.y + rect.height), new Scalar(0, 0, 255), 4);
      }

      Utils.display(image, "Cars");
      //Imgcodecs.imwrite("recognized-obj"  , image);

      image.close();
      objDetector.close();
      return "" + detected;
    }
    catch (Exception e) {
      System.err.println("Exception: " + e);
      e.printStackTrace();
      return "-1";
    }
  }

}
