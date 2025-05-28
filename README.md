# hsmUtils

This repository hosts a set of scripts to connect to Juno or Cassandra
using ssh but automating the boring part of 1st and 2nd factor
authentication. **NOTE:** tools provided through this repository are
not developed or officially supported by CMCC HSM.

## Initial setup

First of all, you have to create a file in your home directory called
`.hsmconfig`. Follow the template included in this repository to see
which are the required fields.

Second (and last), you should add the folder containing this script to
your path directory, so that you can easily invoke these script from
each path of your filesystem. Then, modify your `.bashrc` file adding:

```
PATH=$PATH:/path/to/this/repository
```


## Connecting to Juno/Cassandra

To connect to Juno:

```
$ ./hsmConnect.sh juno
```

You can force using login node 1 or 2 by simply adding 1 or 2 at the
end of the line. By not specifying it, the destination login node will
be the login1.

To connect to Cassandra, follow the same procedure, but replace `juno`
with `cassandra`.

**NOTE:** Before using this tool, be sure that you have already
  performed at least one connection to each of the login nodes,
  otherwise the server will ask to confirm the fingerprint and this is
  not yet implemented in our script.

## Transfer files to/from Juno/Cassandra

This script works exactly like the well known `scp`, so you should be
comfortable with it.

Transferring data from Juno to local host and vice versa:

```
$ ./hsmCopy.sh user@login1.juno.cmcc.scc:/path/to/file .
$ ./hsmCopy.sh :/path/to/file user@login1.juno.cmcc.scc:/path/to/destination
```

The same for `cassandra`, just replace the word `juno`.