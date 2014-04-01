docker-lvs-nginx
================

testing an nginx proxy/content + lvs setup in docker

Once again I'm putting my docker testbed craphere so that
if my laptop dies I have a backup; plus it's entertaining.
Who in their right mind would run a baby lvs redirector
in a docker container?

Requirements:

Be root for everything, many of these steps need privileges.
login root:testing for all containers as usual.

I've only tested on docker 0.9, docker server running fedora 20.

If you want to play, run things as root.  Here's the steps
in order:

Build all images and containers if needed and start them up:
   start-containers.sh
(better have built my deb base container first)

Create the nginx certs and stick em on the containers
  setup-certs.sh
  push-out-certs.sh

Put out html and conf files for the nginx servers, restart them:
  setup-nginx.sh

Set up all the /etc/hosts entries, lvs entries, arp off on
the nginx proxy, etc:
  configure.sh

Don't really need these once the entries are in your /etc/hosts
but anyways...
  ip-of-instance.sh
  ssh-to-instance.sh

Done with them for now?
  stop-containers.sh
You'll have to rerun configure.sh when you start them back up again
in order to get all the ip settings back in place

Done with them for good?
  delete-containers.sh

--------------

See TODO.txt for stuff I'm not likely to do any time soon.

All the stuff that edits /etc/hosts on server or container is
extremely iffy, double check yourself that there aren't duplicate
or extra entries left over.
