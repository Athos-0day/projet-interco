#!/bin/bash
EASYRSA_DIR="/etc/openvpn/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"
OUTPUT_DIR="/home/client_ovpn"

mkdir -p $OUTPUT_DIR
echo "CREATION DES CLES CLIENT"
CLIENT_ID = "test"
echo "Création du certificat pour $CLIENT_ID"

# creation de la clée 
cd $PKI_DIR
./easyrsa --batch build-client-full $CLIENT_ID


# generation du fichier .ovpn a donner au client 
cp /etc/openvpn/client.conf $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
cat$PKI_DIR/ca.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <$PKI_DIR/issued/$CLIENT_ID.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
cat$PKI_DIR/private/$CLIENT_ID.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < /etc/openvpn/server/ta.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn

for CLIENT_ID in $(ldapsearch -x -LLL \
  -H ldaps:192.168.49.21 \
  -D "cn=readonly,dc=example,dc=com" \
  -W \
  -b "ou=People,dc=example,dc=com" \
  "(objectClass=posixAccount)" uid \
  | grep '^uid:' | cut -d' ' -f2); do

  echo "Création du certificat pour $CLIENT_ID"

  # creation de la clée 
  cd $PKI_DIR
  ./easyrsa --batch build-client-full $CLIENT_ID


  # generation du fichier .ovpn a donner au client 
  cp /etc/openvpn/client.conf $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "<ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  cat$PKI_DIR/ca.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "</ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "<cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <$PKI_DIR/issued/$CLIENT_ID.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "</cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "<key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  cat$PKI_DIR/private/$CLIENT_ID.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "</key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "<tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < /etc/openvpn/server/ta.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
  echo "</tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn


done

