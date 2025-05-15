#!/usr/bin/expect -f

##############################################
#
# Read configuration file
#
##############################################

proc read_config {filepath} {
    set configDict {}
    if {[file exists $filepath]} {
        set f [open $filepath r]
        while {[gets $f line] >= 0} {
            # Salta righe vuote o commenti
            if {[regexp {^\s*#} $line] || [regexp {^\s*$} $line]} {
                continue
            }
            # Analizza chiave=valore
            if {[regexp {^\s*([^=\s]+)\s*=\s*(.+)$} $line -> key value]} {
                dict set configDict $key $value
            }
        }
        close $f
    } else {
        puts "Errore: file di configurazione non trovato in $filepath"
        exit 1
    }
    return $configDict
}

set configFile [file join $env(HOME) ".hsmconfig"]
set configVars [read_config $configFile]

foreach key {username password secret} {
    if {![dict exists $configVars $key]} {
        puts "Errore: la chiave \"$key\" manca nel file di configurazione."
        exit 1
    }
}

set username [dict get $configVars username]
set password [dict get $configVars password]
set secret [dict get $configVars secret]


##############################################
#
# Read command line arguments
#
##############################################

set server "juno"
set loginNode ""

if { $argc >= 1 } {
    set server [string tolower [lindex $argv 0]]
}
if { $argc >= 2 } {
    set loginNode [lindex $argv 1]
}


##############################################
#
# Build server url
#
##############################################

if {![regexp {^(juno|cassandra)$} $server]} {
    puts "Errore: il server deve essere 'juno' o 'cassandra'."
    exit 1
}

if { $loginNode == "" } {
    set fullHost "login.$server.cmcc.scc"
} elseif { $loginNode == "1" } {
    set fullHost "login1.$server.cmcc.scc"
} elseif { $loginNode == "2" } {
    set fullHost "login2.$server.cmcc.scc"
} else {
    puts "Errore: loginNode deve essere vuoto, '1' o '2'."
    exit 1
}

set otp [exec oathtool --totp=sha1 -b $secret]


##############################################
#
# Connect
#
##############################################

spawn ssh -Y $username@$fullHost
expect "First Factor: "
send "$password\r"
expect "Second Factor: "
send "$otp\r"
interact
