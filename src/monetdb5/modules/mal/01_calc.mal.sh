# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 1997 - July 2008 CWI, August 2008 - 2016 MonetDB B.V.

sed '/^$/q' $0			# copy copyright from this file

cat <<EOF
# This file was generated by using the script ${0##*/}.

module calc;

EOF

integer="bte sht int wrd lng"	# all integer types
numeric="$integer flt dbl"	# all numeric types
fixtypes="bit $numeric oid"
alltypes="$fixtypes str"

for tp in $numeric; do
    cat <<EOF
pattern iszero(v:$tp) :bit
address CMDvarISZERO
comment "Unary check for zero of V";

EOF
done
echo

for func in nil notnil; do
    cat <<EOF
pattern is$func(v:any) :bit
address CMDvarIS${func^^}
comment "Unary check for $func of V";

EOF
    echo
done

com="Return the Boolean inverse"
for tp in bit $integer; do
    cat <<EOF
pattern not(v:$tp) :$tp
address CMDvarNOT
comment "$com";

EOF
    com="Unary bitwise not of V"
done
echo

for tp in $numeric; do
    cat <<EOF
pattern sign(v:$tp) :bte
address CMDvarSIGN
comment "Unary sign (-1,0,1) of V";

EOF
done
echo

for func in 'abs:ABS:Unary absolute value of V' \
    '-:NEG:Unary negation of V' \
    '++:INCRsignal:Unary V + 1' \
    '--:DECRsignal:Unary V - 1'; do
    op=${func%%:*}
    com=${func##*:}
    func=${func%:*}
    func=${func#*:}
    for tp in $numeric; do
	cat <<EOF
pattern $op(v:$tp) :$tp
address CMDvar${func}
comment "$com";

EOF
    done
    echo
done

for func in +:ADD -:SUB \*:MUL; do
    name=${func#*:}
    op=${func%:*}
    for tp1 in bte sht int wrd lng flt; do
	for tp2 in bte sht int wrd lng flt; do
	    case $tp1$tp2 in
	    *flt*) tp3=dbl;;
	    *lng*) continue;;	# lng only allowed in combination with flt
	    *wrd*) continue;;	# wrd only allowed in combination with flt
	    *int*) tp3=lng;;
	    *sht*) tp3=int;;
	    *bte*) tp3=sht;;
	    esac
	    cat <<EOF
pattern $op(v1:$tp1,v2:$tp2) :$tp3
address CMDvar${name}signal
comment "Return V1 $op V2, guarantee no overflow by returning larger type";

EOF
	done
    done
    echo
done

for func in +:ADD -:SUB \*:MUL; do
    name=${func#*:}
    op=${func%:*}
    for tp1 in $numeric; do
	for tp2 in $numeric; do
	    case $tp1$tp2 in
	    *dbl*) tp3=dbl;;
	    *flt*) tp3=flt;;
	    *lng*) tp3=lng;;
	    *wrd*) tp3=wrd;;
	    *int*) tp3=int;;
	    *sht*) tp3=sht;;
	    *bte*) tp3=bte;;
	    esac
	    cat <<EOF
pattern $op(v1:$tp1,v2:$tp2) :$tp3
address CMDvar${name}signal
comment "Return V1 $op V2, signal error on overflow";
pattern ${name,,}_noerror(v1:$tp1,v2:$tp2) :$tp3
address CMDvar${name}
comment "Return V1 $op V2, overflow causes NIL value";

EOF
	done
    done
    echo
done
cat <<EOF
command +(v1:str,v2:str) :str
address CMDvarADDstr
comment "Concatenate LEFT and RIGHT";
command +(v1:str,i:int) :str
address CMDvarADDstrint
comment "Concatenate LEFT and string representation of RIGHT";

EOF

for tp1 in $numeric; do
    for tp2 in $numeric; do
	case $tp1$tp2 in
	*dbl*) tp3=dbl;;
	*flt*) tp3=flt;;
	lng*) tp3=lng;;
	wrd*) tp3=wrd;;
	int*) tp3=int;;
	sht*) tp3=sht;;
	bte*) tp3=bte;;
	esac
	if [ $tp3 != dbl ]; then
	    if [ $tp3 != flt ]; then
		cat <<EOF
pattern /(v1:$tp1,v2:$tp2) :flt
address CMDvarDIVsignal
comment "Return V1 / V2, signal error on overflow";
EOF
	    fi
	    cat <<EOF
pattern /(v1:$tp1,v2:$tp2) :dbl
address CMDvarDIVsignal
comment "Return V1 / V2, signal error on overflow";
EOF
	fi
	cat <<EOF
pattern /(v1:$tp1,v2:$tp2) :$tp3
address CMDvarDIVsignal
comment "Return V1 / V2, signal error on overflow";
pattern div_noerror(v1:$tp1,v2:$tp2) :$tp3
address CMDvarDIV
comment "Return V1 / V2, overflow causes NIL value";

EOF
    done
done
    echo

for tp1 in $numeric; do
    for tp2 in $numeric; do
	case $tp1$tp2 in
	*dbl*) tp3=dbl;;
	*flt*) tp3=flt;;
	*bte*) tp3=bte;;
	*sht*) tp3=sht;;
	*int*) tp3=int;;
	*wrd*) tp3=wrd;;
	*lng*) tp3=lng;;
	esac
	cat <<EOF
