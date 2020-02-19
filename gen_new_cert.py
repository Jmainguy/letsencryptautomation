#!/usr/bin/python
import argparse
import subprocess
import sys
import os

parser = argparse.ArgumentParser(description='Update ssl certs with Lets Encrypt as needed')
parser.add_argument('domain', help='domain to update')
args = parser.parse_args()
domain = args.domain

def bash(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    rc = p.wait()
    return stdout, stderr, rc

# Bak working haproxy.cfg
print "HAproxy stuff"
cmd = 'bak -f /etc/haproxy/haproxy.cfg'
bash(cmd)
cmd = 'cp /etc/ssl/private/letsencrypt/haproxy.cfg /etc/haproxy/haproxy.cfg'
bash(cmd)
cmd = 'systemctl restart haproxy'
bash(cmd)

print "creating cert now"
# Create certs
domain_len = domain.split('.')
if len(domain_len) == 2:
    cmd = 'ssh le.soh.re "/usr/src/letsencrypt/certbot-auto --text --email jon@soh.re --domains %s,www.%s --agree-tos --webroot -w /var/www/html certonly"' % (domain, domain)
elif len(domain_len) >= 3:
    cmd = 'ssh le.soh.re "/usr/src/letsencrypt/certbot-auto --text --email jon@soh.re --domains %s --agree-tos --webroot -w /var/www/html certonly"' % domain
stdout, stderr, rc = bash(cmd)
print rc
print stdout

# Copy certs to haproxy location
dir = '/etc/ssl/private/letsencrypt/' + domain
if not os.path.isdir(dir):
    os.makedirs(dir)

# scp certs from vm to host
cmd = 'scp root@le.soh.re:/etc/letsencrypt/live/%s/* %s/' % (domain, dir)
bash(cmd)
cmd = 'cat %s/fullchain.pem > %s/%s.pem' % (dir, dir, domain)
bash(cmd)
cmd = 'cat %s/privkey.pem >> %s/%s.pem' % (dir, dir, domain)
bash(cmd)
cmd = 'cp %s/%s.pem /etc/ssl/private/' % (dir, domain)
bash(cmd)
cmd = 'unbak /etc/haproxy/haproxy.cfg.bak'
bash(cmd)
cmd = 'systemctl restart haproxy'
bash(cmd)
