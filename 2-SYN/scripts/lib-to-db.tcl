set lib_file $::env(LIB_FILE)
set out_file $::env(OUT_DB)
set lib_name $::env(LIB_NAME)

read_lib -no_warnings $lib_file
write_lib -format db -output $out_file $lib_name
quit
