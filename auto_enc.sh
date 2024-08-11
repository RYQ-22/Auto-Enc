#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NO_COLOR='\033[0m' # Reset color to default

# Check command line arguments
if [ "$#" -ne 3 ]; then
    echo -e "${RED}[Fail]${NO_COLOR} Usage: $0 <enc|dec> <password_file> <directory>"
    exit 1
fi

MODE=$1
PASSWORD_FILE=$2
TARGET_DIR=$3

# Check if the password file exists
if [ ! -f "$PASSWORD_FILE" ]; then
    echo -e "${RED}[Fail]${NO_COLOR} Password file does not exist at $PASSWORD_FILE. Please provide a valid password file."
    exit 1
fi

# Read the password
PASSWORD=$(cat "$PASSWORD_FILE")

# Process files in the specified directory
cd "$TARGET_DIR" || exit
find "$TARGET_DIR" -type f ! -name "$(basename "$0")" ! -name "$(basename "$PASSWORD_FILE")" -print0 | while IFS= read -r -d $'\0' file; do
    case $MODE in
    enc)
        if [[ "$file" == *.enc ]]; then
            echo -e "${YELLOW}[Warning]${NO_COLOR} $file is already an encrypted file."
            continue
        fi
        # Encrypt the file
        openssl enc -aes-256-cbc -in "$file" -out "${file}.enc" -pass pass:"$PASSWORD" -pbkdf2 -iter 10000
        if [ $? -eq 0 ]; then
            rm "$file"
            echo -e "${GREEN}[Success]${NO_COLOR} File $file encrypted."
        else
            echo -e "${RED}[Fail]${NO_COLOR} Encryption failed for file $file."
        fi
        ;;
    dec)
        if [[ "$file" != *.enc ]]; then
            echo -e "${YELLOW}[Warning]${NO_COLOR} $file is not an encrypted file."
            continue
        fi
        # Decrypt the file
        DECRYPTED_FILENAME="${file%.enc}"
        openssl enc -aes-256-cbc -d -in "$file" -out "$DECRYPTED_FILENAME" -pass pass:"$PASSWORD" -pbkdf2 -iter 10000
        if [ $? -eq 0 ]; then
            rm "$file"
            echo -e "${GREEN}[Success]${NO_COLOR} File $file decrypted."
        else
            echo -e "${RED}[Fail]${NO_COLOR} Decryption failed for file $file."
        fi
        ;;
    *)
        echo -e "${RED}[Fail]${NO_COLOR} Invalid mode $MODE. Use 'enc' or 'dec'."
        exit 1
        ;;
    esac
done

echo "END."
