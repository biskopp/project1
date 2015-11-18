import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

Minim minim;
AudioInput in;

void setup(){
  
size(400,400);
smooth();

minim = new Minim(this);

in = minim.getLineIn(Minim.STEREO, 512);

 background(0); 
}

void draw(){

noFill();
stroke(255);

float r2 = in.mix.level()*100;

float r = 0;
for (int i = 0; i < in.bufferSize(); i++){
  r +=  abs (in.mix.get(i));
 }
 
ellipse(width/2,height/2,r,r2);
rect( width/2, 0, 100, in.mix.level()*width );

}
  


void stop(){
  
    in.close();
    minim.stop();
    super.stop();
}