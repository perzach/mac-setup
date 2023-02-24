export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh


# export PATH=/opt/homebrew/bin:$PATH -- already included in default?
# export PATH=~/bin:$PATH -- already included in default?
# export PATH=~/go/bin/:$PATH

# Special aliases for x86_64 installations, to be set if needed:
# alias brewX86=/usr/local/Homebrew/bin/brew
# alias pythonX86=/usr/local/bin/python3
# alias pipX86='/usr/local/bin/python3 -m pip'

# Oracle instantclient setup, to be set if needed
# export PATH=/Users/per-oystein/Diverse/instantclient_19_8:$PATH
# export ORACLE_HOME=/Users/per-oystein/Diverse/instantclient_19_8
# export DYLD_LIBRARY_PATH=/Users/per-oystein/Diverse/instantclient_19_8
# export OCI_LIB_DIR=/Users/per-oystein/Diverse/instantclient_19_8
# export OCI_INC_DIR=/Users/per-oystein/Diverse/instantclient_19_8/sdk/include

# AWS Glue and pyspark setup, to be set if needed
# export SPARK_HOME=/Users/per-oystein/Diverse/spark-3.1.1-amzn-0-bin-3.2.1-amzn-3
# export AWS_GLUE_HOME=/Users/per-oystein/Diverse/aws-glue-libs-3.0
