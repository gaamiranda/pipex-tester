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


check_valgrind() {
	local valgrind_log="errors/valgrind_log.txt"
	local errors="errors/errors_log.txt"

	if grep -q "ERROR SUMMARY: 0 errors from 0 contexts" "$valgrind_log"; then
		if grep -q "FILE DESCRIPTORS: 4 open (3 std) at exit." "$valgrind_log"; then
			cat "$valgrind_log" >> "$errors"
			echo "" >> "$errors"
			rm -f "$valgrind_log"
			return 0
		else
			cat "$valgrind_log" >> "$errors"
			echo "" >> "$errors"
			rm -f "$valgrind_log"
			return 2
		fi
	else
		cat "$valgrind_log" >> "$errors"
		echo "" >> "$errors"
		rm -f "$valgrind_log"
		return 1
	fi
}

mandatory() {
	printf "${MAGENTA}Mandatory part:\n${RST}"
	#test 1-> Invalid argc

	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in-default.txt wcc lss > /dev/null 2>&1
	CODE=$?
	check_valgrind
	VALGRIND_CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 1: ${RED}KO${RST}\n"
			printf "mandatory TEST 1: Invalid argc(can be because you exit program with status 0)\n" >> errors/errors_log.txt
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
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX non-existingfile wc ls out/outfile2_1.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ -e out/outfile2_1.txt ]; then
			printf "\t\t${BLUE}TEST 2: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 2: ${RED}KO${RST}\n"
			printf "mandatory TEST 2: you need to create the outfile even if the infile doesnt exist\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 2: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 2: ${YELLOW}KO->open fds ${RST}\n"
	fi
	# test 3

	ls | wc > out/outfile_shell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_default.txt ls "wc" out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 3: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 3: ${RED}KO${RST}\n"
			printf "mandatory TEST 3: failed with input ./pipex in/in_default.txt ls wc out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 3: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 3: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#test 4

	< in/in_1.txt grep "nulla" | wc -l > out/outfileshell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_1.txt "grep nulla" "wc -l" out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 4: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 4: ${RED}KO${RST}\n"
			printf "mandatory TEST 4: failed with input ./pipex in/in_1.txt grep nulla wc -l out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 4: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 4: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#test 5 -> no env variables

	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt env -i ../$PIPEX in/in_default.txt ls wc out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	check_valgrind
	VALGRIND_CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 5: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 5: ${RED}KO${RST}\n"
			printf "mandatory TEST 5: failed test without env variables this could also be if you are returning exit code 0 when there are no env variables" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 5: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 5: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#test 6

	< in/in_1.txt /bin/ls | /usr/bin/wc > out/outfileshell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_1.txt /bin/ls /usr/bin/wc out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 6: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 6: ${RED}KO${RST}\n"
			printf "mandatory TEST 6: failed with input: ./pipex in/in_1.txt /bin/ls /usr/bin/wc out/outfile_user.txt(this could also be if these commands are in a different path) \n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 6: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 6: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#Test 7

	< in_default.txt whoami | cat > out/outfileshell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_default.txt whoami cat out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 7: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 7: ${RED}KO${RST}\n"
			printf "mandatory TEST 7: failed with input: ./pipex in/in_default.txt whoami cat out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 7: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 7: ${YELLOW}KO->open fds ${RST}\n"
	fi
	#TEST 8 ->invalid commands

	< in_default.txt no_command | ls > out/outfileshell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_default.txt no_command ls out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 127 ]; then
			printf "\t\t${BLUE}TEST 8: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 8: ${RED}KO${RST}\n"
			printf "mandatory TEST 8: failed with input: ./pipex in/in_default.txt no_command ls out/outfile_user.txt(invalid command)->invalid command returns 127\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 8: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 8: ${YELLOW}KO->open fds ${RST}\n"
	fi
	# Test 9

	< in_default.txt nocommand | no_command > out/outfileshell.txt > /dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --log-file=errors/valgrind_log.txt ../$PIPEX in/in_default.txt nocommand no_command out/outfile_user.txt > /dev/null 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 127 ]; then
			printf "\t\t${BLUE}TEST 9: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 9: ${RED}KO${RST}\n"
			printf "mandatory TEST 9: invalid command should return 127\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 9: ${YELLOW}KO->memory leaks ${RST}\n"
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 9: ${YELLOW}KO->open fds ${RST}\n"
	fi
}


make -C .. re > /dev/null
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
make -C .. fclean > /dev/null