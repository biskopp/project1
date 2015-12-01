import processing.net.*;
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

// General declarations:

int bedtime = 22;

boolean isBedtime;
boolean wantRecord;
boolean preRecord;

// Minim declarations:

Minim minim;

AudioInput in;
AudioOutput out;
AudioRecorder recorder;

FilePlayer player;
AudioPlayer myRecord;
AudioPlayer preRecorded;
FFT freqLog;

boolean recorded;
boolean playback;

int baseHz = 100;  //size of the smallest octave in Hz
int bandPOct = 1;  //how many bands each octave is split into
int numBands;      //the total number of bands

int sampleRate = 44100;
int bufferSize = 512;

//Philips Hue declarations:

int[] val = { 0, 0, 0};
int[] prev = { 0, 0, 0 };
int[] colorVal = { 0, 0, 0 };
int[] currentCol = { 0, 0, 0 };
int[] len = new int[3];
String[] toStr = new String[3];

boolean isLight;
boolean prevLight;

Client c;
String data;

String apiKey = "26ec30f23a2aea1f676e1c0208245ff";
String light = "4";
String IP = "192.168.0.199";

void setup() {

  size(400, 400);
  background(127);

  // initializing minim elements
  minim = new Minim(this);

  in = minim.getLineIn(Minim.STEREO, bufferSize);
  out = minim.getLineOut(Minim.STEREO);
  recorder = minim.createRecorder(in, "recording.wav");

  preRecorded = minim.loadFile("200mader.wav", bufferSize);
  freqLog = new FFT( bufferSize, sampleRate );
  freqLog.logAverages(baseHz, bandPOct); // this creates 8 bands.
  freqLog.window(FFT.HAMMING);

  numBands = freqLog.avgSize();
  println(preRecorded);
  //println("Bands: " + numBands);


  // initializing general elements


  // initializing the Philips Hue
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

    if ( wantRecord ) { 
      freqLog.forward( myRecord.mix );
      //println("Bandwidth: " + freqLog.getBandWidth() + " Hz");
    }

    if ( preRecord ) {
      freqLog.forward( preRecorded.mix );
      //println("Bandwidth: " + freqLog.getBandWidth() + " Hz");
    }

    int bri = 0;

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

      // **** Below is the 8 bands of frequencies **** \\

      // ** Between 0.0 Hz - 172.0 Hz ** \\
      //if ( i == 0) {
      //  //println(averageB);
      //  if ( averageB > 30 ) {
      //  }
      //}

      // ** Between 172.0 Hz - 344.0 Hz ** \\
      //if ( i == 1 ) {
      //}

      // ** Between 344.0 Hz - 689.0 Hz ** \\
      if ( i == 1 || i == 2 || i == 3 || i == 4 ) {
        //println("num: " + i + " : " + averageB);
        if ( averageB > 0 && averageB < 4.5 ) {
          bri += (int) map ( averageB, 0, 4.5, 0, 254 );
          float lol = map ( averageB, 0, 4.5, 0, width );
          fill(bri, 0, 0, 127);
          ellipse(width/2, height/2, lol, lol);
        }
      }

      // ** Between 689.0 Hz - 1378.0 Hz ** \\
      //if ( i == 3 ) {
      //  //println(averageB);
      //  if ( averageB > 0 && averageB < 20 ) {
      //  }
      //}

      // ** Between 1378.0 Hz - 2756.0 Hz ** \\
      //if ( i == 4 ) {
      //  //println(averageB);
      //  if ( averageB > 0 && averageB < 25 ) {
      //  }
      //}

      // ** Between 2756.0 Hz - 5512.0 Hz ** \\
      if ( i == 5 ) {
        //println(averageB);
        if ( averageB > 1 && averageB < 16 ) {
        }
      }

      // ** Between 5512.0 Hz - 11025.0 Hz ** \\
      if ( i == 6 ) {
        //println(averageB);
        if ( averageB >= 0 && averageB <= 8 ) {
        }
      }

      // ** Between 11025.0 Hz - 22050.0 Hz ** \\
      if ( i == 7 ) {
        //println(averageB);
        if ( averageB > 0 && averageB < 5 ) {
        }
      }
    }

    currentCol[0] = bri;
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
    if ( c.active() ) {
      c.write("PUT /api/" + apiKey + "/lights/" + light + "/state HTTP/1.1\r\n"); 
      c.write("Content-Length: " + 20 + "\r\n\r\n");
      c.write("{\"on\":" + isLight + "}\r\n");
      c.write("\r\n");
      c.stop();
      //sendHTTPData();

      println("sent: " + isLight + " :"); // command executed
      delay(1); // slight delay
      prevLight = isLight; // set previous
    } else {
      println("could not connect to server");
    }
  }

  if (val[0] != prev[0] ) { // if new reading is different than the old one

    c = new Client(this, IP, 80); // Connect to server on port 80
    if ( c.active() ) {
      c.write("PUT /api/" + apiKey + "/lights/" + light + "/state HTTP/1.1\r\n"); 
      c.write("Content-Length: " + 18 + len[0] + "\r\n\r\n");
      c.write("{\"bri\":" + val[0] + "}\r\n");
      c.write("\r\n");
      c.stop();
      //sendHTTPData();

      println("sent: bri : " + val[0]);  // command executed
      delay(1);                          // slight delay
      prev[0] = val[0];                  // set previous
    } else {
      println("could not connect to server");
    }
  }

  if (val[1] != prev[1] ) { // if new reading is different than the old one

    c = new Client(this, IP, 80); // Connect to server on port 80
    if ( c.active() ) {
      c.write("PUT /api/" + apiKey + "/lights/" + light + "/state HTTP/1.1\r\n"); 
      c.write("Content-Length: " + 18 + len[1] + "\r\n\r\n");
      c.write("{\"sat\":" + val[1] + "}\r\n");
      c.write("\r\n");
      c.stop();
      //sendHTTPData();

      println("sent: sat :"); // command executed
      delay(1);               // slight delay
      prev[1] = val[1];       //set previous
    } else {
      println("could not connect to server");
    }
  }

  if (val[2] != prev[2] ) { // if new reading is different than the old one

    c = new Client(this, IP, 80); // Connect to server on port 80
    if ( c.active() ) {
      c.write("PUT /api/" + apiKey + "/lights/" + light + "/state HTTP/1.1\r\n"); 
      c.write("Content-Length: " + 18 + len[2] + "\r\n\r\n");
      c.write("{\"hue\":" + val[2] + "}\r\n");
      c.write("\r\n");
      c.stop();
      //sendHTTPData();

      println("sent: hue :");  // command executed
      delay(1);                // slight delay
      prev[2] = val[2];        //set previous
    } else {
      println("could not connect to server");
    }
  }

  //println("Val 1: " + val[0] + " | Val 2: " + val[1] + " | Val 3: " + val[2]);


  if ( !playback && wantRecord ) {

    if ( recorder.isRecording() ) {
      println("Now recording, press the r key to stop recording.");
    } else if ( !recorded ) {
      println("Press the r key to start recording.");
    } else {
      println("Press the s key to save");
    }
  }

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

  if ( key == 'w' ) {
    wantRecord = true; 
    println("want record myself");
  }
  if ( key == 'p' ) {
    preRecord = true; 
    println("using preRecorded audio");
  }

  if ( wantRecord ) {

    if ( !recorded && key == 'r' ) {

      if ( recorder.isRecording() ) {
        recorder.endRecord();
        recorded = true;
      } else {
        recorder.beginRecord();
      }
    }

    if ( recorded && key == 's' ) {

      if ( player != null ) {
        player.unpatch( out );
        player.close();
      }

      player = new FilePlayer( recorder.save() );
      player.patch( out );
      println("is saved");
    }

    if ( player != null && key == 'l') {
      myRecord = minim.loadFile("recording.wav", bufferSize);
      println("file loaded");
    }

    if (myRecord != null && key == 'm') {
      freqLog = new FFT( bufferSize, sampleRate );
      freqLog.logAverages(baseHz, bandPOct); // this creates 8 bands.
      freqLog.window(FFT.HAMMING);
      numBands = freqLog.avgSize();
      //println("Bands: " + numBands);
      println("freq loaded");
    }
  }

  if ( key == 'o' && !isLight ) {
    isLight = true;
    currentCol[2] = 1;

    if ( myRecord != null && wantRecord ) {
      myRecord.loop();
      playback = true;
      println("is playing");
    }

    if ( preRecord ) {
      preRecorded.loop();
      playback = true;
      println("is playing");
    }
  } else if ( key == 'o' && isLight ) {
    isLight = false;

    if ( myRecord != null && wantRecord ) {
      myRecord.close();
    }

    if ( preRecord ) {
      preRecorded.close();
    }
  }
}

void stop() {
  in.close();
  player.close();
  myRecord.close();
  preRecorded.close();
  minim.stop();
  super.stop();
}