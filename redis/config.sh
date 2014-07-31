

RSERVER="10.216.25.44"
RCLIENT="10.216.25.43"
RCLIENT2="10.216.25.60"
SERVERIP="10.216.26.44"

SERVER_DIR="/home/hcho.ho/test/server/redis"
MEASURE_DIR="/home/hcho.ho/test/server/measures"
CLIENT_DIR="/home/hcho.ho/test/client/redis"
CLIENT2_DIR="/home/hcho.ho/test/client/redis"

#measures=("llc")
measures=("cpu" "throughput" "llc")


NTUPLE="off"
NTRULE=0
RFS_ENABLED=0
RPS_ENABLED=0

RECORD_TIME=12000

#####################
# Choose to test
#####################
TEST_RSS=1
TEST_ATR=2
TEST_RFS=3
TEST_RFS_ATR=4
TEST_NEW=5
TEST_NEW_ATR=6
TEST_P_NTUPLE=7


if [ $DO_TEST -eq $TEST_RSS ]; then
	echo "RSS"
	NTUPLE="on"
	NTRULE=0
	RFS_ENABLED=0
elif [ $DO_TEST -eq $TEST_ATR ]; then
	echo "ATR"
	NTUPLE="off"
	NTRULE=0
	RFS_ENABLED=0
elif [ $DO_TEST -eq $TEST_RFS ]; then
	echo "RFS"
	NTUPLE="on"
	NTRULE=0
	RFS_ENABLED=1
elif [ $DO_TEST -eq $TEST_RFS_ATR ]; then
	echo "RFS_ATR"
	NTUPLE="off"
	NTRULE=0
	RFS_ENABLED=1
elif [ $DO_TEST -eq $TEST_NEW ]; then
	echo "NEW"
	NTUPLE="on"
	NTRULE=0
elif [ $DO_TEST -eq $TEST_NEW_ATR ]; then
	echo "NEW_ATR"
elif [ $DO_TEST -eq $TEST_P_NTUPLE ]; then
	echo "PERFECT_NUTPLE"
	NTUPLE="on"
	NTRULE=1
fi
###################

