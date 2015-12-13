import processing.net.*;  //<>//
import voce.*;
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

// General declarations:

Userinput ui;

// Minim declarations:

Minim minim;

ddf.minim.AudioPlayer preRecorded;
ddf.minim.AudioPlayer activationJingle;
FFT freqLog;

boolean playback;

int baseHz = 86;   //size of the smallest octave in Hz
int bandPOct = 1;  //how many bands each octave is split into
int numBands;      //the total number of bands

int sampleRate = 44100;
int bufferSize = 512;

//Philips Hue declarations:
HueControl hc;

int[] val = new int[2];
int[] prev = new int[2];
int[] currentCol = new int[2];
int[] len = new int[2];
String[] toStr = new String[2];

int[] briVal = new int[5];
int[] prevBri = new int[5];
int[] currentBri = new int[5];
int[] briLen = new int[5];
String[] briStr = new String[5];

int hue;
int[] bri = new int[5];

boolean isLight;
boolean prevLight;
boolean reachable;

Client c;
String data;

String light;
String IP;

void setup() {

  size(400, 400);
  colorMode(HSB, 65535, 254, 254);
  background(127);
  frameRate(15);

  ui = new Userinput();
  ui.setBedtime(12, 00);
  ui.setPassword("crisp");

  // initializing minim elements
  minim = new Minim(this);

  preRecorded = minim.loadFile("roedhaette.wav", bufferSize);
  activationJingle = minim.loadFile("introjingle.wav", bufferSize);

  freqLog = new FFT( bufferSize, sampleRate );
  freqLog.logAverages(baseHz, bandPOct);      // this creates 9 bands.
  freqLog.window(FFT.HAMMING);

  numBands = freqLog.avgSize();

  println("Bands: " + numBands);

  // initializing the Philips Hue
  hc = new HueControl("86659ed120ab2a7363ca8a935f03cc3"); //insert PhilipsDev API key into constructor
  IP = hc.ipSearch();

  for ( int i = 1; i <= hc.lightsInSystem(); i++ ) {
    if (  hc.isReachable(i) == true ) {
      light = str(i);
      println(light);
      break;
    } else {
      light = str(0);
    }
  }

  for ( int i = 0; i < bri.length; i++ ) 
  {
    currentBri[i] = 0; // The Brightness  (value btw. 0 - 254)
  }
  currentCol[0] = 254; // The Saturation  (value btw. 0 - 254)
  currentCol[1] = 0;   // The Hue         (value btw. 0 - 65535)
}

void draw() {

  ui.checkBedtime();
  if ( ui.getIsBedtime() && !ui.getEntry() ) {

    isLight = true;
    activationJingle.play();
    hue = (hue + 200) % 65535;
    currentCol[1] = hue;

    for (int i = 0; i < bri.length; i++) {
      currentBri[i] = 127;
    }

    fill(hue, 254, 254);
    ellipse(width/2, height/2, 200, 200);

    if ( activationJingle.position() == activationJingle.length() ) {

      ui.checkPassword();
    }
  }

  if ( ui.isPlayingBack() ) { 

    preRecorded.play();
    freqLog.forward( preRecorded.mix );

    int highBands = numBands - 1;
    for ( int i = 0; i < numBands; i++ ) {

      float averageB = freqLog.getAvg(i); 
      //println("Averages: " + i + " : " + averageB);

      float avg = 0;
      float lowFreq;

      if ( i == 0) {
        lowFreq = 0;
      } else {
        lowFreq = (int)((sampleRate/2) / (float)Math.pow(2, numBands - i));
      }
      float hiFreq = (int)((sampleRate/2) / (float)Math.pow(2, highBands - i));

      int lowBound = freqLog.freqToIndex(lowFreq);
      int hiBound = freqLog.freqToIndex(hiFreq);

      //println("range " + i + " = " + "Freq: " + lowFreq + " Hz - " + hiFreq + " Hz " + "indexes: " + lowBound + "-" + hiBound);

      for (int j = lowBound; j <= hiBound; j++) {
        float spectrum = freqLog.getBand(j);
        avg += spectrum;
      }

      avg /= (hiBound - lowBound + 1);
      averageB = avg; 

      //  For every i'th iteration in the loop, is a corresponding frequency range \\
      //  The lowest range being from 0 Hz - 172 Hz and the highest 11025.0 Hz - 22050.0 Hz \\
      //  I have combined 4 ranges under one if-statement to get a wider frequency input into one array\\

      // ** Between 86.0 Hz - 2756.0 Hz ** \\
      if ( i == 1 || i == 2 || i == 3 || i == 4 || i == 5 ) {
        //println("num: " + i + " : " + averageB);
        if ( averageB >= 0.5 && averageB <= 6 ) {

          bri[i-1] = int( map( averageB, 0.5, 6, 0, 254 ) );

          float visuals = map( averageB, 0.5, 6, 0, width );
          fill(hue, 254, bri[i-1], 127);
          ellipse(width/2, height/2, visuals, visuals);
        }
      }
    }

    currentCol[1] = hue;
  } // end "playback" bracket

  if ( hc.isOnline() ) {

    if ( isLight != prevLight ) {     // if new reading is different than the old one
      c = new Client(this, IP, 80);   // connect to server on port 80 
      hc.sendData(c, isLight, light); // send data to the server

      delay(1);
      prevLight = isLight; //set the previous value;
    }

    for ( int i = 0; i < bri.length; i++ ) {

      briVal[i] = bri[i];
      briStr[i] = str(briVal[i]);
      briLen[i] = briStr[i].length();

      if ( briVal[i] != prevBri[i] ) { // if new reading is different than the old one
        c = new Client(this, IP, 80);  // Connect to server on port 80
        hc.sendData(c, "bri", light, briLen[i], briVal[i]);

        delay(1); 
        prevBri[i] = briVal[i]; //set the previous value;
      }
    }

    for ( int i = 0; i < val.length; i++ ) {

      val[i] = currentCol[i];
      toStr[i] = str(val[i]);
      len[i] = toStr[i].length();
    }

    if ( val[0] != prev[0] ) { // if new reading is different than the old one
      c = new Client(this, IP, 80);  // Connect to server on port 80
      hc.sendData(c, "sat", light, len[0], val[0]);

      delay(1); 
      prev[0] = val[0]; //set the previous value;
    }

    if ( val[1] != prev[1] ) { // if new reading is different than the old one
      c = new Client(this, IP, 80);  // Connect to server on port 80
      hc.sendData(c, "hue", light, len[1], val[1]);

      delay(1); 
      prev[1] = val[1]; //set the previous value;
    }

    //println("Val ");
  }


  noStroke();
  fill(25000, 8);
  rect(0, 0, width, height);
} // end draw bracket


void keyReleased() {

  ui.playSound( !preRecorded.isPlaying() );

  ui.stopSound( preRecorded.isPlaying(), preRecorded );

  ui.replay( preRecorded.position(), preRecorded.length(), preRecorded );

  ui.notBedtime();

  ui.isOn( isLight );

  ui.changeColor();
}


void stop() {
  preRecorded.close();
  activationJingle.close();
  minim.stop();
  super.stop();
}