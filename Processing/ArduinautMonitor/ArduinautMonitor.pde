/*
ArduinautMonitor
2013-03-02
karl@symbollix.org
http://symbollix.org/code/arduinaut/
https://github.com/karljacuncha/arduinaut/
====================

A GUI for use with the 'Arduinaut' sketch on arduino, with JSON serial updates.
 
Requires controlP5:
http://www.sojamo.de/libraries/controlP5/

Similar to the accomanying python script, continually read the latest complete data set from the arduino.
Pipe the results into slider/buttons for display.

App provides a list of available serial ports on start up.
Select the port & buad then hit connect to begin.


*/
import controlP5.*;
import processing.serial.*;

/* UI components */
ControlP5 cp5;
ListBox arduinoList, baudRateList;
Toggle connectButton;
Slider[] analogBars;
Toggle[] digitalButtons;

/* colors/theme */
color SCREENBG = color(1, 52, 15);
color BGCOLOR = color(0);
color FGCOLOR = color(46, 61, 138);
color HIGHLIGHT =  color(242, 78, 34);
PImage bg;
PFont f;

/* available ports & baudrates - for dropdowns & serial connection */
final int[] baudRates = {
  115200, 57600, 38400, 31250, 28800, 19200, 14400, 9600
};
String[] serialPorts;


/*
 Custom class for arduino.
 Store the connection & data received. 
 The connection, data reading & parsing are all handled in here, and teh class should be reasonably self contained & portable.
 Everything after this is really just UI.
 */
public class Arduino {
  public boolean[] digitalPins;
  public int[] analogPins;
  public String portName;
  public int baudRate; 

  private Serial conn;
  private String buffer;

  Arduino() {
    portName = "";
    baudRate = -1;
    digitalPins = new boolean[14];
    analogPins = new int[6];
    buffer = "";
  }

  boolean doConnect(PApplet parent) {
    if (portName != null && baudRate > 0) {
      try {
        conn = new Serial(parent, portName, baudRate);   
        println("Connected");
        return true;
      }
      catch(Exception e) {
        println("Error connecting:");
        println(e);
        doDisconnect();
        return false;
      }
    }else{
       return false; 
    }
  }

  void doDisconnect() {
    if (conn != null) {
      conn.stop();
      conn = null;
    }
  }

  void update() {
    if (conn != null) {
      buffer = buffer + conn.readString();
      String[] lines = split(buffer, '\n');

      if (lines.length > 2) {
        try {
          buffer = lines[(lines.length-1)];
          JSONObject latest_data = JSONObject.parse(lines[(lines.length-2)]);
          for (int i = 0; i < digitalPins.length; i++) {
            digitalPins[i] = (latest_data.getInt("D"+i) == 1);  // read int, make bool
          }
          for (int i = 0; i < analogPins.length; i++) {
            analogPins[i] = latest_data.getInt("A"+i);
          }
        }
        catch(Exception e) {
          println("Error - dirty data?");
          println(e);
        }
      }
    }
  }
}
Arduino ard;





