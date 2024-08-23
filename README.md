# tempot
Template POT extractor. Currently supported Twig.

Main idea behind this is to provide alternative solution for translation key extraction without needs to install php and twig parser.

Package depends on GNU gettext which should be installed before running it. Just download, chmod +x tempot.sh and put it somewhere in your project.

Usage example:

tempot.sh --php "./modules ./www" --twig "./views" --output "./dict.pot" --output-json "./dict.json"

it assumes your php files in ./modules and ./www contain translatable strings in format __('some key') and also you have some of them like {{ __('another key') }} in your .twig files located in ./views directory.
It will generate ./dict.pot POT file and ./dict.json file with alphabetically sorted translation keys and empty values. It's useful to keep both for better traceability of missing translations.
