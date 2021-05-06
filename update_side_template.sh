#!/bin/bash
SIDE_FILEPATH=$1
SIDE_FILENAME=`basename $SIDE_FILEPATH`
DIR=`dirname $0`
cd $DIR
cat $SIDE_FILEPATH | sed 's!"url": "[^"]\+",!"url": "EPRINTS_URL",!' | sed 's!"urls": \["[^"]\+"\],!"urls": ["EPRINTS_URL"],!' > $DIR/side_templates/${SIDE_FILENAME}.tmpl
