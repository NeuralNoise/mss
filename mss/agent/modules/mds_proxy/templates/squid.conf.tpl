#
hierarchy_stoplist cgi-bin ?
acl QUERY urlpath_regex cgi-bin \?
no_cache deny QUERY
dns_nameservers localhost
maximum_object_size_in_memory 64 KB
cache_store_log none
hosts_file /etc/hosts
#
# Recommended minimum configuration:
#
acl manager proto cache_object
#acl webserver src 10.0.0.122/32
#http_access allow manager webserver
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
#acl localnet src 10.0.0.0/8    # RFC1918 possible internal network
#acl localnet src 172.16.0.0/12 # RFC1918 possible internal network
#acl localnet src 192.168.0.0/16        # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT
############################################# AUTH CONF #####################################
auth_param basic realm Atention: Autentication Required!
auth_param basic program /usr/lib/squid/squid_ldap_auth -b "@DN@" -f uid=%s localhost
auth_param basic children 3
auth_param basic casesensitive off
auth_param basic credentialsttl 1 hours

external_acl_type ldap_auth %LOGIN /usr/lib/squid/squid_ldap_group -d -b "dc=@DN@" -f "(&(memberuid=%u)(cn=%g))" -h localhost

######################################## GENERIC ACLs ########################
#
acl auth proxy_auth REQUIRED
#
######################################## MASTER GROUP ACLs ####################
#
acl master_group external ldap_auth "Internet Master"
#
#########################################  NORMAL GROUP ACLs #################
#
acl normal_group external ldap_auth "Internet Filtered"

acl normal_bad_ext urlpath_regex -i "/etc/squid/rules/group_internet/normal_blacklist_ext.txt"
acl normal_blacklist url_regex -i "/etc/squid/rules/group_internet/normal_blacklist.txt"
acl normal_whitelist url_regex -i "/etc/squid/rules/group_internet/normal_whitelist.txt"
#
################################ TIME ACLS ###################################
#
acl time_group external ldap_auth "Internet Time"

acl time_day       time MTWHF   "/etc/squid/rules/group_internet/time_day.txt"
#
################################# MACHINE ACL ###############################
#
acl machines src "/etc/squid/rules/group_internet/allow_machines.txt"
#
##############################################################################
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
#
##############################################################################
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
##############################################################################
#
http_access allow master_group all
http_access allow machines all
http_access deny normal_group normal_bad_ext
http_access allow normal_group !normal_blacklist
http_access allow time_group normal_whitelist
http_access allow normal_group normal_whitelist
#
#################################################################################
#
http_access allow localhost
http_access deny all
http_port 3128

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
refresh_pattern -i \.(mp3|mp4|m4a|ogg|mov|avi|wmv)$ 10080 90% 999999 ignore-no-cache override-expire ignore-private