keygen:
	if [ ! -d "./ssh_keys" ]; then \
        /bin/mkdir ./ssh_keys; \
	fi
	if [ ! -f "./ssh_keys/rsa" ]; then \
		/usr/bin/ssh-keygen -b 2048 -t rsa -f ./ssh_keys/rsa -q -N ""; \
	fi