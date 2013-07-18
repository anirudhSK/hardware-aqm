#! /usr/bin/python
import sys
from math import sqrt
numerator = int(sys.argv[1])
print "case (i__input)"
for count in range(0, 1024):
  if (count == 0) :
    print "10'b"+str(bin(count)).split('b')[-1]," :"
    print "\tbegin"
    print "\to__output = 64'b"+str(bin(int(numerator))).split('b')[-1],";"
    print "\tend"
  else :
    print "10'b"+str(bin(count)).split('b')[-1]," :"
    print "\tbegin"
    print "\to__output = 64'b"+str(bin(int(numerator/sqrt(count)))).split('b')[-1],";"
    print "\tend"

print "default :\n\tbegin"
print "\to__output = 64'b"+str(bin(int(numerator/sqrt(count)))).split('b')[-1],";\n\tend"
print "endcase"
