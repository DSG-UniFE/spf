package it.unife.loadopencv;

import java.io.IOException;

public class LoadOpenCV {

  private static loaded = false;

  public static doLoad() {
    if (!loaded) {
      try {
        NativeUtils.loadLibraryFromJar("/org/opencv/libopencv_java310.so");
      } catch (IOException e) {
        // This is probably not the best way to handle exception
        System.err.println("Error: load opencv library");
        System.exit(1);
      }
      loaded = true;
    }
  }
}
