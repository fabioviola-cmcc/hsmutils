#!/bin/bash

oathtool --totp=sha1 -b $(cat /home/val/.ssh/juno_secret)
