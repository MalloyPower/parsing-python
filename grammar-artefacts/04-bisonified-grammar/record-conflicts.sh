LOGFILE="conflicts.txt"

rm -f $LOGFILE
for f in [0123]*.y; do 
	echo -n $f >> $LOGFILE
	bison -Wno-other -Wconflicts-sr -Wconflicts-rr $f 2>&1 | awk '{printf(": %s  %s",$3,$4);}' >> $LOGFILE
	echo "" >> $LOGFILE
done 
rm -f *.tab.c
echo Results written to $LOGFILE

