package it.unife.spf;

import java.awt.image.BufferedImage;
import org.bytedeco.opencv.opencv_core.*;
import org.opencv.imgcodecs.Imgcodecs;
//import org.opencv.imgcodecs.Imgcodecs;


public class ImageDiff {

/*	static
	{
		System.load("/usr/local/Cellar/opencv/4.0.1/share/java/opencv4/opencv-401.jar");
	}
*/
  public static double calculateDiff(byte[] img_stream_1, byte[] img_stream_2, int step) {
    try {
	    if (((img_stream_1 == null) || (img_stream_1.length == 0)) &&
					((img_stream_2 == null) || (img_stream_2.length == 0))) {
	    	return 0.0;
			}
	    if ((img_stream_1 == null) || (img_stream_1.length == 0) ||
					(img_stream_2 == null) || (img_stream_2.length == 0)) {
	    	return 1.0;
	    }

	    Mat m1 = new Mat(img_stream_1);
	    Mat m2 = new Mat(img_stream_2);

	    BufferedImage img1 = mat2Img(m1);
	    BufferedImage img2 = mat2Img(m2);
		m1.release();
		m2.release();
		m1.close();
		m2.close();

	    // Cut images if their dimensions are not multiple of 'step'
	    int width1 = img1.getWidth(null);
	    while (width1 % step > 0)
	      width1--;
	    int width2 = img2.getWidth(null);
	    while (width2 % step > 0)
	      width2--;
	    int height1 = img1.getHeight(null);
	    while (height1 % step > 0)
	      height1--;
	    int height2 = img2.getHeight(null);
	    while (height2 % step > 0)
	      height2--;

	    if ((width1 != width2) || (height1 != height2)) {
	      System.err.println("Error: Images dimensions mismatch");
	      return 1.0;
	    }

	    double diff = 0;
	    for (int y = 0; y < height1; y += step) {
	      for (int x = ((y / step) % 2 == 0) ? 0 : step / 2; x < width1; x += step) {
	        int rgb1 = img1.getRGB(x, y);
	        int rgb2 = img2.getRGB(x, y);

	        int r1 = (rgb1 >> 16) & 0xff;
	        int g1 = (rgb1 >> 8) & 0xff;
	        int b1 = (rgb1) & 0xff;
	        int r2 = (rgb2 >> 16) & 0xff;
	        int g2 = (rgb2 >> 8) & 0xff;
	        int b2 = (rgb2) & 0xff;

	        // Get luminance
	        double lum1 = (0.299 * r1 + 0.587 * g1 + 0.114 * b1) / 255.0;
	        double lum2 = (0.299 * r2 + 0.587 * g2 + 0.114 * b2) / 255.0;

	        // Use square power to give more importance to big differences
	        // in luminance
	        diff += (lum1 - lum2) * (lum1 - lum2);
	      }
	    }

	    // The number of pixels processed is X * Y minus 1 for each odd line
	    // (where we begin from 4)
	    int xPixels = width1 / step;
	    int yPixels = height1 / step;
	    int nPixels = (xPixels * yPixels) - (yPixels / 2);

	    return (diff / nPixels);
		}
		catch (Exception e) {
      System.out.println("Eccezione Core Processing: " + e);
      return -1;
    }
  }


  // public static String calculateDiff2(String file1, String file2, int step) {
  //   System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  //   System.out.println("1_ " + System.currentTimeMillis());
  //   Mat mat1 = Imgcodecs.imread(file1, 0);
  //   System.out.println("2_ " + System.currentTimeMillis());
  //   Mat mat2 = Imgcodecs.imread(file2, 0);
  //   System.out.println("3_ " + System.currentTimeMillis());
  //   BufferedImage img1 = mat2Img(mat1);
  //   BufferedImage img2 = mat2Img(mat2);

  //   System.out.println("4_ " + System.currentTimeMillis());
  //   int width1 = img1.getWidth(null);
  //   int width2 = img2.getWidth(null);
  //   int height1 = img1.getHeight(null);
  //   int height2 = img2.getHeight(null);
  //   if ((width1 != width2) || (height1 != height2)) {
  //     System.err.println("Error: Images dimensions mismatch");
  //     System.exit(1);
  //   }

  //   System.out.println("" + System.currentTimeMillis());
  //   long diff = 0;
  //   for (int y = 0; y < height1; y += step) {
  //     for (int x = 0; x < width1; x += step) {
  //       int rgb1 = img1.getRGB(x, y);
  //       int rgb2 = img2.getRGB(x, y);
  //       int r1 = (rgb1 >> 16) & 0xff;
  //       int g1 = (rgb1 >> 8) & 0xff;
  //       int b1 = (rgb1) & 0xff;
  //       int r2 = (rgb2 >> 16) & 0xff;
  //       int g2 = (rgb2 >> 8) & 0xff;
  //       int b2 = (rgb2) & 0xff;
  //       diff += Math.abs(r1 - r2);
  //       diff += Math.abs(g1 - g2);
  //       diff += Math.abs(b1 - b2);
  //     }
  //   }
  //   double n = width1 * height1 * 3;
  //   double p = diff / n / 255.0;
  //   System.out.println("diff percent: " + (p * 100.0));

  //   return "" + p * 100.0;
  // }

  public static BufferedImage mat2Img(Mat in) {

        BufferedImage out;
        int type;
        byte[] data = new byte[320 * 240 * (int)in.elemSize()];

        if (in.channels() == 1) {
            type = BufferedImage.TYPE_BYTE_GRAY;
        }
        else {
            type = BufferedImage.TYPE_3BYTE_BGR;
        }
        out = new BufferedImage(320, 240, type);

        out.getRaster().setDataElements(0, 0, 320, 240, in.asBuffer());
        return out;
    }

}
