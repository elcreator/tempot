#/bin/bash
PHP_DIRS="."

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --php <dirs>            Specify the directories to search for PHP and PHTML files."
    echo "                          Provide multiple directories as a space-separated list."
    echo "                          Default: ."
    echo ""
    echo "  --twig <dirs>           Specify the directories to search for Twig files."
    echo "                          Provide multiple directories as a space-separated list."
    echo ""
    echo "  --output <file>         Specify the output .pot file."
    echo "                          This option is mandatory."
    echo ""
    echo "  --output-json <file>    Specify an output .json file. (Optional)"
    echo ""
    echo "  --help                  Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  $0 --php \"./modules ./www\" --twig \"./views\" --output ./i18n/i18n.pot"
    echo "  $0 --php \"./modules ./www\" --twig \"./views\" --output ./i18n/i18n.pot --output-json ./i18n/i18n.json"
    echo ""
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --php) PHP_DIRS="$2"; shift ;;
        --twig) TWIG_DIRS="$2"; shift ;;
        --output) OUTPUT_FILE="$2"; shift ;;
        --output-json) OUTPUT_JSON_FILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$OUTPUT_FILE" ]; then
    echo "You must specify an output file using the --output option."
    exit 1
fi

find $PHP_DIRS -type f \( -name "*.php" -o -name "*.phtml" \) |\
    xargs -r xgettext -s --language=PHP --keyword=__ --from-code=UTF-8 -o $OUTPUT_FILE

function process_twig_files() {
    TWIG_TEMP_DIR=$(mktemp -d)

    for TWIG_SEARCH_DIR in $TWIG_DIRS; do
        find $TWIG_SEARCH_DIR -name '*.twig' | while read -r TWIG_FILE; do
            RELATIVE_PATH="${TWIG_FILE#$TWIG_SEARCH_DIR/}"
            TEMP_FILE="$TWIG_TEMP_DIR/$RELATIVE_PATH"
            TWIG_TEMP_DIR_FOR_FILE=$(dirname "$TEMP_FILE")

            mkdir -p "$TWIG_TEMP_DIR_FOR_FILE"

            perl -0777 -pe '
            s/\s?__\(\s*(["'\''`].*?["'\''`])\s*(,\s*(.*?)\s*)?\)\s?/<?__($1$2)?>/gsx;
            ' "$TWIG_FILE" > "$TEMP_FILE"
        done
    done

    find "$TWIG_TEMP_DIR" -type f \( -name "*.twig" \) |\
        xargs -r xgettext -j -s --language=PHP --keyword=__ --from-code=UTF-8 -o $OUTPUT_FILE

    rm -rf $TWIG_TEMP_DIR

    TWIG_TEMP_DIR_NO_DOT="${TWIG_TEMP_DIR#./}"
    TWIG_SEARCH_DIR_NO_DOT="${TWIG_SEARCH_DIR#./}"
    sed -i '/^#: /s|'"$TWIG_TEMP_DIR_NO_DOT"'|'"$TWIG_SEARCH_DIR_NO_DOT"'|g' "$OUTPUT_FILE"
}

if [ -n "$TWIG_DIRS" ]; then
    process_twig_files
fi

if [ -z "$OUTPUT_JSON_FILE" ]; then
    exit
fi

msgcat --no-wrap --sort-output "$OUTPUT_FILE" | awk '
/^msgid / {
  if (msgid != "") {
    print "\"" msgid "\"";
  }
  msgid = $0;
  sub(/^msgid "/, "", msgid);
  sub(/"$/, "", msgid);
}
!/^msgid / && /^"/ {
  sub(/^"/, "", $0);
  sub(/"$/, "", $0);
  msgid = msgid $0;
}
END {
  if (msgid != "") {
    print "\"" msgid "\"";
  }
}' > "$OUTPUT_JSON_FILE"

sed -i ':a;N;$!ba;s/\n/: "",\n/g' "$OUTPUT_JSON_FILE"
sed -i 's/^/  /' "$OUTPUT_JSON_FILE"
sed -i '1s/.*/{/' "$OUTPUT_JSON_FILE"
truncate -s -1 "$OUTPUT_JSON_FILE"
echo -e ": \"\"\n}" >> "$OUTPUT_JSON_FILE"
