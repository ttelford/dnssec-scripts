#!/bin/bash
# temp dir for everything.
OLDDIR=${PWD}
TMPDIR=$(mktemp -d)
cd ${TMPDIR}

# The root anchors can be obtained from:
# https://data.iana.org/root-anchors/
# We use https:// for an additional layer of authentication - as https:// uses
# x.509 certificates.

wget https://data.iana.org/root-anchors/root-anchors.asc https://data.iana.org/root-anchors/root-anchors.xml https://data.iana.org/root-anchors/icann.pgp

# Import the GPG key obtained
echo "Importing IANA/ICANN GPG key (DNSSEC Manager <dnssec@iana.org>)"
gpg --import icann.pgp

# Verify the signature
echo "Verifying GPG signature"
gpg --verify root-anchors.asc root-anchors.xml

echo "Obtaining key via DNS"
# Via DNS:
dig . dnskey | grep "IN	DNSKEY	257 3 8" > root_dnskey
/usr/sbin/dnssec-dsfromkey -2 -f root_dnskey . > DSrecord

#Now to compare the two:
XMLKEY=$(cat root-anchors.xml | grep \<Digest\> | sed -e "s@<Digest>@@" | sed -e "s@</Digest>@@")
DNSKEY=$(cat DSrecord | awk '{print $7$8}')

echo "Key obtained via IANA https:	${XMLKEY}"
echo "Key obtained via DNS (dig):	${DNSKEY}"
if [[ ${XMLKEY} == ${DNSKEY} ]]
then
	echo "Keys validated."
else
	echo "Keys do not match!!"
fi

# Clean up
cd ${OLDDIR}
rm -rf ${TMPDIR}
