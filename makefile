GTEST_DIR=googletest/googletest
GMOCK_DIR=googletest/googlemock
TEST_DIR=test
SRC_DIR=src
BUILD_DIR=build

CXX =g++
CXXFLAGS =-g -Wall -pthread -std=c++11 -DBOOST_LOG_DYN_LINK  
CXXLINK =-lboost_system -lboost_log -lboost_regex -lmysqlcppconn
TESTFLAGS =-std=c++11 -isystem ${GTEST_DIR}/include -isystem ${GMOCK_DIR}/include -DBOOST_LOG_DYN_LINK
TESTARGS =-pthread
TESTLINK =-L./build/ -lgmock -lgtest -lboost_system -lboost_log -lboost_regex -lpthread

CCFILE = src/*.cc
DEPS = src/*.h

all: create_table webserver

create_table:
	mysql -u root TSC < $(SRC_DIR)/create_table.sql

webserver: $(CCFILE) $(DEPS)
	$(CXX) -o $(BUILD_DIR)/$@ $(CCFILE) $(CXXFLAGS) $(CXXLINK)

.PHONY: clean test

test: unit_test integration_test

integration_test: webserver
	python $(TEST_DIR)/integration_test.py

unit_test: gtest_setup config_parser_test config_handler_test static_file_handler_test echo_handler_test request_handler_test connection_test
	./$(BUILD_DIR)/config_parser_test;\
	./$(BUILD_DIR)/config_handler_test;\
	./$(BUILD_DIR)/static_file_handler_test;\
	./$(BUILD_DIR)/echo_handler_test;\
	./$(BUILD_DIR)/request_handler_test;\
	./$(BUILD_DIR)/connection_test


gtest_setup:
	g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
    	-pthread -c ${GTEST_DIR}/src/gtest-all.cc
	ar -rv $(BUILD_DIR)/libgtest.a gtest-all.o

	g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
    	-isystem ${GMOCK_DIR}/include -I${GMOCK_DIR} \
    	-pthread -c ${GMOCK_DIR}/src/gmock-all.cc
	ar -rv $(BUILD_DIR)/libgmock.a gtest-all.o gmock-all.o
	rm gtest-all.o gmock-all.o

connection_test: $(TEST_DIR)/connection_test.cc $(SRC_DIR)/connection.cc $(SRC_DIR)/request_handler.cc
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@

config_parser_test: $(TEST_DIR)/config_parser_test.cc $(SRC_DIR)/config_parser.cc
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@

config_handler_test: $(TEST_DIR)/config_handler_test.cc $(SRC_DIR)/config_handler.cc 
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@

request_handler_test: $(TEST_DIR)/request_handler_test.cc $(SRC_DIR)/request_handler.cc
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@

static_file_handler_test: $(TEST_DIR)/static_file_handler_test.cc $(SRC_DIR)/static_file_handler.cc $(SRC_DIR)/request_handler.cc
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@

echo_handler_test: $(TEST_DIR)/echo_handler_test.cc $(SRC_DIR)/echo_handler.cc $(SRC_DIR)/request_handler.cc
	$(CXX) $(TESTFLAGS) $(TESTARGS) $^ ${GTEST_DIR}/src/gtest_main.cc $(TESTLINK) -o $(BUILD_DIR)/$@



test_coverage: TESTARGS += -fprofile-arcs -ftest-coverage

test_coverage: gtest_setup connection_test config_parser_test config_handler_test static_file_handler_test echo_handler_test request_handler_test
	./$(BUILD_DIR)/connection_test && gcov -r connection.cc;\
	./$(BUILD_DIR)/config_parser_test && gcov -r config_parser.cc;\
	./$(BUILD_DIR)/config_handler_test && gcov -r config_handler.cc;\
	./$(BUILD_DIR)/static_file_handler_test && gcov -r static_filehandler.cc;\
	./$(BUILD_DIR)/echo_handler_test && gcov -r echo_handler.cc;\
	./$(BUILD_DIR)/request_handler_test && gcov -r request_handler.cc;

drop_table:
	mysql -u root TSC < $(SRC_DIR)/drop_table.sql

clean: drop_table
	rm -rf $(BUILD_DIR)/* *.o *.a *.gcno *.gcov *.gcda



