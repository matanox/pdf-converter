echo
echo -e "opening up the use of default web server ports for the currently logged in user."
echo -e "this is a good idea, as by default, linux blocks access to those ports for any user but root."
sudo touch /etc/authbind/byport/80
sudo chmod 500 /etc/authbind/byport/80
sudo chown `whoami` /etc/authbind/byport/80
sudo touch /etc/authbind/byport/443
sudo chmod 500 /etc/authbind/byport/443
sudo chown `whoami` /etc/authbind/byport/443
echo
echo -e "if no prior errors, the permissions are reflected in the permissions in the following files, and linux will no longer block them for that user."
echo
ls -la /etc/authbind/byport
