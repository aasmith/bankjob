#!/bin/sh
# Required: curl, xmllint
# Optional: tidy

# Program options
DOWNLOAD=0
OUTDIR=fidata
ENCODING=

# Check for pretty printing capability
TIDY=`which tidy`
ICONV=`which iconv`
ICONVCMD="$ICONV -f utf-16le -t us-ascii"
if test -n $TIDY; then
	# Format with tidy
	#TIDYCMD="$TIDY -xml -indent -quiet -utf16le -wrap 0"
	TIDYCMD="$TIDY -xml -indent -quiet -wrap 0"
else
	# Skip formatting
  echo "skipping tidy"
	TIDYCMD="cat"
fi

# Create out dirs
init() {
	if test ! -d $OUTDIR; then mkdir $OUTDIR; fi
	if test ! -d $OUTDIR/fi; then mkdir $OUTDIR/fi; fi
}

# Fetch main financial institution indexes from MS
fetch_fi_indices() {
	# Fetch index files for financial institutions
	if test $DOWNLOAD -eq 1 -o ! -e $OUTDIR/bank.xml; then
		echo -n "Fetching bank index..."
		if curl -s -d "T=1&S=*&R=1&O=0&TEST=0" http://moneycentral.msn.com/money/2008/mnynet/service/ols/filist.aspx?SKU=3\&VER=9 | $ICONVCMD | $TIDYCMD > $OUTDIR/bank.xml; then
			echo "ok"
		else
			echo "failed"
		fi
	fi
	if test $DOWNLOAD -eq 1 -o ! -e $OUTDIR/creditcard.xml; then
		echo -n "Fetching credit card index..."
		if curl -s -d "T=2&S=*&R=1&O=0&TEST=0" http://moneycentral.msn.com/money/2008/mnynet/service/ols/filist.aspx?SKU=3\&VER=9 | $ICONVCMD | $TIDYCMD > $OUTDIR/creditcard.xml; then
			echo "ok"
		else
			echo "failed"
		fi
	fi
	if test $DOWNLOAD -eq 1 -o ! -e $OUTDIR/brokerage.xml; then
		echo -n "Fetching brokerage index..."
		if curl -s -d "T=3&S=*&R=1&O=0&TEST=0" http://moneycentral.msn.com/money/2008/mnynet/service/ols/filist.aspx?SKU=3\&VER=9 | $ICONVCMD | $TIDYCMD > $OUTDIR/brokerage.xml; then
			echo "ok"
		else
			echo "failed"
		fi
	fi
}

# Fetch individual FI data from MS
fetch_fi_data() {
	echo "Loading financial institutions..."
	# Convert to UTF-8 to grep GUIDs from UTF-16 file
	for GUID in `xmllint --encode utf-8 $OUTDIR/*.xml | grep "<guid>" | sed -e "s|^.*<guid>\\(.*\\)</guid>.*$|\\1|" | sort -g`; do
		if test $DOWNLOAD -eq 1 -o ! -e $OUTDIR/fi/$GUID.xml; then
			echo -n "Fetching details for $GUID..."
			if curl -s http://moneycentral.msn.com/money/2008/mnynet/service/olsvcupd/OnlSvcBrandInfo.aspx?MSNGUID=\&GUID=$GUID\&SKU=3\&VER=9 | $ICONVCMD | $TIDYCMD > $OUTDIR/fi/$GUID.xml; then
				echo "ok"
			else
				echo "failed"
			fi
		fi
	done
}

create_master_index() {
	echo "Saved financial institution details in directory \"$OUTDIR\"."
}

convert_encoding() {
	CONVERTDIR=${OUTDIR}.${ENCODING}
	DISPENCODING=`echo $ENCODING | tr [:lower:] [:upper:]`
	echo "Converting to $DISPENCODING in directory \"$CONVERTDIR\" (may take awhile)..."
	if test ! -d $CONVERTDIR; then
		mkdir $CONVERTDIR
		mkdir $CONVERTDIR/fi
	fi
	for TYPE in bank creditcard brokerage; do
		xmllint --encode $ENCODING $OUTDIR/$TYPE.xml > $CONVERTDIR/$TYPE.xml
	done
	for FI in $OUTDIR/fi/*.xml; do
		CONVFI=`echo $FI | sed -e "s/fidata/$CONVERTDIR/g"`
		xmllint --encode $ENCODING $FI > $CONVFI
	done
}

usage() {
	echo "Usage: $0 [options]"
	echo "Options:"
	echo "    -d, --download        Download fresh financial institution data"
	echo "    -e, --encoding        Convert from UTF-16 to the specified encoding"
	echo "    -o, --out-dir=[dir]   Output directory"
}

run() {
	if test ! -d $OUTDIR; then
		DOWNLOAD=1
		init
	fi
	fetch_fi_indices
	fetch_fi_data
	create_master_index
	if test -n "$ENCODING"; then
		convert_encoding $ENCODING
	fi
}

while [ $# != 0 ]; do
	OPTION=$1
	shift
	case $OPTION in
		-d|--download) DOWNLOAD=1;;
		-e|--encoding|--encoding=*)
			if echo $OPTION | grep -q =; then
				ENCODING=`echo $OPTION | sed -e "s/^.*=\(.*\)$/\\1/g"`
			else
				ENCODING=$1
				shift
			fi
			;;
		-o|--out-dir|--out-dir=*)
			if echo $OPTION | grep -q =; then
				OUTDIR=`echo $OPTION | sed -e "s/^.*=\(.*\)$/\\1/g"`
			else
				OUTDIR=$1
				shift
			fi
			;;
		-h|--help) usage; exit 0;;
	esac
done

run
