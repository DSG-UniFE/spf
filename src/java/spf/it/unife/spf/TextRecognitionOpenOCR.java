package it.unife.spf;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

	public class TextRecognitionOpenOCR {

		public static String doOCR() {
			try {
				URL url = new URL("http://172.17.0.1:9292/ocr");
				HttpURLConnection conn = (HttpURLConnection) url.openConnection();
				conn.setDoOutput(true);
				conn.setRequestMethod("POST");
				conn.setRequestProperty("Content-Type", "application/json");
				
				String input = "{\"img_url\":\"http://bit.ly/ocrimage\",\"engine\":\"tesseract\"}";

				OutputStream os = conn.getOutputStream();
				os.write(input.getBytes());
				os.flush();

				BufferedReader br = new BufferedReader(
						new InputStreamReader((conn.getInputStream())));

				String output;
				System.out.println("Output from Server .... \n");
				while ((output = br.readLine()) != null) {
					System.out.println(output);
				}

				conn.disconnect();
				return br.toString();
			}
			catch (MalformedURLException e) {
				e.printStackTrace();
				return null;
			}
			catch (IOException e) {
				e.printStackTrace();
				return null;
			}
		}
	}


