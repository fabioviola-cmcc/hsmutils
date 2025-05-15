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
            if {[regexp {^\s*#} $line] || [regexp {^\s*$} $line]} {
                continue
            }
            if {[regexp {^\s*([^=\s]+)\s*=\s*(.+)$} $line -> key value]} {
                dict set configDict $key $value
            }
        }
        close $f
    } else {
        puts "Errore: file di configurazione non trovato"
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

set otp [exec oathtool --totp=sha1 -b $secret]


##############################################
#
# Read command line arguments
#
##############################################

if { $argc < 2 } {
    puts "Uso: ./script.expect <origine> <destinazione> [loginNode] [server]"
    exit 1
}

set source [lindex $argv 0]
set destination [lindex $argv 1]

##############################################
#
# Build and run command
#
##############################################

set scpCommand "scp -r $source $destination"

spawn {*}$scpCommand

expect {
    "First Factor:" {
        send "$password\r"
        exp_continue
    }
    "Second Factor:" {
        send "$otp\r"
        exp_continue
    }
    eof
}
