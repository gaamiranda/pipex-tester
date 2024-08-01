#!/bin/bash

RST="\033[0m"
BOLD="\033[1m"
ULINE="\033[4m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
PIPEX=pipex
PIPEX_BONUS=pipex_bonus

check_valgrind() {
	local valgrind_log="errors/valgrind_log.txt"

	if grep -q "ERROR SUMMARY: 0 errors from 0 contexts" "$valgrind_log"; then
		if grep -q "FILE DESCRIPTORS: 3 open" "$valgrind_log"; then
			rm -f "$valgrind_log"
			return 0
		else
			rm -f "$valgrind_log"
			return 2
		fi
	else
		rm -f "$valgrind_log"
		return 1
	fi
}

mandatory() {
	printf "${MAGENTA}Mandatory part:\n${RST}"
	make -C .. re > /dev/null
	#test 1-> Invalid argc
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in-default.txt wc ls > /dev/null 2>&1
	CODE=$?
	check_valgrind
	VALGRIND_CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 1: ${RED}KO${RST}\n"
			printf "mandatory test 1: Invalid argc(can be because you exit program with status 0)\n" >> errors/errors_log.txt
		else
			printf "\t\t${BLUE}TEST 1: ${GREEN}OK${RST}\n"
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 1: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 1: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#test 2-> no input still creates an output file
	rm -f out/outfile2_1.txt
	fi
	../$PIPEX non-existingfile wc ls out/outfile2_1.txt > /dev/null 2>&1
	if [ -e out/outfile2_1.txt ]; then
		printf "\t\t${BLUE}TEST 2: ${GREEN}OK${RST}\n"
	else
		printf "\t\t${BLUE}TEST 2: ${RED}KO${RST}\n"
		printf "mandatory test 2: you need to create the outfile even if the infile doesnt exist\n" >> errors/errors_log.txt
	fi
	# test 3-> ls wc -l
	ls | wc -l > out/outfile3.txt
	../$PIPEX in/in_default.txt ls "wc -l" out/outfile3_1.txt > /dev/null 2>&1
	diff --brief out/outfile3.txt out/outfile3_1.txt
	CODE=$?
	if [ $CODE -eq 0 ]; then
		printf "\t\t${BLUE}TEST 3: ${GREEN}OK${RST}\n"
	else
		printf "\t\t${BLUE}TEST 3: ${RED}KO${RST}\n"
	fi





	make -C .. fclean > /dev/null
}









printf "Errors:\n" > errors/errors_log.txt
printf "\t\t\t${GREEN}Welcome to pipex-tester by gaamiranda${RST}\n"
printf "\t\t\t${GREEN}If it helps you give a star :)${RST}\n"

if [ -z "$1" ]; then
	printf "${RED}main bonus${RST}"
elif [ "$1" == "m" ]; then
	mandatory
elif [ "$1" == "b" ]; then
	echo "multiple pipes"
elif [ "$1" == "h" ]; then
	echo "here_doc"
else
	echo "Invalid option"
fi
printf "\n\n${BOLD}You can find error logs in errors/errors_log.txt${RST}\n"