package it.unife.spf;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.core.RotatedRect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;

import org.opencv.core.Core;
import org.opencv.imgproc.Imgproc; 		// for opencv3.0.0
import org.opencv.imgcodecs.Imgcodecs; 	// for opencv3.0.0


public class TextRecognition {

	static {
		System.loadLibrary("opencv_java300");
	}
	
	public static String doOCR(String file) {
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
