#!/usr/bin/env python
"""
 ArduinautMonitor.py
 2013-03-02
 karl@symbollix.org
 http://symbollix.org/code/arduinaut/

Requires: pySerial
http://pyserial.sourceforge.net/

This is a quick & dirty client/monitor for the arduino with my arduinaut/all-pin-reads-to-json sketch.
This just connects to the serial port, buffers the data into a dict and continually updates as best as it can.
The functional bit of the script is pretty small and marked out below.
The rest of the script is just stats, formatting and the usual optparse/cli set up.
And apart from pySerial, the rest is standard python 2.6, tested on OSX.

Example usage:
	./arduinoMonitor.py --port=/dev/tty.usbmodem3d11 --baud=115200 -v=true

Outputs:
	Reading /dev/tty.usbmodem3d11 at 115200:
	{
	    "A0": 660,
	    "A1": 674,
	    "A2": 674,
	    "A3": 588,
	    "A4": 555,
	    "A5": 532,
	    "D0": 1,
    	"D1": 0,
   		"D10": 0,
    	"D11": 0,
    	"D12": 0,
    	"D13": 0,
    	"D2": 0,
    	"D3": 0,
    	"D4": 0,
    	"D5": 0,
    	"D6": 0,
    	"D7": 0,
    	"D8": 0,
    	"D9": 0
	}
	______________________________________
	Last error: 
	Current Buffer:

Some stats:
	Total Bytes: 2.0 MB
	Error Rate: 1/18409 : 0.01%
	Total Time: 00:32:38
	Bytes per second: 1398
	Successful updates per second: 9.4

"""
import datetime
import json
import optparse
import os
import serial
import sys
import time

# 
#	Helper Functions:
#	(mostly just for displaying stats)
#
def cls():
	''' clear screen between updates '''
	os.system(['clear','cls'][os.name == 'nt'])


def display_time(input_time=None):
	''' custom pretty time function - accepts timestamp, timedelta or datetime
		default to now if no param'''
	if isinstance(input_time, (int, long, float)):
		output_time = datetime.datetime.fromtimestamp(input_time)
	elif isinstance(input_time, datetime.timedelta):
		output_time = datetime.datetime(1970,1,1,0,0,0,0) + input_time
	elif isinstance(input_time, datetime.datetime):
		output_time = input_time
	else:
		output_time = datetime.datetime.now()
	return output_time.strftime("%H:%M:%S")


def format_percent(amount, total):
	''' for a given amount from a larger total, return the percentage string '''
	ratio = (amount * 1.0) / (total * 1.0)
	return '%.2f' % round(ratio*100,2)


def humanize_bytes(bytes, precision=1):
	'''	http://code.activestate.com/recipes/577081-humanized-representation-of-a-number-of-bytes/ '''
	abbrevs = (
		(1<<50L, 'PB'),
		(1<<40L, 'TB'),
		(1<<30L, 'GB'),
		(1<<20L, 'MB'),
		(1<<10L, 'kB'),
		(1, 'bytes')
	)
	if bytes == 1:
		return '1 byte'
	for factor, suffix in abbrevs:
		if bytes >= factor:
			break
	return '%.*f %s' % (precision, bytes / factor, suffix)


#
#	The Main app:
#
def main():
	description = """A command line interface for json/arduino monitor"""
	usage = "usage: %prog --port=/dev/tty.usbmodem3d11 --baud=115200"
	version = "%prog version 0.1"
	p = optparse.OptionParser(description=description,
							  usage=usage,
							  version=version)
	p.add_option('--port', '-p',
				 help="Serial port name for the Arduino",
				 type="string",
				 dest="port")
	p.add_option('--baud', '-b',
				 help="Baud rate to read at",
				 type="int",
				 dest="baud")
	p.add_option("-v",
				 help="Verbose logging",
				 dest="verbose")
	options, arguments = p.parse_args()

	print "Connecting to " + options.port + " at " + str(options.baud) + "..."
	try:		
		s = serial.Serial(options.port, options.baud, timeout=1)
	except serial.SerialException, e:
		sys.stderr.write("Could not open port %r: %s\n" % (options.port, e))
		exit(-1)
	print "... OK"

	latest_data = {}	# contant store of latest successful read
	buffer = ""			# the serial input buffer
	last_error = ""		# last error message
	bytes_read = 0		# counters for the stats
	num_errors = 0
	loop_counter = 0
	start_time = datetime.datetime.now()

	try:
		while(True):
			loop_counter = loop_counter + 1
			cls()

			if options.verbose:
				print "Reading " + options.port + " at " + str(options.baud) + ":"
				print '______________________________________'
			
			try:
				bytes_read = bytes_read + s.inWaiting()	
				'''
				This is the actual serial read/parse section:
				Tead everything of the serial buffer, dependng on speed there may be
				several 'println's sent since last check, but we only want the latest one.
				Split the buffer to an array based on line breaks
				Push the last (probably incomplete) line back onto the internal buffer for next time.
				Take the 2nd last line as the most up to date and complete data set and
				update the 'latest data' dict here.
				Any exceptions, just log the error and move on.
				'''
				buffer = buffer + s.read(s.inWaiting())
				if '\n' in buffer:
					ls = buffer.split("\n")		# split and
					buffer = ls[-1]				# leave last incomplete line on the buffer
					latest_data = json.loads(ls[-2])	# try parse last complete line to json obj
														# this should be the last thing in the try/catch
			except Exception as e:
				last_error = "%r Error: %s" % (display_time(), e)
				num_errors = num_errors + 1

			# display data (or do something useful with it...)
			# if the try block above failed, then we'll just display the previous successful update
			print json.dumps(latest_data, sort_keys=True, indent=4, separators=(',', ': '))
						
			if options.verbose:
				print '______________________________________'
				print "Last error: " + last_error
				print "Current Buffer:" + str(buffer)

			time.sleep(0.1)		# pause between loops
		
	except KeyboardInterrupt:
		# report stats on exit
		end_time = datetime.datetime.now() 
		print "\nDone"
		print "Total Bytes: " + humanize_bytes(bytes_read)
		print "Error Rate: " + str(num_errors) + "/" + str(loop_counter) + " : " + format_percent(num_errors, loop_counter) + "%"
		print "Total Time: " + display_time(end_time - start_time)
		print "Bytes per second: " + str((bytes_read * 1.0)/ (end_time - start_time).seconds)
		print "Successful updates per second: " + str((loop_counter - num_errors * 1.0) / (end_time - start_time).seconds)
		exit(0)


if __name__ == '__main__':
	main()
