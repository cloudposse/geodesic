#!/bin/bash

[ -d /localhost/.awsvault ] || mkdir /localhost/.awsvault
ln -sf /localhost/.awsvault ${HOME}
