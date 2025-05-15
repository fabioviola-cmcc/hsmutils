#!/usr/bin/expect -f

# === Funzione: Legge file di configurazione ===
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

# === Leggi file di configurazione ===
set configFile [file join $env(HOME) ".hsmconfig"]
set configVars [read_config $configFile]

# === Controlla se le chiavi esistono ===
foreach key {username password otppath} {
    if {![dict exists $configVars $key]} {
        puts "Errore: la chiave \"$key\" manca nel file di configurazione."
        exit 1
    }
}

# === Estrai variabili dal config ===
set username [dict get $configVars username]
set filePath [dict get $configVars password]
set jotpPath [dict get $configVars otppath]

# === Argomenti da linea di comando ===
set server "juno"
set loginNode ""

if { $argc >= 1 } {
    set server [string tolower [lindex $argv 0]]
}
if { $argc >= 2 } {
    set loginNode [lindex $argv 1]
}

# === Verifica server valido ===
if {![regexp {^(juno|cassandra)$} $server]} {
    puts "Errore: il server deve essere 'juno' o 'cassandra'."
    exit 1
}

# === Costruisci host ===
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

# === Leggi la password dal file ===
if {![file exists $filePath]} {
    puts "Errore: file password non trovato: $filePath"
    exit 1
}
set fileHandle [open $filePath r]
set password [gets $fileHandle]
close $fileHandle

# === Ottieni OTP ===
if {![file exists $jotpPath]} {
    puts "Errore: script OTP non trovato: $jotpPath"
    exit 1
}

set secretFile "/home/val/.ssh/juno_secret"
if {![file exists $secretFile]} {
    puts "Errore: file secret OTP non trovato: $secretFile"
    exit 1
}
set otp [exec oathtool --totp=sha1 -b [exec cat $secretFile]]

# === Connessione SSH ===
spawn ssh -Y $username@$fullHost
expect "First Factor: "
send "$password\r"
expect "Second Factor: "
send "$otp\r"
interact
