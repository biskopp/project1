import processing.net.*;
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

// General declarations:

int bedtime = 20;
boolean isBedtime;

// Minim declarations:

Minim minim;

AudioPlayer preRecorded;
FFT freqLog;

boolean playback;

int baseHz = 100;  //size of the smallest octave in Hz
int bandPOct = 1;  //how many bands each octave is split into
int numBands;      //the total number of bands

int sampleRate = 44100;
int bufferSize = 512;

//Philips Hue declarations:
HueControl hc;

int[] val = { 0, 0, 0};
int[] prev = { 0, 0, 0 };
int[] colorVal = { 0, 0, 0 };
int[] currentCol = { 0, 0, 0 };
int[] len = new int[3];
String[] toStr = new String[3];

int hue;

boolean isLight;
boolean prevLight;

Client c;
String data;

String light;
String IP;

void setup() {

  size(400, 400);
  background(127);
  frameRate(15);

  // initializing minim elements
  minim = new Minim(this);

  preRecorded = minim.loadFile("200mader.wav", bufferSize);
  freqLog = new FFT( bufferSize, sampleRate );
  freqLog.logAverages(baseHz, bandPOct); // this creates 8 bands.
  freqLog.window(FFT.HAMMING);

  numBands = freqLog.avgSize();
  println(preRecorded);
  //println("Bands: " + numBands);

  // initializing the Philips Hue

  hc = new HueControl("26ec30f23a2aea1f676e1c0208245ff"); //insert PhilipsDev API key into constructor
  IP = hc.ipSearch();

  for ( int i = 1; i <= hc.lightsInSystem(); i++ ) {
    if (  hc.isReachable(i) == true ) {
      light = str(i);
      break;
    } else {
      light = str(0);
    }
  }

  currentCol[0] = 0;   // The Brightness  (value btw. 0 - 254)
  currentCol[1] = 254; // The Saturation  (value btw. 0 - 254)
  currentCol[2] = 0;   // The Hue         (value btw. 0 - 65535)
}

void draw() {

  if ( hour() >= bedtime ) {
    isBedtime = true;
  } else {
    isBedtime = false;
  }

  if ( playback ) { 

    freqLog.forward( preRecorded.mix );
    //println("Bandwidth: " + freqLog.getBandWidth() + " Hz");

    int bri = 0;
    hue = 0;
    hue += (int) map ( mouseX, 0, width, 0, 65535 ); 

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

      //  For every i'th iteration the loop, is a corresponding frequency range \\
      //  The lowest range being from 0 Hz - 172 Hz and the highest 11025.0 Hz - 22050.0 Hz \\
      //  I have combined 4 ranges under one if-statement to get a wider frequency input into one variable \\

      // ** Between 172.0 Hz - 2756.0 Hz ** \\
      if ( i == 1 || i == 2 || i == 3 || i == 4 ) {
        //println("num: " + i + " : " + averageB);
        if ( averageB >= 0 && averageB <= 4.5 ) {
          bri += int( map ( averageB, 0, 4.5, 0, 127 ) );
          float displayVis = map ( averageB, 0, 4.5, 0, width );
          colorMode(HSB, 65535, 254, 254);
          fill(hue, 254, bri, 127);
          ellipse(width/2, height/2, displayVis, displayVis);
        }
      }
    }

    currentCol[0] = bri;
    currentCol[2] = hue;
    //println(currentCol[0]);
  } // end "playback" bracket

  for ( int i = 0; i < colorVal.length; i++ ) {
    colorVal[i] = currentCol[i];
    val[i] = colorVal[i];
    toStr[i] = str(val[i]);
    len[i] = toStr[i].length();
  }

  if ( isLight != prevLight ) {  // if new reading is different than the old one
    c = new Client(this, IP, 80); // Connect to server on port 80 
    hc.sendData(c, isLight, light);

    delay(1);
    prevLight = isLight;
  }

  if ( val[0] != prev[0] ) { // if new reading is different than the old one
    c = new Client(this, IP, 80); // Connect to server on port 80
    hc.sendData(c, "bri", light, len[0], val[0]);

    delay(1); 
    prev[0] = val[0];
  }

  if ( val[1] != prev[1] ) { // if new reading is different than the old one
    c = new Client(this, IP, 80); // Connect to server on port 80
    hc.sendData(c, "sat", light, len[1], val[1]);

    delay(1); 
    prev[1] = val[1];
  }

  if ( val[2] != prev[2] ) { // if new reading is different than the old one
    c = new Client(this, IP, 80); // Connect to server on port 80
    hc.sendData(c, "hue", light, len[2], val[2]);

    delay(1); 
    prev[2] = val[2];
  }

  //println("Val 1: " + val[0] + " | Val 2: " + val[1] + " | Val 3: " + val[2]);

  noStroke();
  fill(127, 8);
  rect(0, 0, width, height);
} // end draw bracket


void sendHTTPData() {
  if (c.available() > 0) { // If there's incoming data from the client...
    data = c.readString(); // ...then grab it and print it
    println(data);
  }
}

void keyReleased() {
  
  if ( key == 'o' && !isLight && isBedtime ) {

    isLight = true;
    currentCol[2] = 1;
    preRecorded.play();
    playback = true;
    println("is playing");
  } else if ( key == 'o' && isLight ) {

    isLight = false;
    preRecorded.pause();
    preRecorded.rewind();
  }
}

void stop() {
  preRecorded.close();
  minim.stop();
  super.stop();
}