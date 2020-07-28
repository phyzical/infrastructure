#!/usr/bin/python

#
# load in a PHP or nginx .conf env var file
# parse it and output it as key=value environment
# pairs to be sourced, or prefixed in a command
# line
#

import re
import sys
from optparse import OptionParser

def read_file_lines(filename):
    with open(filename) as fh:
        return fh.readlines()

def php_line(line):
    assert "[" in line
    assert "]" in line
    assert "=" in line
    results = re.search('^env\[(.+)\]\s*=\s*["\'](.+)["\']\s*$', line)
    if results:
        return results.group(1), results.group(2)

def nginx_line(line):
    results = re.search('^fastcgi_param\s*(.+)\s+["\'](.+)["\'];\s*$', line)
    if results:
        return results.group(1), results.group(2)

def apache_line(line):
    results = re.search('^SetEnv\s+(.+)\s+["\'](.+)["\']\s*$', line)
    if results:
        return results.group(1), results.group(2)


def process_lines(lines, func):
    results = [func(l.strip()) for l in lines if l.strip()]
    return {k:v for (k,v) in [line for line in results if line]}

def process_file(filename, func):
    envs = process_lines(read_file_lines(filename), func)
    return ["%s=%s"%(key, val)
            for (key,val) in envs.iteritems()]

def process(filename, func):
    print " ".join(process_file(filename, func))

def parse_command_line():
    parser = OptionParser(
        usage="usage: %prog [options] conf-file",
        description="read in a config file containing env var settings and parse, printing to standard output a bash env var settings code block to be sourced into a shell environment.")
    parser.add_option("-n", "--nginx", dest="nginx", action="store_true", help="parse an nginx config file")
    parser.add_option("-p", "--php", dest="php", action="store_true", help="parse a php.ini config file")
    parser.add_option("-a", "--apache", dest="apache", action="store_true", help="parse an apache directives config file")
    return parser.parse_args()

def main():
    options, args = parse_command_line()
    assert len(args)==1, "need to pass in a single argument containing path to config file"
    assert options.nginx or options.php or options.apache, "you need to specify if it is a php, an nginx or an apache config file"
    num_options = (1 if options.nginx else 0) + (1 if options.apache else 0) + (1 if options.php else 0)
    assert num_options==1, "you cannot specify both a php and an nginx config file"
    if options.php:
        process(args[0], php_line)
    elif options.apache:
        process(args[0], apache_line)
    elif options.nginx:
        process(args[0], nginx_line)

if __name__ == "__main__":
    main()