pattern %(v1:$tp1,v2:$tp2) :$tp3
address CMDvarMODsignal
comment "Return V1 % V2, signal error on divide by zero";
pattern mod_noerror(v1:$tp1,v2:$tp2) :$tp3
address CMDvarMOD
comment "Return V1 % V2, divide by zero causes NIL value";

EOF
    done
done
echo

for op in and or xor; do
    for tp in bit $integer; do
	cat <<EOF
pattern ${op}(v1:$tp,v2:$tp) :$tp
address CMDvar${op^^}
comment "Return V1 ${op^^} V2";

EOF
    done
    echo
done

for func in '<<:lsh' '>>:rsh'; do
    op=${func%:*}
    func=${func#*:}
    for tp1 in $integer; do
	for tp2 in $integer; do
	    cat <<EOF
pattern $op(v1:$tp1,v2:$tp2) :$tp1
address CMDvar${func^^}signal
comment "Return V1 $op V2, raise error on out of range second operand";
pattern ${func}_noerror(v1:$tp1,v2:$tp2) :$tp1
address CMDvar${func^^}
comment "Return V1 $op V2, out of range second operand causes NIL value";

EOF
	done
    done
    echo
done

for func in '<:lt' '<=:le' '>:gt' '>=:ge' '==:eq' '!=:ne'; do
    op=${func%:*}
    func=${func#*:}
    for tp in bit str oid; do
	cat <<EOF
pattern $op(v1:$tp,v2:$tp) :bit
address CMDvar${func^^}
comment "Return V1 $op V2";

EOF
    done
    for tp1 in $numeric; do
	for tp2 in $numeric; do
	    cat <<EOF
pattern $op(v1:$tp1,v2:$tp2) :bit
address CMDvar${func^^}
comment "Return V1 $op V2";

EOF
	done
    done
    echo
done

op=${func%:*}
func=${func#*:}
for tp in bit str oid; do
    cat <<EOF
pattern cmp(v1:$tp,v2:$tp) :bte
address CMDvarCMP
comment "Return -1/0/1 if V1 </==/> V2";

EOF
done
for tp1 in $numeric; do
    for tp2 in $numeric; do
	cat <<EOF
pattern cmp(v1:$tp1,v2:$tp2) :bte
address CMDvarCMP
comment "Return -1/0/1 if V1 </==/> V2";

EOF
    done
done
echo

cat <<EOF
pattern between(b:any_1,lo:any_1,hi:any_1) :bit
address CMDvarBETWEEN
comment "B between LO and HI inclusive";

pattern between_symmetric(b:any_1,v1:any_1,v2:any_1) :bit
address CMDvarBETWEENsymmetric
comment "B between V1 and V2 (or vice versa) inclusive";

EOF

for tp1 in void $alltypes; do
    for tp2 in void $alltypes; do
	cat <<EOF
pattern $tp1(v:$tp2) :$tp1
address CMDvarCONVERT
comment "Cast VALUE to $tp1";

EOF
    done
    echo
done

for func in min min_no_nil max max_no_nil; do
    if [[ $func == *_no_nil ]]; then
	com=", ignoring nil values"
    else
	com=
    fi
    cat <<EOF
pattern $func(v1:any_1, v2:any_1) :any_1
address CALC$func
comment "Return ${func%%_*} of V1 and V2$com";

EOF
done

cat <<EOF
command ptr(v:ptr) :ptr
address CMDvarCONVERTptr
comment "Cast VALUE to ptr";

pattern setoid(v:int) :void
address CMDsetoid;
pattern setoid(v:oid) :void
address CMDsetoid;
pattern setoid(v:lng) :void
address CMDsetoid;

pattern ifthenelse(b:bit,t:any_1,f:any_1):any_1
address CALCswitchbit
comment "If VALUE is true return MIDDLE else RIGHT";

command length(s:str) :int
address CMDstrlength
comment "Length of STRING";

EOF

cat <<EOF
module aggr;

EOF

for func in sum:sum prod:product; do
    for tp1 in 1:bte 2:sht 4:int 8:wrd 8:lng; do
	for tp2 in 1:bte 2:sht 4:int 4:wrd 8:lng 8:dbl; do
	    if [ ${tp1%:*} -le ${tp2%:*} -o ${tp1#*:} = ${tp2#*:} ]; then
		cat <<EOF
pattern ${func%:*}(b:bat[:${tp1#*:}]) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B.";
pattern ${func%:*}(b:bat[:${tp1#*:}],nil_if_empty:bit) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B.";
pattern ${func%:*}(b:bat[:${tp1#*:}],s:bat[:oid]) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B with candidate list.";
pattern ${func%:*}(b:bat[:${tp1#*:}],s:bat[:oid],nil_if_empty:bit) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B with candidate list.";

EOF
	    fi
	done
    done

    for tp1 in 4:flt 8:dbl; do
	for tp2 in 4:flt 8:dbl; do
	    if [ ${tp1%:*} -le ${tp2%:*} ]; then
		cat <<EOF
pattern ${func%:*}(b:bat[:${tp1#*:}]) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B.";
pattern ${func%:*}(b:bat[:${tp1#*:}],nil_if_empty:bit) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B.";
pattern ${func%:*}(b:bat[:${tp1#*:}],s:bat[:oid]) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B with candidate list.";
pattern ${func%:*}(b:bat[:${tp1#*:}],s:bat[:oid],nil_if_empty:bit) :${tp2#*:}
address CMDBAT${func%:*}
comment "Calculate aggregate ${func#*:} of B with candidate list.";

EOF
	    fi
	done
    done
done
