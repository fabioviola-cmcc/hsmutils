#!/usr/bin/expect -f

# === Funzione: Legge file di configurazione ===
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

# === Leggi file di configurazione ===
set configFile [file join $env(HOME) ".hsmconfig"]
set configVars [read_config $configFile]

# === Controlla se le chiavi esistono ===
foreach key {username password secret} {
    if {![dict exists $configVars $key]} {
        puts "Errore: la chiave \"$key\" manca nel file di configurazione."
        exit 1
    }
}

# === Estrai variabili dal config ===
set username [dict get $configVars username]
set password [dict get $configVars password]
set secret [dict get $configVars secret]

# === OTP ===
set otp [exec oathtool --totp=sha1 -b $secret]

# === Argomenti ===
if { $argc < 2 } {
    puts "Uso: ./script.expect <origine> <destinazione> [loginNode] [server]"
    exit 1
}

set source [lindex $argv 0]
set destination [lindex $argv 1]

# === Costruisci comando SCP ===
set scpCommand "scp -r $source $destination"

# === Avvia SCP ===
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
