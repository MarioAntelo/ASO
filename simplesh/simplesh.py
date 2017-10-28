#! /usr/bin/env python3
# -*- coding: utf-8; -*-

'''
    Testing `simplesh` v0.17.0 built on pexpect library:
    https://pexpect.readthedocs.io/en/stable/index.html

    Ampliación de Sistemas Operativos (Curso 2017/2018)
    Departamento de Ingeniería y Tecnología de Computadores
    Facultad de Informática de la Universidad de Murcia
'''


################################################################################


from enum import Enum

# Global imports
import argparse
import atexit
import json
import os
import pexpect
import re
import shutil
import subprocess
import sys
import tempfile


################################################################################


def info(*args):
    print("{}:".format(sys.argv[0]), *args)


def panic(*args):
    info(*args)
    sys.exit(1)


################################################################################


def parse_arguments():

    ''' Parse command-line arguments. '''

    parser = argparse.ArgumentParser(
        usage = '%(prog)s [-h] [options]',
        description = 'XXX testing system.',
        epilog = 'EXAMPLE: %(prog)s -i test.json'
    )

    parser.add_argument(
        '-i', '--in-test-file',
        type = argparse.FileType('r'),
        dest = 'test_file',
        required = True,
        help = 'JSON file containing list of tests.')

    return parser.parse_args()


################################################################################


class ShStatus(Enum):

    SUCCESS = 0
    FAILURE = 1
    TIMEOUT = 2
    EOFCORE = 3
    UNKNOWN = 4


################################################################################


class ShTest:

    ''' Shell tests. '''

    id = 0

    @staticmethod
    def setup(config_d):

        # Initialize class variables
        ShTest.echo    = False

        ShTest.shell   = config_d.get('shell', 'simplesh')
        ShTest.prompt  = config_d.get('prompt', 'simplesh> ')
        ShTest.timeout = config_d.get('timeout', 3)
        ShTest.verbose = config_d.get('verbose', 0)

        # Make sure pexpect can find the shell if it is in the current directory
        os.environ['PATH'] = os.environ.get('PATH', '') + ':' + os.getcwd()

        # TODO: Primitive filesystem sandboxing as chroot requires root privileges

        # Create temporary directory
        try:
            ShTest.cwd = os.getcwd()
            ShTest.tmp_dir = tempfile.TemporaryDirectory()
            os.chdir(ShTest.tmp_dir.name)
        except OSError:
            panic("Error: Unable to create temporary directory: '{}'.".format(ShTest.tmp_dir.name))
        else:
            info("Created temporary directory: '{}'.".format(ShTest.tmp_dir.name))

        # Execute commands
        try:
            cmds = config_d.get('cmds', '')
            for cmd in cmds:
                subprocess.check_output(cmd.split(' '))
        except OSError:
            panic("Error: Setup command not found: '{}'.".format(cmd))
        except subprocess.CalledProcessError:
            panic("Error: Setup command failed: '{}'.".format(cmd))
        else:
            info("Successfully executed setup commands: '{}'.".format(cmds))


    def __init__(self, test_d, config_d):

        if not hasattr(ShTest, 'id'):
            panic("Error: Call ShTest.setup!")

        if not ShTest.id:
            ShTest.setup(config_d)
        ShTest.id  += 1

        # Initialize instance variables
        self.id     = ShTest.id

        self.cmd    = test_d.get('cmd', '')
        self.out    = test_d.get('out', '')

        self.shproc = None
        self.status = ShStatus.UNKNOWN
        self.result = ''


    def run(self):

        # Execute shell
        try:
            self.shproc = pexpect.spawn(ShTest.shell,
                                        echo=ShTest.echo,
                                        timeout=ShTest.timeout)
        except pexpect.exceptions.ExceptionPexpect as e:
            panic("Test {:2}: Error executing shell: {}".format(self.id, e))

        # Wait for prompt, execute command and wait for prompt again
        try:
            idx = self.shproc.expect([ShTest.prompt])
            assert(idx == 0)

            self.shproc.sendline(self.cmd)

            idx = self.shproc.expect([ShTest.prompt])
            assert(idx == 0)
        # Prompt not found
        except (pexpect.exceptions.TIMEOUT):
            assert(self.shproc.isalive())
            self.status = ShStatus.TIMEOUT
        # Shell process finished or died
        except (pexpect.exceptions.EOF):
            assert(not self.shproc.isalive())
            if not self.shproc.status:
                self.result = (self.shproc.before.decode('utf-8')).strip() # Remove '\r\n'
                #print('{}'.format(list(self.result)))
                self.status = ShStatus.SUCCESS if re.search(self.out, self.result) else ShStatus.FAILURE
            else:
                self.status = ShStatus.EOFCORE
        # Prompt found: retrieve command output
        else:
            assert(self.shproc.isalive())
            self.result = self.shproc.before.decode('utf-8').strip() # Remove '\r\n'
            #print('{}'.format(list(self.result)))
            self.status = ShStatus.SUCCESS if re.search(self.out, self.result) else ShStatus.FAILURE
            self.cmd = self.cmd.translate({ord(c): ' ' for c in '\r\n'})
            self.result = self.result.translate({ord(c): ' ' for c in '\r\n'})
        finally:
            # Terminate process
            self.shproc.close(force=True) # Try to terminate process with SIGHUP, SIGINT or SIGKILL
            self.shproc.isalive()         # Update exitstatus and signalstatus


    def print(self):

        if self.status == ShStatus.UNKNOWN:
            panic("Test {:2}: Call self.run!".format(self.id))

        exit_status = self.shproc.exitstatus if self.shproc.exitstatus is not None else self.shproc.signalstatus

        print("{}: Test {:2}: ".format(sys.argv[0], self.id), end='')
        if self.verbose:
            print("Cmd '{:30}' : ".format(self.cmd[:30]), end='')
            print("Status [{:3}/".format(exit_status), end='')
            if self.status == ShStatus.SUCCESS:
                print("'{:20}' << '{:40}'] : ".format(self.out[:20], self.result.strip('\r\n')[:40]), end='')
            elif self.status == ShStatus.FAILURE:
                print("'{:20}' <> '{:40}'] : ".format(self.out[:20], self.result.strip('\r\n')[:40]), end='')
            elif self.status == ShStatus.TIMEOUT:
                print("{:^67}'] : ".format('TIMEOUT! Prompt not found!'), end='')
            elif self.status == ShStatus.EOFCORE:
                print("{:^67}'] : ".format('CORE! (ulimit -c unlimited)'), end='')

        if self.status == ShStatus.SUCCESS:
            print("OK!")
        else:
            print("KO!")


################################################################################


def main():

    '''Main driver'''

    # Parse command-line arguments
    args = parse_arguments()

    # Parse JSON file
    try:
        tests_json = json.load(args.test_file)
    except ValueError:
        panic("Error: Invalid JSON format.".format(args.test_file.name))

    # Instantiate test objects
    tests = [ ShTest(t, tests_json['setup']) for t in tests_json['tests'] ]

    # Run tests
    for test in tests:
        test.run()
        test.print()

    return 0


################################################################################


if __name__ == "__main__":
    sys.exit(main())
