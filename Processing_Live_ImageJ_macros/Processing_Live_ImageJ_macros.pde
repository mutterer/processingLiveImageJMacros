import ij.*;
import ij.gui.*;
import ij.io.*;
import ij.macro.*;
import ij.measure.*;
import ij.plugin.*;
import ij.plugin.filter.*;
import ij.plugin.frame.*;
import ij.plugin.tool.*;
import ij.process.*;
import ij.text.*;
import ij.util.*;


import controlP5.*;
import java.awt.image.BufferedImage;
import java.awt.Font;
import g4p_controls.*;
import drop.*;

SDrop drop;

PImage img;
PImage img2;
ImagePlus imp, imp2;

int min = 0;
int max = 255;
int smoothness=0;
String[] luts = {"Grays", "Fire", "Spectrum"};
String lut = luts[0];

ControlP5 cp5;
Range range;
Knob myKnob;
DropdownList ddl;
int params = 9;
Numberbox [] p  = new Numberbox [params];
Bang [] b  = new Bang [params];
GTextArea mf;
ImageJ ij;

void setup() {
  size(1280, 1024);
  //frameRate(5);
  ij = new ImageJ(ImageJ.NO_SHOW);
  String[] lts =  IJ.getLuts();
  luts=lts;
  printArray(lts);

  String strtup = Prefs.getImageJDir();
  println(strtup);
  cp5 = new ControlP5(this);


  for (int i = 0; i<params; i++) {
    p[i] = cp5.addNumberbox("p"+i)
      .setSize(70, 20)
      .setPosition(30+95*(i%3), 10+50*floor(i/3))
      .setValue(0)
      .setDecimalPrecision(0) 
      .setFont(createFont("Monospaced", 16))
      ;
    b[i] = cp5.addBang("b"+i)
      .setSize(10, 10)
      .setPosition(10+95*(i%3), 10+50*floor(i/3))
      .setLabel("");
    ;
  }
  String macro = "run('RGB Color');\n"
    +"setBackgroundColor(0,0,0);\n"
    +"run('Size...','width=#P3# constrain');\n"
    +"run('Rotate... ', 'angle=#P6# grid=1 enlarge interpolation=Bilinear fill');\n"
    +"run('Canvas Size...','width=#P7# height=#P8# position=Center');";


  mf = new GTextArea(this, 400, 10, 800, 150);
  mf.tag = "mf";
  // Font f = createFont("monospaced",24);
  mf.setFont(new Font("Monospaced", Font.BOLD, 16));
  mf.setText(macro);

  cp5.addToggle("process")
    .setPosition(330, 10)
    .setSize(50, 20)
    .setValue(1)
    .setMode(ControlP5.SWITCH)
    ;



  String url = "http://wsr.imagej.net/images/blobs.gif";
  imp = IJ.openImage(url);
  drop = new SDrop(this);
  // initial defaults
  p[3].setValue(imp.getWidth());
  p[6].setValue(30);
  p[7].setValue(imp.getWidth());
  p[8].setValue(imp.getHeight());
}

void draw() {
  background(128);
  updateImage();
}

void controlEvent(ControlEvent e) {
  println (e.toString());
  if (e.getController().getName().startsWith("b")) {
    String t = mf.getText();
    mf.insertText("#P"+e.getController().getName().substring(1)+"#");
  } 
}


void updateImage() {
  imp2 = imp.duplicate();
  if (cp5.getController("process").getValue()==0) {
    WindowManager.setTempCurrentImage(imp2);
    Interpreter interp = new Interpreter();
    interp.setIgnoreErrors(true);
    String macro = mf.getText();
    for (int i =0; i<params; i++) {
      macro = macro.replaceAll("#P"+i+"#", ""+cp5.getController("p"+i).getValue());
    }
    macro = "IJ.redirectErrorMessages();"+macro;
    try {
      imp2 = interp.runBatchMacro(macro, imp2);
      if (interp.getErrorMessage()!=null) {
        println("try:"+interp.getErrorMessage());
        imp2 = imp.duplicate();
      }
    } 
    catch (Throwable e) {
      interp.abortMacro();
      if (interp.getErrorMessage()!=null) println("catch:"+interp.getErrorMessage());
    }
  }
  IJ.run(imp2, "RGB Color", "");
  ImageProcessor ip = imp2.getProcessor();
  img2 = createImage(ip.getWidth(), ip.getHeight(), RGB);
  for (int i = 0; i < img2.pixels.length; i++) {
    img2.pixels[i] = color((int) ip.getf(i));
  }
  image(img2, 10, 180);
}

void dropEvent(DropEvent theDropEvent) {
  imp = IJ.openImage(theDropEvent.toString());
}

/*
run('RGB Color');
 setBackgroundColor(0,0,0); 
 run('Rotate... ', 'angle=#P6# grid=1 enlarge interpolation=Bilinear fill');
 run('Canvas Size...','width=#P7# height=#P8# position=Center');
 */
