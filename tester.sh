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
		if grep -q "Open file descriptor " "$valgrind_log"; then
			cat "$valgrind_log" >> "$errors"
			echo "" >> "$errors"
			#rm -f "$valgrind_log"
			return 2
		else
			rm -f "$valgrind_log"
			return 0
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

	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes  ../$PIPEX in/in-default.txt wcc lss > errors/valgrind_log.txt 2>&1
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
		printf "Mandatory TEST 1 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 1: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 1 leaks above\n" >> errors/errors_log.txt
	fi
	#test 2-> no input still creates an output file

	rm -f out/outfile2_1.txt
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX non-existingfile wc ls out/outfile2_1.txt > errors/valgrind_log.txt 2>&1
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
		printf "Mandatory TEST 2 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 2: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 2 leaks above\n" >> errors/errors_log.txt
	fi
	# test 3

	< in/in_default.txt ls | wc > out/outfile_shell.txt

	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_default.txt ls "wc" out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
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
		printf "Mandatory TEST 3 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 3: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 3 leaks above\n" >> errors/errors_log.txt
	fi
	#test 4

	< in/in_1.txt grep "nulla" | wc -l > out/outfile_shell.txt
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt "grep nulla" "wc -l" out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
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
		printf "Mandatory TEST 4 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 4: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 4 leaks above\n" >> errors/errors_log.txt
	fi
	#test 5 -> no env variables

	< in/in_default.txt ls | wc > out/outfile_shell.txt
	env -i ../$PIPEX in/in_default.txt ls wc out/outfile_user.txt > /dev/null 2>&1
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $CODE -eq 0 ]; then
		printf "\t\t${BLUE}TEST 5: ${RED}KO${RST}\n"
		printf "mandatory TEST 5: failed test without env variables this could also be if you are returning exit code 0 when there are no env variables" >> errors/errors_log.txt
	else
		printf "\t\t${BLUE}TEST 5: ${GREEN}OK${RST}\n"
	fi
	#test 6

	< in/in_1.txt /bin/ls | /usr/bin/wc > out/outfile_shell.txt
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt /bin/ls /usr/bin/wc out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
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
		printf "Mandatory TEST 6 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 6: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 6 leaks above\n" >> errors/errors_log.txt
	fi
	#Test 7

	( < in/in_default.txt whoami | cat > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_default.txt whoami cat out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
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
		printf "Mandatory TEST 7 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 7: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 7 leaks above\n" >> errors/errors_log.txt
	fi
	#TEST 8 ->invalid commands

	( < in/in_default.txt no_command | ls > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_default.txt no_command ls out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 8: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 8: ${RED}KO${RST}\n"
			printf "mandatory TEST 8: failed with input: ./pipex in/in_default.txt no_command ls out/outfile_user.txt(invalid command)\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 8: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Mandatory TEST 8 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 8: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 8 leaks above\n" >> errors/errors_log.txt
	fi
	# Test 9

	( < in/in_default.txt no_command | nocommand > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_default.txt nocommand no_command out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 9: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 9: ${RED}KO${RST}\n"
			printf "mandatory TEST 9: invalid command\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 9: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Mandatory TEST 9 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 9: ${YELLOW}KO->open fds ${RST}\n"
		printf "Mandatory TEST 9 leaks above\n" >> errors/errors_log.txt
	fi
}

bonus() {
	printf "${MAGENTA}Bonus part:\n${RST}"
	#Test 1

	( < in/in_1.txt grep nulla | sort | cat > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt "grep nulla" sort cat out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 1: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 1: ${RED}KO${RST}\n"
			printf "Bonus TEST 1: input-> ./pipex in/in_1.txt grep nulla sort cat out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 1: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Bonus TEST 1 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 1: ${YELLOW}KO->open fds ${RST}\n"
		printf "Bonus TEST 1 leaks above\n" >> errors/errors_log.txt
	fi
	#Test 2

	( < in/in_1.txt cat | grep odio | grep -E a$ | wc -l > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt cat "grep odio" "grep -E a$" "wc -l" out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 2: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 2: ${RED}KO${RST}\n"
			printf "mandatory TEST 2: input -> ./pipex in/in_1.txt cat grep odio grep -E a$ wc -l out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 2: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Bonus TEST 2 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 2: ${YELLOW}KO->open fds ${RST}\n"
		printf "Bonus TEST 2 leaks above\n" >> errors/errors_log.txt
	fi

	#Test 3

	( < in/in_1.txt cat | grep -v a | grep -E s$ > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt cat "grep -v a" "grep -E s$" out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 3: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 3: ${RED}KO${RST}\n"
			printf "mandatory TEST 3: input -> ./pipex in/in_1.txt cat grep -v a grep -E s$ out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 3: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Bonus TEST 3 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 3: ${YELLOW}KO->open fds ${RST}\n"
		printf "Bonus TEST 3 leaks above\n" >> errors/errors_log.txt
	fi
	#Test 4

	( < in/in_1.txt ls -l | cat | wcc | ls | cat > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_1.txt "ls -l" cat wcc ls cat out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 4: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 4: ${RED}KO${RST}\n"
			printf "mandatory TEST 4(invalid command): input -> ./pipex in/in_1.txt ls -l cat wcc ls cat out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 4: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Bonus TEST 4 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 4: ${YELLOW}KO->open fds ${RST}\n"
		printf "Bonus TEST 4 leaks above\n" >> errors/errors_log.txt
	fi
	#TEST 5

	( < in/in_awk.txt awk -F | '$2 > 80 {print $1}' in | grep '^A' | wc -l > out/outfile_shell.txt ) >/dev/null 2>&1
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ../$PIPEX in/in_awk.txt "awk -F, '\$2 > 80 {print \$1}'" "grep '^A'" "wc -l" out/outfile_user.txt > errors/valgrind_log.txt 2>&1
	check_valgrind
	VALGRIND_CODE=$?
	diff --brief out/outfile_shell.txt out/outfile_user.txt > /dev/null 2>&1
	CODE=$?
	if [ $VALGRIND_CODE -eq 0 ]; then
		if [ $CODE -eq 0 ]; then
			printf "\t\t${BLUE}TEST 5: ${GREEN}OK${RST}\n"
		else
			printf "\t\t${BLUE}TEST 5: ${RED}KO${RST}\n"
			printf "mandatory TEST 5: input -> ./pipex in/in_awk.txt awk -F, \$2 > 80 {print \$1} grep ^A wc -l out/outfile_user.txt\n" >> errors/errors_log.txt
		fi
	elif [ $VALGRIND_CODE -eq 1 ]; then
		printf "\t\t${BLUE}TEST 5: ${YELLOW}KO->memory leaks ${RST}\n"
		printf "Bonus TEST 5 leaks above\n" >> errors/errors_log.txt
	elif [ $VALGRIND_CODE -eq 2 ]; then
		printf "\t\t${BLUE}TEST 5: ${YELLOW}KO->open fds ${RST}\n"
		printf "Bonus TEST 5 leaks above\n" >> errors/errors_log.txt
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
	mandatory
	bonus
elif [ "$1" == "h" ]; then
	echo "here_doc"
else
	echo "Invalid option"
	exit
fi
printf "\n\n${BOLD}You can find error logs in errors/errors_log.txt${RST}\n"
make -C .. fclean > /dev/null