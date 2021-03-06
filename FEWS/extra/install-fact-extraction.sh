#!/usr/bin/env bash
# Setup fact-extraction on Ubuntu 16.04
# J.Graham@software.ac.uk

source ~/.profile

SQL_USER="intelanalysis"
SQL_DB_NAME="intelanalysis"
SQL_SCHEMA_NAME="factextract"
SQL_PASSWORD="passw0rd"

FACT_EXTRACTION_DIR=${CISPACES}/tools/fact-extraction
FACT_EXTRACTION_REPO="https://github.com/CISpaces/factextraction.git"

usage="$(basename "$0") [-h] [-y]

where:
    -h  Show this help text
    -y  Automatically answer yes for all questions
    -e  Setup over existing installation"

yes='false'
existing='false'
while getopts 'yhe' flag; do
    case "${flag}" in
        y) yes='true' ;;
        h) echo "${usage}"
           exit ;;
        e) existing='true' ;;
        *) exit 1 ;;
    esac
done

echo "### - Set up fact-extraction on Ubuntu 16.04...? (Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi

echo "# - Installing prerequisites [postgresql, postgis, curl, ant, python2.7(dev), python-virtualenv, gcc]...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
if [ "${existing}" != 'true' ]; then sudo apt-get install --yes postgresql postgis curl ant python2.7 python2.7-dev python-virtualenv gcc; fi
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Download fact-extraction...? (Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
if [ "${existing}" != 'true' ]; then
    git clone ${FACT_EXTRACTION_REPO} ${FACT_EXTRACTION_DIR}
else
    git -C ${FACT_EXTRACTION_DIR} pull --ff-only
fi
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi
echo

echo "# - Creating role and database...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
if [ "${existing}" != 'true' ]; then sudo -u postgres createuser ${SQL_USER} -w; fi
if [ "${existing}" != 'true' ]; then sudo -u postgres createdb ${SQL_DB_NAME}; fi
sudo -u postgres psql -d ${SQL_DB_NAME} < FEWS/extra/create_vocab_tables.sql &&
    sudo -u postgres psql -d ${SQL_DB_NAME} < FEWS/extra/intelanalysis_factextract_vocab_topic.sql &&
    sudo -u postgres psql -d ${SQL_DB_NAME} < FEWS/extra/intelanalysis_factextract_vocab_keyword.sql &&
    sudo -u postgres psql -d ${SQL_DB_NAME} < ${FACT_EXTRACTION_DIR}/corpus/database-phase1/scenario-18-dec-2017.sql &&
    echo "ALTER USER ${SQL_USER} WITH PASSWORD '${SQL_PASSWORD}';" | sudo -u postgres psql -d ${SQL_DB_NAME} &&
    echo "GRANT ALL ON SCHEMA ${SQL_SCHEMA_NAME} TO ${SQL_USER};" | sudo -u postgres psql -d ${SQL_DB_NAME} &&
    echo "GRANT ALL ON ALL TABLES IN SCHEMA ${SQL_SCHEMA_NAME} TO ${SQL_USER};" | sudo -u postgres psql -d ${SQL_DB_NAME} &&
    echo "GRANT ALL ON ALL SEQUENCES IN SCHEMA ${SQL_SCHEMA_NAME} TO ${SQL_USER};" | sudo -u postgres psql -d ${SQL_DB_NAME}
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Setting database permissions...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
echo "GRANT ALL ON SCHEMA ${SQL_SCHEMA_NAME} TO ${SQL_USER};" | sudo -u postgres psql -d ${SQL_DB_NAME} &&
    echo "GRANT ALL ON ALL TABLES IN SCHEMA ${SQL_SCHEMA_NAME} TO ${SQL_USER};" | sudo -u postgres psql -d ${SQL_DB_NAME}
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Modifying PostgreSQL config...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
sudo sed -i.bak "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/9.5/main/postgresql.conf &&
    echo "host    ${SQL_DB_NAME}     ${SQL_USER}             all                     password" | sudo tee --append /etc/postgresql/9.5/main/pg_hba.conf
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Modifying RabbitMQ config...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
if [ "${existing}" != 'true' ]; then sudo rabbitmqctl add_user ${SQL_USER} ${SQL_PASSWORD}; fi
sudo rabbitmqctl set_user_tags ${SQL_USER} administrator &&
    sudo rabbitmqctl set_permissions ${SQL_USER} ".*" ".*" ".*"
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Restarting services...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
sudo systemctl restart postgresql rabbitmq-server &&
    sudo systemctl enable postgresql rabbitmq-server
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Download fact-extraction dependencies...? (Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
mkdir -p ${FACT_EXTRACTION_DIR}/third-party/download &&
    wget -r -np -k -A whl -nd -nc -P ${FACT_EXTRACTION_DIR}/third-party http://southampton.ac.uk/~sem03/intelanalysis-dstl/ &&
    wget -nc -P ${FACT_EXTRACTION_DIR}/third-party/download https://nlp.stanford.edu/software/stanford-postagger-full-2016-10-31.zip &&
    wget -nc -P ${FACT_EXTRACTION_DIR}/third-party/download https://nlp.stanford.edu/software/stanford-parser-full-2016-10-31.zip &&
    wget -nc -P ${FACT_EXTRACTION_DIR}/third-party/download https://nlp.stanford.edu/software/stanford-english-corenlp-2016-10-31-models.jar
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi
echo

echo "# - Setting up virtualenv...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
if [ "${existing}" != 'true' ]; then virtualenv -p python2.7 ${FACT_EXTRACTION_DIR}/env; fi
source ${FACT_EXTRACTION_DIR}/env/bin/activate
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Install Python requirements...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
cp $(dirname $0)/requirements.txt ${FACT_EXTRACTION_DIR}/requirements.txt &&
    xargs -L 1 pip install < ${FACT_EXTRACTION_DIR}/requirements.txt &&
    pip install ${FACT_EXTRACTION_DIR}/third-party/*none-any.whl &&
    python -m nltk.downloader stopwords names
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Extract Stanford CoreNLP...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
rm -rf ${FACT_EXTRACTION_DIR}/third-party/stanford-parser-full-2016-10-31 &&
    unzip ${FACT_EXTRACTION_DIR}/third-party/download/stanford-parser-full-2016-10-31.zip -d ${FACT_EXTRACTION_DIR}/third-party &&
    rm -rf ${FACT_EXTRACTION_DIR}/third-party/stanford-postagger-full-2016-10-31 &&
    unzip ${FACT_EXTRACTION_DIR}/third-party/download/stanford-postagger-full-2016-10-31.zip -d ${FACT_EXTRACTION_DIR}/third-party &&
    ln -sf ${FACT_EXTRACTION_DIR}/third-party/download/stanford*models.jar ${FACT_EXTRACTION_DIR}/third-party/stanford-parser-full-2016-10-31/.
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Configure fact-extraction...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
CONFIG_FILE=${FACT_EXTRACTION_DIR}/config/fact_extraction_app/fact_extraction_app.ini
sed -i "s:^stanford_tagger_dir=.*:stanford_tagger_dir=${FACT_EXTRACTION_DIR}/third-party/stanford-postagger-full-2016-10-31:g" ${CONFIG_FILE} &&
    sed -i "s:^stanford_parser_dir=.*:stanford_parser_dir=${FACT_EXTRACTION_DIR}/third-party/stanford-parser-full-2016-10-31:g" ${CONFIG_FILE} &&
    sed -i "s:^model_jar=.*:model_jar=${FACT_EXTRACTION_DIR}/third-party/stanford-parser-full-2016-10-31/stanford-english-corenlp-2016-10-31-models.jar:g" ${CONFIG_FILE} &&
    sed -i "s:^db_user=.*:db_user=intelanalysis:g" ${FACT_EXTRACTION_DIR}/config/fact_extraction_app/fact_extraction_app.ini &&
    sed -i "s:^db_pass=.*:db_pass=${SQL_PASSWORD}:g" ${FACT_EXTRACTION_DIR}/config/fact_extraction_app/fact_extraction_app.ini &&
    sed -i "s:^unit_test_publish_vocab=.*:unit_test_publish_vocab=False:g" ${FACT_EXTRACTION_DIR}/config/fact_extraction_app/fact_extraction_app.ini &&
    sed -i "s:^input_file=.*:input_file=:g" ${FACT_EXTRACTION_DIR}/config/fact_extraction_app/fact_extraction_app.ini &&
    sed -i "s:/projects-git/intel-analysis-dstl/fact-extraction:${FACT_EXTRACTION_DIR}:g" ${CONFIG_FILE}
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

echo "# - Modify Python source...(Y/n)"
if [ "${yes}" != 'true' ]; then read stopgo; if [ "$stopgo" == "n" ]; then exit 0; fi; fi
sed -i "s#connection.socket#connection#g" ${FACT_EXTRACTION_DIR}/src/fact_extraction_app/RabbitMQHandler.py
if [ $? -eq 0 ]; then echo "[OK]"; else echo "[Failed]"; exit; fi

if [ $? -eq 0 ]; then echo "[OK] - Fact-extraction set up."; else echo "[Failed]"; exit; fi
