#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os
import select
import threading
import xmlrpclib
from subprocess import Popen, PIPE, STDOUT


class ExecManager:
    """ Class managing running tasks """

    def __init__(self):
        self.thread = None
        self.code = None
        self.output = ""

    def load_packages(self):
        """ get all installed packages """
        self.launch(["rpm", "-qa", "--queryformat", "%{NAME}#"], wait=True)
        if self.code == 0:
            packages = self.output.split('#')
        else:
            packages = []
        return packages

    def install_packages(self, packages):
        """ launch installation of packages list """
        #self.launch(['mss-test'])
        self.launch(["urpmi", "--auto"] + packages)

    def run_script(self, script, args, cwd):
        """ launch configuration script for module """
        #self.launch(['mss-test'])
        print cwd
        self.launch(["bash", script] + args, cwd=cwd)
        
    def add_media(self, name, proto, url, login=None, passwd=None):
        """ add media """
        if login and passwd:
            self.launch(["urpmi.addmedia", "--distrib",
                proto+"://"+login+":"+passwd+"@"+url], wait=True)
            #self.launch(["ls", "-a"], wait=True)
        else:
            self.launch(["urpmi.addmedia", "--distrib",
                proto+"://"+url], wait=True)
            #self.launch(["ls", "-a"], wait=True)
        return (self.code, self.output)

    def launch(self, command, wait=False, cwd=None):
        """ launch wrapper """    
        # accept only one thread
        if threading.activeCount() == 1:
            self.output = ""
            self.code = 2000
            self.thread = ExecThread(self, command, cwd)
            self.thread.start()
            if wait:
                self.thread.join()
        else:
            raise ExecManagerBusyError, "ExecManager is busy"

    def get_state(self):
        """ get current/last execution context """
        return (self.code, xmlrpclib.Binary(self.output))


class ExecThread(threading.Thread):
    """ Base class for running tasks """

    def __init__(self, EM, command, cwd):
        self.EM = EM
        self.process = None
        self.command = command
        self.cwd = cwd
        self.lock = threading.RLock()
        threading.Thread.__init__(self)

    def run(self):
        """ run command """
        self.process = Popen(self.command, stdout=PIPE, stderr=STDOUT,
            bufsize=1, shell=False, cwd=self.cwd)
        self.get_output()
        return 0

    def get_output(self):
        """ get command context """
        while self.isAlive():
            self.process.poll()
            if self.process.returncode == None:
                try:
                    fd = select.select([self.process.stdout.fileno()],
                        [], [], 5)[0][0]
                # raise an exception when the process doesn't make output
                # for long time
                except IndexError:
                    pass
                if fd:
                    self.lock.acquire()
                    self.EM.output += os.read(fd, 1)
                    self.lock.release()
            else:
                self.EM.code = self.process.returncode
                break


class ExecManagerError(Exception):
    """Base class for exceptions in ExecManager."""

    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return self.msg

class ExecManagerBusyError(ExecManagerError):
    pass
