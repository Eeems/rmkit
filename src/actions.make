include ../common.make
SRC_DIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR=$(shell realpath -s ${SRC_DIR}/../)
APP?=$(EXE:.exe=)


compile:
ifeq ($(ARCH),x86)
	make compile_x86
else ifeq ($(ARCH),arm)
	make compile_arm
else ifeq ($(ARCH),arm-dev)
	make compile_arm_fast
else ifeq ($(ARCH),dev)
	make compile_dev
else
	# Unsupported arch: ${ARCH}
	exit 1
endif

clean-default:
	rm ${SRC_DIR}/build/${EXE}

compile_arm: ../build/stb.arm.o
compile_arm: export CPP_FLAGS += -O2
compile_arm: export OKP_FLAGS += ../build/stb.arm.o
compile_arm:
	CXX=${CXX_BIN} okp ${OKP_FLAGS} -- -D"REMARKABLE=1" -D${RMKIT_IMPL} ${CPP_FLAGS}

compile_arm_fast: ../build/stb.arm.o
compile_arm_fast: export CPP_FLAGS += -O0 -g
compile_arm_fast: export OKP_FLAGS += ../build/stb.arm.o
compile_arm_fast:
	CXX=${CXX_BIN} okp ${OKP_FLAGS} -- -D"REMARKABLE=1" -D${RMKIT_IMPL} ${CPP_FLAGS}

compile_dev: ../build/stb.x86.o
compile_dev: export CPP_FLAGS += -O0 -g
compile_dev: export OKP_FLAGS += ../build/stb.x86.o
compile_dev:
	okp ${OKP_FLAGS} --  -D${RMKIT_IMPL} -D"DEV=1" ${CPP_FLAGS} -D"DEV_KBD=\"${KBD}\""

compile_x86: ../build/stb.x86.o
compile_x86: export CPP_FLAGS += -O0 -g
compile_x86: export OKP_FLAGS += ../build/stb.x86.o
compile_x86:
	okp ${OKP_FLAGS} -- ${CPP_FLAGS}

../build/stb.x86.o: ../vendor/stb/stb.cpp
	mkdir ../build 2> /dev/null || true
	g++ -c ../vendor/stb/stb.cpp -o ../build/stb.x86.o -fPIC -Os

../build/stb.arm.o: ../vendor/stb/stb.cpp
	mkdir ../build 2> /dev/null || true
	${CXX_BIN} -c ../vendor/stb/stb.cpp -o ../build/stb.arm.o -fPIC -Os

assets:
	# ${SRC_DIR} ${APP}
	bash ${ROOT_DIR}/scripts/build/build_assets.sh ${SRC_DIR}/${APP}/assets.h ${ASSET_DIR}

install-default:
	make copy

install_draft-default:
	ssh -C root@${HOST} mkdir -p /opt/etc/draft 2>/dev/null
	scp -C ${DRAFT} root@${HOST}:/opt/etc/draft/

resim:
	ARCH=dev make && cd ../../ && resim ./src/build/${EXE}

copy-default:
	ARCH=arm $(MAKE) compile
	if [ -n "${DRAFT}" ]; then make install_draft; fi

	ssh root@${HOST} killall -9 ${EXE} ${APP} || true
	ssh root@${HOST} mkdir -p ${DEST} 2>/dev/null
	scp -C ../build/${EXE} root@${HOST}:${DEST}/${EXE}


stop:
	ssh root@${HOST} killall -9 ${EXE} || true

run: compile copy
	ssh root@${HOST} systemctl stop xochitl
	ssh root@${HOST} ${DEST}/${EXE}

test: export ARCH=arm
test: copy
	HOST=${HOST} bash scripts/run_app_arm.sh ${EXE} || true

lint:
	make compile OKP_FLAGS="--lint ${OKP_FLAGS}"

reboot:
	ssh root@10.11.99.1 systemctl start xochitl

%: %-default
	@ true

.PHONY: assets clean reboot
# vim: syntax=make
