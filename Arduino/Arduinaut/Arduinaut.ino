/*
 Arduinaut
 2013-03-02
 karl@symbollix.org
 http://symbollix.org/code/arduinaut/
 https://github.com/karljacuncha/arduinaut/

 Simple read of all pins and output to serial as JSON.
 =====================================================
 
 If you just want to read sensor data from your *duino and pipe that somewhere
 else for futher processing, this should do the trick.
 
 CAVEAT: C sucks, Python is miles better.
 That is to say, I'm not very good at the C programming with all the
 pointers and having to do lots of verbose conversions and whatnot.
 And ss you could probably guess by the output format, I'd rather be
 coding in a higher level language.
 As such, this may not be the most correct way of doing things, but
 suits my requirements at least.
 
 The (formatted) output will look like:
 {
 	"A0": 660,
 	"A1": 674,
 	"A2": 674,
 	"A3": 588,
 	"A4": 555,
 	"A5": 532,
 	"D0": 1,
 	"D1": 0,
 	"D2": 0,
 	"D3": 0,
 	"D4": 0,
 	"D5": 0,
 	"D6": 0,
 	"D7": 0,
 	"D8": 0,
 	"D9": 0
 	"D10": 0,
 	"D11": 0,
 	"D12": 0,
 	"D13": 0,
 }
 
 For all 20 pins, and analog values up to 4 digits, the sie of the output
 will be up to 164 ASCII chars/bytes.
 A byte stream might be more efficient, but I'm using the JSON format for
 portability, so there's a trade off there.
 If you're really concerned about the size & faster updating, map/contrain
 the analog vals to lower amounts. 
 Also try setting the pins array to only the ones you want to read to reduce
 unnecessary data.
 
 Default pin collection is for eveything.
 
 // Just the analogs:
 const String pins[] = {"A0","A1","A2","A3","A4","A5"};
 const int numPins = 6; 
 
 // Just the digital:
 const String pins[] = {"D0","D1","D2","D3","D4","D5","D6","D7","D8","D9","D10","D11","D12","D13"};
 const int numPins = 14; 
 
 // Selective mix:
 const String pins[] = {"A0","A5","D2","D10","D11","D12","D13"};
 const int numPins = 7; 
 
 */


/*
CONFIG SECTION
 Some contants to edit to suit your needs before uploading to your *duino.
 */

const long baudRate = 115200;  // set the baud rate for your comms
const long delayTime = 100;    // pause time between iterations of the loop (ms)

// and configure the array of pins you want to use:
const String pins[] = {
  "A0","A1","A2","A3","A4","A5","D0","D1","D2","D3","D4","D5","D6","D7","D8","D9","D10","D11","D12","D13"};
const int numPins = 20;   // and set the size here since we can't just use array.length, and don't start on 'sizeof'...

//limits on the analog pins
const int analogMin = 0;
const int analogMax = 1023;
// const int analogMax = 675;  // for use with 3.3v components
// 

void setup(){
  Serial.begin(baudRate);   
}

void loop(){
  Serial.print("{");  

  for(int i = 0; i < numPins; i++){

    // quote and postfox a semi colon to the pin name:
    Serial.print("\"");  
    Serial.print(pins[i]);  
    Serial.print("\":");  

    if(pins[i].startsWith("A")){
      // analog read & constrain:
      // NOTE: if you needed any other pre-processing, chuck that in here
      int val = analogRead(pinNameToNumber(pins[i]));
      val = constrain(val, analogMin, analogMax);      
      Serial.print(val);
    }
    else{
      // digital is a simpler read high or low
      int val = digitalRead(pinNameToNumber(pins[i]));
      Serial.print(val);   
    }

    // add comma for all but the last item
    if(i != (numPins - 1)){
      Serial.print(",");    
    }
  }
  Serial.println("}"); 

  delay(delayTime);
}

/*
 Helper function to convert the pin name to the corresponding int
 eg: "A0" -> 0
 "D13" -> 13 
 */
int pinNameToNumber(String pinName) {
  pinName = pinName.substring(1);  // lop off the first char
  // for each char, add up the int value:
  int value = 0;
  for(int i = 0; i < pinName.length(); i++) {
    value = (10*value) + pinName.charAt(i)-(int) '0';
  }
  return value;
}


