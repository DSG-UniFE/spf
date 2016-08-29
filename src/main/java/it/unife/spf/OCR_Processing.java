package it.unife.spf;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
//import javax.imageio.ImageIO;
import java.awt.image.*;
//import javax.imageio.ImageIO
//import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;
import org.opencv.photo.Photo;

//import net.sourceforge.tess4j.Tesseract;
//import net.sourceforge.tess4j.Tesseract1;
//import net.sourceforge.tess4j.TesseractException;

public class OCR_Processing {

    static{
              System.loadLibrary( "opencv_java310" );

    }

    public static String performOCR_String2Text(File x) throws IOException 
    {
    	
    	System.out.println("START: Esecuzione performOCR_String2Text\n\n");
      
          
        File input = x;      //da  usare CON filtro in grigio mettendo il risultato output
        Mat imagetoread = Imgcodecs.imread(input.getAbsolutePath());
        byte[] imageinbytes = new byte[(int) (imagetoread.total() * imagetoread.channels())];
        imagetoread.get(0, 0, imageinbytes);
        /*
        BufferedImage image = ImageIO.read(input);	
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        baos.flush();*/
        Size s = imagetoread.size();
        //byte[] data = baos.toByteArray();
        
        Mat mat = new Mat((int)s.height,(int)s.width, CvType.CV_8UC3);
        mat.put(0, 0, imageinbytes);
         
         
        Mat mat1 = new Mat((int)imagetoread.height(),(int) imagetoread.width(),CvType.CV_8UC1);
        Imgproc.cvtColor(mat, mat1, Imgproc.COLOR_RGB2GRAY);
        byte[] data1 = new byte[mat1.rows() * mat1.cols() * (int)(mat1.elemSize())];
        mat1.get(0, 0, data1);
        BufferedImage image1 = new BufferedImage(mat1.cols(),mat1.rows(), BufferedImage.TYPE_BYTE_GRAY);
        image1.getRaster().setDataElements(0, 0, mat1.cols(), mat1.rows(), data1);
        //File output = new File("grayscale.jpg");
        //File output = new File("src/pipeline/outputImg/"+Global.getJPGNameFile()+"grayscale.jpg");
                       
        //ImageIO.write(image1, "jpg", output);
       	System.out.println("\n\n START: Motore tesseract-ocr");
        executeCommand("tesseract "+ x.getName()+" output.txt -l eng -psm 3");
        return "1";
        /*
         * try {
                Tesseract1 instance = new Tesseract1(); 
                result = instance.doOCR(output); ////file da elaborare

            } catch (TesseractException e) {
                System.err.println(e.getMessage());
            } 
         * */
         	
          }
    	
    
    public static String performOCR(String filename) throws IOException 
    {


	    String shortname = filename.substring(0,filename.length()-4);
        
        //System.out.println("Library Loaded.\n");
        Mat imagetif = Imgcodecs.imread(filename);
        //System.out.println("File Loaded.\n");
        Mat out = new Mat();
        //System.out.println("Denoising...\n");
        Photo.fastNlMeansDenoising(imagetif, out);
        imagetif.release();

        //System.out.println("Denoised!\n");
        System.out.println("Writing "+shortname+"-denoised image...\n");
        Imgcodecs.imwrite(shortname+"-denoised.jpg", out);
        out.release();

        Mat gray = Imgcodecs.imread(shortname+"-denoised.jpg",0);
        Mat adaptive = new Mat();
        //System.out.println("Adapting threshold...\n");
        Imgproc.adaptiveThreshold(gray, adaptive, 255, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 11, 2);
        gray.release();
        System.out.println("Writing "+shortname+"-threshold image...\n");
        Imgcodecs.imwrite(shortname+"-threshold.jpg", adaptive);
        adaptive.release();
        //Imgproc.resize(adaptive, adaptive, dsize);
        
        /*
         * CRASH DELLA JVM:
         * 
         * Errore:
         * 
         * SIGSEGV: Avviene un segmentation fault e non è possibile effettuare
         * un core dump dei dati.
         * 
         * Ancora da risolvere
         * 
        try {
            //Tesseract1 instance = new Tesseract1();
            Tesseract instance1 = new Tesseract();
            System.out.println("CHECK_1");
            String result = instance1.doOCR(new File(shortname+"-threshold.jpg")); ////file da elaborare
            System.out.println("END!!");
            return result;
        } catch (TesseractException e) {
            System.err.println(e.getMessage());
        } 
          
        */
        executeCommand("tesseract "+filename+" "+shortname+"-output-ocr -l eng -psm 3");
        return "-1";
    }

    public static void doSimpleOCR(String namefile){
    	
    	 String shortname = namefile.substring(0,namefile.length()-4);  
    	 executeCommand("tesseract "+namefile+" "+shortname+"-output-ocr -l eng -psm 3");
    	 
    	 
    }
    
    public static void executeCommand(String command) {

		StringBuffer output = new StringBuffer();

		Process p;
		try {
			p = Runtime.getRuntime().exec(command);
			p.waitFor();
			BufferedReader reader = 
                            new BufferedReader(new InputStreamReader(p.getInputStream()));

                        String line = "";			
			while ((line = reader.readLine())!= null) {
				output.append(line + "\n");
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		//return output.toString();

	}
    
}
