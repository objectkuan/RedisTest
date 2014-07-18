
RSERVER="sinatest03"
RCLIENT="sinatest01"
RCLIENT2="sinatest05"
SERVERIP="192.168.0.180"

SERVER_DIR="/home/hcho.ho/test/server/redis"
MEASURE_DIR="/home/hcho.ho/test/server/measures"
CLIENT_DIR="/home/hcho.ho/test/client/redis"
CLIENT2_DIR="/home/hcho.ho/test/client/redis"

measures=("cpu" "throughput")

NTUPLE="on"
RFS_ENABLED=0
RPS_ENABLED=0

RECORD_TIME=120

#####################
# Choose to test
#####################
TEST_RSS=1
TEST_ATR=2
TEST_RFS=3
TEST_RFS_ATR=4
TEST_NEW=5
TEST_NEW_ATR=6


if [ $DO_TEST -eq $TEST_RSS ]; then
	echo "RSS"
	NTUPLE="on"
	RFS_ENABLED=0
elif [ $DO_TEST -eq $TEST_ATR ]; then
	echo "ATR"
	NTUPLE="off"
	RFS_ENABLED=0
elif [ $DO_TEST -eq $TEST_RFS ]; then
	echo "RFS"
	NTUPLE="on"
	RFS_ENABLED=1
elif [ $DO_TEST -eq $TEST_RFS_ATR ]; then
	echo "RFS_ATR"
	NTUPLE="off"
	RFS_ENABLED=1
elif [ $DO_TEST -eq $TEST_NEW ]; then
	echo "NEW"
	NTUPLE="on"
elif [ $DO_TEST -eq $TEST_NEW_ATR ]; then
	echo "NEW_ATR"
fi
###################

