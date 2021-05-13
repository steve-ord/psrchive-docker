#!/usr/bin//python

import os
from subprocess import Popen, PIPE, check_call

#start up tempo2 service
check_call(["docker-compose","up","-d"])
p = Popen(["docker","ps","-aq"],stdout=PIPE,stderr=PIPE)
p.wait()

#want to add anything ...
container = "psrchive"
