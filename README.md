(JSON and the) Arduinaut
========================

A pretty simple setup to read arduino pins and output to serial as JSON data.

> http://symbollix.org/code/arduinaut/

## Ok, so why?

Note: For practical purposes, you're probably better off looking into Firmata[1] or a
similar library that's well established, and provides read & write access.

...but I couldn't get that working with my Uno.
I also wasted a lot of time trying to debug what was happening with an accelerometer that
eventually turned out to be fried.

So rather than working with byte-streams, custom formats, flakey clients apps, etc...
I wanted this to be both machine & human readable from the start, easy to work with,
destination agnostic and in a flexible open standard.
So JSON fits the bill.
JSON also provides some data validation due to it's structure - which is always handy
for serial comms.

On the downside, the ascii stream per read is up to 164 bytes, compared to the 27 bytes
of booelan/ints or raw data. But there's always a trade off...


## What's included?

Aside from the Arduino sketch, there are 2 monitor scripts: a Python console script
and a Processing GUI. Most of these 2 monitor scripts is actually taken up the usual 
configuration.
The actual serial reading code in each is basicaly just:

	in-continous-loop:
		// do stuff		
		try:
			internalBuffer = internalBuffer + everythingCurrentlyOnSerial
			if more than 1 complete line in internalBuffer:
				linesArray = internalBuffer.split("\n")		
				internalBuffer = linesArray[lastItem]	    // probably in incomplete line, reset buffer with just that
				latestData = json.loads(linesArray[secondlastItem])		// the last complete read, parse to JSON object
		catch Exception:
			log or handle if needed			
		// do more stuff


All scripts are reasonably well commented, and should be easy to reconfigure & extend.

### Arduino

> Arduinaut.ino

The Arduino Sketch.
(Change the config to suit, if needed) and upload to your board.
Use the in-built serial monitor in the Arduino app to confirm the outout:

	{"A0":1023,"A1":0,"A2":674,"A3":0, ... "D13":0}
	{"A0":999,"A1":0,"A2":674,"A3":0, ... "D13":1}
	...

### Python

> ArduinautMonitor.py

A CLI script to see the arduino output.
(reuires pySerial)

Run as:

	./ArduinautMonitor.py --port=/dev/tty.usbmodem3d11 --baud=115200


### Processing

> ArduinautMonitor.pde

(requires controlP5)
Load up the sketch & run...


## Issues and Such...

Tested on OSX 10.6.8, with an Arduino Uno (original release).
Using Arduino 1.0.3, Processing 2.0b8 and Python 2.6



[1]: http://firmata.org/wiki/Main_Page
