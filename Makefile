#!/bin/bash

# https://www.gnu.org/software/make/manual/html_node/One-Shell.html
.ONESHELL: 

#################################
##### Definition of variables:

## Set the name of the user with admin privileges
## Their :-) password will be set at first login
adminLogin   := admin

# Name of the local folder for TLJH repository 
localDir     := tljh 

# Set the name of the containter
containername:= tljhcont

# Set port of your machine at which the JupyteHub service will be accessible
externalPort := 12000

# name of the local folder for the data (admin/users data) of TLJH server
dataDir      := data

# auxiliary variables
current_dir  := $(shell pwd)
PROJECTDIR   := "${current_dir}/${localDir}"
#################################

.PHONY: clean-auxiliary
## Clean auxiliary and temporary files
clean-auxiliary:
	find . -name '*.pyc' -exec rm --force {} \;
	find . -name '*.pyo' -exec rm --force {} \; 
	find . -name '*~'    -exec rm --force {} \;
	find acopti -name '__pycache__'    -exec rm --force --recursive {} \;
	find tests  -name '__pycache__'    -exec rm --force --recursive {} \;
	rm --force --recursive .pytest_cache
	# find , -name '__pycache__'    -exec rm --force --recursive {} \;   # this deletes __pycache__ also from venv
	find . -name '*~'    -exec rm --force {} \;
	find . -name '*.aux'    -exec rm --force {} \;
	find . -name '*.bbl'    -exec rm --force {} \;
	find . -name '*.blg'    -exec rm --force {} \;
	find . -name '*.log'    -exec rm --force {} \;
	find . -name '*.nav'    -exec rm --force {} \;
	find . -name '*.out'    -exec rm --force {} \;
	find . -name '*.snm'    -exec rm --force {} \;
	find . -name '*.synctex.gz'    -exec rm --force {} \;
	find . -name '*.toc'    -exec rm --force {} \;
	find . -name 'tmp_preprocess__*.do.txt'    -exec rm --force {} \;
	find . -name '*.dlog'    -exec rm --force {} \;
	find . -name '#*.org#'    -exec rm --force {} \;	
	find . -name '.#*.org'    -exec rm --force {} \;
	find . -name '.#*.tex'    -exec rm --force {} \;
	find . -name '.#*.pdf'    -exec rm --force {} \;

.PHONY: download-image
## Download image from repo
download-image:
	git clone https://github.com/jupyterhub/the-littlest-jupyterhub
	if [ ! -d ${PROJECTDIR} ]; then mkdir ${PROJECTDIR}; fi
	mv the-littlest-jupyterhub ${PROJECTDIR}

.PHONY: build-image
## Build image
build-image:
	docker build -t tljh-systemd . -f ${PROJECTDIR}/integration-tests/Dockerfile	
	docker run \
	--privileged \
	--detach \
	--name=${containername} \
	--publish ${externalPort}:80 \
	--mount type=bind,source=${PROJECTDIR},target=/srv/src \
	tljh-systemd
	
.PHONY: run-bootstraper
##  Prepare server configuration
run-bootstraper:
	# docker exec -it ${containername} /bin/bash
	# python3 /srv/src/bootstrap/bootstrap.py --admin menda
	docker exec -it ${containername} python3 /srv/src/bootstrap/bootstrap.py --admin ${adminLogin}
	
.PHONY: initialize-from-scratch
##  Initialize project from the scratch, create data directory only if it doesn't exist
initialize-from-scratch: download-image build-image start-server run-bootstraper
	if [ ! -d ${dataDir} ]; then mkdir ${dataDir}; fi
	
.PHONY: start-server
##  Start container 
start-server:
	docker start ${containername}

.PHONY: stop-server
##  Stop container 
stop-server:
	docker stop ${containername}
	
	
.PHONY: clean-whole-project
##  Clean project files
clean-whole-project:	
	@echo "Really want to do this? Uncomment the lines below and run 'make clean' again."
# 	docker stop ${containername} # stop container
# 	docker rm ${containername}   # remove container
# 	docker container prune       # remove all stopped containers
# 	docker system prune          # remove unused containers 
# 	${PROJECTDIR}
# 	rm -rf ${localDir}
# 	rm -rf data

.PHONY: testing
##  Testing 
testing:	
	echo ${var}
	rm -rf ${var}
	
.PHONY: info
##  Just for test. 2 Delete
info:
	echo ${current_dir}
	echo ${PROJECTDIR}
	
.PHONY: test
##  Process all tests in project 
test:
	echo "TODO"

	

# Plonk the following at the end of your Makefile
.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>

# 	+ bugfix:     https://github.com/drivendata/cookiecutter-data-science/issues/67

.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		    h; \
		    s/.*//; \
		    :doc" \
		-e "H; \
		    n; \
		    s/^## //; \
		    t doc" \
		-e "s/:.*//; \
		    G; \
		    s/\\n## /---/; \
		    s/\\n/ /g; \
		    p; \
	    }" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
	      -v ncol=$$(tput cols) \
	      -v indent=19 \
	      -v col_on="$$(tput setaf 6)" \
	      -v col_off="$$(tput sgr0)" \
	      '{ \
		    printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		    n = split($$2, words, " "); \
		    line_length = ncol - indent; \
		    for (i = 1; i <= n; i++) { \
			    line_length -= length(words[i]) + 1; \
			    if (line_length <= 0) { \
				    line_length = ncol - indent - length(words[i]) - 1; \
				    printf "\n%*s ", -indent, " "; \
			    } \
			    printf "%s ", words[i]; \
		    } \
		    printf "\n"; \
	    }' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
