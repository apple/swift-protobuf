#!/bin/sh

new_copyright=""

for f in `find . -name '*.swift' | sed -e 's|./||' | grep -v '.pb.swift'`; do
    if head -n 4 $f | grep 'DO NOT EDIT' > /dev/null; then
        # If the first lines contain 'DO NOT EDIT', then
        # this is a generated file and we should not
        # try to check or edit the copyright message.
        # But: print the filename; all such files should be .pb.swift
        # files that we're not even looking at here.
        echo "DO NOT EDIT: $f"
    else
        if head -n 10 $f | grep 'Copyright.*Apple' > /dev/null; then
            # This has a copyright message, update it
            tmp=$f~
            mv $f $tmp
            head -n 1 $tmp | sed "s|// [^-]* - \(.*\)|// $f - \1|" >$f
            cat <<EOF >>$f
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
EOF
            # The copyright message ends at the first blank comment line after
            # the first line containing "LICENSE.txt":
            cat $tmp | sed -n '/LICENSE.txt/,$ p' | sed -n '/^\/\/$/,$ p' >> $f
        else
            # This does not have a copyright message, insert one
            echo "Inserting copyright >> $f"
            tmp=$f~
            mv $f $tmp
            cat <<EOF >>$f
// $f - description
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

EOF
            cat $tmp >> $f
        fi
    fi
done


echo <<EOF
/*
 * DO NOT EDIT.
EOF
