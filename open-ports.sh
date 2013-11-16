echo
echo "This script opens up the use of default web server ports for the currently logged in user."
echo "This is a good idea, as by default, linux blocks access to those ports for any user but root."
sudo touch /etc/authbind/byport/80
sudo chmod 500 /etc/authbind/byport/80
sudo chown `whoami` /etc/authbind/byport/80
sudo touch /etc/authbind/byport/443
sudo chmod 500 /etc/authbind/byport/443
sudo chown `whoami` /etc/authbind/byport/443
echo
echo "If no prior errors, the permissions are reflected in the permissions in the following files, and linux will no longer block them for that user."
echo
ls -la /etc/authbind/byport
