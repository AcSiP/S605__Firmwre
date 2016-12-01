BEGIN { OFS = "#"; } # OFS is a field separator used for "print"
/\<Cell/ {
	# New cell description has started, so we need to print a previous one.
	# Detect auth_mode mode first.
	if(essid) print essid, auth_mode, encrypt_type;
	# Reset auth_mode flags.
	auth_mode = ""
	encrypt_type = ""
}
/\<ESSID:/ {
	essid = substr($0, index($0, ":") + 1);
	essid = substr(essid, 2, length(essid) - 2)  # discard quotes
	auth_mode = "OPEN"
	encrypt_type = "NONE"
}
/\<Encryption key:(o|O)n/ {
	auth_mode = "SHARED" 
	encrypt_type = "WEP"
}
/\<IE:.*WPA.*/ { auth_mode = "WPA" }
/\<IE:.*WPA2.*/ { auth_mode = "WPA2" }
/\<Pairwise Ciphers.*TKIP.*/ {
	encrypt_type = "TKIP"
}
/\<Pairwise Ciphers.*CCMP.*/ {
	encrypt_type = "AES"
}
/\<Authentication Suites.*PSK.*/ {
	auth_mode = auth_mode"PSK"
}
END {
    # handle last cell
    if(essid) print essid, auth_mode, encrypt_type;
}
