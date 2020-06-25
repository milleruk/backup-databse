#!/bin/bash

user=xxxx # Change this to the root user
pw=xxxx # Change this to the root password
max_children=5
host=127.0.0.1 # Change this to localhost most likely

cd $1
DATE=`date +%Y-%m-%d`

dbs=$(echo "select distinct table_schema from information_schema.tables where table_schema not in ('information_schema', 'mysql', 'performance_schema');" | mysql -u $user -p$pw -h$host)
for each in $dbs ; do
        if [ $each = "table_schema" ] ; then continue; fi
        mkdir -p $each/$DATE 2>/dev/null

	## Clean out the dir from old backups
	count=$(ls -1 $each/$DATE | wc -w)
	while [ $count -gt 5 ]; do
	        OLDDIR=$(ls -1 $each/$DATE | head -n 1)
	        echo Cleaning $each/$DATE ...
	        rm -rf $OLDDIR
	        count=$(ls -1 $each | wc -w)
	done

        tables=$(echo "SELECT table_name from (SELECT table_name, round(((data_length + index_length) / 1024 / 1024),2) size FROM information_schema.TABLES WHERE table_schema = '$each') as f order by size" | mysql -u $user -p$pw -h$host)
        for table in $tables ; do
                if [ $table = "table_name" ] ; then continue; fi

                num_children=$(( $max_children + 1 ))
                while [ $num_children -gt $max_children ] ; do
                        bash_pid=$$
                        children=`ps -eo ppid | grep -w $bash_pid`
                        num_children=`echo $children | wc -w`
                        if [ $num_children -gt $max_children ]; then sleep 0.1 ; fi
                done

                (
                        echo $each.$table
                        while ! mysqldump --routines --triggers --compact --disable-keys --add-drop-table --single-transaction -e -q -u $user -p$pw -h$host $each $table | gzip -3 --rsyncable > $each/$DATE/$table.sql.gz ; do sleep 15; done
                ) &
        done
done

wait
