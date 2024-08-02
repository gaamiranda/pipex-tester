# pipex tester

Tester for pipex(42 School)

> This tester also checks for leaks and open file descriptors

> It will not check norminette

**How to run the tester?**
```
git clone https://github.com/gaamiranda/pipex-tester.git -> in the same directory as your Makefile
cd pipex-tester
./tester.sh
```
Different modes
```
./tester.sh -> will run all tests
./tester.sh m -> will run all mandatory tests
./tester.sh b -> will run all mandatory tests and multiple pipes bonus tests
./tester.sh h -> will run all here_doc tests
```

**Example**


![image](https://github.com/user-attachments/assets/35b266f0-8891-43f8-8b39-3065485da7f1)

As you can see above, if you get any errors you can find them in errors directory
