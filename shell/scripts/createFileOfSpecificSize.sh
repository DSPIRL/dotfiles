#!/usr/bin/env bash

read -p "What is the file name?: " fileName
read -p "What is the file size you want to make?: " fileSize

truncate -s $fileSize $fileName
