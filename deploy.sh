#!/bin/bash
EPRINTS_PATH=$1
EPRINTS_URL=$2
dir=`dirname $0`
cd $dir
for template in `ls side_templates/`; do
	side=`echo $template | sed 's/\.tmpl$//'`
	cat side_templates/$template | sed "s!EPRINTS_URL!$EPRINTS_URL!g" > sides/$side
done
if [ -d $EPRINTS_PATH/lib/static/ ]; then
	cp selenium.xpage $EPRINTS_PATH/lib/static/
else
	echo "WARNING: You will need to copy $dir/selenium.xpage to $EPRINTS_PATH/lib/static/ on your EPrints repository server!"
fi

