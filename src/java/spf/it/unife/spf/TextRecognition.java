package it.unife.spf;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.io.FileOutputStream;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.RotatedRect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.core.Core;
import org.opencv.imgproc.Imgproc;    // for opencv3.0.0
import org.opencv.imgcodecs.Imgcodecs;  // for opencv3.0.0
import net.sourceforge.tess4j.*; //import Tesseract java interface
import net.sourceforge.tess4j.util.LoadLibs;
import java.io.File;

public class TextRecognition {

  static{

    //System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
    System.load("/usr/local/lib/libopencv_java310.so");

  }

  public static String doOCR(byte[] img_stream) {

    String result = "";
    //File imageFile = new File(file);
    File tempFile;
<<<<<<< HEAD
    try{
    tempFile = File.createTempFile("ocr-temp-image", ".png", null);
    FileOutputStream fos = new FileOutputStream(tempFile);
    fos.write(img_stream);
    fos.flush();
    fos.close();

     //File imageFile = new File("water.jpg");
    File imageFile = new File(tempFile.getAbsolutePath());

    Tesseract instance = new Tesseract();
    instance.setDatapath("../../../resources");
    result = instance.doOCR(imageFile);
    System.out.println("--TESSERACT RESULT : \n"+result+"\n");
    imageFile.delete();
    tempFile.delete();
=======
    try {
        tempFile = File.createTempFile("ocr-temp-image", ".png", null);
        FileOutputStream fos = new FileOutputStream(tempFile);
        fos.write(img_stream);
        fos.flush();
        fos.close();

         //File imageFile = new File("water.jpg");
        File imageFile = new File(tempFile.getAbsolutePath());

        Tesseract instance = new Tesseract();
        instance.setDatapath(LoadLibs.extractTessResources("tessdata").getAbsolutePath());
        result = instance.doOCR(imageFile);
        // System.out.println("Result = " + result);
        imageFile.delete();
        tempFile.delete();
>>>>>>> 751a86d137f372a06aff7bc02eecffe981b47f2c
    }
    catch(IOException e) {
      e.printStackTrace();
      System.exit(1);
    }
    catch(TesseractException e) {
      System.err.println(e.getMessage());
    }

    return result;
  }

  /* Try to improve previous function with further processing on the input image..*/

  public static String doOCR_2(String file) {
    Mat source = Imgcodecs.imread(file, 0);
    Mat destination = new Mat(source.rows(), source.cols(), source.type());
    Imgproc.threshold(source, destination, 0, 255, Imgproc.THRESH_OTSU);

    Imgcodecs.imwrite("text-recognition-threshold.jpg", destination);
    source.release();
    int white = Core.countNonZero(destination);
    int black = (int) (destination.size().area() - white);

    if (white > black) {
      Core.bitwise_not(destination, destination);
    }
    Imgcodecs.imwrite("text-recognition-treshZero.jpg", destination);

    Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_CROSS, new Size(3, 3));
    Mat dilated = new Mat();
    Imgproc.dilate(destination, dilated, kernel, new Point(-1, -1), 30);

    destination.release();
    kernel.release();
    Imgcodecs.imwrite("text-recognition-dilated.jpg", dilated);

    ArrayList<MatOfPoint> contours = new ArrayList<MatOfPoint>();
    Mat hierarchy = new Mat();
    Imgproc.findContours(dilated, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE);

    for (int i = 0; i < contours.size(); i++) {
      Imgproc.drawContours(dilated, contours, i, new Scalar(255, 0, 0), 2, 8, hierarchy, 0, new Point());
    }
    hierarchy.release();
    Imgcodecs.imwrite("text-recognition-contours.jpg", dilated);
    dilated.release();

    ArrayList<RotatedRect> areas = new ArrayList<RotatedRect>();
    for (MatOfPoint contour : contours) {
      // Find it's rotated rect
      RotatedRect box = Imgproc.minAreaRect(new MatOfPoint2f(contour.toArray()));

      // Discard very small boxes
      if (box.size.width < 50 || box.size.height < 50) {
        continue;
      }
      double proportion;

      if (box.angle < -45.0) {
        proportion = box.size.height / box.size.width;
      }
      else {
        proportion = box.size.width / box.size.height;
      }

      if (proportion < 2) {
        continue;
      }

      areas.add(box);
    }

    int i = 1;
    String response = "";
    System.out.println(areas.size());
    for (RotatedRect rect : areas) {
      Mat img = Imgcodecs.imread(file, 0);
      Rect brect = rect.boundingRect();

      Imgproc.rectangle(img, new Point(brect.x, brect.y),
          new Point(brect.x + brect.width, brect.y + brect.height), new Scalar(110, 220, 0), 5);
      System.out.println(i);
      System.out.println(img.height());
      System.out.println(img.width());

      if (brect.x < 0 || brect.y < 0) {
        continue;
      }

      //TODO : maybe we need to call a.release() at the end of function
      Mat a = img.submat(brect);
      System.out.println("submat");
      Imgcodecs.imwrite("part-" + i + ".jpg", a);

      Mat sub_image = Imgcodecs.imread("part-" + i + ".jpg", 0);
      Mat adaptive = new Mat();
      Imgproc.adaptiveThreshold(sub_image, adaptive, 255, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
          Imgproc.THRESH_BINARY, 11, 2);
      // PSM value from tesseract manual: 8 = Treat the image as a single word.
      executeCommand("tesseract " + "part-" + i + ".jpg" + " output-" + "part-" + i + " " + "-l eng -psm 8");

      Path part = Paths.get("./", "output-" + "part-" + i + ".txt");
      try {
        String t = new String(Files.readAllBytes(part));
        System.out.println(t);
        response += t + " ";
      }
      catch (IOException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
      i++;
      sub_image.release();
      adaptive.release();
      img.release();
    }

    System.out.println(response);
    return response;
  }

  public static String executeCommand(String command) {
    StringBuffer output = new StringBuffer();
    Process p;
    try {
      p = Runtime.getRuntime().exec(command);
      p.waitFor();
      BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));

      String line = "";
      while ((line = reader.readLine()) != null) {
        output.append(line + "\n");
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }

    return output.toString();
  }

}