void setup() {
  size(412, 481);
  smooth();
  frameRate(10);
  f = createFont("Arial", 12, true); 

  cp5 = new ControlP5(this);  
  ard = new Arduino();

  /* select list for serial ports */
  arduinoList = cp5.addListBox("arduinoList")
    .setPosition(14, 85)
      .setSize(190, 90)
        .setItemHeight(15)
          .setBarHeight(15)
            .setColorBackground(BGCOLOR)
              .setColorForeground(FGCOLOR)
                .setColorActive(HIGHLIGHT);

  arduinoList.captionLabel().set("Select Input:")
    .style().marginTop = 3;  

  serialPorts = Serial.list();
  for (int i=0; i < serialPorts.length; i++) {
    ListBoxItem lbi = arduinoList.addItem(serialPorts[i], i);
    lbi.setColorBackground(BGCOLOR);
    lbi.setColorForeground(FGCOLOR);
  }

  /* select list for baudrates */
  baudRateList = cp5.addListBox("baudRateList")
    .setPosition(210, 85)
      .setSize(100, 90)
        .setItemHeight(15)
          .setBarHeight(15)
            .setColorBackground(BGCOLOR)
              .setColorForeground(FGCOLOR)
                .setColorActive(HIGHLIGHT);

  baudRateList.captionLabel().set("Select Baud Rate:")
    .style().marginTop = 3;  

  for (int i=0; i < baudRates.length; i++) {
    ListBoxItem lbi = baudRateList.addItem(""+baudRates[i]+"", i);
    lbi.setColorBackground(BGCOLOR);
  }

  /* connection button */
  connectButton = cp5.addToggle("doConnect")
    .setPosition(320, 70)
      .setSize(40, 20)
        .setValue(false)
          .setCaptionLabel("Connect")
            .setColorBackground(BGCOLOR)                                            
              .setColorForeground(FGCOLOR)
                .setColorActive(HIGHLIGHT);

  /*  display bars for analog data */
  analogBars = new Slider[ard.analogPins.length];
  for (int i = 0; i < ard.analogPins.length; i++) {
    int xPos = 14;
    int yPos = 220 + (30 * i);
    analogBars[i] = cp5.addSlider("A"+i)
      .setBroadcast(false)
        .setPosition(xPos, yPos)
          .setSize(175, 20)
            .setRange(0, 1024)
              .setColorBackground(BGCOLOR)
                .setColorForeground(HIGHLIGHT);
  }

  /* display buttons for digital data */
  digitalButtons = new Toggle[ard.digitalPins.length];
  for (int i = 0; i < ard.digitalPins.length; i++) {
    int xPos = 234 + (42 * (i % 4));
    int yPos = 220 + (40 * (i / 4));
    digitalButtons[i] = cp5.addToggle("D"+i)
      .setValue(false)
        .setPosition(xPos, yPos)
          .setSize(20, 20)
            .setColorForeground(FGCOLOR)
              .setColorForeground(FGCOLOR)
                .setColorActive(HIGHLIGHT);
  }
}


/* connect/disconnect event */
void doConnect(boolean trigger) {
  if (connectButton != null) {
    if (trigger && ard.doConnect(this)) {
      connectButton.setCaptionLabel("Disonnect");
    }
    else {
      ard.doDisconnect();
      connectButton.setCaptionLabel("Connect");
    }
  }
}

/* handler for select lists */
void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup() && theEvent.name().equals("arduinoList")) {
    // get selected index:
    int index = (int)theEvent.group().value();
    // set name
    ard.portName = serialPorts[index];
    // highlight selected
    for (int i=0; i < serialPorts.length; i++) {
      if (i == index) {
        arduinoList.getItem(i).setColorBackground(HIGHLIGHT);
      }
      else {
        arduinoList.getItem(i).setColorBackground(BGCOLOR);
      }
    }
  }  

  if (theEvent.isGroup() && theEvent.name().equals("baudRateList")) {
    // get selected index:
    int index = (int)theEvent.group().value();
    // set rate
    ard.baudRate = baudRates[index];
    // highlight selected
    for (int i=0; i < baudRates.length; i++) {
      if (i == index) {
        baudRateList.getItem(i).setColorBackground(HIGHLIGHT);
      }
      else {
        baudRateList.getItem(i).setColorBackground(BGCOLOR);
      }
    }
  }
}


void draw() {
  /* begin screen bg & labels */
  background(SCREENBG);
  fill(255);                      
  textFont(f, 22);               
  text("ArduinoMonitor", 14, 24);  
  textFont(f, 12);
  text("Serial Comms:", 14, 55);  
  text("Analog Pins:", 14, 201);  
  text("Digital Pins:", 234, 201);  
  stroke(255);
  line(14, 34, 396, 34);
  line(14, 180, 396, 180); 
  line(219, 180, 219, 408); 
  noStroke();
  /* end screen bg & labels */


  // Read arduino data:
  if (ard != null) {
    ard.update();

    // update sliders & buttons:
    for (int i = 0; i < ard.analogPins.length; i++) {
      analogBars[i].setValue(ard.analogPins[i]);
    }   
    for (int i = 0; i < ard.digitalPins.length; i++) {
      digitalButtons[i].setState(ard.digitalPins[i]);
    }
  }
}

